locals {
  region   = "us-east-1"
  domain   = "wasp.silvios.me"
  cert_arn = "arn:aws:acm:us-east-1:221047292361:certificate/76e86c75-717f-4269-a109-bcd426a4b565"
  tags     = { project = "eks-lab", env = "lab" }

  virtual_network_subnets = [
    { cidr = "10.0.1.0/24", name = "public-1a",  availability_zone = "us-east-1a", public = true  },
    { cidr = "10.0.2.0/24", name = "public-1b",  availability_zone = "us-east-1b", public = true  },
    { cidr = "10.0.3.0/24", name = "private-1a", availability_zone = "us-east-1a", public = false },
    { cidr = "10.0.4.0/24", name = "private-1b", availability_zone = "us-east-1b", public = false },
  ]
}

module "vpc" {
  source  = "../../src/vpc"
  name    = "wasp"
  cidr    = "10.0.0.0/16"
  subnets = local.virtual_network_subnets
  tags    = local.tags
}