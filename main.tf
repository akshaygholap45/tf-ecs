###############################################################################
# main.tf
###############################################################################

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "tracklet-tf-state"        # set via -backend-config in workflow
    key            = "ecs-infra/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tracklet-tf-state-table"   # set via -backend-config in workflow
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = var.project_name
      ManagedBy = "Terraform"
    }
  }
}

###############################################################################
# Modules
###############################################################################

module "vpc" {
  source = "./modules/vpc"

  project_name       = var.project_name
  aws_region         = var.aws_region
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  public_subnets     = var.public_subnets
  private_subnets    = var.private_subnets
}

module "security_groups" {
  source = "./modules/security-groups"

  project_name   = var.project_name
  vpc_id         = module.vpc.vpc_id
  container_port = var.container_port
}

module "ecr" {
  source = "./modules/ecr"

  project_name          = var.project_name
  image_retention_count = var.ecr_image_retention_count
}

module "iam" {
  source = "./modules/iam"

  project_name = var.project_name
}

module "alb" {
  source = "./modules/alb"

  project_name      = var.project_name
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  alb_sg_id         = module.security_groups.alb_sg_id
  container_port    = var.container_port
  health_check_path = var.health_check_path
  certificate_arn   = var.certificate_arn
}

module "ecs" {
  source = "./modules/ecs"

  project_name          = var.project_name
  aws_region            = var.aws_region
  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnet_ids
  ecs_sg_id             = module.security_groups.ecs_sg_id
  ecr_repository_url    = module.ecr.repository_url
  image_tag             = var.image_tag
  container_port        = var.container_port
  task_cpu              = var.task_cpu
  task_memory           = var.task_memory
  desired_count         = var.desired_count
  min_capacity          = var.min_capacity
  max_capacity          = var.max_capacity
  target_group_arn      = module.alb.target_group_arn
  execution_role_arn    = module.iam.ecs_execution_role_arn
  task_role_arn         = module.iam.ecs_task_role_arn
  environment_variables = var.environment_variables
  log_retention_days    = var.log_retention_days
}
