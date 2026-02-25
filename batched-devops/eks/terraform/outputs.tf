output "eks_cluster_name" {
  value = module.eks.cluster_name
}
output "eks_cluster_arn" {
  value = module.eks.cluster_arn
}
output "eks_oidc" {
  value = module.eks.cluster_oidc_issuer_url
}
output "eks_oidc_provider" {
  value = module.eks.oidc_provider
}
output "oidc_provider_arn" {
  value = module.eks.oidc_provider_arn
}
output "cluster-autosclaer-role-arn" {
  value = aws_iam_role.cluster-autoscaler-role.arn
}
output "cluster-version" {
  value = module.eks.cluster_version
}