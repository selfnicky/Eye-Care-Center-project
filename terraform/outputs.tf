output "eks_cluster_name" {
  description = "Name of the EKS cluster."
  value       = aws_eks_cluster.eye_care_cluster.name
}

output "eks_cluster_endpoint" {
  description = "Endpoint for the EKS cluster."
  value       = aws_eks_cluster.eye_care_cluster.endpoint
}

output "eks_cluster_certificate_authority_data" {
  description = "Certificate authority data for the EKS cluster."
  value       = aws_eks_cluster.eye_care_cluster.certificate_authority.0.data
  sensitive   = true
}

output "frontend_ecr_repo_url" {
  description = "URL of the frontend ECR repository."
  value       = aws_ecr_repository.frontend_app.repository_url
}

output "backend_ecr_repo_url" {
  description = "URL of the backend ECR repository."
  value       = aws_ecr_repository.backend_app.repository_url
}

output "rds_endpoint" {
  description = "Endpoint address of the RDS instance."
  value       = aws_db_instance.eye_care_db.address
}

output "rds_port" {
  description = "Port of the RDS instance."
  value       = aws_db_instance.eye_care_db.port
}