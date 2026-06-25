# University Demo Checklist

Use this checklist before the demo.

## Source Control

- [ ] `EMT_2025` is in a public Git repository
- [ ] `ARGOCD_CONFIGURATION` is in a public Git repository or otherwise accessible for review

## Docker and Local Run

- [ ] backend Dockerfile exists
- [ ] frontend Dockerfile exists
- [ ] `docker compose up --build` works locally
- [ ] PostgreSQL is internal to the Docker network

## CI

- [ ] backend CI workflow passes
- [ ] frontend CI workflow passes
- [ ] integration CI workflow passes
- [ ] images are pushed to Amazon ECR

## Kubernetes and GitOps

- [ ] Helm chart exists in `charts/emt-app`
- [ ] frontend Deployment exists
- [ ] backend Deployment exists
- [ ] frontend Service exists
- [ ] backend Service exists
- [ ] Ingress exists
- [ ] separate namespace is used
- [ ] PostgreSQL HA is configured through the Bitnami Helm dependency
- [ ] Argo CD project is applied
- [ ] Argo CD application is applied
- [ ] Argo CD sync works

## AWS

- [ ] EKS cluster is running
- [ ] EBS CSI driver is installed
- [ ] AWS Load Balancer Controller is installed
- [ ] ECR repositories exist

## Final Verification

- [ ] frontend is reachable through Ingress
- [ ] backend answers through `/api`
- [ ] database is healthy
- [ ] image tags in `environments/prod/values.yaml` match the latest deployed build
