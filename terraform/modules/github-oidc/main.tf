data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  partition  = data.aws_partition.current.partition

  # Which GitHub workflow runs may assume the role.
  allowed_subjects = concat(
    [for b in var.allowed_branches : "repo:${var.github_repository}:ref:refs/heads/${b}"],
    [for e in var.allowed_environments : "repo:${var.github_repository}:environment:${e}"],
    var.allow_pull_requests ? ["repo:${var.github_repository}:pull_request"] : [],
  )

  oidc_provider_arn = var.create_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : "arn:${local.partition}:iam::${local.account_id}:oidc-provider/token.actions.githubusercontent.com"
}

# Only one GitHub OIDC provider can exist per AWS account. Set
# create_oidc_provider = false if your account already has it.
resource "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider ? 1 : 0

  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]

  # AWS no longer validates these for GitHub, but older providers require a value.
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd",
  ]

  tags = var.tags
}

data "aws_iam_policy_document" "trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = local.allowed_subjects
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name                 = var.role_name
  description          = "Assumed by GitHub Actions (${var.github_repository}) via OIDC"
  assume_role_policy   = data.aws_iam_policy_document.trust.json
  max_session_duration = 3600
  tags                 = var.tags
}

# ---------------------------------------------------------------------------
# Remote state access: read/write state, create/delete the .tflock file.
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "state" {
  statement {
    sid       = "ListStateBucket"
    actions   = ["s3:ListBucket"]
    resources = ["arn:${local.partition}:s3:::${var.state_bucket}"]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = [var.state_prefix, "${var.state_prefix}/*"]
    }
  }

  statement {
    sid       = "ReadWriteState"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["arn:${local.partition}:s3:::${var.state_bucket}/${var.state_prefix}/*"]
  }
}

resource "aws_iam_role_policy" "state" {
  name   = "terraform-state-access"
  role   = aws_iam_role.github_actions.id
  policy = data.aws_iam_policy_document.state.json
}

# ---------------------------------------------------------------------------
# IAM permissions the pipeline needs to manage resources (e.g. the EC2
# instance role/profile), limited to names starting with the project prefix.
# PowerUserAccess deliberately excludes IAM, so this fills that gap safely.
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "iam_scoped" {
  statement {
    sid = "ManageProjectRoles"
    actions = [
      "iam:CreateRole", "iam:DeleteRole", "iam:GetRole", "iam:UpdateRole",
      "iam:TagRole", "iam:UntagRole", "iam:ListRoleTags",
      "iam:PutRolePolicy", "iam:GetRolePolicy", "iam:DeleteRolePolicy", "iam:ListRolePolicies",
      "iam:AttachRolePolicy", "iam:DetachRolePolicy", "iam:ListAttachedRolePolicies",
      "iam:UpdateAssumeRolePolicy", "iam:PassRole",
      "iam:CreateInstanceProfile", "iam:DeleteInstanceProfile", "iam:GetInstanceProfile",
      "iam:AddRoleToInstanceProfile", "iam:RemoveRoleFromInstanceProfile",
      "iam:TagInstanceProfile", "iam:UntagInstanceProfile",
      "iam:ListInstanceProfilesForRole",
    ]
    resources = [
      "arn:${local.partition}:iam::${local.account_id}:role/${var.resource_name_prefix}-*",
      "arn:${local.partition}:iam::${local.account_id}:instance-profile/${var.resource_name_prefix}-*",
    ]
  }
}

resource "aws_iam_role_policy" "iam_scoped" {
  name   = "scoped-iam-management"
  role   = aws_iam_role.github_actions.id
  policy = data.aws_iam_policy_document.iam_scoped.json
}

resource "aws_iam_role_policy_attachment" "managed" {
  for_each   = toset(var.managed_policy_arns)
  role       = aws_iam_role.github_actions.name
  policy_arn = each.value
}
