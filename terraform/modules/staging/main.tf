module "eks-cluster" {
    source = "../eks"
    tag = "staging"
    clusterName = "eks-staging-cluster"
    NodegroupName = "nodegroup-staging"
}