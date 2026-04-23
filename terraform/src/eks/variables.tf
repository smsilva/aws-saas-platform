variable "name" {
  description = "Cluster name (also used for associated resources)"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.32"
}

variable "vpc_id" {
  description = "VPC ID where the cluster will be created"
  type        = string
}

variable "subnet_ids" {
  description = "Subnets for the EKS control plane"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Private subnets for managed node groups"
  type        = list(string)
}

variable "node_instance_type" {
  description = "EC2 instance type for managed node group"
  type        = string
  default     = "t3.medium"
}

variable "node_min_count" {
  description = "Minimum number of nodes in the managed node group"
  type        = number
  default     = 1
}

variable "node_max_count" {
  description = "Maximum number of nodes in the managed node group"
  type        = number
  default     = 3
}

variable "node_desired_count" {
  description = "Desired number of nodes in the managed node group"
  type        = number
  default     = 2
}

variable "enable_cluster_creator_admin_permissions" {
  description = "Add the cluster creator IAM identity as an administrator via access entry"
  type        = bool
  default     = true
}

variable "addons" {
  description = "EKS managed addons to install. Set to null to skip all addons."
  type        = any
  default = {
    vpc-cni = {
      most_recent    = true
      before_compute = true
    }
    kube-proxy = {
      most_recent = true
    }
    coredns = {
      most_recent = true
    }
    metrics-server = {
      most_recent = true
    }
  }
}

variable "access_entries" {
  description = "Access entries to add to the cluster (map of principal ARN to policy associations)"
  type        = any
  default     = {}
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
