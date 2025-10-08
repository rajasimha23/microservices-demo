module "eks-cluster" {
    source = "../eks"
    tag = "staging"
    clusterName = "eks-staging-cluster"
}