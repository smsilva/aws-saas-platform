.PHONY: init plan apply destroy

TF_DIR := examples/lab

init:
	terraform -chdir=$(TF_DIR) init -backend-config=backend.conf

plan:
	terraform -chdir=$(TF_DIR) plan

apply:
	terraform -chdir=$(TF_DIR) apply

destroy:
	terraform -chdir=$(TF_DIR) destroy
