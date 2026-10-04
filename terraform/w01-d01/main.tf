resource "aws_s3_bucket" "devops_lab" {
  bucket = "w01-d01-devops-lab"
  tags = {
    Environment = "learning"
    Project     = "cloud-security-lab"
    ManagedBy   = "terraform"
  }
}