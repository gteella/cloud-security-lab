module "networking" {
  source              = "../../modules/networking"
  common_tags         = local.common_tags
  private_subnet_cidr = var.private_subnet_cidr
  public_subnet_cidr  = var.public_subnet_cidr
  vpc_cidr            = var.vpc_cidr
}

resource "aws_s3_bucket" "devops_lab" {
  bucket = var.bucket_name
  tags   = local.common_tags
}

resource "aws_s3_bucket_public_access_block" "devops_lab" {
  bucket = aws_s3_bucket.devops_lab.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "access_logs" {
  bucket = "${var.bucket_name}-access-logs"
  tags = merge(local.common_tags, {
    Purpose = "S3AccessLogging"
  })
}

resource "aws_s3_bucket_public_access_block" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "devops_lab" {
  bucket = aws_s3_bucket.devops_lab.id
  versioning_configuration {
    status = "Enabled"
  }
}
resource "aws_s3_bucket_versioning" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

data "aws_iam_policy_document" "access_logs" {
  statement {
    sid    = "AllowS3ServerAccessLogs"
    effect = "Allow"

    principals {
      identifiers = ["logging.s3.amazonaws.com"]
      type        = "Service"
    }
    actions = ["s3:PutObject"]

    resources = [
      "${aws_s3_bucket.access_logs.arn}/access-logs/*"
    ]

    condition {
      test     = "ArnLike"
      values   = [aws_s3_bucket.devops_lab.arn]
      variable = "aws.sourceArn"
    }

    condition {
      test     = "StringEquals"
      values   = [data.aws_caller_identity.current.account_id]
      variable = "aws.SourceAccount"
    }
  }
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket_policy" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id
  policy = data.aws_iam_policy_document.access_logs.json
}

resource "aws_s3_bucket_logging" "devops_lab" {
  bucket        = aws_s3_bucket.devops_lab.id
  target_bucket = aws_s3_bucket.access_logs.id
  target_prefix = "access-logs/"

  depends_on = [
    aws_s3_bucket_policy.access_logs
  ]
}
resource "aws_security_group" "app" {
  name        = "app-sg"
  description = "Security group for application"
  vpc_id      = module.networking.vpc_id

  ingress {
    description = "Application Http"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Application egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "app-sg"
  })
}

resource "aws_instance" "app" {
  ami           = "ami-1e749f67"
  instance_type = "t2.micro"

  subnet_id                   = module.networking.public_subnet_id
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.app.name

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    encrypted   = true
    volume_size = 8
    volume_type = "gp3"
  }
  vpc_security_group_ids = [
    aws_security_group.app.id
  ]
  tags = merge(local.common_tags, {
    Name = "cloud-security-lab-app"
  })
}

resource "aws_iam_role" "app" {
  name = "cloud-security-lab-app-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Principal = {
        Service = "ec2.amazonaws.com"
      }

      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "app_s3" {
  name = "app-s3-policy"
  role = aws_iam_role.app.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.devops_lab.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = "${aws_s3_bucket.devops_lab.arn}/*"
    }]
  })
}

resource "aws_iam_instance_profile" "app" {
  name = "cloud-security-lab-app-profile"
  role = aws_iam_role.app.name
}
