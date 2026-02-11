# External Secrets Operator Demo

A complete demonstration of using Kubernetes External Secrets Operator (ESO) to sync secrets from HashiCorp Vault to your applications running in a Kind cluster.

## Architecture

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   HashiCorp     │     │  External Secrets│     │  Python Demo    │
│     Vault       │────▶│     Operator     │────▶│     App         │
│  (Port 58200)   │     │   (Kubernetes)   │     │  (Port 58080)   │
└─────────────────┘     └──────────────────┘     └─────────────────┘
         │                        │
         └───────────────┴────────────────┘
```

## Quick Start

### Prerequisites

- Docker
- Just command runner
- kubectl (comes with Kind)
- Helm 3

### Just

```bash
just setup
```

## Two Methods Demonstrated

1. **Environment Variables** - Traditional approach for simple secrets
2. **Mounted Files** - Ideal for certificates and complex configs

## Access Points

After `just setup`, access the demo app at:

- **<http://localhost:58080/env>** - Environment variables only
- **<http://localhost:58080/files>** - Mounted files only
- **<http://localhost:58080/combined>** - Both env vars and files

### Manual Step Through

```bash
just vault-up  # starts Vault
just vault-init  # initializes the instance
just vault-add-files # seed vault with some secrets
just build # builds the app
just cluster-create # create kind cluster
just eso-install # install external secrets operator
just eso-apply # create external secrets resources
just deploy  # deploy the app
```

## Available Commands

```bash
just --list                    # See all 54 recipes
just status                    # Check all components
just health-check               # Verify everything works
```

## Success Criteria

After setup, you should see:

- [ ] Vault UI: <http://localhost:58200> (token: root)
- [ ] App shows 2 secrets + 3 configs
- [ ] ESO pods: 3 running pods
- [ ] Endpoints respond on localhost:58080

## Cleanup

```bash
# Remove everything except essentials
just clean

# Full cleanup
just clean-all
```
