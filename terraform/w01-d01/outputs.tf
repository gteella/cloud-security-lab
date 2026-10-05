output "bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.devops_lab.bucket
}

output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.devops_lab.arn
}

output "subnet_id" {
  description = "ID of the application subnet"
  value       = aws_subnet.app.id
}

output "vpc_id" {
  description = "ID of the vpc"
  value       = aws_vpc.main.id
}