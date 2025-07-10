variable "region" {
  description = "AWS region for deployments."
  type        = string
  default     = "us-east-1"
}

variable "aws_account_id" {
  description = "Your AWS Account ID."
  type        = string
  default     = "819313480446" # Your provided AWS Account ID
}

variable "eks_cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
  default     = "eye-care-eks-cluster" # This default value ensures it's always set
}

variable "db_username" {
  description = "Username for the RDS PostgreSQL database."
  type        = string
  default     = "eyecareuser" # CHANGE THIS FROM "admin" to a non-reserved word!
}

variable "db_password" {
  description = "Password for the RDS PostgreSQL database."
  type        = string
  sensitive   = true # Mark as sensitive to prevent outputting to logs/CLI
}