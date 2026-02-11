#!/bin/bash
set -e

VAULT_ADDR=${VAULT_ADDR:-http://localhost:58200}
VAULT_TOKEN=${VAULT_TOKEN:-root}

echo "=== Vault Initialization Script ==="
echo "Vault Address: $VAULT_ADDR"
echo ""

# Wait for Vault to be ready
echo "Waiting for Vault to be ready..."
until curl -s "$VAULT_ADDR/v1/sys/health" | grep -q '"initialized":true'; do
	sleep 1
done
echo "✓ Vault is ready"
echo ""

# Enable KV secrets engine v2
echo "Enabling KV secrets engine..."
curl -s -X POST \
	-H "X-Vault-Token: $VAULT_TOKEN" \
	-d '{"type": "kv-v2"}' \
	"$VAULT_ADDR/v1/sys/mounts/secret" || echo "  (may already be enabled)"
echo "✓ KV engine enabled"
echo ""

# Create sample secrets
echo "Creating sample secrets..."

# Sensitive secrets
curl -s -X POST \
	-H "X-Vault-Token: $VAULT_TOKEN" \
	-d '{
        "data": {
            "database_password": "super_secret_db_pass_123",
            "api_key": "sk-demo-api-key-xyz789"
        }
    }' \
	"$VAULT_ADDR/v1/secret/data/demo-app/secrets"
echo "✓ Created: secret/demo-app/secrets"

# Configuration values
curl -s -X POST \
	-H "X-Vault-Token: $VAULT_TOKEN" \
	-d '{
        "data": {
            "app_name": "External Secrets Demo",
            "debug_mode": "true",
            "max_connections": "100"
        }
    }' \
	"$VAULT_ADDR/v1/secret/data/demo-app/config"
echo "✓ Created: secret/demo-app/config"
echo ""

# Enable Kubernetes auth backend
echo "Enabling Kubernetes auth backend..."
curl -s -X POST \
	-H "X-Vault-Token: $VAULT_TOKEN" \
	-d '{"type": "kubernetes"}' \
	"$VAULT_ADDR/v1/sys/auth/kubernetes" || echo "  (may already be enabled)"
echo "✓ Kubernetes auth enabled"
echo ""

# Create policy for demo-app
echo "Creating demo-app policy..."
curl -s -X PUT \
	-H "X-Vault-Token: $VAULT_TOKEN" \
	-d '{
        "policy": "path \"secret/data/demo-app/*\" {\n  capabilities = [\"read\"]\n}"
    }' \
	"$VAULT_ADDR/v1/sys/policies/acl/demo-app-policy"
echo "✓ Policy created"
echo ""

echo "=== Vault Initialization Complete ==="
echo ""
echo "Secrets created:"
echo "  - secret/demo-app/secrets (database_password, api_key)"
echo "  - secret/demo-app/config (app_name, debug_mode, max_connections)"
echo ""
echo "Auth backends:"
echo "  - kubernetes/ (enabled, configure with your cluster)"
echo ""
echo "Policies:"
echo "  - demo-app-policy (read access to secret/demo-app/*)"
echo ""
echo "Root Token: $VAULT_TOKEN"
echo ""
