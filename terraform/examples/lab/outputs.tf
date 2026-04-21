output "vpc_id" {
  value = module.vpc.id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}

output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "oidc_provider_arn" {
  value = module.eks.oidc_provider_arn
}

output "dynamodb_table_id" {
  value = module.dynamodb.id
}

output "dynamodb_table_arn" {
  value = module.dynamodb.arn
}

output "cognito_lambda_arn" {
  value = module.cognito.lambda_arn
}

output "customer1_user_pool_id" {
  value = module.userpool_customer1.user_pool_id
}

output "customer1_app_client_id" {
  value = module.userpool_customer1.app_client_id
}

output "waf_arn" {
  value = module.waf.arn
}

output "waf_id" {
  value = module.waf.id
}
