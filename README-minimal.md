# Superset MCP Service - Minimal Deployment (No Screenshots)

> **Leichte Version ohne Chart-Vorschau-Funktionalität für ressourcenschonende Deployments**

## 🎯 Wann die Minimal-Version verwenden?

### ✅ Ideal für:
- **Ressourcenbeschränkte Umgebungen**
- **Air-gapped Deployments** ohne Chrome-Abhängigkeiten
- **Hochskalierbare Multi-Tenant-Umgebungen**
- **Test- und Entwicklungs-Umgebungen**
- **Wenn Screenshots nicht benötigt werden**

### ❌ Nicht geeignet für:
- **Visuelle Chart-Analysen**
- **KI-Agenten mit Bildverarbeitung**
- **Dashboard-Vorschau-Funktionen**

## 📊 Funktionsumfang

### ✅ Verfügbare MCP Tools:
- **Chart Management**: `list_charts`, `get_chart_info`, `generate_chart`, `update_chart`
- **Dashboard Operations**: `list_dashboards`, `get_dashboard_info`, `generate_dashboard`
- **Database & Dataset**: `list_databases`, `list_datasets`, `get_dataset_info`
- **SQL Operations**: `execute_sql`, `open_sql_lab_with_context`
- **System**: `health_check`, `get_instance_info`, `get_schema`

### ❌ Deaktivierte Funktionen:
- **Chart Screenshots**: `get_chart_preview`, `update_chart_preview`
- **Visual Previews**: Keine PNG-Bilder von Charts
- **WebDriver**: Kein Selenium/Chrome erforderlich

## 🚀 Quickstart

### 1. Deployment
```bash
# Minimal-Version deployen
make -f Makefile-minimal deploy

# Oder manuell
oc apply -f openshift-deployment-minimal.yaml
```

### 2. Validierung
```bash
# Health-Check
make -f Makefile-minimal health

# Tests durchführen
make -f Makefile-minimal test
```

## 📈 Ressourcen-Vergleich

| Metrik | Minimal | Mit Selenium |
|--------|---------|--------------|
| **Memory pro Pod** | 256-512 Mi | 1-2 Gi |
| **CPU pro Pod** | 200-500 m | 500-2000 m |
| **Max Replicas** | 8 | 4 |
| **Startup-Zeit** | ~15s | ~45s |
| **Image-Größe** | ~400 MB | ~800 MB |

## 🔧 Konfiguration

### Environment Variablen
```yaml
env:
  - name: WEBDRIVER_TYPE
    value: "none"
  - name: MCP_SCREENSHOTS_ENABLED
    value: "false"
```

### Requirements
- **Kein Chrome** erforderlich
- **Kein ChromeDriver** benötigt
- **Keine zusätzlichen System-Libraries**

## 🛠️ Build-Prozess

### Dockerfile.minimal
```dockerfile
# Keine Chrome-Installation
# Kein Selenium Download
# Nur Core MCP Service Dependencies
```

### Requirements.minimal.txt
```txt
# Ohne selenium und webdriver-manager
# ~40% weniger Dependencies
```

## 📋 Deployment-Optionen

### Option 1: Minimal (empfohlen für Production)
```bash
make -f Makefile-minimal deploy
```

### Option 2: Mit Screenshots (falls visuelle Features benötigt)
```bash
make -f Makefile-airgapped deploy-with-selenium
```

### Option 3: Manuelles Switching
```bash
# Von Minimal zu Screenshots wechseln
oc apply -f openshift-deployment-with-selenium.yaml

# Von Screenshots zu Minimal wechseln
oc apply -f openshift-deployment-minimal.yaml
```

## 🔍 Monitoring

### Health Checks
```bash
# Service-Status
oc get pods -l app=superset-mcp

# Logs prüfen
oc logs -l app=superset-mcp

# Health-Endpoint
curl https://your-route/health
```

### Performance-Metriken
```bash
# Ressourcen-Nutzung
oc top pods -l app=superset-mcp

# Skalierungs-Status
oc get hpa superset-mcp-hpa
```

## 🚨 Fehlerbehebung

### Häufige Probleme

**1. Screenshots nicht deaktiviert:**
```bash
# Umgebungsvariablen prüfen
oc exec -it <pod> -- env | grep SCREENSHOT

# Manuell deaktivieren
oc set env deployment/superset-mcp MCP_SCREENSHOTS_ENABLED=false
```

**2. Tool-Fehler bei Screenshots:**
```bash
# Erwartetes Verhalten
curl -X POST https://your-route/mcp \
  -d '{"jsonrpc": "2.0", "method": "tools/call", "params": {"name": "get_chart_preview"}, "id": 1}'

# Sollte Fehler zurückgeben: "not available" oder "disabled"
```

**3. Memory-Probleme:**
```bash
# Limits prüfen
oc get deployment superset-mcp -o yaml | grep -A 10 resources

# Bei Problemen reduzieren
oc patch deployment superset-mcp -p '{"spec":{"template":{"spec":{"containers":[{"name":"mcp-service","resources":{"limits":{"memory":"384Mi"}}}]}}}}'
```

## 🔄 Migration

### Von Minimal zu Screenshots
```bash
# Backup erstellen
oc get deployment superset-mcp -o yaml > deployment-backup.yaml

# Mit Screenshots deployen
make -f Makefile-airgapped deploy-with-selenium

# Validieren
make -f Makefile-airgapped test
```

### Von Screenshots zu Minimal
```bash
# Minimal-Version deployen
make -f Makefile-minimal deploy

# Validieren
make -f Makefile-minimal test
```

## 📚 Beispiele

### Claude Desktop Konfiguration (Minimal)
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

### Beispiel-Interaktion
```bash
# Charts auflisten
curl -X POST https://your-route/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc": "2.0", "method": "tools/call", "params": {"name": "list_charts"}, "id": 1}'

# SQL ausführen
curl -X POST https://your-route/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc": "2.0", "method": "tools/call", "params": {"name": "execute_sql", "arguments": {"database_id": 1, "sql": "SELECT COUNT(*) FROM users"}}, "id": 2}'
```

## 🎯 Best Practices

### Production
- **Minimal-Version** für bessere Skalierbarkeit
- **Separates Monitoring** für Screenshot-Funktionen
- **Feature-Flags** für dynamisches Umschalten

### Development
- **Screenshots-Version** für visuelle Tests
- **Lokale Entwicklung** mit vollständigen Features

### Testing
- **Beide Versionen** in separaten Namespaces
- **Automatisierte Tests** für beide Varianten
