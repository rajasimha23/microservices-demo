module "myvpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.4.0"
  
  name = "my-vpc"

  cidr = "10.0.0.0/16"
  azs  = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
  public_subnets = ["10.0.1.0/24","10.0.2.0/24","10.0.3.0/24"]
  map_public_ip_on_launch = true

  tags = {
    "kubernetes.io/cluster/eks-dev-cluster" = "shared"
  }

  public_subnet_tags = {
     "kubernetes.io/cluster/eks-dev-cluster" = "shared"
     "kubernetes.io/role/elb" = 1
  }

}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = "eks-dev-cluster"
  kubernetes_version = "1.33"

  endpoint_public_access = true   # Optional

  
  enable_cluster_creator_admin_permissions = true    # Optional: Adds the current caller identity as an administrator via cluster access entry

  vpc_id                   = module.myvpc.vpc_id
  control_plane_subnet_ids = module.myvpc.public_subnets
  subnet_ids               = module.myvpc.public_subnets

  addons = {
    coredns                = {}
    eks-pod-identity-agent = {
      before_compute = true
    }
    kube-proxy             = {}
    vpc-cni                = {
      before_compute = true
    }
  }
  
  # EKS Managed Node Group(s)
  eks_managed_node_groups = {
    
    dev_nodegroup = {

      instance_types = ["t3.medium"]
 
      min_size     = 2
      max_size     = 3
      desired_size = 2
    }
  }

  tags = {
    Environment = "dev"
  }
}