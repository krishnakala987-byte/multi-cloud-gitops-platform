# Keyless CI: GitHub Actions assumes this IAM role via OIDC federation.
# No long-lived AWS keys anywhere - same pattern as your KubeIntel project.

data "aws_caller_identity" "current" {}

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

data "aws_iam_policy_document" "github_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:krishnakala987-byte@249091793/multi-cloud-gitops-platform@1310051356:*"]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = "gha-${var.cluster_name}"
  assume_role_policy = data.aws_iam_policy_document.github_assume.json
}

# ReadOnly is enough for CI plan/validate; widen deliberately if CI ever applies.
resource "aws_iam_role_policy_attachment" "github_readonly" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}
