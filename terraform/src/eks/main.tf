data "aws_region" "current" {}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.18"

  name               = var.name
  kubernetes_version = var.cluster_version
  vpc_id             = var.vpc_id
  subnet_ids         = var.subnet_ids
  endpoint_public_access = true

  enable_cluster_creator_admin_permissions = var.enable_cluster_creator_admin_permissions

  addons = var.addons

  eks_managed_node_groups = {
    default = {
      instance_types = [var.node_instance_type]
      subnet_ids     = var.private_subnet_ids
      min_size       = var.node_min_count
      max_size       = var.node_max_count
      desired_size   = var.node_desired_count

      metadata_options = {
        http_endpoint               = "enabled"
        http_tokens                 = "required"
        http_put_response_hop_limit = 2
      }

      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 80
            volume_type           = "gp3"
            iops                  = 3000
            throughput            = 125
            delete_on_termination = true
          }
        }
      }

      attach_cluster_primary_security_group = true
    }
  }

  tags = var.tags
}

locals {
  kubeconfig = <<-EOT
    apiVersion: v1
    kind: Config
    clusters:
    - cluster:
        server: ${module.eks.cluster_endpoint}
        certificate-authority-data: ${module.eks.cluster_certificate_authority_data}
      name: ${var.name}
    contexts:
    - context:
        cluster: ${var.name}
        user: ${var.name}
      name: ${var.name}
    current-context: ${var.name}
    users:
    - name: ${var.name}
      user:
        exec:
          apiVersion: client.authentication.k8s.io/v1beta1
          args:
          - --region
          - ${data.aws_region.current.id}
          - eks
          - get-token
          - --cluster-name
          - ${var.name}
          command: aws
    EOT
}
