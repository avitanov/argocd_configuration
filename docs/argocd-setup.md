# Argo CD Setup

This repository is meant to be watched by Argo CD.

## Install Argo CD

Example:

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

## Apply the Project

```bash
kubectl apply -f argocd/projects/emt-project.yaml
```

## Apply the Application

```bash
kubectl apply -f argocd/applications/emt-app.yaml
```

## Required Placeholder Updates First

Before applying, replace:

- `https://github.com/your-org/ARGOCD_CONFIGURATION.git`
- placeholder domain names
- placeholder image repositories if needed
- External Secrets store names and remote secret references in `charts/emt-app/values-prod.yaml`

Do not put real secrets in `values-prod.yaml`.
For AWS EKS, keep real values in AWS Secrets Manager and sync them through External Secrets Operator.

## Sync Behavior

The application manifest enables:

- `prune: true`
- `selfHeal: true`

That is good for the university demo, but you should understand that Argo CD can delete resources removed from Git.

## Runtime Namespace

The chart deploys into:

- `emt-prod` by default

The namespace is also defined in the Helm chart values.

## Production Values File

The Argo CD application points to:

- `charts/emt-app/values-prod.yaml`

That file is the production overlay GitHub Actions should update with new image tags.
