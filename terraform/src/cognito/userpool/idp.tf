resource "aws_cognito_identity_provider" "google" {
  count         = var.idp_type == "google" ? 1 : 0
  user_pool_id  = aws_cognito_user_pool.default.id
  provider_name = local.idp_name
  provider_type = "Google"

  provider_details = {
    client_id        = var.idp_client_id
    client_secret    = var.idp_client_secret
    authorize_scopes = "openid email profile"
  }

  attribute_mapping = {
    email = "email"
    name  = "name"
  }
}

resource "aws_cognito_identity_provider" "microsoft" {
  count         = var.idp_type == "microsoft" ? 1 : 0
  user_pool_id  = aws_cognito_user_pool.default.id
  provider_name = local.idp_name
  provider_type = "OIDC"

  provider_details = {
    client_id                 = var.idp_client_id
    client_secret             = var.idp_client_secret
    authorize_scopes          = "openid email profile"
    oidc_issuer               = var.idp_oidc_issuer
    attributes_request_method = "GET"
  }

  attribute_mapping = {
    email = "email"
    name  = "name"
  }
}
