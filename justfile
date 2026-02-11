# External Secrets Operator Demo - Justfile
# Quick commands for setting up and managing the demo

# Default recipe - show available commands
[private]
default:
    @just --list --unsorted

# ============================================
# Phase 1: Vault Setup
# ============================================

# Start Vault container
vault-up:
    cd vault && docker compose up -d
    @echo "Waiting for Vault to be ready..."
    @sleep 3
    @curl -s http://localhost:58200/v1/sys/health | jq -r '.initialized and .sealed == false' | grep -q "true" && echo "✓ Vault is ready" || echo "✗ Vault not ready yet, run 'just vault-status'"

# Stop Vault container
vault-down:
    cd vault && docker compose down

# Stop Vault and remove volumes
vault-clean:
    cd vault && docker compose down -v

# Check Vault status
vault-status:
    @curl -s http://localhost:58200/v1/sys/health | jq .

# Initialize Vault with sample secrets
vault-init:
    cd vault && ./init-vault.sh

# Add file-based secrets (TLS certs and configs)
vault-add-files:
    # Add TLS certificate and key
    curl -s -X POST \
      -H "X-Vault-Token: root" \
      -d '{"data": {"tls.crt": "-----BEGIN CERTIFICATE-----\nMIIBkTCB+wIJAJHGTVDEANmEMA0GCSqGSIb3DQEBCwUAMBExDzANBgNVBAMMBmRlbW9jYTAe\nFw0yNDAxMDEwMDAwMDBaFw0yNTAxMDEwMDAwMDBaMBExDzANBgNVBAMMBmRlbW9jYTBc\nMA0GCSqGSIb3DQEBAQUAA0sAMEgCQQC/FIpfUX5Jp3hFT+f3HYBzK5F3gT0zqB5w5prf\na2P8f3x7t8h5jA5IJnQeK3LZv7t5k8fBQY5TgYwJz2E8rNsnAgMBAAGjUzBRMB0GA1Ud\nDgQWBBQYXb4rfCz0SODx1KL2I5R3O9dFYzAfBgNVHSMEGDAWgBQYXb4rfCz0SODx1KL2\nI5R3O9dFYzAPBgNVHRMBAf8EBTADAQH/MA0GCSqGSIb3DQEBCwUAA0EALhXzT7U72g9P\n3y8K9rI1X7h8f5I5nK7l6J8h2jJ9K0LM5N4P3Q2O1R6T7U8V9W0X1Y2Z3A4B5C6D7E8F9G0H1I2J3K4L5\n-----END CERTIFICATE-----", "tls.key": "-----BEGIN PRIVATE KEY-----\nMIIBVAIBADANBgkqhkiG9w0BAQEFAASCAT4wggE6AgEAAkEAvxSKX1F+Sae4RU/n9x2A\ncyuRd4E9M6gecOa2n2tj/H98e7fIeYwOSDgt0Hit+y2b+7eZPHwUGOU4GMCc9hPKzbJw\nIDAQABAkEAlv8zL2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z\n2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z\nAiEA7vPn2L2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z\n2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z\nCIQCv8zL2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z\n2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z\nAiEA3vPn2L2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z\n2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z2Z\n-----END PRIVATE KEY-----"}}' \
      http://localhost:58200/v1/secret/data/demo-app/tls-files
    # Add database configuration file
    curl -s -X POST \
      -H "X-Vault-Token: root" \
      -d '{"data": {"database.conf": "# Database Configuration\nhost=postgres.example.com\nport=5432\ndatabase=demo_app\nssl_mode=require\npool_size=20\nmax_overflow=10\n"}}' \
      http://localhost:58200/v1/secret/data/demo-app/config-files
    @echo "✓ File-based secrets added to Vault"

# List all Vault secrets
vault-list:
    @echo "=== Environment Secrets ==="
    @curl -s -H "X-Vault-Token: root" http://localhost:58200/v1/secret/data/demo-app/secrets | jq -r '.data.data // {} | keys[]' | sed 's/^/  • /'
    @echo ""
    @echo "=== Config Secrets ==="
    @curl -s -H "X-Vault-Token: root" http://localhost:58200/v1/secret/data/demo-app/config | jq -r '.data.data // {} | keys[]' | sed 's/^/  • /'
    @echo ""
    @echo "=== File Secrets (TLS) ==="
    @curl -s -H "X-Vault-Token: root" http://localhost:58200/v1/secret/data/demo-app/tls-files | jq -r '.data.data // {} | keys[]' | sed 's/^/  • /'
    @echo "=== File Secrets (Config) ==="
    @curl -s -H "X-Vault-Token: root" http://localhost:58200/v1/secret/data/demo-app/config-files | jq -r '.data.data // {} | keys[]' | sed 's/^/  • /'

