.PHONY: create-cluster delete-cluster tf-clean

plan-cluster: ## Plan the cluster
	@echo "Plan eks cluster..."
	cd examples && terraform init && terraform plan

apply-cluster: ## create the cluster
	@echo "Creating eks cluster..."
	cd examples && terraform init && terraform apply

destroy-cluster: ## Destroy the cluster
	@echo "Destroy kind cluster..."
	cd examples && terraform destroy -auto-approve

output-cluster: ## Destroy the cluster
	@echo "Destroy kind cluster..."
	cd examples && terraform output

update-kubeconfig: ## get kubconfig for the cluster
	@echo "get kubconfig for the cluster..."
	cd examples && terraform output -json | jq -r '."pyxis-workload-cluster-01".value.result.cluster.cluster_name' > output.json
	source .env && aws eks update-kubeconfig --name $(shell cat examples/output.json)
	rm examples/output.json

tf-clean: ## Clean up terraform files
	@echo "Cleaning up terraform files..."
	cd examples && rm -rf .terraform terraform.tfstate terraform.tfstate.backup .terraform.lock.hcl

deploy-application: ## deploy application
	@echo "deploying application ..."
	cd k8s-application && terraform init && terraform apply -auto-approve

plan: ## plan application
	@echo "plan application ..."
	cd k8s-application && terraform plan

apply: ## apply application
	@echo "apply application ..."
	cd k8s-application && terraform apply -auto-approve


format:
	find modules -mindepth 1 -maxdepth 1 -type d -exec sh -c 'cd "{}" && terraform fmt .' \;
	terraform fmt .

tf-doc:
	find modules -mindepth 1 -maxdepth 1 -type d -exec sh -c 'cd "{}" && terraform-docs markdown table --output-file README.md --output-mode inject .' \;
	terraform-docs markdown table --output-file README.md --output-mode inject .


clean:
	rm -rf .terraform
	rm -rf terraform.tfstate*
	rm -rf .terraform.lock.hcl

check-encrypted:
	bash scripts/sops-utils.sh checkFilesEncryptedAll deployments

encrypt:
	bash scripts/sops-utils.sh encryptAll .

decrypt:
	bash scripts/sops-utils.sh decryptAll .

decryptFile:
	bash scripts/sops-utils.sh decryptFile $(file)

encryptFile:
	bash scripts/sops-utils.sh encryptFile $(file)

updateSopsKeys:
	bash scripts/sops-utils.sh updateSopsConfig

createAgeKey:
	age-keygen -o age-key.txt

encryptArgoValues:
	bash scripts/sops-utils.sh encryptFile argocd/environments/dev/vvc-portal/values.yaml
