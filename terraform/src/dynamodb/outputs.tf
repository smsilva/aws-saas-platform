output "id" {
  value       = aws_dynamodb_table.default.id
  description = "Table name (same as ID)"
}

output "arn" {
  value       = aws_dynamodb_table.default.arn
  description = "Table ARN"
}

output "instance" {
  value       = aws_dynamodb_table.default
  description = "Full table resource"
}
