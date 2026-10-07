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
  ami           = "ami-12345678"
  instance_type = "t2.micro"

  subnet_id                   = module.networking.public_subnet_id
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.app.name

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
          "s3:ListObject"
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
