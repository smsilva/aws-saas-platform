variable "tenant" {
  description = "Tenant name (e.g. customer1); used to name resources and derive default URLs"
  type        = string
}

variable "name" {
  description = "Platform name prefix shared across all tenants (e.g. wasp)"
  type        = string
}

variable "domain" {
  description = "Base domain used to derive callback and logout URLs"
  type        = string
  default     = "wasp.silvios.me"
}

variable "lambda_arn" {
  description = "ARN of the shared pre-token generation Lambda (output of module.cognito)"
  type        = string
}

variable "idp_type" {
  description = "Identity provider type: 'google', 'microsoft', or '' to skip IdP creation"
  type        = string
  default     = ""

  validation {
    condition     = contains(["google", "microsoft", ""], var.idp_type)
    error_message = "idp_type must be 'google', 'microsoft', or ''."
  }
}

variable "idp_client_id" {
  description = "OAuth client ID for the IdP"
  type        = string
  sensitive   = true
  default     = ""
}

variable "idp_client_secret" {
  description = "OAuth client secret for the IdP"
  type        = string
  sensitive   = true
  default     = ""
}

variable "idp_oidc_issuer" {
  description = "OIDC issuer URL (Microsoft only); defaults to the personal accounts tenant"
  type        = string
  default     = "https://login.microsoftonline.com/9188040d-6c67-4c5b-b112-36a304b66dad/v2.0"
}

variable "callback_urls" {
  description = "OAuth callback URLs; defaults to https://auth.<domain>/callback"
  type        = list(string)
  default     = []
}

variable "logout_urls" {
  description = "Logout URLs; defaults to https://<tenant>.<domain>/logout"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
