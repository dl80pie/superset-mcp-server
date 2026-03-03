# LibreChat Integration für Superset MCP Service

> **Anleitung zur Integration des Superset MCP Service in LibreChat**

## 🎯 Übersicht

LibreChat ist eine Open-Source Chat-Plattform, die verschiedene KI-Modelle und Tools unterstützt. Die Integration des Superset MCP Service ermöglicht es Benutzern, direkt im Chat-Interface mit Superset zu interagieren.

## 📋 Voraussetzungen

### LibreChat Installation
- LibreChat 0.7+ mit MCP-Unterstützung
- Zugriff auf LibreChat Konfigurationsdateien
- Admin-Rechte für Konfigurationsänderungen

### Superset MCP Service
- Laufender Superset MCP Service in OpenShift
- Öffentliche Route/URL für den MCP Service
- Funktionierende Authentifizierung

## 🔧 Integration Steps

### 1. MCP Service URL ermitteln

```bash
# OpenShift Route abrufen
oc get route superset-mcp -o jsonpath='{.spec.host}'

# Ergebnis: superset-mcp-your.apps.cluster.example.com
```

### 2. LibreChat Konfiguration anpassen

#### Option A: Environment Variables (empfohlen)

```bash
# LibreChat .env Datei bearbeiten
nano librechat/.env
```

```env
# Superset MCP Service Configuration
SUPerset_MCP_ENABLED=true
SUPerset_MCP_URL=https://superset-mcp-your.apps.cluster.example.com
SUPerset_MCP_USERNAME=admin
SUPerset_MCP_TIMEOUT=30000

# MCP Service Authentication (falls erforderlich)
SUPerset_MCP_AUTH_TYPE=basic
# SUPerset_MCP_API_KEY=your-api-key-here

# LibreChat MCP Settings
ENABLE_MCP_TOOLS=true
MCP_SERVICE_TIMEOUT=30000
```

#### Option B: Konfigurationsdatei

```json
// librechat/config/mcp-services.json
{
  "services": {
    "superset": {
      "name": "Apache Superset",
      "description": "Interact with Apache Superset dashboards and data",
      "url": "https://superset-mcp-your.apps.cluster.example.com",
      "enabled": true,
      "auth": {
        "type": "basic",
        "username": "admin",
        "password": "your-password"
      },
      "timeout": 30000,
      "tools": [
        "list_charts",
        "get_chart_info", 
        "list_dashboards",
        "get_dashboard_info",
        "execute_sql",
        "list_datasets",
        "get_dataset_info"
      ]
    }
  }
}
```

### 3. LibreChat neu starten

```bash
# Docker Compose (wenn verwendet)
docker-compose down && docker-compose up -d

# Oder direkter Neustart
npm restart librechat
```

## 💬 Nutzung in LibreChat

### 1. Superset Tools aktivieren

Im LibreChat Interface:
1. **Settings** → **Tools** oder **Plugins**
2. **Superset MCP** aktivieren
3. **Authentifizierung** konfigurieren (falls erforderlich)

### 2. Beispiel-Konversationen

#### Charts auflisten
```
User: Zeig mir alle verfügbaren Charts in Superset

LibreChat: Ich frage die verfügbaren Charts in Superset ab...

[Ergebnis: Liste aller Charts mit IDs und Namen]
```

#### SQL Abfrage ausführen
```
User: Führe eine SQL Abfrage aus, um die Anzahl der Benutzer zu zählen

LibreChat: Ich führe die SQL Abfrage in Superset aus...

[Ergebnis: Abfrageergebnis mit Daten]
```

#### Dashboard Informationen
```
User: Gib mir Informationen über das Sales Dashboard

LibreChat: Ich rufe die Dashboard-Informationen ab...

[Ergebnis: Dashboard Details, Charts, Metriken]
```

#### Chart erstellen (Advanced)
```
User: Erstelle einen neuen Chart für die Verkaufszahlen nach Monat

LibreChat: Ich erstelle einen neuen Chart in Superset...

[Ergebnis: Chart ID und Konfiguration]
```

## 🔍 Konfigurationsbeispiele

### Full Integration mit Screenshots

```env
# LibreChat .env für Full Superset Integration
SUPerset_MCP_ENABLED=true
SUPerset_MCP_URL=https://superset-mcp-your.apps.cluster.example.com
SUPerset_MCP_USERNAME=admin
SUPerset_MCP_PASSWORD=your-secure-password
SUPerset_MCP_TIMEOUT=60000

# Screenshots aktivieren
SUPerset_MCP_SCREENSHOTS=true
SUPerset_MCP_WEBDRIVER_TYPE=chrome

# LibreChat erweiterte Einstellungen
ENABLE_MCP_SCREENSHOTS=true
MCP_SCREENSHOT_TIMEOUT=45000
```

### Minimal Integration (ohne Screenshots)

```env
# LibreChat .env für Minimal Superset Integration
SUPerset_MCP_ENABLED=true
SUPerset_MCP_URL=https://superset-mcp-minimal.apps.cluster.example.com
SUPerset_MCP_USERNAME=admin
SUPerset_MCP_TIMEOUT=30000

# Screenshots deaktiviert
SUPerset_MCP_SCREENSHOTS=false
```

## 🛠️ Advanced Configuration

### Custom Tool Mapping

