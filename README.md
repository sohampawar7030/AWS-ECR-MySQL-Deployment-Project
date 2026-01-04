# 🚀 MySQL Database Deployment on AWS ECR

![AWS](https://img.shields.io/badge/AWS-ECR-FF9900?style=for-the-badge&logo=amazon-aws&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![MySQL](https://img.shields.io/badge/MySQL-4479A1?style=for-the-badge&logo=mysql&logoColor=white)

A production-ready MySQL database deployment solution using Amazon Elastic Container Registry (ECR) and Docker. This project demonstrates cloud-native database deployment with enterprise-grade security and scalability.

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Detailed Deployment Guide](#detailed-deployment-guide)
- [Configuration](#configuration)
- [Security Best Practices](#security-best-practices)
- [Monitoring & Maintenance](#monitoring--maintenance)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

## 🎯 Overview

This project provides a streamlined approach to deploy MySQL databases using AWS ECR, enabling:

- **Centralized Container Management**: Store and version control your MySQL images
- **Enhanced Security**: Private container registry with AWS IAM integration
- **Scalability**: Easy deployment across multiple AWS services (ECS, EKS, EC2)
- **Cost Efficiency**: Pay-as-you-go pricing with image lifecycle policies

## 🏗️ Architecture

```
┌─────────────────┐
│   Docker Hub    │
│  mysql-project  │
└────────┬────────┘
         │
         │ Pull & Tag
         ▼
┌─────────────────┐
│   AWS ECR       │
│  Private Repo   │
└────────┬────────┘
         │
         │ Deploy to
         ▼
┌─────────────────┐
│   AWS Services  │
│  ECS/EKS/EC2    │
└─────────────────┘
```

## ✅ Prerequisites

Before you begin, ensure you have the following installed and configured:

- **AWS Account** with appropriate permissions
- **AWS CLI** (v2.x or later)
- **Docker** (v20.x or later)
- **IAM User** with ECR permissions

### Required IAM Permissions

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload",
        "ecr:CreateRepository"
      ],
      "Resource": "*"
    }
  ]
}
```

## 🚀 Quick Start

Get up and running in 5 minutes:

```bash
# 1. Clone this repository
git clone https://github.com/sohampawar7030/aws-ecr-mysql-deployment.git
cd aws-ecr-mysql-deployment

# 2. Configure AWS credentials
aws configure

# 3. Run the deployment script
chmod +x deploy.sh
./deploy.sh
```

## 📖 Detailed Deployment Guide

### Step 1: Configure AWS CLI

```bash
aws configure
# AWS Access Key ID: YOUR_ACCESS_KEY
# AWS Secret Access Key: YOUR_SECRET_KEY
# Default region name: us-east-1
# Default output format: json
```

### Step 2: Create ECR Repository

```bash
# Create a private ECR repository
aws ecr create-repository \
    --repository-name mysql-project \
    --region us-east-1 \
    --image-scanning-configuration scanOnPush=true \
    --encryption-configuration encryptionType=AES256
```

**Expected Output:**
```json
{
    "repository": {
        "repositoryArn": "arn:aws:ecr:us-east-1:123456789012:repository/mysql-project",
        "registryId": "123456789012",
        "repositoryName": "mysql-project",
        "repositoryUri": "123456789012.dkr.ecr.us-east-1.amazonaws.com/mysql-project"
    }
}
```

### Step 3: Authenticate Docker with ECR

```bash
# Get authentication token and login
aws ecr get-login-password --region us-east-1 | \
docker login --username AWS --password-stdin \
123456789012.dkr.ecr.us-east-1.amazonaws.com
```

### Step 4: Pull, Tag, and Push Image

```bash
# Pull the MySQL image from Docker Hub
docker pull sohampawar1030/mysql-project:latest

# Tag the image for ECR
docker tag sohampawar1030/mysql-project:latest \
123456789012.dkr.ecr.us-east-1.amazonaws.com/mysql-project:latest

# Push to ECR
docker push 123456789012.dkr.ecr.us-east-1.amazonaws.com/mysql-project:latest
```

### Step 5: Verify Upload

```bash
# List images in your ECR repository
aws ecr describe-images \
    --repository-name mysql-project \
    --region us-east-1
