output "subnet_ids_AZs"{
    description = "these are subnet ids of the AZs EKS is going to use"
    value = aws_eks_cluster.eks-demo-cluster.vpc_config[0].subnet_ids
}