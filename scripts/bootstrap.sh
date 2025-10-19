#!/bin/bash

set -e

echo "=== DevOps Assignment Bootstrap Script ==="
echo "Roll Number: ITA775"

# Step 1: Terraform
echo ""
echo "Step 1: Provisioning infrastructure with Terraform..."
cd terraform
terraform init
terraform apply -auto-approve
cd ..

# Get outputs
MANAGER_IP=$(cd terraform && terraform output -raw manager_public_ip)
CONTROLLER_IP=$(cd terraform && terraform output -raw controller_public_ip)

echo "Manager IP: $MANAGER_IP"
echo "Controller IP: $CONTROLLER_IP"

# Step 2: Wait for instances to be ready
echo ""
echo "Step 2: Waiting for instances to be ready..."
sleep 30

# Step 3: Run Ansible playbooks
echo ""
echo "Step 3: Configuring servers with Ansible..."
cd ansible

# Install Docker
ansible-playbook -i inventory install-docker.yml

# Initialize Swarm
ansible-playbook -i inventory swarm-init.yml

# Deploy application
ansible-playbook -i inventory deploy-stack.yml

cd ..

# Step 4: Verify deployment
echo ""
echo "Step 4: Verifying deployment..."
ssh -i terraform/terraform-key.pem ubuntu@$MANAGER_IP "docker service ls"

echo ""
echo "=== Bootstrap Complete! ==="
echo "Application URL: http://$MANAGER_IP:8000"
echo "Jenkins URL: http://$CONTROLLER_IP:8080"