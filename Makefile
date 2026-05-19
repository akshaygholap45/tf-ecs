###############################################################################
# Makefile — Common Terraform operations
###############################################################################

ENV ?= dev
TFVARS = environments/$(ENV)/terraform.tfvars

.PHONY: init plan apply destroy fmt validate clean

init:
	terraform init -upgrade

plan:
	terraform plan -var-file=$(TFVARS) -out=tfplan

apply:
	terraform apply tfplan

apply-auto:
	terraform apply -var-file=$(TFVARS) -auto-approve

destroy:
	terraform destroy -var-file=$(TFVARS)

fmt:
	terraform fmt -recursive

validate:
	terraform validate

clean:
	rm -f tfplan
	rm -rf .terraform.lock.hcl

# Usage examples:
#   make init
#   make plan ENV=dev
#   make apply ENV=dev
#   make plan ENV=prod
#   make apply ENV=prod

