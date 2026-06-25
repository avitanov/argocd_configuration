# Local Secrets

Local K3D testing should not depend on AWS Secrets Manager.

Use a local ignored env file and create the Kubernetes Secret manually.

## Recommended Local Secret File

Create:

```text
/home/atanas-vitanov/Documents/KII/ARGOCD_CONFIGURATION/local-secrets/emt-dev.env
```

This repository already ignores the real env file through:

```gitignore
local-secrets/*.env
```

## Example Local Secret File

```env
SPRING_DATASOURCE_URL=jdbc:postgresql://postgresql-ha-pgpool:5432/products?useUnicode=true&characterEncoding=UTF-8&serverTimezone=CET
SPRING_DATASOURCE_USERNAME=products
SPRING_DATASOURCE_PASSWORD=write-your-database-password
GEMINI_API_KEY=write-your-gemini-api-key
password=write-your-app-database-password
postgres-password=write-your-postgres-admin-password
repmgr-password=write-your-repmgr-password
admin-password=write-your-pgpool-admin-password
sr-check-password=write-your-pgpool-sr-check-password
```

The datasource URL above points to the Pgpool service created by the Bitnami PostgreSQL HA chart.

The backend consumes:

- `SPRING_DATASOURCE_URL`
- `SPRING_DATASOURCE_USERNAME`
- `SPRING_DATASOURCE_PASSWORD`
- `GEMINI_API_KEY`

The Bitnami PostgreSQL HA dependency consumes:

- `password`
- `postgres-password`
- `repmgr-password`
- `admin-password`
- `sr-check-password`

## Create the Secret

```bash
kubectl create namespace emt-dev

kubectl -n emt-dev create secret generic emt-app-secrets \
  --from-env-file=/home/atanas-vitanov/Documents/KII/ARGOCD_CONFIGURATION/local-secrets/emt-dev.env
```

`charts/emt-app/values-dev.yaml` already references:

```yaml
secrets:
  existingSecret: emt-app-secrets
```

Commit only `local-secrets/emt-dev.env.example`.
Do not commit `local-secrets/emt-dev.env`.
