# Kustomize Overlays für Superset MCP Service

## 📁 Übersicht der Environment-Overlays

### 🚀 Minimal (`minimal/`)
**Zweck**: Leichtgewichtiges Deployment ohne Screenshots

**Eigenschaften**:
- **Memory**: 256-512 Mi pro Pod
- **CPU**: 200-500 m pro Pod  
- **Replicas**: 3 (max 8)
- **Screenshots**: Deaktiviert
- **Use Case**: Production ohne visuelle Features

**Deployment**:
```bash
make -f Makefile-kustomize build ENV=minimal
make -f Makefile-kustomize deploy ENV=minimal
```

---

### 🖼️ With Selenium (`with-selenium/`)
**Zweck**: Vollständiges Deployment mit Screenshots

**Eigenschaften**:
- **Memory**: 1-2 Gi pro Pod
- **CPU**: 500-2000 m pro Pod
- **Replicas**: 2 (max 4)
- **Screenshots**: Aktiviert
- **Volumes**: /tmp und /dev/shm für Chrome
- **Use Case**: Development/Staging mit visuellen Features

**Deployment**:
```bash
make -f Makefile-kustomize build ENV=with-selenium
make -f Makefile-kustomize deploy ENV=with-selenium
```

---

### 🛠️ Development (`development/`)
**Zweck**: Entwicklungsumgebung mit Debug-Features

**Eigenschaften**:
- **Memory**: 512 Mi-1 Gi pro Pod
- **CPU**: 200-1000 m pro Pod
- **Replicas**: 1 (max 2)
- **Screenshots**: Aktiviert
- **Debug**: DEBUG logging, development mode
- **Use Case**: Lokale Entwicklung

**Deployment**:
```bash
make -f Makefile-kustomize build ENV=development
make -f Makefile-kustomize deploy ENV=development
```

---

### 🧪 Staging (`staging/`)
**Zweck**: Staging-Umgebung mit Monitoring

**Eigenschaften**:
- **Memory**: 768 Mi-1.5 Gi pro Pod
- **CPU**: 300-1500 m pro Pod
- **Replicas**: 2 (max 4)
- **Screenshots**: Aktiviert
- **Monitoring**: Prometheus integration
- **Use Case**: Pre-Production Tests

**Deployment**:
```bash
make -f Makefile-kustomize build ENV=staging
make -f Makefile-kustomize deploy ENV=staging
```

---

### 🔒 Production (`production/`)
**Zweck**: Production mit Security-Hardening

**Eigenschaften**:
- **Memory**: 1-2 Gi pro Pod
- **CPU**: 500-2000 m pro Pod
- **Replicas**: 3 (max 6)
- **Screenshots**: Aktiviert
- **Security**: Network Policies, JWT auth, audit logging
- **Monitoring**: Prometheus metrics
- **Compliance**: Seccomp profile, security context

**Deployment**:
```bash
make -f Makefile-kustomize build ENV=production
make -f Makefile-kustomize deploy ENV=production
```

---

## 📊 Ressourcen-Vergleich

| Environment | Memory/Pod | CPU/Pod | Replicas | Screenshots | Security |
|-------------|------------|---------|----------|-------------|----------|
| **minimal** | 256-512 Mi | 200-500 m | 3 (max 8) | ❌ | Basic |
| **with-selenium** | 1-2 Gi | 500-2000 m | 2 (max 4) | ✅ | Basic |
| **development** | 512-1 Gi | 200-1000 m | 1 (max 2) | ✅ | Basic |
| **staging** | 768-1.5 Gi | 300-1500 m | 2 (max 4) | ✅ | Enhanced |
| **production** | 1-2 Gi | 500-2000 m | 3 (max 6) | ✅ | Hardened |

## 🔧 Custom Overlay erstellen

```bash
# Neues Overlay erstellen
mkdir -p kustomize/overlays/my-environment

# Basis kopieren
cp kustomize/overlays/minimal/* kustomize/overlays/my-environment/

# Anpassen
vim kustomize/overlays/my-environment/deployment-patch.yaml
vim kustomize/overlays/my-environment/kustomization.yaml
```

## 🚀 Quick Commands

### Alle Environments auflisten
```bash
make -f Makefile-kustomize list-envs
```

### Deployment mit einem Befehl
```bash
# Minimal
make -f Makefile-kustomize deploy-minimal

# Production
make -f Makefile-kustomize deploy-production
```

### Status prüfen
```bash
make -f Makefile-kustomize status ENV=production
```

### Health Check
```bash
make -f Makefile-kustomize health ENV=staging
```

## 📋 Environment-spezifische Features

### Minimal
- ✅ Keine Screenshots
- ✅ Geringste Ressourcen
- ✅ Höchste Skalierbarkeit
- ❌ Keine visuellen Features

### With Selenium
- ✅ Screenshots aktiviert
- ✅ Chrome Integration
- ✅ Volle Funktionalität
- ❌ Höherer Ressourcenverbrauch

### Development
- ✅ Debug Logging
- ✅ Hot Reload möglich
- ✅ Einzelne Instanz
- ❌ Keine High Availability

### Staging
- ✅ Production-like
- ✅ Monitoring aktiviert
- ✅ Load Testing möglich
- ❌ Noch keine Security-Hardening

### Production
- ✅ Security-Hardening
- ✅ Audit Logging
- ✅ Network Policies
- ✅ JWT Authentication
- ✅ Prometheus Monitoring
- ❌ Komplexere Konfiguration

## 🔍 Troubleshooting

### Environment nicht gefunden
```bash
make -f Makefile-kustomize list-envs
```

### Manifeste prüfen
```bash
make -f Makefile-kustomize build ENV=production | less
```

### Direkt mit oc kustomize prüfen
```bash
oc kustomize kustomize/overlays/production > /dev/null
```

### Diff anzeigen
```bash
make -f Makefile-kustomize diff ENV=production
```

### Logs prüfen
```bash
make -f Makefile-kustomize logs ENV=production
```

## 📚 Best Practices

1. **Environment-spezifische Secrets**: Verwenden Sie Secret-Generatoren
2. **Resource Limits**: Definieren Sie immer limits und requests
3. **Health Checks**: Konfigurieren Sie liveness/readiness probes
4. **Network Policies**: Verwenden Sie Policies in Production
5. **Monitoring**: Aktivieren Sie Prometheus in Staging/Production
6. **Version Control**: Tracken Sie alle Kustomize-Konfigurationen
