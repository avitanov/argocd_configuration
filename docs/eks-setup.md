# EKS Setup

Do not create EKS before the application images, CI workflows, and Helm chart are ready.

## Cluster Checklist

Create:

- one EKS cluster
- at least one managed node group
- private subnets for worker nodes
- public subnets for the ALB if you expose the app publicly

## Required Add-ons

Install these before the first application sync:

1. Amazon EBS CSI driver
2. AWS Load Balancer Controller
3. metrics-server
4. Argo CD

## Storage

The chart uses Bitnami PostgreSQL HA with persistent volumes.

Recommended production storage:

- StorageClass: `gp3`
- dynamic provisioning through the EBS CSI driver

## Networking

Recommended routing model:

- `/` -> frontend service
- `/api` -> backend service

The database must stay internal.

## Validation Before Argo CD

Check:

- worker nodes are Ready
- ALB controller pods are healthy
- EBS CSI driver is healthy
- your IngressClass strategy is clear

For this repository, the production values default to `alb` as the ingress class.