# ============================================
# Phase 2: Build Application
# ============================================

# Build Docker image
build:
    docker build -t demo-app:latest app/
    @echo "✓ Demo app image built"

# Test app locally (port 58000)
test-app:
    docker run -d --name test-app -p 58000:8000 demo-app:latest
    @sleep 3
    @echo "App running at http://localhost:58000"
    @echo "Test with: curl http://localhost:58000"
    @echo "Stop with: docker stop test-app && docker rm test-app"

# ============================================
# Phase 3: Kind Cluster
# ============================================

# Create Kind cluster
cluster-create:
    kind create cluster --config kind-config.yaml --name eso-demo
    @echo "✓ Kind cluster 'eso-demo' created"

# Delete Kind cluster
cluster-delete:
    kind delete cluster --name eso-demo

# Check cluster status
cluster-status:
    kubectl get nodes

# Set kubectl context to eso-demo
cluster-use:
    kubectl config use-context kind-eso-demo

# ============================================
# Phase 4: Install ESO
# ============================================

# Install External Secrets Operator
eso-install:
    helm repo add external-secrets https://charts.external-secrets.io 2>/dev/null || true
    helm repo update
    helm install external-secrets external-secrets/external-secrets \
      --namespace external-secrets \
      --create-namespace \
      --wait
    @echo "✓ ESO installed"

# Upgrade ESO
eso-upgrade:
    helm upgrade external-secrets external-secrets/external-secrets \
      --namespace external-secrets \
      --wait

# Uninstall ESO
eso-uninstall:
    helm uninstall external-secrets -n external-secrets
    kubectl delete namespace external-secrets

# Check ESO status
eso-status:
    kubectl get pods -n external-secrets
    kubectl get crd | grep external-secrets

# ============================================
# Phase 5: Configure ESO
# ============================================

# Apply ClusterSecretStore
eso-store:
    kubectl apply -f manifests/eso/secret-store.yaml
    @sleep 2
    kubectl get clustersecretstore vault-backend

# Apply env-based ExternalSecrets
eso-secrets:
    kubectl apply -f manifests/eso/external-secrets.yaml
    @sleep 5
    kubectl get externalsecret

# Apply file-based ExternalSecrets
eso-files:
    kubectl apply -f manifests/eso/external-secrets-files.yaml
    @sleep 5
    kubectl get externalsecret

# Apply all ESO manifests
eso-apply: eso-store eso-secrets eso-files
    @echo "✓ All ESO manifests applied"

# Check ExternalSecret status
eso-check:
    kubectl get externalsecret
    @echo ""
    @echo "Waiting for all to be ready..."
    kubectl wait --for=condition=ready externalsecret --all --timeout=30s 2>/dev/null || echo "Some secrets not ready yet, run 'just eso-check' again"

# View ESO logs
eso-logs:
    kubectl logs -n external-secrets deployment/external-secrets -f

# ============================================
# Phase 6: Deploy Application
# ============================================

# Load image into Kind and deploy
deploy: build
    kind load docker-image demo-app:latest --name eso-demo
    helm upgrade --install demo-app charts/demo-app/
    kubectl wait --for=condition=available --timeout=60s deployment/demo-app
    @echo "✓ Demo app deployed"

# Deploy without rebuilding image
deploy-fast:
    helm upgrade --install demo-app charts/demo-app/
    kubectl wait --for=condition=available --timeout=60s deployment/demo-app
    @echo "✓ Demo app deployed"

# Restart deployment
restart:
    kubectl rollout restart deployment/demo-app
    kubectl wait --for=condition=available --timeout=60s deployment/demo-app
    @echo "✓ Deployment restarted"

# ============================================
# Phase 7: Verification
# ============================================

# Open all endpoints in browser (Linux)
open-browser:
    xdg-open http://localhost:58080/ &

