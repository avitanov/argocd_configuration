# ARGOCD_CONFIGURATION

This repository is the GitOps and Kubernetes side of the EMT project.

It contains:

- the Helm chart for the application
- environment-specific values files
- Argo CD project and application manifests
- documentation for AWS, ECR, EKS, Argo CD, and the deployment flow

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
├── environments/
│   ├── dev/
│   │   └── values.yaml
│   └── prod/
│       └── values.yaml
└── docs/
    ├── argocd-setup.md
    ├── aws-setup.md
    ├── deployment-flow.md
    ├── ecr-setup.md
    ├── eks-setup.md
    └── university-demo-checklist.md
```

## Chart Usage

Build dependencies first:

```bash
cd ARGOCD_CONFIGURATION
helm dependency build charts/emt-app
```

Validate the chart:

```bash
helm lint charts/emt-app
helm template emt-app charts/emt-app -f environments/dev/values.yaml
helm template emt-app charts/emt-app -f environments/prod/values.yaml
```

## GitOps Flow

1. `EMT_2025` builds backend/frontend Docker images
2. GitHub Actions pushes images to Amazon ECR
3. GitHub Actions updates `environments/prod/values.yaml`
4. Argo CD detects the Git change in this repository
5. Argo CD syncs the Helm chart into EKS

## Important Placeholders

Before a real deployment, replace these placeholders:

- repository URLs in `argocd/applications/emt-app.yaml` and `argocd/projects/emt-project.yaml`
- ECR repository names in `environments/dev/values.yaml` and `environments/prod/values.yaml`
- domain names such as `emt.example.com`
- placeholder database and API secrets

For production, move real secrets to AWS Secrets Manager or Kubernetes Secrets created outside Git.
