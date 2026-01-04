#!/bin/bash

# ========================================
# AWS ECR MySQL Project Deployment Script
# ========================================

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOCKER_IMAGE="sohampawar1030/mysql-project:latest"
REPOSITORY_NAME="mysql-project"
AWS_REGION="us-east-1"

# Print colored messages
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}$1${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
}

# Check if AWS CLI is installed
check_aws_cli() {
    print_info "Checking AWS CLI installation..."
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi
    print_success "AWS CLI found: $(aws --version)"
}

# Check if Docker is installed
check_docker() {
    print_info "Checking Docker installation..."
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install it first."
        exit 1
    fi
    print_success "Docker found: $(docker --version)"
}

# Check AWS credentials
check_aws_credentials() {
    print_info "Checking AWS credentials..."
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials are not configured. Please run 'aws configure'."
        exit 1
    fi
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    print_success "AWS credentials configured. Account ID: $ACCOUNT_ID"
}

# Prompt for AWS region
select_region() {
    echo ""
    read -p "Enter AWS Region (default: us-east-1): " input_region
    AWS_REGION=${input_region:-us-east-1}
    print_info "Using AWS Region: $AWS_REGION"
}

# Create ECR repository
create_ecr_repository() {
    print_info "Checking if ECR repository exists..."
    
    if aws ecr describe-repositories --repository-names $REPOSITORY_NAME --region $AWS_REGION &> /dev/null; then
        print_warning "Repository '$REPOSITORY_NAME' already exists. Skipping creation."
    else
        print_info "Creating ECR repository: $REPOSITORY_NAME"
        aws ecr create-repository \
            --repository-name $REPOSITORY_NAME \
            --region $AWS_REGION \
            --image-scanning-configuration scanOnPush=true \
            --encryption-configuration encryptionType=AES256
        print_success "ECR repository created successfully!"
    fi
    
    # Get repository URI
    REPOSITORY_URI=$(aws ecr describe-repositories \
        --repository-names $REPOSITORY_NAME \
        --region $AWS_REGION \
        --query 'repositories[0].repositoryUri' \
        --output text)
    
    print_success "Repository URI: $REPOSITORY_URI"
}

# Authenticate Docker to ECR
authenticate_docker() {
    print_info "Authenticating Docker to AWS ECR..."
    aws ecr get-login-password --region $AWS_REGION | \
        docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
    print_success "Docker authentication successful!"
}

# Pull Docker image
pull_docker_image() {
    print_info "Pulling Docker image: $DOCKER_IMAGE"
    docker pull $DOCKER_IMAGE
    print_success "Docker image pulled successfully!"
}

# Tag Docker image
tag_docker_image() {
    print_info "Tagging Docker image for ECR..."
    docker tag $DOCKER_IMAGE $REPOSITORY_URI:latest
    docker tag $DOCKER_IMAGE $REPOSITORY_URI:v1.0
    print_success "Docker image tagged successfully!"
}

# Push Docker image to ECR
push_docker_image() {
    print_info "Pushing Docker image to ECR..."
    docker push $REPOSITORY_URI:latest
    docker push $REPOSITORY_URI:v1.0
    print_success "Docker image pushed to ECR successfully!"
}

# Set lifecycle policy
set_lifecycle_policy() {
    print_info "Setting lifecycle policy for ECR repository..."
    
    cat > /tmp/lifecycle-policy.json <<EOF
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Keep last 10 images",
      "selection": {
        "tagStatus": "any",
        "countType": "imageCountMoreThan",
        "countNumber": 10
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
EOF
    
    aws ecr put-lifecycle-policy \
        --repository-name $REPOSITORY_NAME \
        --lifecycle-policy-text file:///tmp/lifecycle-policy.json \
        --region $AWS_REGION
    
    print_success "Lifecycle policy set successfully!"
}

# Display deployment summary
display_summary() {
    print_header "DEPLOYMENT SUMMARY"
    
    echo -e "${BLUE}Repository Name:${NC} $REPOSITORY_NAME"
    echo -e "${BLUE}Repository URI:${NC} $REPOSITORY_URI"
    echo -e "${BLUE}AWS Region:${NC} $AWS_REGION"
    echo -e "${BLUE}AWS Account ID:${NC} $ACCOUNT_ID"
    echo ""
    echo -e "${GREEN}Available Image Tags:${NC}"
    echo "  - latest"
    echo "  - v1.0"
    echo ""
    echo -e "${YELLOW}Next Steps:${NC}"
    echo "  1. Deploy to ECS, EKS, or EC2 using the repository URI"
    echo "  2. Use: docker pull $REPOSITORY_URI:latest"
    echo "  3. Configure your application to use the ECR image"
    echo ""
    print_success "Deployment completed successfully! 🎉"
}

# Verify deployment
verify_deployment() {
    print_info "Verifying deployment..."
    
    # List images in repository
    print_info "Images in ECR repository:"
    aws ecr describe-images \
        --repository-name $REPOSITORY_NAME \
        --region $AWS_REGION \
        --output table
    
    print_success "Verification complete!"
}

# Main execution
main() {
    print_header "AWS ECR MySQL Project Deployment"
    
    # Pre-flight checks
    check_aws_cli
    check_docker
    check_aws_credentials
    
    # Configuration
    select_region
    
    # Confirm deployment
    echo ""
    read -p "Proceed with deployment? (y/n): " confirm
    if [[ $confirm != [yY] ]]; then
        print_warning "Deployment cancelled by user."
        exit 0
    fi
    
    # Deployment steps
    echo ""
    create_ecr_repository
    authenticate_docker
    pull_docker_image
    tag_docker_image
    push_docker_image
    set_lifecycle_policy
    verify_deployment
    
    # Summary
    display_summary
}

# Run main function
main
