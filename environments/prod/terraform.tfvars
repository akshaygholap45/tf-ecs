###############################################################################
# environments/prod/terraform.tfvars
###############################################################################

# General
aws_region   = "us-east-1"
project_name = "myapp"
environment  = "prod"

# Networking
vpc_cidr           = "10.1.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
public_subnets     = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
private_subnets    = ["10.1.11.0/24", "10.1.12.0/24", "10.1.13.0/24"]
enable_nat_gateway = true

# ALB
health_check_path = "/health"
certificate_arn   = "arn:aws:acm:us-east-1:123456789012:certificate/your-cert-id"

# ECR
ecr_image_retention_count = 20

# ECS / Container
image_tag      = "stable"
container_port = 8080
task_cpu       = 1024
task_memory    = 2048
desired_count  = 3
min_capacity   = 2
max_capacity   = 20

# Logging
log_retention_days = 90

# App environment variables
environment_variables = [
  { name = "APP_ENV",   value = "production" },
  { name = "LOG_LEVEL", value = "info" }
]
