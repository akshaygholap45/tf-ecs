# AWS ECS Fargate — Terraform Modular Infrastructure

A production-ready, modular Terraform setup for running containerised applications on **AWS ECS Fargate** behind an **Application Load Balancer**, with auto-scaling, ECR, VPC flow logs, and CloudWatch observability.

---

## Architecture

```
Internet
    │
    ▼
┌─────────────────────────────────────────────┐
│          Application Load Balancer           │  ← Public subnets
│     HTTP (80) → redirect → HTTPS (443)      │
└───────────────────┬─────────────────────────┘
                    │ Target Group (IP mode)
    ┌───────────────▼─────────────────┐
    │       ECS Fargate Service        │  ← Private subnets
    │   ┌──────┐ ┌──────┐ ┌──────┐   │
    │   │ Task │ │ Task │ │ Task │   │
    │   └──────┘ └──────┘ └──────┘   │
    └──────────────┬──────────────────┘
                   │
    ┌──────────────▼──────────────────┐
    │      Supporting Services         │
    │  ECR  │  CloudWatch  │  SSM     │
    └─────────────────────────────────┘
```

## Module Structure

```
terraform-ecs/
├── main.tf                    # Root orchestrator
├── variables.tf               # Root input variables
├── outputs.tf                 # Root outputs
├── Makefile                   # Convenience commands
├── modules/
│   ├── vpc/                   # VPC, subnets, IGW, NAT, flow logs
│   ├── security-groups/       # ALB and ECS security groups
│   ├── ecr/                   # ECR repository + lifecycle policy
│   ├── iam/                   # Execution role, task role, autoscaling role
│   ├── alb/                   # ALB, target group, HTTP/HTTPS listeners
│   └── ecs/                   # Cluster, task definition, service, auto-scaling
└── environments/
    ├── dev/terraform.tfvars
    └── prod/terraform.tfvars
```

## Quick Start

### 1. Prerequisites
- Terraform ≥ 1.5
- AWS CLI configured (`aws configure`)
- An ECR image pushed (or use a public image for testing)

### 2. Initialise

```bash
make init
```

### 3. Plan & Apply (dev)

```bash
make plan ENV=dev
make apply ENV=dev
```

### 4. Deploy to prod

```bash
make plan ENV=prod
make apply ENV=prod
```

## Push an Image to ECR

```bash
# Get ECR URL from Terraform output
ECR_URL=$(terraform output -raw ecr_repository_url)
AWS_REGION=us-east-1

# Authenticate
aws ecr get-login-password --region $AWS_REGION \
  | docker login --username AWS --password-stdin $ECR_URL

# Build, tag and push
docker build -t myapp .
docker tag myapp:latest $ECR_URL:latest
docker push $ECR_URL:latest
```

## Auto-scaling

Tasks scale automatically based on:

| Metric | Scale-out threshold | Scale-in cooldown |
|--------|--------------------|--------------------|
| CPU    | 70 %               | 300 s              |
| Memory | 80 %               | 300 s              |

## Security Highlights

- ECS tasks run in **private subnets** (no public IPs)
- ALB → ECS traffic only allowed on the configured `container_port`
- Task execution role scoped to ECR + Secrets Manager
- ECR images scanned on push
- VPC flow logs enabled to CloudWatch
- ALB access logs stored in S3 (90-day retention)
- **ECS Exec** enabled for live container debugging

## Remote State (recommended for teams)

Uncomment and configure the `backend "s3"` block in `main.tf`:

```hcl
backend "s3" {
  bucket         = "my-tf-state"
  key            = "ecs-infra/terraform.tfstate"
  region         = "us-east-1"
  dynamodb_table = "terraform-state-lock"
  encrypt        = true
}
```

Create the bucket and DynamoDB table once manually or via a bootstrap script.