```json
// librechat/config/superset-tools.json
{
  "tool_mapping": {
    "list_charts": {
      "name": "Charts auflisten",
      "description": "Zeigt alle verfügbaren Charts in Superset",
      "category": "Discovery"
    },
    "execute_sql": {
      "name": "SQL ausführen", 
      "description": "Führt SQL Abfragen in der Datenbank aus",
      "category": "Data Analysis",
      "requires_approval": true
    },
    "get_chart_preview": {
      "name": "Chart Vorschau",
      "description": "Zeigt eine visuelle Vorschau des Charts",
      "category": "Visualization",
      "requires_screenshots": true
    }
  }
}
```

### User Permissions

```json
// librechat/config/user-permissions.json
{
  "permissions": {
    "admin": {
      "superset_tools": ["*"],
      "sql_execution": true,
      "chart_creation": true
    },
    "analyst": {
      "superset_tools": ["list_charts", "get_chart_info", "execute_sql"],
      "sql_execution": true,
      "chart_creation": false
    },
    "viewer": {
      "superset_tools": ["list_charts", "get_chart_info", "list_dashboards"],
      "sql_execution": false,
      "chart_creation": false
    }
  }
}
```

## 📊 Beispiel-Workflows

### Workflow 1: Datenanalyse

```
1. User: "Ich möchte die Verkaufsdaten analysieren"
2. LibreChat: "Ich helfe Ihnen bei der Analyse. Welche Daten möchten Sie sehen?"
3. User: "Zeig mir alle verfügbaren Dashboards"
4. LibreChat: [list_dashboards] → "Hier sind die verfügbaren Dashboards..."
5. User: "Gib mir die Details zum Sales Dashboard"
6. LibreChat: [get_dashboard_info] → "Das Sales Dashboard enthält..."
7. User: "Führe eine Abfrage für die letzten 6 Monate aus"
8. LibreChat: [execute_sql] → "Hier sind die Ergebnisse..."
```

### Workflow 2: Chart-Erstellung

```
1. User: "Ich brauche einen neuen Chart für Customer Lifetime Value"
2. LibreChat: "Ich erstelle einen neuen Chart. Welche Datenquelle soll verwendet werden?"
3. User: "Verwende die customers Tabelle"
4. LibreChat: [list_datasets] → "Hier sind die verfügbaren Datasets..."
5. User: "Erstelle einen Bar Chart mit CLV nach Segment"
6. LibreChat: [generate_chart] → "Chart wurde erstellt mit ID: 123"
7. User: "Zeig mir eine Vorschau"
8. LibreChat: [get_chart_preview] → "Hier ist die Chart-Vorschau..."
```

## 🔧 Troubleshooting

### Häufige Probleme

**1. MCP Service nicht erreichbar**
```bash
# Verbindung testen
curl -I https://superset-mcp-your.apps.cluster.example.com/health

# LibreChat Logs prüfen
docker logs librechat-app | grep -i mcp
```

**2. Authentifizierungsfehler**
```bash
# Credentials prüfen
curl -X POST https://your-mcp-url/mcp \
  -H "Content-Type: application/json" \
  -u admin:password \
  -d '{"jsonrpc": "2.0", "method": "tools/list", "id": 1}'
```

**3. Timeout-Probleme**
```env
# Timeouts erhöhen
SUPerset_MCP_TIMEOUT=60000
MCP_SERVICE_TIMEOUT=60000
```

**4. Screenshots nicht verfügbar**
```bash
# Minimal-Version prüfen
curl -X POST https://your-mcp-url/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc": "2.0", "method": "tools/call", "params": {"name": "get_chart_preview"}, "id": 1}'
```

## 📈 Performance Optimierung

### LibreChat Konfiguration

```env
# Optimale Einstellungen für Superset Integration
LIBRECHAT_CONCURRENT_REQUESTS=5
MCP_POOL_SIZE=3
MCP_TIMEOUT=45000
MCP_RETRY_ATTEMPTS=2

# Caching
ENABLE_MCP_CACHE=true
MCP_CACHE_TTL=300
```

### Monitoring

```bash
# LibreChat Performance
curl http://localhost:3080/health

# MCP Service Status
curl https://your-mcp-url/health

# LibreChat Logs
docker logs librechat-app --tail 100 -f
```

## 🔒 Sicherheit

### Best Practices

1. **HTTPS verwenden**: Immer verschlüsselte Verbindungen
2. **Credentials schützen**: Environment Variables statt Hardcoding
3. **User Permissions**: Rollenbasierte Zugriffssteuerung
4. **Audit Logging**: Alle MCP-Aktionen protokollieren

### Security Headers

```json
{
  "security": {
    "mcp_service": {
      "verify_ssl": true,
      "allowed_hosts": ["superset-mcp-your.apps.cluster.example.com"],
      "rate_limit": {
        "requests_per_minute": 60,
        "burst_size": 10
      }
    }
  }
}
```

## 📚 Additional Resources

- [LibreChat Documentation](https://librechat.ai/)
- [Superset MCP Service Docs](README.md)
- [MCP Protocol Specification](https://spec.modelcontextprotocol.io/)
- [OpenShift Route Configuration](openshift-deployment.yaml)

## 🤝 Support

Bei Problemen mit der LibreChat Integration:

1. **Logs prüfen**: LibreChat und MCP Service
2. **Netzwerk testen**: Verbindung zwischen LibreChat und MCP Service
3. **Konfiguration validieren**: Environment Variables und JSON-Configs
4. **Permissions überprüfen**: User-Rollen und MCP-Berechtigungen
