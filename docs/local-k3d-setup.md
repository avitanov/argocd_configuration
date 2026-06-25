# Local K3D Runbook

Use this document when you want to run the full stack locally on Kubernetes with K3D.

This flow uses:

- Helm directly
- `charts/emt-app/values-dev.yaml`
- a manually created Kubernetes Secret
- locally built Docker images imported into K3D

Argo CD is not required locally.

## Prerequisites

Make sure these tools are installed:

- Docker
- `kubectl`
- `helm`
- `k3d`

You also need both repositories available locally:

- `/home/atanas-vitanov/Documents/KII/EMT_2025`
- `/home/atanas-vitanov/Documents/KII/ARGOCD_CONFIGURATION`

## 1. Create the K3D Cluster

```bash
k3d cluster create emt-local \
  --agents 2 \
  --port "8080:80@loadbalancer" \
  --port "8443:443@loadbalancer"
```

K3D/K3s commonly ships with Traefik as the Ingress controller. That matches the local chart overlay in `charts/emt-app/values-dev.yaml`.

## 2. Build the Application Images

Build the frontend and backend from `EMT_2025`:

```bash
docker build -t emt-backend:dev /home/atanas-vitanov/Documents/KII/EMT_2025/backend
docker build -t emt-frontend:dev /home/atanas-vitanov/Documents/KII/EMT_2025/frontend
```

## 3. Import the Images into K3D

```bash
k3d image import emt-backend:dev -c emt-local
k3d image import emt-frontend:dev -c emt-local
```

## 4. Create the Local Secret File

Create and fill:

- `/home/atanas-vitanov/Documents/KII/ARGOCD_CONFIGURATION/local-secrets/emt-dev.env`

The template file is:

- `/home/atanas-vitanov/Documents/KII/ARGOCD_CONFIGURATION/local-secrets/emt-dev.env.example`

The full secret format is documented in [local-secrets.md](./local-secrets.md).

## 5. Create the Kubernetes Secret

```bash
kubectl create namespace emt-dev

kubectl -n emt-dev create secret generic emt-app-secrets \
  --from-env-file=/home/atanas-vitanov/Documents/KII/ARGOCD_CONFIGURATION/local-secrets/emt-dev.env
```

This is required because the local chart overlay expects:

```yaml
secrets:
  existingSecret: emt-app-secrets
```

## 6. Build Helm Dependencies

```bash
cd /home/atanas-vitanov/Documents/KII/ARGOCD_CONFIGURATION
helm dependency update charts/emt-app
```

## 7. Validate the Chart Locally

```bash
helm lint charts/emt-app
helm template emt-app charts/emt-app -f charts/emt-app/values-dev.yaml
```

## 8. Install or Upgrade the Local Release

```bash
helm upgrade --install emt-app charts/emt-app \
  --namespace emt-dev \
  --create-namespace \
  -f charts/emt-app/values-dev.yaml
```

## 9. Validate the Running Stack

```bash
kubectl get pods -n emt-dev
kubectl get svc -n emt-dev
kubectl get ingress -n emt-dev
kubectl get pvc -n emt-dev
kubectl get secret -n emt-dev
```

Useful checks:

```bash
kubectl logs deployment/emt-app-backend -n emt-dev
kubectl logs deployment/emt-app-frontend -n emt-dev
```

## 10. Access the Application

With the load balancer mapping above:

- ingress host: `emt.localhost`
- frontend URL: `http://emt.localhost:8080`

The chart routes:

- `/` to the frontend
- `/api` to the backend

## 11. Clean Up

To remove the Helm release:

```bash
helm uninstall emt-app -n emt-dev
```

To remove the whole local cluster:

```bash
k3d cluster delete emt-local
```
