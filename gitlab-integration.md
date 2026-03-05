# GitLab Integration für Superset MCP Service

> **Anleitung zur Integration in GitLab CI/CD Pipeline und GitOps**

## 🎯 Übersicht

GitLab bietet native Unterstützung für OpenShift Deployments und kann mit dem Superset MCP Service über verschiedene Methoden integriert werden:

1. **GitLab CI/CD Pipeline** für automatisierte Builds und Deployments
2. **GitLab Container Registry** für Docker Images
3. **Argo CD (OpenShift GitOps)** für GitOps-Synchronisierung
4. **GitLab Pages** für Dokumentation

## 📋 Voraussetzungen

### GitLab Setup
- GitLab Instance (Self-hosted oder gitlab.com)
- GitLab Container Registry aktiviert
- OpenShift GitOps Operator (Argo CD) installiert
- OpenShift Cluster verbunden mit GitLab

### Berechtigungen
- `maintainer` Zugriff auf das Projekt
- OpenShift Cluster Admin-Rechte
- Container Registry Push-Rechte

## 🔧 GitLab CI/CD Konfiguration

### 1. `.gitlab-ci.yml` erstellen

```yaml
# .gitlab-ci.yml
stages:
  - build
  - deploy-dev
  - deploy-staging
  - deploy-production

variables:
  DOCKER_DRIVER: overlay2
  DOCKER_TLS_CERTDIR: "/certs"
  OPENSHIFT_PROJECT: "superset-mcp"
  DOCKER_BUILDKIT: 1

# Base Image
image: docker:24.0.5

services:
  - docker:24.0.5-dind

before_script:
  - docker info
  - echo $CI_REGISTRY_PASSWORD | docker login -u $CI_REGISTRY_USER --password-stdin $CI_REGISTRY

# Build Docker Image
build-image:
  stage: build
  script:
    - docker build --build-arg BUILDKIT_INLINE_CACHE=1 --cache-from $CI_REGISTRY_IMAGE:latest -f Dockerfile -t $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA -t $CI_REGISTRY_IMAGE:latest .
    - docker push $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
    - docker push $CI_REGISTRY_IMAGE:latest
  only:
    - main
    - develop

# Reusable OpenShift scripted deploy template
.openshift-scripted-deploy:
  image: quay.io/openshift/origin-cli:4.16
  script:
    - |
      set -eu
      : "${KUBE_CONTEXT:?KUBE_CONTEXT is required}"
      : "${OVERLAY_PATH:?OVERLAY_PATH is required}"
      : "${DATABASE_URI:?DATABASE_URI is required}"
      : "${REDIS_URL:?REDIS_URL is required}"

      oc config use-context "$KUBE_CONTEXT"
      oc get project "$OPENSHIFT_PROJECT" >/dev/null 2>&1 || oc new-project "$OPENSHIFT_PROJECT"

      oc create secret generic superset-mcp-secrets \
        --from-literal=superpassword="$SUPERSET_PASSWORD" \
        --from-literal=database-uri="$DATABASE_URI" \
        --from-literal=redis-url="$REDIS_URL" \
        --dry-run=client -o yaml | oc apply -f -

      TMP_KUSTOMIZE_FILE="$(mktemp)"
      cat > "$TMP_KUSTOMIZE_FILE" << EOF
      apiVersion: kustomize.config.k8s.io/v1beta1
      kind: Kustomization
      
      resources:
        - $OVERLAY_PATH
      
      images:
        - name: superset-mcp
          newName: $CI_REGISTRY_IMAGE
          newTag: $CI_COMMIT_SHA

      namespace: $OPENSHIFT_PROJECT
      EOF

      oc apply -f "$TMP_KUSTOMIZE_FILE"
      rm -f "$TMP_KUSTOMIZE_FILE"
      oc rollout status deployment/superset-mcp -n "$OPENSHIFT_PROJECT" --timeout="${DEPLOY_TIMEOUT:-300s}"

# Deploy to Development (scripted OpenShift pipeline)
deploy-dev:
  stage: deploy-dev
  extends: .openshift-scripted-deploy
  variables:
    KUBE_CONTEXT: $KUBE_CONTEXT_DEV
    OVERLAY_PATH: kustomize/overlays/development
    DATABASE_URI: $DATABASE_URI_DEV
    REDIS_URL: $REDIS_URL_DEV
    DEPLOY_TIMEOUT: 300s
  environment:
    name: development
    url: https://superset-mcp-dev.apps.cluster.example.com
  only:
    - develop

# Deploy to Staging (scripted OpenShift pipeline)
deploy-staging:
  stage: deploy-staging
  extends: .openshift-scripted-deploy
  variables:
    KUBE_CONTEXT: $KUBE_CONTEXT_STAGING
    OVERLAY_PATH: kustomize/overlays/staging
    DATABASE_URI: $DATABASE_URI_STAGING
    REDIS_URL: $REDIS_URL_STAGING
    DEPLOY_TIMEOUT: 300s
  environment:
    name: staging
    url: https://superset-mcp-staging.apps.cluster.example.com
  only:
    - main

# Deploy to Production (manual scripted OpenShift pipeline)
deploy-production:
  stage: deploy-production
  extends: .openshift-scripted-deploy
  variables:
    KUBE_CONTEXT: $KUBE_CONTEXT_PROD
    OVERLAY_PATH: kustomize/overlays/production
    DATABASE_URI: $DATABASE_URI_PROD
    REDIS_URL: $REDIS_URL_PROD
    DEPLOY_TIMEOUT: 600s
  environment:
    name: production
    url: https://superset-mcp.apps.cluster.example.com
  when: manual
  only:
    - main

# Security Scanning
container_scanning:
  stage: build
  script:
    - docker run --rm -v /var/run/docker.sock:/var/run/docker.sock 
      aquasec/trivy:latest image 
      --exit-code 0 
      --severity HIGH,CRITICAL 
      $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
  allow_failure: true
  only:
    - main
    - develop

# Dependency Scanning
dependency_scanning:
  stage: build
  image: python:3.11-slim
  script:
    - pip install safety
    - safety check --json --output safety-report.json || true
  artifacts:
    reports:
      dependency_scanning: safety-report.json
  only:
    - main
    - develop
```

