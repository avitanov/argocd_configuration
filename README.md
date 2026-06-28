# ARGOCD_CONFIGURATION

This repository is the GitOps and Kubernetes side of the EMT project.

It contains:

- the Helm chart for the application
- chart-level environment overlays for local and production
- Argo CD project and application manifests
- documentation for local K3D and AWS EKS deployment

Application source code, Dockerfiles, Docker Compose, and GitHub Actions stay in `../EMT_2025`.

## Structure

```text
ARGOCD_CONFIGURATION/
├── README.md
├── argocd/
│   ├── applications/
│   │   └── emt-app.yaml
│   └── projects/
│       └── emt-project.yaml
├── charts/
│   └── emt-app/
└── docs/
    ├── local-k3d-setup.md
    ├── aws-setup.md
    ├── local-architecture.md
    └── aws-architecture.md
```

## Primary Guides

The docs are intentionally limited to four files:

- local setup and testing: [docs/local-k3d-setup.md](./docs/local-k3d-setup.md)
- how local deployment works: [docs/local-architecture.md](./docs/local-architecture.md)
- AWS setup and deployment: [docs/aws-setup.md](./docs/aws-setup.md)
- how AWS deployment works: [docs/aws-architecture.md](./docs/aws-architecture.md)

## Chart Usage

Base values live in:

- `charts/emt-app/values.yaml`

Local K3D overrides live in:

- `charts/emt-app/values-dev.yaml`

Production EKS overrides live in:

- `charts/emt-app/values-prod.yaml`

Build dependencies first:

```bash
cd ARGOCD_CONFIGURATION
helm dependency update charts/emt-app
```

That command generates the dependency artifacts under `charts/emt-app/charts/` and may also generate `Chart.lock`.

Validate the chart:

```bash
helm lint charts/emt-app
helm template emt-app charts/emt-app -f charts/emt-app/values-dev.yaml
helm template emt-app charts/emt-app -f charts/emt-app/values-prod.yaml
```

## GitOps Flow

1. `EMT_2025` builds backend/frontend/database seeder Docker images
2. GitHub Actions pushes images to Amazon ECR
3. GitHub Actions updates `charts/emt-app/values-prod.yaml`
4. Argo CD detects the Git change in this repository
5. Argo CD syncs the Helm chart into EKS

## Important Placeholders

Before a real deployment, replace these placeholders:

- repository URLs in `argocd/applications/emt-app.yaml` and `argocd/projects/emt-project.yaml`
- ECR repository names in `charts/emt-app/values-dev.yaml` and `charts/emt-app/values-prod.yaml`
- secret store names and remote secret keys in `charts/emt-app/values-prod.yaml`
- domain names such as `emt.example.com`
- local secret file contents used for K3D testing

For local K3D, create the secret manually.
For AWS EKS, keep real secrets in AWS Secrets Manager and sync them through External Secrets Operator.
