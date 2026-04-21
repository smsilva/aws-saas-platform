variable "name" {
  type = string
}

variable "alb_arn" {
  type    = string
  default = ""
}

variable "tags" {
  type    = map(string)
  default = {}
}
