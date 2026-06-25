# Ingress Setup

This repository uses different Ingress settings per environment.

## Local K3D

Local testing uses Traefik through:

- `charts/emt-app/values-dev.yaml`

Current local settings:

```yaml
ingress:
  enabled: true
  className: traefik
  host: emt.localhost
```

Recommended K3D cluster creation:

```bash
k3d cluster create emt-local \
  --agents 2 \
  --port "8080:80@loadbalancer" \
  --port "8443:443@loadbalancer"
```

## AWS EKS

Production/demo uses AWS Load Balancer Controller through:

- `charts/emt-app/values-prod.yaml`

Current ALB-oriented settings include:

- `alb.ingress.kubernetes.io/scheme: internet-facing`
- `alb.ingress.kubernetes.io/target-type: ip`
- `alb.ingress.kubernetes.io/listen-ports: '[{"HTTP":80}]'`

## Routing

The chart routes:

- `/` to the frontend service
- `/api` to the backend service

PostgreSQL is never exposed through Ingress.
