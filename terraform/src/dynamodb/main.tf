resource "aws_dynamodb_table" "default" {
  name           = var.table_name
  billing_mode   = "PROVISIONED"
  read_capacity  = var.read_capacity
  write_capacity = var.write_capacity
  hash_key       = var.hash_key

  dynamic "attribute" {
    for_each = var.attributes
    content {
      name = attribute.value.name
      type = attribute.value.type
    }
  }

  dynamic "global_secondary_index" {
    for_each = var.global_secondary_indexes
    content {
      name            = global_secondary_index.value.name
      projection_type = global_secondary_index.value.projection_type
      read_capacity   = global_secondary_index.value.read_capacity
      write_capacity  = global_secondary_index.value.write_capacity

      key_schema {
        attribute_name = global_secondary_index.value.hash_key
        key_type       = "HASH"
      }
    }
  }

  tags = var.tags
}

resource "aws_dynamodb_table_item" "seed" {
  for_each = { for item in var.seed_items : item.hash_key_value => item }

  table_name = aws_dynamodb_table.default.name
  hash_key   = var.hash_key
  item       = each.value.item
}
