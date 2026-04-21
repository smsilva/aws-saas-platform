output "id" {
  description = "EKS cluster name (used as ID)"
  value       = module.eks.cluster_name
}

output "instance" {
  description = "Full EKS module outputs"
  value       = module.eks
  sensitive   = true
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for the EKS Kubernetes API"
  value       = module.eks.cluster_endpoint
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC Provider for IRSA"
  value       = module.eks.oidc_provider_arn
}

output "kubeconfig" {
  description = "Kubeconfig for authenticating with the cluster"
  value       = local.kubeconfig
  sensitive   = true
}
