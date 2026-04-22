variable "table_name" {
  type        = string
  description = "DynamoDB table name"
}

variable "hash_key" {
  type        = string
  description = "Partition key attribute name"
}

variable "attributes" {
  type = list(object({
    name = string
    type = string
  }))
  description = "Attribute definitions (name + type: S, N, or B)"
}

variable "global_secondary_indexes" {
  type = list(object({
    name            = string
    hash_key        = string
    projection_type = optional(string, "ALL")
    read_capacity   = optional(number, 5)
    write_capacity  = optional(number, 5)
  }))
  default     = []
  description = "GSI list — empty means no secondary index"
}

variable "read_capacity" {
  type        = number
  default     = 5
  description = "Provisioned read capacity units"
}

variable "write_capacity" {
  type        = number
  default     = 5
  description = "Provisioned write capacity units"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to the table"
}

variable "seed_items" {
  type = list(object({
    hash_key_value = string
    item           = string
  }))
  default     = []
  description = "Initial items to seed into the table (DynamoDB JSON format)"
}
