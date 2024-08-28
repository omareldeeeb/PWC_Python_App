module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.24.0"

  cluster_name    = "my-cluster"
  cluster_version = "1.30"

  cluster_endpoint_public_access  = true

  cluster_addons = {
    coredns                = {}
    eks-pod-identity-agent = {}
    kube-proxy             = {}
    vpc-cni                = {}
  }

  vpc_id                   = "vpc-06c3b7d96aaa79150"
  subnet_ids               = ["subnet-022b52ee805b6a69d", "subnet-0b2ce2701b26aa7e9"]
  control_plane_subnet_ids = ["subnet-022b52ee805b6a69d", "subnet-0b2ce2701b26aa7e9"]

  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    instance_types = ["t2.micro", "t2.micro"]
  }

  eks_managed_node_groups = {
    lab = {
      # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["t2.micro"]

      min_size     = 1
      max_size     = 2
      desired_size = 1
      key_name = "my-eks-keypair" 
    }
  }

  tags = {
    Environment = "EKS PWC"
    Terraform   = "true"
  }
}