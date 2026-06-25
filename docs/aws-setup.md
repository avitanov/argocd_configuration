# AWS Deployment Runbook

Use this document when you want to deploy the full stack to AWS with:

- Amazon ECR for images
- Amazon EKS for Kubernetes
- AWS Load Balancer Controller for Ingress
- AWS Secrets Manager plus External Secrets Operator for secrets
- Argo CD for GitOps deployment

This is the production-style flow for the project.

## Prerequisites

Prepare these first:

- one AWS account for the demo
- AWS CLI configured locally
- `kubectl`
- `helm`
- access to the GitHub repositories
- an IAM identity with permission to create ECR, EKS, IAM roles, networking, and add-ons
- a public DNS name if you want a real internet-facing hostname

You also need both repositories ready:

- `EMT_2025` for CI, Docker images, and image publishing
- `ARGOCD_CONFIGURATION` for Helm and Argo CD deployment state

## 1. Decide the AWS Baseline

Before building anything, decide:

- AWS region
- cluster name
- VPC and subnet layout
- public hostname
- certificate strategy if you want HTTPS
- whether you will use a `ClusterSecretStore` or `SecretStore` for External Secrets

Recommended naming:

- EKS cluster: `emt-eks`
- ECR repositories: `emt-backend`, `emt-frontend`
- namespace: `emt-prod`

## 2. Prepare IAM the Right Way

Use short-lived credentials wherever possible.

Recommended model:

- GitHub Actions assumes an AWS role through OIDC
- cluster add-ons use IAM roles where required
- no long-lived AWS access keys in GitHub

Minimum IAM topics to prepare:

1. GitHub OIDC provider
2. GitHub Actions role for ECR push
3. EKS cluster role
4. EKS node group role
5. IAM role for the AWS Load Balancer Controller
6. IAM role for the EBS CSI driver
7. IAM access path for AWS Secrets Manager through External Secrets Operator

## 3. Create the ECR Repositories

```bash
aws ecr create-repository --repository-name emt-backend
aws ecr create-repository --repository-name emt-frontend
```

Recommended settings:

- immutable image tags
- image scanning enabled
- lifecycle policies for cleanup

See also:

- [ecr-setup.md](./ecr-setup.md)

## 4. Configure GitHub Actions in EMT_2025

Set the required GitHub variables for the CI workflows in `EMT_2025`:

- `AWS_REGION`
- `AWS_ROLE_TO_ASSUME`
- `ECR_BACKEND_REPOSITORY`
- `ECR_FRONTEND_REPOSITORY`
- `GITOPS_REPOSITORY`
- `GITOPS_BRANCH`
- `GITOPS_BACKEND_VALUES_FILE`
- `GITOPS_FRONTEND_VALUES_FILE`

The production GitOps target in this repository is:

- `charts/emt-app/values-prod.yaml`

That is the file CI should update with new image tags.

## 5. Create the EKS Cluster

Do not create EKS before the application images, CI workflows, and Helm chart are ready.

Cluster checklist:

- one EKS cluster
- at least one managed node group
- private subnets for worker nodes
- public subnets for the ALB if the application is internet-facing

Required add-ons before the first application sync:

1. Amazon EBS CSI driver
2. AWS Load Balancer Controller
3. metrics-server
4. Argo CD
5. External Secrets Operator

See also:

- [eks-setup.md](./eks-setup.md)

## 6. Prepare AWS Secrets Manager

Production and demo secrets must not live in Git.

Create the application and database secrets in AWS Secrets Manager so the chart can map them into the Kubernetes Secret `emt-app-secrets`.

Expected remote secrets:

- `emt/prod/app`
- `emt/prod/database`

Expected properties:

- `SPRING_DATASOURCE_URL`
- `SPRING_DATASOURCE_USERNAME`
- `SPRING_DATASOURCE_PASSWORD`
- `GEMINI_API_KEY`
- `password`
- `postgres-password`
- `repmgr-password`
- `admin-password`
- `sr-check-password`

`SPRING_DATASOURCE_URL` should point to the PostgreSQL HA Pgpool service, not a specific PostgreSQL pod.

See also:

- [aws-secrets-manager.md](./aws-secrets-manager.md)

## 7. Review Production Helm Values

Before Argo CD syncs anything, review:

- `charts/emt-app/values.yaml`
- `charts/emt-app/values-prod.yaml`

Update placeholders such as:

- ECR repository URLs
- ingress host name
- External Secrets store name
- remote secret keys and property names if your AWS layout differs

Do not put real secret values into `values-prod.yaml`.

## 8. Validate the Helm Chart

From `ARGOCD_CONFIGURATION`:

```bash
helm dependency update charts/emt-app
helm lint charts/emt-app
helm template emt-app charts/emt-app -f charts/emt-app/values-prod.yaml
```

## 9. Install Argo CD

Example:

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

See also:

- [argocd-setup.md](./argocd-setup.md)

## 10. Point Argo CD at This Repository

Before applying the manifests, replace placeholders in:

- `argocd/projects/emt-project.yaml`
- `argocd/applications/emt-app.yaml`

Important values to review:

- Git repo URL
- target branch
- destination namespace
- production host name

Then apply:

```bash
kubectl apply -f argocd/projects/emt-project.yaml
kubectl apply -f argocd/applications/emt-app.yaml
```

## 11. Validate the EKS Deployment

Check:

```bash
kubectl get pods -n emt-prod
kubectl get svc -n emt-prod
kubectl get ingress -n emt-prod
kubectl get externalsecret -n emt-prod
kubectl get secret -n emt-prod
```

Also confirm:

- worker nodes are `Ready`
- ALB controller pods are healthy
- EBS CSI driver is healthy
- Argo CD application sync is healthy
- External Secrets successfully created `emt-app-secrets`

## 12. Production Routing Model

This repository expects:

- `/` to the frontend
- `/api` to the backend
- PostgreSQL to remain internal only

Production uses AWS Load Balancer Controller with ALB-oriented ingress settings from `values-prod.yaml`.

See also:

- [ingress-setup.md](./ingress-setup.md)
