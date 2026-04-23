locals {
  name     = "wasp"
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
  name    = local.name
  cidr    = "10.0.0.0/16"
  subnets = local.virtual_network_subnets
  tags    = local.tags
}

module "eks" {
  source = "../../src/eks"

  name               = local.name
  cluster_version    = "1.34"
  vpc_id             = module.vpc.id
  subnet_ids         = module.vpc.private_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids
  node_min_count     = 1
  node_max_count     = 5
  tags               = local.tags

  access_entries = {
    sso_admin = {
      principal_arn = "arn:aws:iam::221047292361:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_AdministratorAccess_f7ded39be32ff185"
      policy_associations = {
        admin = {
          policy_arn   = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = { type = "cluster" }
        }
      }
    }
  }
}

module "dynamodb" {
  source = "../../src/dynamodb"

  table_name = "tenant-registry"
  hash_key   = "pk"

  attributes = [
    { name = "pk",                    type = "S" },
    { name = "cognito_app_client_id", type = "S" },
  ]

  global_secondary_indexes = [
    {
      name     = "client-id-index"
      hash_key = "cognito_app_client_id"
    },
  ]

  seed_items = [
    {
      hash_key_value = "domain#gmail.com"
      item = jsonencode({
        pk                    = { S = "domain#gmail.com" }
        tenant_id             = { S = "customer1" }
        domain                = { S = "gmail.com" }
        cognito_app_client_id = { S = module.cognito_userpool_customer1.app_client_id }
        auth = {
          M = {
            cognito_user_pool_id  = { S = module.cognito_userpool_customer1.user_pool_id }
            cognito_app_client_id = { S = module.cognito_userpool_customer1.app_client_id }
          }
        }
        status = { S = "active" }
      })
    },
  ]

  tags = local.tags
}

module "cognito" {
  source = "../../src/cognito"

  name                = local.name
  dynamodb_table_name = module.dynamodb.id
  dynamodb_table_arn  = module.dynamodb.arn
  tags                = local.tags
}

module "cognito_userpool_customer1" {
  source = "../../src/cognito/userpool"

  tenant     = "customer1"
  name       = local.name
  domain     = local.domain
  lambda_arn = module.cognito.lambda_arn

  idp_type          = "google"
  idp_client_id     = var.google_client_id
  idp_client_secret = var.google_client_secret

  tags = local.tags
}

module "waf" {
  source = "../../src/waf"

  name = local.name
  tags = local.tags
}
