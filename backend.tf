terraform {
  backend "s3" {
    encrypt = true
    bucket = "terraform-conf-s3-backend"
    key    = "terraform.tfstate"
    region = "sa-east-1"
  }
  }