output "user_pool_id" {
  value       = aws_cognito_user_pool.default.id
  description = "Cognito User Pool ID"
}

output "user_pool_arn" {
  value       = aws_cognito_user_pool.default.arn
  description = "Cognito User Pool ARN"
}

output "app_client_id" {
  value       = aws_cognito_user_pool_client.default.id
  description = "App Client ID for this tenant"
}

output "instance" {
  value       = aws_cognito_user_pool.default
  sensitive   = true
  description = "Full User Pool resource"
}
