variable "name" {
  type = string
}

variable "cidr" {
  type = string
}

variable "subnets" {
  type = list(object({
    cidr              = string
    name              = string
    availability_zone = string
    public            = bool
  }))
}

variable "tags" {
  type    = map(string)
  default = {}
}