```

## ⚙️ Configuration

### Environment Variables

Create a `.env` file for your deployment:

```env
# Database Configuration
MYSQL_ROOT_PASSWORD=your_secure_password
MYSQL_DATABASE=your_database_name
MYSQL_USER=your_username
MYSQL_PASSWORD=your_user_password

# AWS Configuration
AWS_REGION=us-east-1
ECR_REPOSITORY_URI=123456789012.dkr.ecr.us-east-1.amazonaws.com/mysql-project
```

### Docker Compose (Optional)

```yaml
version: '3.8'

services:
  mysql:
    image: 123456789012.dkr.ecr.us-east-1.amazonaws.com/mysql-project:latest
    container_name: mysql-prod
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: ${MYSQL_DATABASE}
      MYSQL_USER: ${MYSQL_USER}
      MYSQL_PASSWORD: ${MYSQL_PASSWORD}
    ports:
      - "3306:3306"
    volumes:
      - mysql_data:/var/lib/mysql
    networks:
      - mysql_network

volumes:
  mysql_data:

networks:
  mysql_network:
    driver: bridge
```

## 🔒 Security Best Practices

### 1. Enable Image Scanning

```bash
aws ecr put-image-scanning-configuration \
    --repository-name mysql-project \
    --image-scanning-configuration scanOnPush=true \
    --region us-east-1
```

### 2. Set Lifecycle Policies

Create `lifecycle-policy.json`:

```json
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
```

Apply the policy:

```bash
aws ecr put-lifecycle-policy \
    --repository-name mysql-project \
    --lifecycle-policy-text file://lifecycle-policy.json \
    --region us-east-1
```

### 3. Enable Encryption at Rest

```bash
aws ecr put-repository-encryption-configuration \
    --repository-name mysql-project \
    --encryption-configuration encryptionType=AES256 \
    --region us-east-1
```

### 4. Set Repository Policies

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowPullFromECS",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": [
        "ecr:BatchGetImage",
        "ecr:GetDownloadUrlForLayer"
      ]
    }
  ]
}
```

## 📊 Monitoring & Maintenance

### CloudWatch Metrics

Monitor your ECR repository:

```bash
aws cloudwatch get-metric-statistics \
    --namespace AWS/ECR \
    --metric-name RepositoryPullCount \
    --dimensions Name=RepositoryName,Value=mysql-project \
    --start-time 2024-01-01T00:00:00Z \
    --end-time 2024-01-31T23:59:59Z \
    --period 3600 \
    --statistics Sum \
    --region us-east-1
```

### Image Vulnerability Scanning

```bash
# Get scan results
aws ecr describe-image-scan-findings \
    --repository-name mysql-project \
    --image-id imageTag=latest \
    --region us-east-1
```

## 🛠️ Troubleshooting

### Common Issues

#### Authentication Failed

```bash
# Solution: Refresh ECR login
aws ecr get-login-password --region us-east-1 | \
docker login --username AWS --password-stdin \
123456789012.dkr.ecr.us-east-1.amazonaws.com
```

#### Permission Denied

```bash
# Solution: Check IAM policies
aws iam get-user-policy --user-name your-username --policy-name ECRPolicy
```

#### Image Push Failed

```bash
# Solution: Verify repository exists
aws ecr describe-repositories --repository-names mysql-project --region us-east-1
```

### Logs and Debugging

```bash
# Check Docker logs
docker logs mysql-prod

# View ECR repository details
aws ecr describe-repositories --region us-east-1
```

## 📚 Additional Resources

- [AWS ECR Documentation](https://docs.aws.amazon.com/ecr/)
- [Docker Documentation](https://docs.docker.com/)
- [MySQL Docker Hub](https://hub.docker.com/_/mysql)
- [AWS CLI Reference](https://docs.aws.amazon.com/cli/latest/reference/ecr/)

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👤 Author

**Soham Pawar**

- Docker Hub: [@sohampawar1030](https://hub.docker.com/u/sohampawar1030)
- GitHub: [@sohampawar1030](https://github.com/sohampawar7030)

## 🌟 Acknowledgments

- AWS for providing robust container registry services
- Docker community for excellent documentation
- MySQL team for the reliable database system

---

**Built with ❤️ using AWS ECR and Docker**

*Last Updated: January 2026*
