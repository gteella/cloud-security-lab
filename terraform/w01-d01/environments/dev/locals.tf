locals {
  environment = "dev"
  common_tags = {
    Environment = local.environment
    Project     = "cloud-security-lab"
    ManagedBy   = "terraform"
  }
}