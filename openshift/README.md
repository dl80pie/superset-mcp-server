# OpenShift Deployment Guide for Superset MCP Server

Diese Anleitung beschreibt die Bereitstellung des Superset MCP Servers auf OpenShift mit einem RHEL UBI9-basierten Image.

## Überblick

Der Superset MCP Server ermöglicht es AI-Assistants (wie LibreChat) über das Model Context Protocol (MCP) mit einer Apache Superset-Instanz zu interagieren.

## Komponenten

- **Dockerfile.ubi9**: RHEL UBI9-basiertes Container-Image
- **openshift/**: OpenShift Deployment-Manifeste
  - `00-namespace.yaml`: Namespace-Definition
  - `01-config.yaml`: ConfigMap und Secret für Umgebungsvariablen
  - `02-deployment.yaml`: Deployment-Konfiguration
  - `03-service-route.yaml`: Service und Route
  - `04-buildconfig.yaml`: BuildConfig und ImageStream (optional)

## Voraussetzungen

- OpenShift 4.x Cluster mit Administrator-Zugriff
- Zugang zu einer Superset-Instanz (bereits in OpenShift oder extern bereitgestellt)
- OpenShift CLI (`oc`) installiert

## Deployment-Schritte

### 1. Namespace erstellen

```bash
oc apply -f openshift/00-namespace.yaml
```

### 2. Konfiguration anpassen

Bearbeiten Sie `openshift/01-config.yaml` und passen Sie folgende Werte an:

**ConfigMap (`SUPERSET_BASE_URL`)**:
```yaml
# URL Ihrer Superset-Instanz
SUPERSET_BASE_URL: "https://superset-ihre-domain.apps.cluster.example.com"
```

**Secret (Authentifizierung)**:

Es gibt zwei Möglichkeiten zur Authentifizierung:

**Option A: Access Token (empfohlen)**
```bash
# Nutzen Sie ein bestehendes Superset Access Token
oc create secret generic superset-mcp-credentials \
  --from-literal=SUPERSET_ACCESS_TOKEN=eyJ0eXAiOiJKV1QiLCJhbGc... \
  -n superset-mcp
```

**Option B: Username/Password**
```bash
# Alternativ: Anmeldung mit Credentials
oc create secret generic superset-mcp-credentials \
  --from-literal=SUPERSET_USERNAME=admin \
  --from-literal=SUPERSET_PASSWORD=ihr-passwort \
  -n superset-mcp
```

**Hinweis**: Wenn beide Optionen gesetzt sind, hat das Access Token Priorität.

### 3. Konfiguration anwenden

```bash
oc apply -f openshift/01-config.yaml
```

### 4. Build starten (Option A: OpenShift Build)

```bash
oc apply -f openshift/04-buildconfig.yaml
oc start-build superset-mcp-server -n superset-mcp
```

Warten Sie, bis der Build abgeschlossen ist:
```bash
oc logs -f bc/superset-mcp-server -n superset-mcp
```

### 4. Alternative: Externer Build und Push (Option B)

```bash
# Lokal bauen
docker build -f Dockerfile.ubi9 -t your-registry/superset-mcp-server:latest .

# In die OpenShift Registry pushen
docker login -u $(oc whoami -t) -p $(oc whoami -t) $(oc get route -n openshift-image-registry image-registry -o jsonpath='{.spec.host}')
docker push your-registry/superset-mcp-server:latest
```

### 5. Deployment erstellen

```bash
oc apply -f openshift/02-deployment.yaml
oc apply -f openshift/03-service-route.yaml
```

### 6. Route-URL abrufen

```bash
oc get route superset-mcp-server -n superset-mcp -o jsonpath='{.spec.host}'
```

Die Ausgabe ist die URL für die LibreChat-Konfiguration, z.B.: `superset-mcp-server-superset-mcp.apps.cluster.example.com`

## LibreChat Konfiguration

Fügen Sie folgende Konfiguration zu Ihrer `librechat.yaml` hinzu:

```yaml
mcpServers:
  superset:
    url: https://superset-mcp-server-superset-mcp.apps.cluster.example.com/sse
    timeout: 30000
```

## Fehlersuche

### Pod-Logs anzeigen

```bash
oc logs -l app=superset-mcp-server -n superset-mcp --tail=100 -f
```

### Deployment-Status prüfen

```bash
oc get pods -n superset-mcp
oc describe deployment superset-mcp-server -n superset-mcp
```

### Health-Check testen

```bash
ROUTE_URL=$(oc get route superset-mcp-server -n superset-mcp -o jsonpath='{.spec.host}')
curl -k https://$ROUTE_URL/health
```

## Sicherheitshinweise

- Die Superset-Credentials werden als Kubernetes Secret gespeichert
- **Empfohlen**: Verwenden Sie `SUPERSET_ACCESS_TOKEN` statt Username/Password für bessere Sicherheit
- Der Container läuft als nicht-root User (UID 1001)
- TLS-Termination erfolgt am OpenShift Router (Edge-Termination)
- Readiness- und Liveness-Probes überwachen den Container-Status

## Ressourcenanforderungen

- **CPU**: 100m (Request) / 500m (Limit)
- **Memory**: 256Mi (Request) / 512Mi (Limit)

Passen Sie diese Werte in `openshift/02-deployment.yaml` bei Bedarf an.
