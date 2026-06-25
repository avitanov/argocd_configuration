# Deployment Flow

The intended deployment flow is:

```text
Developer pushes code to EMT_2025
        |
        v
GitHub Actions runs CI
        |
        v
Backend/frontend images are built
        |
        v
Images are pushed to Amazon ECR
        |
        v
GitHub Actions updates charts/emt-app/values-prod.yaml in ARGOCD_CONFIGURATION
        |
        v
Argo CD detects the Git change
        |
        v
Argo CD syncs charts/emt-app to EKS
        |
        v
Frontend, backend, and PostgreSQL HA run in Kubernetes
```

## Important Rule

GitHub Actions should not deploy directly with `kubectl apply`.

This repository is the source of truth for desired Kubernetes state.

## Main Files in This Flow

- `EMT_2025/.github/workflows/backend-ci.yml`
- `EMT_2025/.github/workflows/frontend-ci.yml`
- `ARGOCD_CONFIGURATION/charts/emt-app/values-prod.yaml`
- `ARGOCD_CONFIGURATION/argocd/applications/emt-app.yaml`
