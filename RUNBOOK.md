# External Secrets Operator Demo - Developer Runbook

## 🚀 Quick Start

Choose your approach:

### Option 1: Just (Recommended)
```bash
# Full setup from scratch (Vault → ESO → App)
just setup

# Check everything works
just health-check
```

### Option 2: Bootstrap Script
```bash
./bootstrap.sh
```

### Option 3: Manual Setup
Follow the detailed phases below.

---

## What's Included

This demo showcases **two methods** of consuming secrets from HashiCorp Vault:

1. **Environment Variables** - Secrets injected as environment variables (traditional approach)
2. **Mounted Files** - Secrets mounted as files in `/etc/secrets/` and `/etc/config/` (ideal for certificates, configs)

Both methods are managed by External Secrets Operator and sync automatically from Vault every 10 seconds.

## Demo Overview

| Component | Env Vars | Files | Example |
|-----------|----------|-------|---------|
| **Secrets** | ✅ | ✅ | API_KEY, DATABASE_PASSWORD, tls.crt, tls.key |
| **Configs** | ✅ | ✅ | APP_NAME, DEBUG_MODE, database.conf |
| **Provider** | Vault | Vault | Works with AWS, Azure, GCP too! |

## Access Points

After setup, the demo app provides three views:

- **http://localhost:58080/env** - Environment variables only
- **http://localhost:58080/files** - Mounted files only  
- **http://localhost:58080/combined** - Both env vars and files

---

## 🚀 Quick Start

### Option 1: Just (Recommended)
```bash
# Full setup from scratch (Vault → ESO → App)
just setup

# Check everything works
just health-check

# Open all endpoints
open http://localhost:58080/env
open http://localhost:58080/files
open http://localhost:58080/combined
```

### Option 2: Bootstrap Script
```bash
./bootstrap.sh
```

### Option 3: Manual Setup

Follow the detailed phases below.

---

## 🔧 Justfile Overview

The `justfile` provides 54 organized recipes:

| Category | Recipes | Description |
|----------|----------|-------------|
| **Vault** | `vault-up`, `vault-down`, `vault-init`, `vault-add-files`, `vault-list`, `vault-status` | Manage Vault container and secrets |
| **Build** | `build`, `test-app` | Build and test Docker image |
| **Cluster** | `cluster-create`, `cluster-delete`, `cluster-status`, `cluster-use` | Kind cluster management |
| **ESO** | `eso-install`, `eso-apply`, `eso-check`, `eso-logs`, `eso-upgrade`, `eso-uninstall` | Install and configure ESO |
| **Deploy** | `deploy`, `deploy-fast`, `restart` | Deploy and manage demo app |
| **Verify** | `verify`, `verify-env`, `verify-files`, `verify-combined` | Test all endpoints |
| **Utilities** | `logs`, `exec`, `exec-files`, `port-forward`, `open-browser` | Debug and access tools |
| **Cleanup** | `clean`, `clean-all`, `clean-app`, `clean-eso`, `clean-cluster` | Remove resources |

**Sample workflows:**

```bash
# Full demo setup
just setup

# File-based secrets demo
just vault-up && just vault-init && just vault-add-files && just setup && just verify-files

# Quick verification
just health-check

# See all available commands
just --list
```

---

## Phase 1: Vault Setup

### 1.1 Start Vault Container
```bash
just vault-up
```

**Expected Output:**
```
Vault container started
Waiting for Vault to be ready...
✓ Vault is ready at http://localhost:58200
```

### 1.2 Verify Vault is Running
```bash
just vault-status
```

**Expected Output:**
```json
{
  "initialized": true,
  "sealed": false,
  "standby": false,
  "version": "1.18.5"
}
```

### 1.3 Initialize Vault with Sample Data
```bash
just vault-init
```

**Expected Output:**
```
=== Vault Initialization Script ===
✓ Vault is ready
✓ KV engine enabled
✓ Created: secret/demo-app/secrets
✓ Created: secret/demo-app/config
✓ Kubernetes auth enabled
✓ Policy created
=== Vault Initialization Complete ===
```

### 1.4 Verify Secrets in Vault
```bash
just vault-list
```

**Expected Output:**
```
=== Environment Secrets ===
  • api_key
  • database_password

=== Config Secrets ===
  • app_name
  • debug_mode
  • max_connections

=== File Secrets (TLS) ===
  • tls.crt
  • tls.key
=== File Secrets (Config) ===
  • database.conf
```

