# AWS Architecture Explanation

AWS deployment is the production-style GitOps flow for the university demo.

The goal is that application code changes in `EMT_2025` produce immutable ECR images, update the production Helm values in `ARGOCD_CONFIGURATION`, and let Argo CD deploy the desired state to EKS.

## AWS Flow

```text
Developer pushes code to EMT_2025
        |
        v
GitHub Actions runs CI
        |
        v
Backend, frontend, or database seeder image is built
        |
        v
Image is pushed to Amazon ECR with the Git SHA tag
        |
        v
GitHub Actions updates charts/emt-app/values-prod.yaml
        |
        v
GitHub Actions commits the GitOps change to ARGOCD_CONFIGURATION
        |
        v
Argo CD detects the Git change
        |
        v
Argo CD syncs the Helm chart to EKS
        |
        v
External Secrets creates emt-app-secrets from AWS Secrets Manager
        |
        v
PostgreSQL HA, backend, frontend, Ingress, and seeder Job run in emt-prod
```

GitHub Actions does not deploy with `kubectl apply`. Argo CD owns deployment to EKS.

## Main AWS Components

Amazon ECR stores:

- `emt-backend`
- `emt-frontend`
- `emt-db-seeder`

Amazon EKS runs:

- frontend Deployment
- backend Deployment
- database seeder Job
- Bitnami PostgreSQL HA chart resources
- Services
- Ingress
- ExternalSecret

AWS Load Balancer Controller creates the internet-facing ALB from the Kubernetes Ingress.

Amazon EBS CSI driver dynamically provisions persistent volumes for PostgreSQL HA.

AWS Secrets Manager stores runtime secrets.

External Secrets Operator syncs AWS Secrets Manager values into Kubernetes.

Argo CD watches `ARGOCD_CONFIGURATION` and applies `charts/emt-app` with `values-prod.yaml`.

## Production Values File

`charts/emt-app/values-prod.yaml` is the desired production/demo state.

It contains:

- ECR image repositories
- immutable Git SHA image tags
- namespace `emt-prod`
- ALB Ingress settings
- External Secrets references
- small demo-friendly resources
- PostgreSQL HA values
- database seeder values

It must not contain:

- real secret values
- AWS access keys
- kubeconfig contents
- Argo CD passwords

GitHub Actions updates this file when it pushes new images.

## CI/CD Responsibilities

The `EMT_2025` workflows are responsible for:

- testing backend/frontend where relevant
- building Docker images
- authenticating to AWS through OIDC
- pushing images to ECR
- updating only `values-prod.yaml`
- committing the GitOps change

The three image-producing workflows are:

- `backend-ci.yml`
- `frontend-ci.yml`
- `db-seeder-ci.yml`

The image tag should be the Git commit SHA. Avoid relying on `latest`.

## Argo CD Responsibilities

Argo CD is responsible for:

- watching `ARGOCD_CONFIGURATION`
- rendering the Helm chart
- applying Kubernetes resources to EKS
- self-healing drift when enabled
- pruning resources removed from Git when enabled

The Argo CD Application should point to:

```text
charts/emt-app
```

with:

```text
values-prod.yaml
```

Local K3D does not use Argo CD.

## Secrets on AWS

Real runtime secrets live in AWS Secrets Manager.

Expected remote secrets:

- `emt/prod/app`
- `emt/prod/database`

`emt/prod/app` contains:

- `SPRING_DATASOURCE_URL`
- `SPRING_DATASOURCE_USERNAME`
- `SPRING_DATASOURCE_PASSWORD`
- `GEMINI_API_KEY`

`emt/prod/database` contains:

- `password`
- `postgres-password`
- `repmgr-password`
- `admin-password`
- `sr-check-password`

External Secrets Operator creates the Kubernetes Secret:

```text
emt-app-secrets
```

That Kubernetes Secret is consumed by:

- backend Deployment
- Bitnami PostgreSQL HA chart
- database seeder Job

## Database on AWS

The database is deployed through the Bitnami PostgreSQL HA Helm chart.

This satisfies the StatefulSet/database requirement through a real PostgreSQL HA implementation, not a fake manual StatefulSet with three replicas.

The Bitnami chart provides:

- PostgreSQL primary/replica behavior
- StatefulSets
- persistent volumes
- Pgpool
- Repmgr
- internal services
- replication and failover behavior

The backend and seeder Job connect through:

```text
postgresql-ha-pgpool:5432
```

PostgreSQL is never exposed publicly.

## Database Seeding on AWS

The `emt-db-seeder` image is built by CI and pushed to ECR.

The Helm chart creates a Kubernetes Job that:

- connects to Pgpool
- uses credentials from `emt-app-secrets`
- applies the schema
- loads CSV data
- records the applied seed version in `public.emt_seed_history`

The Job is idempotent. It does not duplicate data on repeated syncs. If demo data must be fully reset, set:

```yaml
databaseSeeder:
  truncateBeforeLoad: true
```

Use that carefully because it deletes existing demo product data before reloading.

## Ingress on AWS

AWS uses the AWS Load Balancer Controller.

`values-prod.yaml` configures:

```yaml
ingress:
  className: alb
```

Typical ALB annotations:

- `alb.ingress.kubernetes.io/scheme: internet-facing`
- `alb.ingress.kubernetes.io/target-type: ip`
- `alb.ingress.kubernetes.io/listen-ports: '[{"HTTP":80}]'`

Routing:

- `/` to frontend
- `/api` to backend

The database is internal only.

## Student-Budget Notes

This AWS setup is for a university demo, not real production traffic.

Keep costs low:

- use minimal frontend/backend replicas unless required
- use small node types
- keep PostgreSQL storage small
- avoid unnecessary load balancers
- use realistic but modest CPU and memory requests
- delete the EKS cluster and load balancers when the demo is done

EKS, EC2 nodes, EBS volumes, and load balancers can all create AWS cost.

## What AWS Deployment Proves

The AWS deployment proves:

- GitHub Actions CI works
- ECR image push works
- immutable image tags are used
- GitOps values are updated automatically
- Argo CD deploys from Git
- application resources run in `emt-prod`
- ALB Ingress exposes the frontend/backend routes
- backend communicates with PostgreSQL HA through Pgpool
- secrets come from AWS Secrets Manager
- database StatefulSets and PVCs are managed by Bitnami PostgreSQL HA
- database seed data is loaded by a Kubernetes Job
