modules = $(shell find . -type f -name "*.tf" -exec dirname {} \;|sort -u)

.PHONY: test

default: test fmt plan

test:
	terraform validate -var-file=variables.example.tfvars

fmt:
	@if [ `terraform fmt | wc -c` -ne 0 ]; then echo "terraform files need be formatted"; exit 1; fi

plan:
	terraform plan -var-file=variables.example.tfvars ./

