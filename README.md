# AWS ECS Fargate — Terraform (Study Project)

Modular Terraform setup for AWS ECS Fargate with ALB, ECR, VPC, IAM, and auto-scaling.
Triggered entirely via **GitHub Actions workflow_dispatch** — no CI/CD on push or PRs.

---

## Project Structure

```
.
├── main.tf                    # Root — wires all modules together
├── variables.tf               # All input variables
├── outputs.tf                 # Key outputs (ALB DNS, ECR URL, etc.)
├── terraform.tfvars           # Your config values — edit this
├── .gitignore
├── .github/
│   └── workflows/
│       └── terraform.yml      # workflow_dispatch: plan | apply | destroy
└── modules/
    ├── vpc/                   # VPC, subnets, IGW, NAT, flow logs
    ├── security-groups/       # ALB and ECS security groups
    ├── ecr/                   # ECR repo + lifecycle policy
    ├── iam/                   # Execution role + task role
    ├── alb/                   # ALB, target group, listeners
    └── ecs/                   # Cluster, task def, service, auto-scaling
```

---

## One-time AWS Setup

### 1. Create IAM user for GitHub Actions

```bash
aws iam create-user --user-name terraform-github
aws iam attach-user-policy \
  --user-name terraform-github \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
aws iam create-access-key --user-name terraform-github
# Copy the AccessKeyId and SecretAccessKey
```

### 2. Create S3 bucket for Terraform state

```bash
aws s3api create-bucket \
  --bucket myapp-tf-state \
  --region us-east-1

aws s3api put-bucket-versioning \
  --bucket myapp-tf-state \
  --versioning-configuration Status=Enabled

aws s3api put-bucket-encryption \
  --bucket myapp-tf-state \
  --server-side-encryption-configuration \
  '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
```

### 3. Create DynamoDB table for state locking

```bash
aws dynamodb create-table \
  --table-name myapp-tf-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

---

## GitHub Secrets Setup

Go to your repo → **Settings → Secrets and variables → Actions** and add:

| Secret | Value |
|---|---|
| `AWS_ACCESS_KEY_ID` | From IAM user creation |
| `AWS_SECRET_ACCESS_KEY` | From IAM user creation |
| `TF_STATE_BUCKET` | `myapp-tf-state` |
| `TF_STATE_LOCK_TABLE` | `myapp-tf-state-lock` |

---

## Running the Workflow

Go to **Actions → Terraform → Run workflow** and pick an action:

| Action | What it does |
|---|---|
| `plan` | Shows what Terraform will create/change/destroy |
| `apply` | Provisions the infrastructure |
| `destroy` | Tears everything down |

Always run **plan** first to review, then **apply**.

---

## After Apply — Push an Image

```bash
# Get ECR URL from workflow output
ECR_URL=<your-ecr-url-from-outputs>
AWS_REGION=us-east-1

# Login to ECR
aws ecr get-login-password --region $AWS_REGION \
  | docker login --username AWS --password-stdin $ECR_URL

# Build and push
docker build -t myapp .
docker tag myapp:latest $ECR_URL:latest
docker push $ECR_URL:latest
```

---

## Estimated Cost (us-east-1)

| Resource | ~Monthly cost |
|---|---|
| NAT Gateway (2) | ~$70 |
| ALB | ~$18 |
| ECS Fargate (1 task, 256CPU/512MB) | ~$10 |
| ECR, CloudWatch, S3, DynamoDB | ~$2 |

> Tip: Run **destroy** when not studying to avoid NAT Gateway charges.
