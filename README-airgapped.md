# Superset MCP Service - Air-Gapped Deployment

> **Für Umgebungen ohne Internetzugriff**

## 📋 Vorbereitung für Air-Gapped Build

### 1. Chrome und ChromeDriver herunterladen

**Auf einem Internet-verbundenen System:**

```bash
# Chrome RPM herunterladen
wget https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm

# ChromeDriver herunterladen (passende Version für Chrome)
CHROME_VERSION=$(google-chrome --version | grep -oP '\d+\.\d+\.\d+')
CHROMEDRIVER_VERSION=$(curl -sS chromedriver.storage.googleapis.com/LATEST_RELEASE_${CHROME_VERSION})
wget https://chromedriver.storage.googleapis.com/${CHROMEDRIVER_VERSION}/chromedriver_linux64.zip

# Verzeichnisstruktur erstellen
mkdir -p chrome/
mv google-chrome-stable_current_x86_64.rpm chrome/
mv chromedriver_linux64.zip chrome/
```

### 2. Python Dependencies offline verfügbar machen

```bash
# Requirements in eine ZIP-Datei packen
pip download -r requirements.txt -d python-packages/

# Alternativ: Wheelhouse erstellen
pip wheel -r requirements.txt -w python-wheels/
```

### 3. Projektstruktur für Air-Gapped Build

```
superset-mcp/
├── chrome/
│   ├── google-chrome-stable_current_x86_64.rpm
│   └── chromedriver_linux64.zip
├── python-packages/           # oder python-wheels/
│   ├── fastapi-*.whl
│   ├── selenium-*.whl
│   └── ...
├── mcp_service/
├── Dockerfile
├── requirements.txt
└── ...
```

## 🔧 Angepasstes Dockerfile

Das Dockerfile wurde für Air-Gapped-Umgebungen angepasst:

### Änderungen:
- **Keine Downloads** während des Build-Prozesses
- **Lokale Chrome-Installation** aus `chrome/` Verzeichnis
- **Optionale Chrome-Installation** mit `|| true`
- **Lokale Python-Packages** (optional)

### Optionales Dockerfile ohne Downloads:

```dockerfile
# Für Python-Packages aus lokalem Verzeichnis
COPY python-packages/ /tmp/python-packages/
RUN pip install --no-index --find-links=/tmp/python-packages -r requirements.txt
```

## 🚀 Build in Air-Gapped Umgebung

### 1. OpenShift Internal Registry

```bash
# Images in internen Registry pushen
oc import-image superset-mcp-base:latest --from=registry.access.redhat.com/ubi9/python-311:latest --confirm

# Build mit internen Resources
oc start-build superset-mcp --from-dir=. --follow
```

### 2. BuildConfig mit lokalen Resources

```yaml
# openshift-buildconfig-airgapped.yaml
apiVersion: build.openshift.io/v1
kind: BuildConfig
metadata:
  name: superset-mcp-airgapped
spec:
  source:
    type: Binary
    binary:
      asFile: false
  strategy:
    type: Docker
    dockerStrategy:
      dockerfilePath: Dockerfile
  output:
    to:
      kind: ImageStreamTag
      name: superset-mcp:latest
  triggers:
    - type: ConfigChange
    - type: ImageChange
```

### 3. Build durchführen

```bash
# Binary Build mit lokalen Dateien
oc new-build superset-mcp-airgapped --binary
oc start-build superset-mcp-airgapped --from-dir=. --follow
```

## 📦 Benötigte Dateien für Air-Gapped Build

### Muss vorhanden sein:
- `chrome/google-chrome-stable_current_x86_64.rpm`
- `chrome/chromedriver_linux64.zip`
- `requirements.txt`
- `mcp_service/` Verzeichnis
- `Dockerfile`

### Optional (für vollständige Offline-Fähigkeit):
- `python-packages/` mit allen Python-Dependencies
- Basis-Image in internem Registry

## 🔍 Validierung

### Build testen:
```bash
# Lokaler Test (falls Docker verfügbar)
docker build -t superset-mcp:test .

# In OpenShift
oc get builds
oc logs build/superset-mcp-1
```

### Chrome-Installation prüfen:
```bash
# Im Container testen
docker run --rm superset-mcp:test google-chrome --version
docker run --rm superset-mcp:test chromedriver --version
```

## ⚠️ Wichtige Hinweise

1. **Chrome-Version-Kompatibilität**: ChromeDriver muss zur Chrome-Version passen
2. **Architecture**: Stellen Sie sicher, dass alle Dateien für x86_64 sind
3. **Dependencies**: Chrome benötigt zusätzliche System-Libraries, die in UBI9 vorhanden sein sollten
4. **Security**: Chrome-Installation ist optional für MCP-Service-Funktionalität

## 🚨 Fallback ohne Selenium

Falls Chrome-Installation fehlschlägt, läuft der MCP-Service weiterhin ohne Screenshot-Funktionalität:

- ✅ Chart-Management
- ✅ Datenbank-Operationen  
- ✅ SQL-Abfragen
- ❌ Chart-Vorschauen (Screenshots)

## 📞 Troubleshooting

### Chrome-Installation fehlgeschlagen:
```bash
# Prüfen ob Chrome RPM vorhanden ist
ls -la chrome/google-chrome-stable_current_x86_64.rpm

# Dependencies prüfen
oc rsh $(oc get pods -l app=superset-mcp -o jsonpath='{.items[0].metadata.name}') \
  rpm -qpR /tmp/chrome/google-chrome-stable_current_x86_64.rpm
```

### ChromeDriver Probleme:
```bash
# Version prüfen
google-chrome --version
chromedriver --version

# Manuelle Installation falls nötig
oc rsh <pod> unzip /tmp/chrome/chromedriver_linux64.zip -d /usr/local/bin/
```