### 2. GitLab Variables konfigurieren

In GitLab Project → Settings → CI/CD → Variables:

```bash
# CI/CD Variables
CI_REGISTRY_PASSWORD: [GitLab Token mit registry:write scope]
KUBE_CONTEXT_DEV: [OpenShift Context für Development]
KUBE_CONTEXT_STAGING: [OpenShift Context für Staging]
KUBE_CONTEXT_PROD: [OpenShift Context für Production]
OPENSHIFT_PROJECT: superset-mcp

# Required Secrets
SUPERSET_PASSWORD: [Superset Admin Passwort]
DATABASE_URI_DEV: [Development Database URI]
DATABASE_URI_STAGING: [Staging Database URI]
DATABASE_URI_PROD: [Production Database URI]
REDIS_URL_DEV: [Development Redis URL]
REDIS_URL_STAGING: [Staging Redis URL]
REDIS_URL_PROD: [Production Redis URL]
```

## 🚀 Argo CD GitOps

### 1. Argo CD Application Manifest

```yaml
# argocd/production-application.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: superset-mcp-production
  namespace: openshift-gitops
  finalizers:
    - resources-finalizer.argocd.argoproj.io
  labels:
    app.kubernetes.io/name: superset-mcp
    app.kubernetes.io/part-of: argocd-gitops
spec:
  project: default
  source:
    repoURL: http://gitlab.home.lab/openshift/superset-mcp-server.git
    targetRevision: main
    path: kustomize/overlays/production
  destination:
    server: https://kubernetes.default.svc
    namespace: superset-mcp
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
      - PruneLast=true
      - ApplyOutOfSyncOnly=true
```

### 2. Anwendung deployen

```bash
make -f Makefile-gitlab argocd-app

# Optional: parameterized apply
make -f Makefile-gitlab argocd-app-custom \
  ARGOCD_REPO_URL=http://gitlab.home.lab/openshift/superset-mcp-server.git \
  ARGOCD_TARGET_REVISION=main \
  ARGOCD_SOURCE_PATH=kustomize/overlays/production
```

## 📦 GitLab Container Registry

### 1. Registry Konfiguration

```bash
# Login bei GitLab Registry
docker login registry.gitlab.com

# Images taggen und pushen
docker tag superset-mcp:latest registry.gitlab.com/your-group/superset-mcp:latest
docker push registry.gitlab.com/your-group/superset-mcp:latest

# Mit Commit SHA taggen
docker tag superset-mcp:latest registry.gitlab.com/your-group/superset-mcp:$CI_COMMIT_SHA
docker push registry.gitlab.com/your-group/superset-mcp:$CI_COMMIT_SHA
```

### 2. Registry in Kustomize verwenden

```yaml
# kustomize/overlays/production/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ../../base

images:
  - name: superset-mcp
    newName: registry.gitlab.com/your-group/superset-mcp
    newTag: latest
```

## 🔒 GitLab Security Integration

### 1. Container Scanning

