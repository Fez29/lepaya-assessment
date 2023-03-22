SHELL := /bin/bash

.PHONY: create-resources

All:
	create-resources
	prepare-lambda

create-resources:
	AWS_PAGER="" aws s3api create-bucket --bucket my-lepaya-demo-bucket --region eu-central-1 --create-bucket-configuration LocationConstraint=eu-central-1
	AWS_PAGER="" aws dynamodb create-table --table-name my-lepaya-demo-terraform-state-lock --attribute-definitions AttributeName=LockID,AttributeType=S --key-schema AttributeName=LockID,KeyType=HASH --billing-mode PAY_PER_REQUEST

install_python_pip:
	@echo "Installing Python 3..."
	sudo apt-get update
	sudo apt-get install -y python3
	@echo "Installing pip..."
	sudo apt-get install -y python3-pip

prepare-lambda:
	cd src && mkdir -p ./modules/python3 && pip3.9 install -r requirements.txt -t ./modules/python3 && zip -r9 lambda_function.zip .

# install-terra-linux:
# # Install Terraform
# 	TERRAFORM_VERSION=$$(curl -s https://api.github.com/repos/hashicorp/terraform/releases/latest | grep tag_name | cut -d '"' -f 4) && \
# 	wget https://releases.hashicorp.com/terraform/$$TERRAFORM_VERSION/terraform_$$TERRAFORM_VERSION\_linux_amd64.zip && \
# 	unzip terraform_$$TERRAFORM_VERSION\_linux_amd64.zip && \
# 	sudo mv terraform /usr/local/bin/ && \
# 	rm terraform_$$TERRAFORM_VERSION\_linux_amd64.zip

# 	# Install Terragrunt
# 	TERRAGRUNT_VERSION=$$(curl -s https://api.github.com/repos/gruntwork-io/terragrunt/releases/latest | grep tag_name | cut -d '"' -f 4 | sed 's/v//') && \
# 	wget https://github.com/gruntwork-io/terragrunt/releases/download/v$$TERRAGRUNT_VERSION/terragrunt_linux_amd64 && \
# 	sudo mv terragrunt_linux_amd64 /usr/local/bin/terragrunt && \
# 	sudo chmod +x /usr/local/bin/terragrunt
