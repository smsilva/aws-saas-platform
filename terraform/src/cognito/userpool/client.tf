resource "aws_cognito_user_pool_client" "default" {
  name         = var.tenant
  user_pool_id = aws_cognito_user_pool.default.id

  generate_secret                      = true
  supported_identity_providers         = local.idp_name != "" ? [local.idp_name] : ["COGNITO"]
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["openid", "email", "profile"]
  allowed_oauth_flows_user_pool_client = true
  callback_urls                        = local.callback_urls
  logout_urls                          = local.logout_urls

  depends_on = [
    aws_cognito_identity_provider.google,
    aws_cognito_identity_provider.microsoft,
  ]
}
