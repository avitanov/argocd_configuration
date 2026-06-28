# AWS EKS Setup and Deployment

This guide deploys the application to AWS with:

- Amazon ECR
- Amazon EKS
- AWS Load Balancer Controller
- Amazon EBS CSI driver
- AWS Secrets Manager
- External Secrets Operator
- Argo CD
- Helm

Use this after Docker Compose, CI, ECR image publishing, and local Helm rendering already work.

## Prerequisites

Install locally:

- AWS CLI
- `kubectl`
- `helm`

You also need:

- AWS account access for the demo
- permission to create ECR, EKS, IAM roles, load balancers, and EBS volumes
- access to the `EMT_2025` and `ARGOCD_CONFIGURATION` GitHub repositories
- a DNS name if you want a real hostname instead of only the ALB DNS name

Recommended demo names:

- EKS cluster: `emt-eks`
- namespace: `emt-prod`
- ECR repositories: `emt-backend`, `emt-frontend`, `emt-db-seeder`
- AWS Secrets Manager secrets: `emt/prod/app`, `emt/prod/database`
- External Secrets store: `aws-secrets-manager`

## 1. Create ECR Repositories

```bash
aws ecr create-repository --repository-name emt-backend
aws ecr create-repository --repository-name emt-frontend
aws ecr create-repository --repository-name emt-db-seeder
```

Recommended settings:

- immutable image tags
- image scanning enabled
- lifecycle policy to remove old images

Example lifecycle policy:

```json
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Expire old images",
      "selection": {
        "tagStatus": "any",
        "countType": "imageCountMoreThan",
        "countNumber": 50
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
```

Apply it to each repository:

```bash
aws ecr put-lifecycle-policy \
  --repository-name emt-backend \
  --lifecycle-policy-text file://policy.json
```

## 2. Configure GitHub Actions

In the `EMT_2025` GitHub repository, configure these variables:

- `AWS_REGION`
- `AWS_ROLE_TO_ASSUME`
- `ECR_BACKEND_REPOSITORY`
- `ECR_FRONTEND_REPOSITORY`
- `ECR_DB_SEEDER_REPOSITORY`
- `GITOPS_REPOSITORY`
- `GITOPS_BRANCH`
- `GITOPS_BACKEND_VALUES_FILE`
- `GITOPS_FRONTEND_VALUES_FILE`
- `GITOPS_DB_SEEDER_VALUES_FILE`

The GitOps values file should normally be:

```text
charts/emt-app/values-prod.yaml
```

Configure this GitHub secret:

- `GITOPS_REPO_TOKEN`

Use AWS OIDC for AWS access. Do not store long-lived AWS access keys in GitHub.

## 3. Push Images to ECR

The application repo has separate workflows for:

- backend image
- frontend image
- database seeder image

On pushes to the main branch, the workflows build images, push them to ECR with the Git SHA tag, and update `ARGOCD_CONFIGURATION/charts/emt-app/values-prod.yaml`.

Confirm `values-prod.yaml` contains current ECR repositories and tags for:

- `backend.image`
- `frontend.image`
- `databaseSeeder.image`

## 4. Create Production Secrets in AWS Secrets Manager

Create `emt/prod/app` with:

```text
SPRING_DATASOURCE_URL
SPRING_DATASOURCE_USERNAME
SPRING_DATASOURCE_PASSWORD
GEMINI_API_KEY
```

`SPRING_DATASOURCE_URL` should point to the Pgpool service:

```text
jdbc:postgresql://postgresql-ha-pgpool:5432/products?useUnicode=true&characterEncoding=UTF-8&serverTimezone=CET
```

Create `emt/prod/database` with:

```text
password
postgres-password
repmgr-password
admin-password
sr-check-password
```

Do not put real secret values in Git, Helm values, documentation, or GitHub Actions logs.

## 5. Create the EKS Cluster

Create a small student-budget EKS cluster:

- one EKS cluster
- one low-cost managed node group
- private subnets for worker nodes
- public subnets for the ALB if the application is public
- small instance types appropriate for a university demo

Install required add-ons before deploying the app:

1. Amazon EBS CSI driver
2. AWS Load Balancer Controller
3. metrics-server
4. External Secrets Operator
5. Argo CD

The chart expects EBS-backed dynamic provisioning for PostgreSQL HA PVCs. `values-prod.yaml` defaults to `gp3`.

## 6. Configure External Secrets

Create a `ClusterSecretStore` named:

```text
aws-secrets-manager
```

It must allow External Secrets Operator to read:

- `emt/prod/app`
- `emt/prod/database`

If you choose a different store name or secret path, update `charts/emt-app/values-prod.yaml`.

## 7. Review Production Values

Before deploying, review:

```text
charts/emt-app/values.yaml
charts/emt-app/values-prod.yaml
```

Check:

- namespace is `emt-prod`
- image repositories point to ECR
- image tags are immutable Git SHA tags
- ingress class is `alb`
- ALB annotations are correct
- `secrets.externalSecret.enabled` is `true`
- `databaseSeeder.enabled` is `true`
- PostgreSQL HA uses small demo-friendly resources

## 8. Validate Helm

From `ARGOCD_CONFIGURATION`:

```bash
helm dependency update charts/emt-app
helm lint charts/emt-app

helm template emt-app charts/emt-app \
  --namespace emt-prod \
  -f charts/emt-app/values-prod.yaml
```

## 9. Install Argo CD

Example:

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

Do not commit Argo CD admin passwords or kubeconfig files.

## 10. Configure Argo CD Manifests

Review and update:

```text
argocd/projects/emt-project.yaml
argocd/applications/emt-app.yaml
```

Check:

- Git repository URL
- target branch
- chart path: `charts/emt-app`
- values file: `values-prod.yaml`
- destination namespace: `emt-prod`
- destination cluster

Apply:

```bash
kubectl apply -f argocd/projects/emt-project.yaml
kubectl apply -f argocd/applications/emt-app.yaml
```

## 11. Verify the AWS Deployment

```bash
kubectl get pods -n emt-prod
kubectl get svc -n emt-prod
kubectl get ingress -n emt-prod
kubectl get pvc -n emt-prod
kubectl get externalsecret -n emt-prod
kubectl get secret -n emt-prod
kubectl get jobs -n emt-prod
```

Check the seeder Job:

```bash
kubectl logs job/$(kubectl get jobs -n emt-prod \
  -l app.kubernetes.io/component=db-seeder \
  -o jsonpath='{.items[0].metadata.name}') -n emt-prod
```

Check application logs:

```bash
kubectl logs deployment/emt-app-backend -n emt-prod
kubectl logs deployment/emt-app-frontend -n emt-prod
```

Check Argo CD:

- application is synced
- application is healthy
- no ExternalSecret errors
- ALB Ingress receives an address

## 12. Test the Application

Get the Ingress:

```bash
kubectl get ingress -n emt-prod
```

Open the configured host or ALB DNS name.

Routing:

- `/` goes to frontend
- `/api` goes to backend
- PostgreSQL is internal only

## 13. Demo Checklist

Before presenting, verify:

- public Git repositories are available
- backend, frontend, and seeder images exist in ECR
- GitHub Actions update only `values-prod.yaml`
- Argo CD syncs from `ARGOCD_CONFIGURATION`
- frontend and backend Deployments are healthy
- Services exist
- Ingress exists and routes correctly
- PostgreSQL HA chart created StatefulSets and PVCs
- database seeder Job completed
- backend can read seeded product data
- secrets are coming from AWS Secrets Manager through External Secrets
- resources run in `emt-prod`, not `default`
