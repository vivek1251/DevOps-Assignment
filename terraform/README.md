# Terraform — Infrastructure as Code

This directory contains Terraform configuration to provision the entire AWS infrastructure automatically.

## What it creates
- EC2 instance (t3.micro, Ubuntu 24.04)
- Security group with ports 22, 80, 443, 3000, 9090, 8080
- User data script to auto-install Docker and deploy the app on launch

## Usage

### Prerequisites
- Terraform installed
- AWS CLI configured with credentials

### Deploy
```bash
terraform init
terraform plan
terraform apply
```

### Destroy
```bash
terraform destroy
```
