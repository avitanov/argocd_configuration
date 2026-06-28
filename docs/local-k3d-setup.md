# Local K3D Setup and Testing

This guide runs the full application locally on Kubernetes with K3D.

Local mode uses:

- K3D/K3s
- Traefik Ingress
- Helm directly
- `charts/emt-app/values-dev.yaml`
- local Docker images tagged `dev`
- a manually created Kubernetes Secret from `ARGOCD_CONFIGURATION/local-secrets/emt-dev.env`

Argo CD is not used locally.

## Prerequisites

Install:

- Docker
- `kubectl`
- `helm`
- `k3d`

Repositories expected on this machine:

- `/home/atanas-vitanov/Documents/KII/EMT_2025`
- `/home/atanas-vitanov/Documents/KII/ARGOCD_CONFIGURATION`

## 1. Create the K3D Cluster

```bash
k3d cluster create emt-local \
  --agents 2 \
  --port "8080:80@loadbalancer" \
  --port "8443:443@loadbalancer"
```

K3D/K3s includes Traefik by default. The local values file uses:

```yaml
ingress:
  className: traefik
  host: emt.localhost
```

## 2. Build Local Images

```bash
docker build -t emt-backend:dev /home/atanas-vitanov/Documents/KII/EMT_2025/backend
docker build -t emt-frontend:dev /home/atanas-vitanov/Documents/KII/EMT_2025/frontend
docker build -t emt-db-seeder:dev \
  -f /home/atanas-vitanov/Documents/KII/EMT_2025/db-seeder/Dockerfile \
  /home/atanas-vitanov/Documents/KII/EMT_2025
```

The `emt-db-seeder` image contains:

- `backend/db/01_schema.sql`
- `backend/db/02_load_data.sql`
- `backend/data/inverteri.csv`
- `backend/data/frizideri.csv`

## 3. Import Images into K3D

```bash
k3d image import emt-backend:dev -c emt-local
k3d image import emt-frontend:dev -c emt-local
k3d image import emt-db-seeder:dev -c emt-local
```

## 4. Create Local Secrets

Create:

```text
/home/atanas-vitanov/Documents/KII/ARGOCD_CONFIGURATION/local-secrets/emt-dev.env
```

Use this format:

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

Do not commit this file. The repository ignores `local-secrets/*.env`.

Create the Kubernetes Secret:

```bash
kubectl create namespace emt-dev

kubectl -n emt-dev create secret generic emt-app-secrets \
  --from-env-file=/home/atanas-vitanov/Documents/KII/ARGOCD_CONFIGURATION/local-secrets/emt-dev.env
```

The backend, PostgreSQL HA chart, and database seeder Job all read from `emt-app-secrets`.

## 5. Build Helm Dependencies

```bash
cd /home/atanas-vitanov/Documents/KII/ARGOCD_CONFIGURATION
helm dependency update charts/emt-app
```

## 6. Validate the Chart

```bash
helm lint charts/emt-app

helm template emt-app charts/emt-app \
  --namespace emt-dev \
  -f charts/emt-app/values-dev.yaml
```

## 7. Install or Upgrade

The namespace is created manually in the secrets step, so `values-dev.yaml` sets `namespace.create=false`.

```bash
helm upgrade --install emt-app charts/emt-app \
  --namespace emt-dev \
  --create-namespace \
  -f charts/emt-app/values-dev.yaml
```

## 8. Verify Kubernetes Resources

```bash
kubectl get pods -n emt-dev
kubectl get svc -n emt-dev
kubectl get ingress -n emt-dev
kubectl get pvc -n emt-dev
kubectl get jobs -n emt-dev
kubectl get secret -n emt-dev
```

Check application logs:

```bash
kubectl logs deployment/emt-app-backend -n emt-dev
kubectl logs deployment/emt-app-frontend -n emt-dev
```

Check the database seeder Job:

```bash
kubectl logs job/$(kubectl get jobs -n emt-dev \
  -l app.kubernetes.io/component=db-seeder \
  -o jsonpath='{.items[0].metadata.name}') -n emt-dev
```

## 9. Test the Application

Open:

```text
http://emt.localhost:8080
```

Routing:

- `/` goes to the frontend
- `/api` goes to the backend
- PostgreSQL is internal only

Useful API check:

```bash
curl http://emt.localhost:8080/api/products/frizideri
```

## 10. Clean Up

Remove the Helm release:

```bash
helm uninstall emt-app -n emt-dev
```

Remove the whole K3D cluster:

```bash
k3d cluster delete emt-local
```
