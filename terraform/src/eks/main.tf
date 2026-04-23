data "aws_region" "current" {}

resource "aws_iam_role" "vpc_cni" {
  name = "${var.name}-vpc-cni"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "pods.eks.amazonaws.com" }
      Action    = ["sts:AssumeRole", "sts:TagSession"]
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "vpc_cni" {
  role       = aws_iam_role.vpc_cni.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.18"

  name               = var.name
  kubernetes_version = var.cluster_version
  vpc_id             = var.vpc_id
  subnet_ids         = var.subnet_ids
  endpoint_public_access = true

  enable_cluster_creator_admin_permissions = var.enable_cluster_creator_admin_permissions

  access_entries = var.access_entries

  addons = merge(
    var.addons,
    {
      eks-pod-identity-agent = {
        before_compute = true
        most_recent    = true
      }
    },
    {
      vpc-cni = merge(
        try(var.addons["vpc-cni"], {}),
        {
          pod_identity_association = [{
            role_arn        = aws_iam_role.vpc_cni.arn
            service_account = "aws-node"
          }]
        }
      )
    }
  )

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

      update_config = {
        max_unavailable = 1
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
