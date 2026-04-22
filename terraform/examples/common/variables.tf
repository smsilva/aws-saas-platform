variable "region" {
  type    = string
  default = "us-east-1"
}

variable "domain" {
  type    = string
  default = "wasp.silvios.me"
}

variable "cert_arn" {
  type    = string
  default = "arn:aws:acm:us-east-1:221047292361:certificate/76e86c75-717f-4269-a109-bcd426a4b565"
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "google_client_id" {
  type      = string
  sensitive = false
}

variable "google_client_secret" {
  type      = string
  sensitive = true
}
