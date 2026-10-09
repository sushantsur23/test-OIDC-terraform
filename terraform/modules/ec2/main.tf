# Latest Amazon Linux 2023 AMI, unless an explicit AMI is given.
data "aws_ssm_parameter" "al2023" {
  count = var.ami_id == null ? 1 : 0
  name  = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

locals {
  ami_id = coalesce(var.ami_id, try(data.aws_ssm_parameter.al2023[0].value, null))
}

# ---------------------------------------------------------------------------
# IAM role: SSM Session Manager access (no SSH keys / open port 22 needed)
# and optional read access to specific Secrets Manager secrets.
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = "${var.name}-role"
  assume_role_policy = data.aws_iam_policy_document.assume.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy_document" "secrets" {
  count = length(var.readable_secret_arns) > 0 ? 1 : 0

  statement {
    sid       = "ReadAppSecrets"
    actions   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
    resources = var.readable_secret_arns
  }
}

resource "aws_iam_role_policy" "secrets" {
  count  = length(var.readable_secret_arns) > 0 ? 1 : 0
  name   = "read-secrets"
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.secrets[0].json
}

resource "aws_iam_instance_profile" "this" {
  name = "${var.name}-profile"
  role = aws_iam_role.this.name
  tags = var.tags
}

# ---------------------------------------------------------------------------
# Security group: no inbound by default, all outbound.
# ---------------------------------------------------------------------------
resource "aws_security_group" "this" {
  name        = "${var.name}-sg"
  description = "Security group for ${var.name}"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, { Name = "${var.name}-sg" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "this" {
  for_each = { for r in var.ingress_rules : "${r.protocol}-${r.from_port}-${r.to_port}-${r.cidr}" => r }

  security_group_id = aws_security_group.this.id
  description       = each.value.description
  ip_protocol       = each.value.protocol
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  cidr_ipv4         = each.value.cidr
}

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.this.id
  description       = "Allow all outbound"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# ---------------------------------------------------------------------------
# EC2 instance
# ---------------------------------------------------------------------------
resource "aws_instance" "this" {
  ami                         = local.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.this.id]
  iam_instance_profile        = aws_iam_instance_profile.this.name
  associate_public_ip_address = var.associate_public_ip
  key_name                    = var.key_name
  monitoring                  = var.detailed_monitoring
  user_data                   = var.user_data

  # Require IMDSv2 (protects instance credentials from SSRF).
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_size
    encrypted             = true
    delete_on_termination = true
    tags                  = merge(var.tags, { Name = "${var.name}-root" })
  }

  tags = merge(var.tags, { Name = var.name })

  lifecycle {
    # A new AMI release shouldn't silently replace a running instance.
    ignore_changes = [ami, user_data]
  }
}
