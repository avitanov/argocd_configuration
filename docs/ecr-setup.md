# ECR Setup

The application images should be pushed to Amazon ECR from the `EMT_2025` CI workflows.

## Create Repositories

```bash
aws ecr create-repository --repository-name emt-backend
aws ecr create-repository --repository-name emt-frontend
```

## Recommended Repository Settings

- immutable image tags
- image scanning enabled
- lifecycle policy for cleanup

## Example Lifecycle Policy

Keep a limited number of old images:

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

Apply it:

```bash
aws ecr put-lifecycle-policy \
  --repository-name emt-backend \
  --lifecycle-policy-text file://policy.json
```

Repeat for `emt-frontend`.

## CI Variables in GitHub

Set these repository or environment variables in GitHub:

- `AWS_REGION`
- `AWS_ROLE_TO_ASSUME`
- `ECR_BACKEND_REPOSITORY`
- `ECR_FRONTEND_REPOSITORY`

The CI workflows in `EMT_2025` already expect those names.
