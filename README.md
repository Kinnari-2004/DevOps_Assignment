# DevOps Assignment - ITA775

## Infrastructure
- **Controller**: 44.193.223.96
- **Manager**: 34.230.229.232  
- **Worker A**: 13.218.252.195
- **Worker B**: 50.19.133.201

## Quick Start

### Bootstrap Everything:
```bash
chmod +x scripts/bootstrap.sh
./scripts/bootstrap.sh
```

### Access Points:
- **Application**: http://34.230.229.232:8000
- **Jenkins**: http://44.193.223.96:8080

## Manual Deployment

### 1. Terraform:
```bash
cd terraform
terraform init
terraform apply
```

### 2. Ansible:
```bash
cd ansible
ansible-playbook -i inventory install-docker.yml
ansible-playbook -i inventory swarm-init.yml
ansible-playbook -i inventory deploy-stack.yml
```

## CI/CD Pipeline
Jenkins automatically builds and deploys on every push to ITA775 branch.