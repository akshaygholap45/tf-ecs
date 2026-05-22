###############################################################################
# terraform.tfvars
###############################################################################

project_name = "tracklet"
aws_region   = "us-east-1"

# Networking
vpc_cidr           = "10.0.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b"]
public_subnets     = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnets    = ["10.0.11.0/24", "10.0.12.0/24"]

# ALB
health_check_path = "/health"
certificate_arn   = ""   # Add ACM ARN here to enable HTTPS

# ECR
ecr_image_retention_count = 10

# ECS
image_tag      = "latest"
container_port = 8080
task_cpu       = 256
task_memory    = 512
desired_count  = 1
min_capacity   = 1
max_capacity   = 4

# Logging
log_retention_days = 30

# App environment variables
environment_variables = [
  { name = "APP_ENV",   value = "dev" },
  { name = "LOG_LEVEL", value = "info" }
]
