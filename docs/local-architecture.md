# Local Architecture Explanation

Local Kubernetes testing is intentionally separate from the AWS GitOps flow.

The local goal is to prove that the Helm chart, application containers, PostgreSQL HA dependency, local secrets, Ingress, and database seed process work before deploying to AWS.

## Local Flow

```text
Developer builds images locally
        |
        v
Images are imported into K3D
        |
        v
Local env file creates emt-app-secrets
        |
        v
Helm installs charts/emt-app with values-dev.yaml
        |
        v
Bitnami PostgreSQL HA starts
        |
        v
Database seeder Job loads schema and CSV data
        |
        v
Backend connects through Pgpool
        |
        v
Frontend reaches backend through /api
        |
        v
Traefik exposes the app at emt.localhost:8080
```

## Repository Responsibilities

`EMT_2025` owns application artifacts:

- backend source code
- frontend source code
- Dockerfiles
- Docker Compose
- database SQL and CSV seed data
- `db-seeder` image definition

`ARGOCD_CONFIGURATION` owns Kubernetes artifacts:

- Helm chart
- local and production values files
- Argo CD manifests
- local and AWS documentation

Application code and Kubernetes configuration stay separated.

## Why Local Uses Helm Directly

Local K3D does not use Argo CD.

For local development, direct Helm is simpler and faster:

```bash
helm upgrade --install emt-app charts/emt-app \
  --namespace emt-dev \
  --create-namespace \
  -f charts/emt-app/values-dev.yaml
```

Argo CD is reserved for AWS EKS production/demo deployment.

## Local Values File

`charts/emt-app/values-dev.yaml` is the local overlay.

It configures:

- namespace `emt-dev`
- local image repositories
- image tag `dev`
- `imagePullPolicy: IfNotPresent`
- Traefik Ingress
- host `emt.localhost`
- smaller resource requests and limits
- local Kubernetes Secret name `emt-app-secrets`
- database seeder image `emt-db-seeder:dev`

It must not contain:

- real secrets
- AWS ALB annotations
- ECR-only image URLs unless explicitly testing that path
- Argo CD-specific behavior

## Secrets Locally

Local secrets come from:

```text
ARGOCD_CONFIGURATION/local-secrets/emt-dev.env
```

That file is ignored by Git.

The file is converted into a Kubernetes Secret:

```text
emt-app-secrets
```

The same Kubernetes Secret is consumed by:

- backend Deployment
- Bitnami PostgreSQL HA chart
- database seeder Job

Important keys:

- `SPRING_DATASOURCE_URL`
- `SPRING_DATASOURCE_USERNAME`
- `SPRING_DATASOURCE_PASSWORD`
- `GEMINI_API_KEY`
- `password`
- `postgres-password`
- `repmgr-password`
- `admin-password`
- `sr-check-password`

## Database Model

The Kubernetes database is provided by the Bitnami PostgreSQL HA Helm chart.

This is intentional. The project does not create a fake three-replica PostgreSQL StatefulSet because PostgreSQL high availability needs real replication, failover behavior, persistent storage, and routing.

The Bitnami chart creates the PostgreSQL StatefulSets, services, Pgpool, replication wiring, and PVCs.

The backend connects to:

```text
postgresql-ha-pgpool:5432
```

It does not connect to a specific PostgreSQL pod.

## Database Seeding

Docker Compose can mount SQL and CSV files directly into the PostgreSQL container. Kubernetes and EKS cannot rely on those local host mounts.

For Kubernetes, the project uses a separate `emt-db-seeder` image and Helm Job.

The seeder image includes:

- `01_schema.sql`
- `02_load_data.sql`
- `inverteri.csv`
- `frizideri.csv`

The seed script:

- waits until Pgpool accepts connections
- applies the schema
- creates `public.emt_seed_history`
- skips a seed version that already ran
- avoids duplicating data if product rows already exist
- can truncate and reload only when `databaseSeeder.truncateBeforeLoad=true`

The SQL loader uses client-side `\copy`, so the CSV files are read from the seeder container filesystem.

## Routing

K3D exposes Traefik through host ports:

- host `8080` maps to cluster port `80`
- host `8443` maps to cluster port `443`

Ingress routes:

- `/` to frontend
- `/api` to backend

PostgreSQL is never exposed through Ingress.

## What Local Testing Proves

Local K3D testing proves:

- images build locally
- images can run in Kubernetes
- Helm chart renders and installs
- namespace separation works
- local secrets work
- PostgreSQL HA chart starts
- database seed Job loads schema and CSV data
- backend connects to Pgpool
- frontend reaches backend
- Ingress routing works through Traefik

After those are proven, the AWS deployment can use the same Helm chart with `values-prod.yaml`.
