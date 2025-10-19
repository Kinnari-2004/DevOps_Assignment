#!/bin/bash

# Bootstrap script for DevOps Assignment
# This script automates the entire deployment process

set -e  # Exit on error

echo "=========================================="
echo "DevOps Assignment Bootstrap Script"
echo "=========================================="

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

# Check if required tools are installed
check_requirements() {
    print_info "Checking requirements..."
    
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install Terraform first."
        exit 1
    fi
    
    if ! command -v ansible &> /dev/null; then
        print_error "Ansible is not installed. Please install Ansible first."
        exit 1
    fi
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    print_success "All required tools are installed"
}

# Step 1: Terraform - Create infrastructure
run_terraform() {
    print_info "Step 1: Creating AWS infrastructure with Terraform..."
    
    cd terraform
    
    # Check if terraform.tfvars exists
    if [ ! -f "terraform.tfvars" ]; then
        print_error "terraform.tfvars not found. Please create it from terraform.tfvars.example"
        exit 1
    fi
    
    # Initialize Terraform
    print_info "Initializing Terraform..."
    terraform init
    
    # Plan
    print_info "Planning infrastructure..."
    terraform plan
    
    # Apply
    print_info "Creating infrastructure..."
    terraform apply -auto-approve
    
    # Get outputs
    print_success "Infrastructure created successfully"
    
    # Save outputs to file
    terraform output -json > ../outputs.json
    
    MANAGER_IP=$(terraform output -raw manager_public_ip)
    WORKER_A_IP=$(terraform output -raw worker_a_public_ip)
    WORKER_B_IP=$(terraform output -raw worker_b_public_ip)
    CONTROLLER_IP=$(terraform output -raw controller_public_ip)
    
    print_info "Manager IP: $MANAGER_IP"
    print_info "Worker A IP: $WORKER_A_IP"
    print_info "Worker B IP: $WORKER_B_IP"
    print_info "Controller IP: $CONTROLLER_IP"
    
    # Update inventory file
    cd ../ansible
    cp inventory inventory.backup
    sed -i "s/MANAGER_IP/$MANAGER_IP/" inventory
    sed -i "s/WORKER_A_IP/$WORKER_A_IP/" inventory
    sed -i "s/WORKER_B_IP/$WORKER_B_IP/" inventory
    
    cd ..
    
    print_success "Terraform completed"
}

# Step 2: Wait for instances to be ready
wait_for_instances() {
    print_info "Step 2: Waiting for instances to be ready..."
    
    sleep 30  # Wait for instances to fully boot
    
    print_success "Instances should be ready"
}

# Step 3: Ansible - Install Docker
install_docker() {
    print_info "Step 3: Installing Docker on all nodes..."
    
    cd ansible
    
    export ANSIBLE_HOST_KEY_CHECKING=False
    
    ansible-playbook -i inventory install-docker.yml
    
    cd ..
    
    print_success "Docker installed on all nodes"
}

# Step 4: Ansible - Initialize Swarm
init_swarm() {
    print_info "Step 4: Initializing Docker Swarm..."
    
    cd ansible
    
    ansible-playbook -i inventory swarm-init.yml
    
    cd ..
    
    print_success "Docker Swarm initialized"
}

# Step 5: Build Docker image
build_docker_image() {
    print_info "Step 5: Building Docker image..."
    
    cd docker
    
    docker build -f Dockerfile.web -t devops_web:latest ../
    
    cd ..
    
    print_success "Docker image built"
}

# Step 6: Deploy stack
deploy_stack() {
    print_info "Step 6: Deploying application stack..."
    
    cd ansible
    
    ansible-playbook -i inventory deploy-stack.yml -e "DOCKER_IMAGE=devops_web:latest"
    
    cd ..
    
    print_success "Application deployed to Swarm"
}

# Step 7: Display access information
display_info() {
    print_info "Step 7: Deployment Summary"
    
    echo ""
    echo "=========================================="
    echo "Deployment Complete!"
    echo "=========================================="
    echo ""
    
    MANAGER_IP=$(cd terraform && terraform output -raw manager_public_ip)
    
    echo "Access your application at:"
    echo "http://$MANAGER_IP:8000"
    echo ""
    echo "To test:"
    echo "1. Register a new user (e.g., ITA700 / 2022PE0000)"
    echo "2. Login with the registered credentials"
    echo "3. You should see: Hello ITA700 How are you"
    echo ""
    echo "SSH Access:"
    echo "ssh -i terraform/terraform-key.pem ubuntu@$MANAGER_IP"
    echo ""
    echo "To check services:"
    echo "ssh -i terraform/terraform-key.pem ubuntu@$MANAGER_IP 'docker service ls'"
    echo ""
}

# Main execution
main() {
    check_requirements
    
    echo ""
    read -p "This will create AWS infrastructure. Continue? (y/n) " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Aborted by user"
        exit 0
    fi
    
    run_terraform
    wait_for_instances
    install_docker
    init_swarm
    build_docker_image
    deploy_stack
    display_info
    
    print_success "Bootstrap completed successfully!"
}

# Run main function
main