terraform {
  backend "s3" {
    bucket = "cloud-security-lab-tfstate"
    key    = "dev/terraform.tfstate"
    region = "eu-west-2"

    endpoints = {
      s3 = "http://localhost.localstack.cloud:4566"
    }

    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    # LocalStack: don't ask real AWS for account identity
    skip_requesting_account_id = true
    use_path_style             = true
    use_lockfile               = true
  }
}