```yaml
# .gitlab-ci.yml (erweitert)
container_scanning:
  stage: build
  variables:
    GIT_STRATEGY: clone
    DOCKER_IMAGE: $CI_REGISTRY_IMAGE/full:$CI_COMMIT_SHA
  script:
    - docker run --rm -v /var/run/docker.sock:/var/run/docker.sock 
      aquasec/trivy:latest image 
      --exit-code 0 
      --severity HIGH,CRITICAL 
      --format json 
      --output gl-container-scanning-report.json 
      $DOCKER_IMAGE
  artifacts:
    reports:
      container_scanning: gl-container-scanning-report.json
  only:
    - main
    - develop
```

### 2. Secret Management

```yaml
# GitLab CI/CD mit External Secrets
deploy-production:
  stage: deploy-production
  image: quay.io/openshift/origin-cli:4.16
  script:
    - oc config use-context $KUBE_CONTEXT_PROD
    # Secrets aus GitLab Variables erstellen
    - |
      oc create secret generic superset-mcp-secrets \
        --from-literal=superpassword=$SUPERSET_PASSWORD \
        --from-literal=database-uri=$DATABASE_URI \
        --from-literal=redis-url=$REDIS_URL \
        --dry-run=client -o yaml | oc apply -f -
    - oc kustomize kustomize/overlays/production | oc apply -f -
  only:
    - main
```

## 📊 GitLab Monitoring

### 1. GitLab Prometheus Integration

```yaml
# kustomize/overlays/production/deployment-patch.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: superset-mcp
spec:
  template:
    metadata:
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "5008"
        prometheus.io/path: "/metrics"
        app.gitlab.com/env: "production"
        app.gitlab.com/app: "superset-mcp"
```

### 2. GitLab Environment Dashboard

```bash
# GitLab Project → Operations → Environments
# Automatische Umgebungserkennung durch CI/CD
```

## 🔄 GitOps Workflow

### 1. Branch Strategy

```bash
# Feature Branches
git checkout -b feature/new-chart-type
# Development → Auto-Deploy zu Development

# Main Branch
git checkout main
# Staging → Auto-Deploy zu Staging

# Production → Manual Deploy
```

### 2. Merge Request Templates

```markdown
<!-- .gitlab/merge_request_templates/feature.md -->
## Beschreibung
<!-- Beschreibung der Änderung -->

## Testing
- [ ] Unit Tests bestanden
- [ ] Integration Tests bestanden
- [ ] Manual Testing in Development

## Deployment
- [ ] Auto-Deploy zu Development
- [ ] Review für Staging Deployment
- [ ] Approval für Production Deployment

## Checklist
- [ ] Code Review abgeschlossen
- [ ] Security Scan bestanden
- [ ] Documentation aktualisiert
```

## 📋 GitLab Pages für Dokumentation

### 1. Pages CI/CD Job

```yaml
# .gitlab-ci.yml (erweitert)
pages:
  stage: deploy
  image: python:3.11-slim
  before_script:
    - pip install mkdocs mkdocs-material
  script:
    - mkdocs build
    - mv public ../
  artifacts:
    paths:
      - public
  only:
    - main
```

### 2. MkDocs Konfiguration

```yaml
# mkdocs.yml
site_name: Superset MCP Service
site_description: Apache Superset MCP Service Documentation

theme:
  name: material
  features:
    - navigation.instant
    - navigation.tracking
    - search.highlight

nav:
  - Home: index.md
  - Installation: installation.md
  - Configuration: configuration.md
  - API Reference: api.md
  - GitLab Integration: gitlab.md

plugins:
  - search
  - git-revision-date-localized
```

## 🚨 Troubleshooting

### Häufige GitLab CI/CD Probleme

**1. Docker Registry Login fehlgeschlagen**
```bash
# CI/CD Variable prüfen
echo $CI_REGISTRY_PASSWORD | docker login -u $CI_REGISTRY_USER --password-stdin $CI_REGISTRY
```

**2. OpenShift Context nicht gefunden**
```bash
# KUBE_CONTEXT Variable prüfen
oc config get-contexts
```

**3. Image Pull Fehler**
```bash
# Registry Permissions prüfen
docker pull registry.gitlab.com/your-group/superset-mcp:latest
```

**4. Kustomize Build Fehler**
```bash
# Syntax prüfen
oc kustomize kustomize/overlays/production > /dev/null
```

## 📚 Best Practices

1. **Environment Separation**: Verschiedene Namespaces pro Environment
2. **Secret Management**: GitLab CI/CD Variables für sensitive Daten
3. **Security Scanning**: Automatische Scans für alle Images
4. **GitOps**: Argo CD für synchronisierte Deployments
5. **Monitoring**: GitLab Environment Dashboard für Übersicht
6. **Documentation**: GitLab Pages für aktuelle Dokumentation