### 1.5 Add File-Based Secrets (TLS Certificates & Config Files)
```bash
just vault-add-files
```

**Expected Output:**
```
✓ File-based secrets added to Vault
```

---

## Phase 2: Build Demo Application

### 2.1 Build Docker Image
```bash
just build
```

**Expected Output:**
```
✓ Demo app image built
```

### 2.2 Test App Locally
```bash
just test-app
```

**Expected Output:**
```
App running at http://localhost:58000
```

---

## Phase 3: Kind Cluster

### 3.1 Create Kind Cluster
```bash
just cluster-create
```

**Expected Output:**
```
✓ Kind cluster 'eso-demo' created
```

### 3.2 Verify Cluster
```bash
just cluster-status
```

**Expected Output:**
```
=== Kind Cluster ===
eso-demo
✓ Cluster exists
=== Nodes ===
eso-demo-control-plane   Ready    control-plane   30s
eso-demo-worker          Ready    <none>          28s
```

### 3.3 Use Kind Context
```bash
just cluster-use
```

---

## Phase 4: Install External Secrets Operator

### 4.1 Install ESO
```bash
just eso-install
```

**Expected Output:**
```
✓ ESO installed
```

### 4.2 Verify ESO Installation
```bash
just eso-status
```

**Expected Output:**
```
=== ESO Pods ===
3 pods running
```

---

## Phase 5: Configure ESO

### 5.1 Apply ClusterSecretStore
```bash
just eso-store
```

**Expected Output:**
```
✓ ClusterSecretStore created and verified
```

### 5.2 Apply Environment-Based ExternalSecrets
```bash
just eso-secrets
```

**Expected Output:**
```
✓ Environment-based ExternalSecrets created
```

### 5.3 Apply File-Based ExternalSecrets
```bash
just eso-files
```

**Expected Output:**
```
✓ File-based ExternalSecrets created
```

### 5.4 Apply All ESO Manifests
```bash
just eso-apply
```

**Expected Output:**
```
✓ All ESO manifests applied
```

### 5.5 Verify ESO Status
```bash
just eso-check
```

**Expected Output:**
```
=== ExternalSecrets ===
4 ExternalSecrets: SecretSynced
✓ All secrets are synced and ready
```

---

## Phase 6: Deploy Demo Application

### 6.1 Deploy with Volume Mounts
```bash
just deploy
```

**Expected Output:**
```
✓ Demo app image loaded into Kind
✓ Demo app deployed
✓ Deployment is ready
```

### 6.2 Verify Deployment
```bash
kubectl get pods -l app.kubernetes.io/name=demo-app
```

**Expected Output:**
```
demo-app-xxxx-xxx  1/1  Running   0  30s
```

---

## Phase 7: Verification

### 7.1 View Application Navigation
```bash
open http://localhost:58080/
```

**Expected Output:**
Home page opens with navigation options.

### 7.2 Test Environment Variables
```bash
just verify-env
```

**Expected Output:**
```
=== Environment Variables ===
Stats: 2 Secrets, 3 Configs, 26 System
Key values:
API_KEY: sk-demo-api-key-xyz789
DATABASE_PASSWORD: super_secret_db_pass_123
APP_NAME: External Secrets Demo
DEBUG_MODE: true
MAX_CONNECTIONS: 100
```

### 7.3 Test Mounted Files
```bash
just verify-files
```

**Expected Output:**
```
=== Mounted Files ===
Stats: 0 Secrets, 0 Configs, 3 Files
Key values:
tls.crt: -----BEGIN CERTIFICATE-----
tls.key: -----BEGIN PRIVATE KEY-----
database.conf: # Database Configuration
host=postgres.example.com
port=5432
database=demo_app
ssl_mode=require
pool_size=20
max_overflow=10
```

### 7.4 Test Combined View
```bash
just verify-combined
```

**Expected Output:**
```
=== Combined View ===
Stats: 2 Secrets, 3 Configs, 3 Files, 23 System
All sources displayed in single page
```

### 7.5 Complete End-to-End Verification
```bash
just verify
```

**Expected Output:**
```
=== Complete Verification ===
Vault → ESO → Kubernetes Secrets → App
✅ All components working correctly
✅ Both env vars and files accessible
✅ Automatic sync from Vault working
```

---

## Phase 8: Testing Secret Rotation

