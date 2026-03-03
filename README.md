# Superset MCP Service for OpenShift

> **Basiert auf dem offiziellen Apache Superset MCP Service (SIP-187)**

Dieser MCP-Server ermöglicht es KI-Agenten, direkt mit Apache Superset zu interagieren und natürliche Sprachabfragen für Datenvisualisierung durchzuführen.

## 🚀 Quickstart für OpenShift

### 1. Projekt vorbereiten

```bash
# OpenShift Projekt erstellen (falls nicht vorhanden)
oc new-project superset-mcp

# Konfiguration Secret anwenden
oc apply -f openshift-config-secret.yaml

# BuildConfig und ImageStream erstellen
oc apply -f openshift-buildconfig.yaml
```

### 2. Build starten

```bash
# Build manuell starten
oc start-build superset-mcp

# Oder Build automatisch bei Git-Push auslösen (Webhook konfigurieren)
```

### 3. Deployment

```bash
# Deployment, Service und Route erstellen
oc apply -f openshift-deployment.yaml

# Status prüfen
oc get pods -l app=superset-mcp
oc logs -l app=superset-mcp
```

### 4. Zugriff konfigurieren

```bash
# Route-URL abrufen
oc get route superset-mcp

# Health-Check testen
curl https://$(oc get route superset-mcp -o jsonpath='{.spec.host}')/health
```

## 📋 Konfiguration

### Umgebungsvariablen

| Variable | Beschreibung | Standard |
|----------|-------------|---------|
| `MCP_DEV_USERNAME` | Superset Benutzername für MCP-Authentifizierung | `admin` |
| `SUPERSET_WEBSERVER_ADDRESS` | Interne Superset URL | `http://superset-service:8088` |
| `DATABASE_URI` | PostgreSQL Datenbank-Verbindung | - |
| `SECRET_KEY` | Flask Secret Key | - |
| `REDIS_URL` | Redis Verbindung für Caching | - |

### Sicherheitseinstellungen

Für Produktionsumgebungen:

```yaml
# In openshift-config-secret.yaml
MCP_JWT_PUBLIC_KEY: "-----BEGIN PUBLIC KEY-----\nIhr öffentlicher Schlüssel\n-----END PUBLIC KEY-----"
MCP_AUTH_ENABLED: "true"
```

## 🔧 Claude Desktop Konfiguration

Fügen Sie dies zu Ihrer Claude Desktop Konfigurationsdatei hinzu:

**macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`

```json
{
  "mcpServers": {
    "superset-mcp": {
      "command": "curl",
      "args": [
        "-X", "POST",
        "-H", "Content-Type: application/json",
        "-d", "@-",
        "https://your-openshift-route/mcp"
      ],
      "env": {
        "MCP_USERNAME": "admin"
      }
    }
  }
}
```

## 📊 Monitoring

### Health Checks

```bash
# Pod-Status
oc get pods -l app=superset-mcp

# Logs
oc logs -l app=superset-mcp -f

# Health-Endpoint
curl https://your-route/health
```

### Metriken

Der MCP-Service stellt Metriken unter `/metrics` bereit:

```bash
# Prometheus-Metriken abrufen
curl https://your-route/metrics
```

## 🔒 Sicherheit

### OpenShift Security Context

- **Non-root User**: Service läuft als User 1001
- **ReadOnly Root Filesystem**: Wo möglich aktiviert
- **Capabilities Drop**: Alle unnötigen Capabilities entfernt
- **Security Context Constraint**: Passt zu `restricted-v2` SCC

### Netzwerk-Policies

```yaml
# Beispiel Network Policy (optional)
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: superset-mcp-netpol
spec:
  podSelector:
    matchLabels:
      app: superset-mcp
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: openshift-ingress
    ports:
    - protocol: TCP
      port: 5008
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: postgresql
    ports:
    - protocol: TCP
      port: 5432
```

## 🚀 Skalierung

### Horizontal Pod Autoscaler

Der MCP-Service ist mit HPA konfiguriert:

- **Min Replicas**: 2
- **Max Replicas**: 5
- **CPU Target**: 70%
- **Memory Target**: 80%

### Manuelles Skalieren

```bash
# Auf 3 Replicas skalieren
oc scale deployment superset-mcp --replicas=3

# Autoscaler-Status prüfen
oc get hpa superset-mcp-hpa
```

## 🔧 Troubleshooting

### Häufige Probleme

1. **Datenbank-Verbindungsfehler**
   ```bash
   # Konfiguration prüfen
   oc get secret superset-mcp-config -o yaml
   
   # Verbindung testen
   oc exec -it $(oc get pods -l app=superset-mcp -o jsonpath='{.items[0].metadata.name}') -- \
   python -c "import sqlalchemy; engine = sqlalchemy.create_engine('$DATABASE_URI'); engine.connect()"
   ```

2. **Authentifizierungsfehler**
   ```bash
   # Benutzer prüfen
   oc exec -it $(oc get pods -l app=superset-mcp -o jsonpath='{.items[0].metadata.name}') -- \
   python -c "from superset.models.core import User; print(User.query.filter_by(username='$MCP_DEV_USERNAME').first())"
   ```

3. **Screenshot-Generierung schlägt fehl**
   ```bash
   # WebDriver im Container prüfen
   oc exec -it $(oc get pods -l app=superset-mcp -o jsonpath='{.items[0].metadata.name}') -- \
   which chromedriver
   ```

### Debug-Modus

Für erweitertes Debugging:

```bash
# Deployment mit Debug-Flags aktualisieren
oc patch deployment superset-mcp -p '{"spec":{"template":{"spec":{"containers":[{"name":"mcp-service","env":[{"name":"DEBUG","value":"1"},{"name":"MCP_LOG_LEVEL","value":"DEBUG"}]}]}}}}'
```

## 📚 Weitere Ressourcen

- [Apache Superset MCP Service Dokumentation](https://github.com/apache/superset/tree/main/superset/mcp_service)
- [SIP-187: MCP Service Proposal](https://github.com/apache/superset/issues/35498)
- [OpenShift Dokumentation](https://docs.openshift.com/)
- [Model Context Protocol Spezifikation](https://spec.modelcontextprotocol.io/)

## 🤝 Contributing

Dieses Projekt basiert auf dem offiziellen Apache Superset MCP Service. Für Contributing Guidelines siehe:

- [Apache Superset Contributing](https://superset.apache.org/docs/contributing/)
- [Apache License 2.0](LICENSE)
