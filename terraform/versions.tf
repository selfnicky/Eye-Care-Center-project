terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # Use a compatible AWS provider version
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0" # For managing K8s resources via Terraform (optional for this project, kubectl is fine)
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0" # For deploying Helm charts (optional)
    }
  }
  required_version = "~> 1.0"
}

provider "aws" {
  region = "us-east-1"
  # If using AWS CLI profiles, you can specify:
  # profile = "your-aws-cli-profile-name"
}