# AWS Secrets Manager

Production and demo secrets must not be stored directly in Git.

Use this flow:

```text
AWS Secrets Manager
        |
        v
External Secrets Operator
        |
        v
Kubernetes Secret in emt-prod
        |
        v
Backend and PostgreSQL HA consume that secret
```

## Secret Names Used by This Repository

The chart expects one Kubernetes Secret named `emt-app-secrets`.

`charts/emt-app/values-prod.yaml` configures an `ExternalSecret` that maps values from:

- `emt/prod/app`
- `emt/prod/database`

## Expected Secret Properties

Application secret properties:

- `SPRING_DATASOURCE_URL`
- `SPRING_DATASOURCE_USERNAME`
- `SPRING_DATASOURCE_PASSWORD`
- `GEMINI_API_KEY`

`SPRING_DATASOURCE_URL` should point to the PostgreSQL HA service exposed by Pgpool, not to a specific PostgreSQL pod.

Database secret properties:

- `password`
- `postgres-password`
- `repmgr-password`
- `admin-password`
- `sr-check-password`

## ClusterSecretStore

This repository assumes an existing `ClusterSecretStore` named:

```text
aws-secrets-manager
```

If you use a different name, update:

`charts/emt-app/values-prod.yaml`

## Important Rule

`values-prod.yaml` may contain secret names and remote property references, but not real secret values.
