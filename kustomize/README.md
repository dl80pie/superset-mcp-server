# Kustomize Konfiguration für Superset MCP Service

> **Declarative OpenShift Configuration Management mit Kustomize**

## 📁 Verzeichnisstruktur

```
kustomize/
├── base/                          # Basis-Konfiguration
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── route.yaml
│   ├── hpa.yaml
│   ├── secret.yaml
│   └── kustomization.yaml
├── overlays/                      # Environment-spezifische Overlays
│   ├── minimal/                   # Minimal-Version (ohne Screenshots)
│   │   ├── deployment-patch.yaml
│   │   └── kustomization.yaml
│   ├── with-selenium/            # Mit Selenium/Chrome
│   │   ├── deployment-patch.yaml
│   │   └── kustomization.yaml
│   ├── development/              # Development Environment
│   │   ├── deployment-patch.yaml
│   │   └── kustomization.yaml
│   ├── staging/                  # Staging Environment
│   │   ├── deployment-patch.yaml
│   │   └── kustomization.yaml
│   └── production/               # Production Environment
│       ├── deployment-patch.yaml
│       ├── networkpolicy.yaml
│       └── kustomization.yaml
└── README.md
```

## 🚀 Schnellstart

### Minimal Deployment
```bash
oc kustomize kustomize/overlays/minimal | oc apply -f -
```

### Mit Selenium Support
```bash
oc kustomize kustomize/overlays/with-selenium | oc apply -f -
```

### Production Deployment
```bash
oc kustomize kustomize/overlays/production | oc apply -f -
```

## 🔧 Konfiguration

### Environment Variablen
Setzen Sie die benötigten Environment Variablen:

```bash
export SUPERSET_MCP_URL="https://superset-mcp.apps.cluster.example.com"
export SUPERSET_PASSWORD="your-secure-password"
export DATABASE_URI="postgresql://superset:password@postgresql:5432/superset"
export REDIS_URL="redis://redis:6379/0"
```

### Secret Management
Kustomize unterstützt verschiedene Secret-Strategien:

1. **Generator** (empfohlen für Development)
2. **External Secrets** (für Production)
3. **Plain Text** (nur für Testing)

## 📊 Overlays im Detail

### Minimal Overlay
- **Memory**: 256-512 Mi
- **CPU**: 200-500 m
- **Replicas**: 2-8
- **Screenshots**: Deaktiviert

### With-Selenium Overlay
- **Memory**: 1-2 Gi
- **CPU**: 500-2000 m
- **Replicas**: 2-4
- **Screenshots**: Aktiviert

### Production Overlay
- **Security**: Network Policies, Pod Security
- **Monitoring**: Prometheus Annotations
- **Backup**: Persistent Volumes
- **Compliance**: Audit Logging

## 🛠️ Custom Overlays erstellen

```bash
# Neues Overlay erstellen
mkdir -p kustomize/overlays/my-environment

# Basis-Overlay kopieren
cp kustomize/overlays/staging/* kustomize/overlays/my-environment/

# Anpassen
vim kustomize/overlays/my-environment/deployment-patch.yaml
vim kustomize/overlays/my-environment/kustomization.yaml
```

## 📋 Build und Deploy

### Build only (Preview)
```bash
oc kustomize kustomize/overlays/production
```

### Build und Apply
```bash
oc kustomize kustomize/overlays/production | oc apply -f -
```

### Build mit Output
```bash
oc kustomize kustomize/overlays/production > production-manifest.yaml
```

### Diff anzeigen
```bash
oc kustomize kustomize/overlays/production | oc diff -f -
```

## 🔍 Validierung

```bash
# Kustomize Rendering prüfen
oc kustomize kustomize/overlays/production > /dev/null

# Dry-Run Apply
oc kustomize kustomize/overlays/production | oc apply --dry-run=client -f -
```

## 📈 Monitoring

```bash
# Deployment Status
oc get deployment -l app=superset-mcp

# Pods Status
oc get pods -l app=superset-mcp

# HPA Status
oc get hpa superset-mcp-hpa

# Events
oc get events --field-selector involvedObject.name=superset-mcp
```

## 🔄 Updates

```bash
# Rolling Update
oc kustomize kustomize/overlays/production | oc apply -f -
oc rollout status deployment/superset-mcp

# Rollback
oc rollout undo deployment/superset-mcp
```

## 🚨 Troubleshooting

### Kustomize Issues
```bash
# Debug Build
oc kustomize kustomize/overlays/production

# Check Resources
oc kustomize kustomize/overlays/production | grep -E "kind:|metadata:"
```

### OpenShift Issues
```bash
# Pod Logs
oc logs -l app=superset-mcp

# Describe Pod
oc describe pod -l app=superset-mcp

# Events
oc get events --sort-by='.lastTimestamp'
```

## 📚 Best Practices

1. **Use Overlays** für Environment-spezifische Konfigurationen
2. **Secret Management** mit External Secrets für Production
3. **Resource Limits** immer definieren
4. **Health Checks** für alle Services
5. **Network Policies** für Security
6. **Version Control** für alle Kustomize Konfigurationen
