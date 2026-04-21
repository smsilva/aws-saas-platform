output "lambda_arn" {
  value       = aws_lambda_function.default.arn
  description = "ARN of the pre-token generation Lambda; pass to each userpool module"
}
