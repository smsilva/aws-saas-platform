locals {
  callback_urls = length(var.callback_urls) > 0 ? var.callback_urls : ["https://auth.${var.domain}/callback"]
  logout_urls   = length(var.logout_urls) > 0 ? var.logout_urls : ["https://${var.tenant}.${var.domain}/logout"]

  idp_name = (
    var.idp_type == "google"    ? "Google" :
    var.idp_type == "microsoft" ? "MicrosoftAD-${title(var.tenant)}" :
    ""
  )
}

resource "aws_cognito_user_pool" "default" {
  name = "${var.name}-${var.tenant}"

  auto_verified_attributes = ["email"]
  username_attributes      = ["email"]

  schema {
    name                     = "tenant_id"
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = false
    required                 = false
    string_attribute_constraints {
      min_length = "1"
      max_length = "64"
    }
  }

  lambda_config {
    pre_token_generation = var.lambda_arn
  }

  tags = var.tags
}

resource "aws_lambda_permission" "cognito" {
  statement_id  = "CognitoPreTokenGeneration-${var.tenant}"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_arn
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = aws_cognito_user_pool.default.arn
}
