variable "name" {
  description = "Name prefix for all resources"
  type        = string
}

variable "dynamodb_table_name" {
  description = "DynamoDB table name passed to the Lambda as DYNAMODB_TABLE"
  type        = string
}

variable "dynamodb_table_arn" {
  description = "DynamoDB table ARN used to build IAM policy for the client-id-index GSI"
  type        = string
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
