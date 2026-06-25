# AWS Setup

This project targets AWS EKS and Amazon ECR.

## Required AWS Building Blocks

Prepare these first:

- one AWS account for the demo
- AWS CLI configured locally
- an IAM identity with permission to create ECR, EKS, IAM roles, and VPC-related resources
- a public DNS name if you want a real internet-facing hostname

## Recommended IAM Model

Use short-lived credentials wherever possible:

- GitHub Actions should assume an IAM role through OIDC
- EKS workloads should use IAM Roles for Service Accounts when needed
- avoid long-lived AWS access keys in GitHub

## Minimum IAM Topics to Prepare

1. GitHub OIDC provider
2. GitHub Actions role for ECR push
3. EKS cluster role
4. EKS node group role
5. IAM role for the AWS Load Balancer Controller
6. IAM role for the EBS CSI driver if your setup requires it
7. IAM access path for AWS Secrets Manager through External Secrets Operator

## Region and Naming

Keep naming consistent:

- EKS cluster: `emt-eks`
- ECR repositories: `emt-backend`, `emt-frontend`
- namespace: `emt-prod`

## Before Moving Forward

Make sure these are decided:

- AWS region
- VPC and subnets for EKS
- public host name for Ingress
- certificate strategy if you want HTTPS
- how the cluster will read secrets from AWS Secrets Manager