# Check all components
status:
    @echo "=== Vault Status ==="
    @curl -s http://localhost:58200/v1/sys/health | jq -r '"Initialized: \(.initialized), Sealed: \(.sealed)"' 2>/dev/null || echo "Vault not running"
    @echo ""
    @echo "=== Kind Cluster ==="
    @kind get clusters | grep eso-demo && echo "✓ Cluster exists" || echo "✗ Cluster not found"
    @echo ""
    @echo "=== ESO Pods ==="
    @kubectl get pods -n external-secrets --no-headers 2>/dev/null | wc -l | xargs -I {} echo "ESO pods running: {}"
    @echo ""
    @echo "=== ExternalSecrets ==="
    @kubectl get externalsecret --no-headers 2>/dev/null | wc -l | xargs -I {} echo "ExternalSecrets: {}"
    @echo ""
    @echo "=== Demo App ==="
    @kubectl get deployment demo-app --no-headers 2>/dev/null | awk '{print "Deployment: " $2 "/" $4 " ready"}' || echo "✗ Demo app not deployed"
    @echo ""
    @echo "=== Access Points ==="
    @echo "  Home:      http://localhost:58080/"
    @echo "  Env Vars:  http://localhost:58080/env"
    @echo "  Files:     http://localhost:58080/files"
    @echo "  Combined:  http://localhost:58080/combined"

# Verify environment variables
verify-env:
    @echo "=== Environment Variables ==="
    curl -s http://localhost:58080/env | grep -oP '(?<=<div class="stat-value">)[^<]+' | head -3 | xargs -I {} echo "Stats: {}"
    @echo ""
    @echo "Key values:"
    curl -s http://localhost:58080/env | grep -oP '(?<=<div class="label secret">)[^<]+|(?<=<div class="value">)[^<]+' | head -10

# Verify mounted files
verify-files:
    @echo "=== Mounted Files ==="
    curl -s http://localhost:58080/files | grep -oP '(?<=<div class="stat-value">)[^<]+' | head -4 | xargs -I {} echo "Stats: {}"
    @echo ""
    @echo "Files in pod:"
    kubectl exec deployment/demo-app -- ls -la /etc/secrets/ /etc/config/ 2>/dev/null || echo "Pod not ready yet"

# Verify combined view
verify-combined:
    @echo "=== Combined View ==="
    curl -s http://localhost:58080/combined | grep -oP '(?<=<div class="stat-value">)[^<]+' | head -4 | xargs -I {} echo "Stats: {}"

# Full verification
verify: verify-env verify-files verify-combined
    @echo ""
    @echo "✓ Full verification complete"

# ============================================
# Phase 8: Utilities
# ============================================

# Port forward for local access
port-forward:
    kubectl port-forward svc/demo-app 8080:8000
    @echo "App available at http://localhost:8080"

# View app logs
logs:
    kubectl logs deployment/demo-app -f

# Execute into pod
exec:
    kubectl exec -it deployment/demo-app -- /bin/sh

# Check mounted files in pod
exec-files:
    kubectl exec deployment/demo-app -- ls -la /etc/secrets/ /etc/config/

# ============================================
# Cleanup
# ============================================

# Remove demo app only
clean-app:
    helm uninstall demo-app 2>/dev/null || echo "Demo app not installed"

# Remove ESO only
clean-eso:
    helm uninstall external-secrets -n external-secrets 2>/dev/null || echo "ESO not installed"
    kubectl delete namespace external-secrets 2>/dev/null || true

# Remove cluster only
clean-cluster:
    kind delete cluster --name eso-demo

# Full cleanup (except Vault)
clean: clean-app clean-eso clean-cluster
    docker rmi demo-app:latest 2>/dev/null || true
    @echo "✓ Cleanup complete (Vault still running)"

# Full cleanup including Vault
clean-all: clean
    cd vault && docker compose down -v
    @echo "✓ Full cleanup complete"

# ============================================
# Complete Workflows
# ============================================

# Full setup from scratch
setup: vault-up vault-init vault-add-files build cluster-create eso-install eso-apply deploy
    @echo ""
    @echo "========================================"
    @echo "✓ Full setup complete!"
    @echo "========================================"
    @echo ""
    @just status
    @echo ""
    @echo "Access the demo at: http://localhost:58080/"

# Quick verify everything
health-check:
    @echo "========================================"
    @echo "Health Check"
    @echo "========================================"
    @just status
    @echo ""
    @echo "Testing endpoints..."
    @curl -s http://localhost:58080/ > /dev/null && echo "✓ Home page accessible" || echo "✗ Home page not accessible"
    @curl -s http://localhost:58080/env > /dev/null && echo "✓ Env vars page accessible" || echo "✗ Env vars page not accessible"
    @curl -s http://localhost:58080/files > /dev/null && echo "✓ Files page accessible" || echo "✗ Files page not accessible"
    @echo ""
    @echo "========================================"
