SHELL := /bin/bash

.PHONY: create-resources install_python_pip prepare_lambda terragrunt_apply_staging terragrunt_apply_production

create_resources:
	AWS_PAGER="" aws s3api create-bucket --bucket my-lepaya-demo-bucket --region eu-central-1 --create-bucket-configuration LocationConstraint=eu-central-1
	AWS_PAGER="" aws dynamodb create-table --table-name terraform-locks --attribute-definitions AttributeName=LockID,AttributeType=S --key-schema AttributeName=LockID,KeyType=HASH --billing-mode PAY_PER_REQUEST

install_python_pip:
	@echo "Installing Python 3..."
	sudo apt-get update
	sudo apt-get install -y python3
	@echo "Installing pip..."
	sudo apt-get install -y python3-pip

prepare_lambda:
	cd src && mkdir -p ./modules/python3 && pip3.9 install -r requirements.txt -t ./modules/python3 && zip -r9 lambda_function.zip .

terragrunt_apply_staging:
	cd ./deployment/staging && terragrunt init && terragrunt apply

terragrunt_apply_production:
	cd ./deployment/staging && terragrunt init && terragrunt apply

