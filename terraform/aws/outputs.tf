output "cluster_name" {
  value = module.eks.cluster_name
}

output "region" {
  value = var.region
}

output "gha_role_arn" {
  description = "Set as GitHub Actions variable AWS_GHA_ROLE_ARN"
  value       = aws_iam_role.github_actions.arn
}

output "kubeconfig_command" {
  value = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name} --alias aws"
}