### 8.1 Update Secret in Vault
```bash
curl -X POST \
  -H "X-Vault-Token: root" \
  -d '{"data": {"database_password": "rotated_password_789"}}' \
  http://localhost:58200/v1/secret/data/demo-app/secrets
```

### 8.2 Verify Secret Rotation
```bash
# Wait for sync (ESO refreshes every 10 seconds)
sleep 15

# Check rotated secret
kubectl get secret demo-app-secrets -o jsonpath='{.data.DATABASE_PASSWORD}' | base64 -d
```

**Expected Output:**
```
rotated_password_789
```

---

## 📚 Quick Reference Commands

### Application Testing
```bash
just verify          # Full verification
just verify-env       # Environment variables only
just verify-files     # Mounted files only
just verify-combined  # Combined view
just health-check      # Quick health check of all components
```

### Development Tools
```bash
just logs            # View app logs
just exec             # Shell into app pod
just exec-files       # Check mounted files in pod
just port-forward     # Forward ports to local
open http://localhost:58080/  # Open all endpoints
```

### Vault Management
```bash
just vault-up          # Start Vault
just vault-down        # Stop Vault
just vault-clean       # Stop and remove volumes
just vault-status      # Check Vault health
just vault-init        # Initialize with sample data
just vault-list        # List all secrets
just vault-add-files   # Add file-based secrets
```

### Cluster Management
```bash
just cluster-create    # Create Kind cluster
just cluster-delete    # Delete Kind cluster
just cluster-status    # Check cluster status
just cluster-use      # Set kubectl context
```

### ESO Management
```bash
just eso-install       # Install ESO
just eso-uninstall     # Remove ESO
just eso-apply         # Apply manifests
just eso-check         # Check ExternalSecret status
just eso-logs          # View ESO controller logs
```

---

## 🧹 Troubleshooting Guide

### Issue: ExternalSecret shows SecretSyncedError

**Diagnosis:**
```bash
kubectl describe externalsecret demo-app-secrets
```

**Common Causes:**
- ClusterSecretStore not ready
- Vault unreachable from cluster
- Authentication failure

**Fix:**
```bash
# Check ClusterSecretStore
just eso-check

# Test Vault connectivity
kubectl run debug --rm -i --restart=Never --image=busybox -- wget -qO- http://10.10.0.1:58200/v1/sys/health || echo "Vault unreachable"

# Check ESO logs
just eso-logs
```

### Issue: App shows 0 secrets/configs

**Diagnosis:**
```bash
# Check if secrets exist
kubectl get secret demo-app-secrets demo-app-config

# Check pod environment
kubectl exec deployment/demo-app -- env | grep -E "API_KEY|DATABASE_PASSWORD|APP_NAME"

# Check if file secrets exist
kubectl get secret demo-app-tls-files demo-app-config-files
```

### Issue: Can't access app on localhost:58080

**Diagnosis:**
```bash
# Check service
kubectl get svc demo-app

# Check port mapping
docker port eso-demo-control-plane | grep 30080

# Test from within cluster
kubectl run test --rm -i --restart=Never --image=busybox -- wget -qO- http://demo-app:8000/
```

---

## 🧹 Cleanup Commands

```bash
# Remove demo app only
just clean-app

# Remove ESO only
just clean-eso

# Remove Kind cluster only
just clean-cluster

# Full cleanup except Vault
just clean

# Full cleanup including Vault
just clean-all
```

---

## 📋 Verification Checklist

After setup, ensure all items are checked:

- [ ] Vault is running on port 58200
- [ ] Vault is initialized with sample secrets
- [ ] Kind cluster 'eso-demo' exists and nodes are Ready
- [ ] ESO is installed and 3 pods are Running
- [ ] ClusterSecretStore 'vault-backend' is Ready
- [ ] Environment-based ExternalSecrets are SecretSynced
- [ ] File-based ExternalSecrets are SecretSynced
- [ ] Demo app deployment is Ready
- [ ] http://localhost:58080/ shows 2 secrets, 3 configs
- [ ] http://localhost:58080/files shows 3 files
- [ ] http://localhost:58080/combined shows all items

---

## 🎉 Success!

When all checks pass, you have successfully demonstrated:
1. **Vault** secrets management
2. **External Secrets Operator** sync from external systems
3. **Kubernetes** secrets management
4. **Two consumption methods**: Environment variables AND file mounting
5. **Automatic synchronization** with configurable refresh intervals

The demo showcases modern secret management best practices for cloud-native applications!