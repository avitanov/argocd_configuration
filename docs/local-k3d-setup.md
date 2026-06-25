# Local K3D Setup

Local Kubernetes testing should use Helm directly with `values-dev.yaml`.

Argo CD is not required locally.

## Create the K3D Cluster

```bash
k3d cluster create emt-local \
  --agents 2 \
  --port "8080:80@loadbalancer" \
  --port "8443:443@loadbalancer"
```

K3D/K3s commonly ships with Traefik as the Ingress controller, which matches `charts/emt-app/values-dev.yaml`.

## Build and Import Images

```bash
docker build -t emt-backend:dev /home/atanas-vitanov/Documents/KII/EMT_2025/backend
docker build -t emt-frontend:dev /home/atanas-vitanov/Documents/KII/EMT_2025/frontend

k3d image import emt-backend:dev -c emt-local
k3d image import emt-frontend:dev -c emt-local
```

## Create Secrets

Follow [local-secrets.md](./local-secrets.md) first and create:

- `/home/atanas-vitanov/Documents/KII/ARGOCD_CONFIGURATION/local-secrets/emt-dev.env`

## Install the Chart

```bash
cd /home/atanas-vitanov/Documents/KII/ARGOCD_CONFIGURATION
helm dependency update charts/emt-app

helm upgrade --install emt-app charts/emt-app \
  --namespace emt-dev \
  --create-namespace \
  -f charts/emt-app/values-dev.yaml
```

## Validate

```bash
kubectl get all -n emt-dev
kubectl get ingress -n emt-dev
kubectl get pvc -n emt-dev
kubectl get secret -n emt-dev
```

## Expected Access

With the K3D load balancer mapping above:

- frontend ingress host: `emt.localhost`
- local URL through the load balancer: `http://emt.localhost:8080`
