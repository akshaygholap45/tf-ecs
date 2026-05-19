variable "project_name"          { type = string }
variable "environment"            { type = string }
variable "aws_region"             { type = string }
variable "vpc_id"                 { type = string }
variable "private_subnet_ids"     { type = list(string) }
variable "ecs_sg_id"              { type = string }
variable "ecr_repository_url"     { type = string }
variable "image_tag"              { type = string; default = "latest" }
variable "container_port"         { type = number }
variable "task_cpu"               { type = number }
variable "task_memory"            { type = number }
variable "desired_count"          { type = number }
variable "min_capacity"           { type = number }
variable "max_capacity"           { type = number }
variable "target_group_arn"       { type = string }
variable "execution_role_arn"     { type = string }
variable "task_role_arn"          { type = string }
variable "log_retention_days"     { type = number; default = 30 }
variable "environment_variables" {
  type = list(object({ name = string; value = string }))
  default = []
}
