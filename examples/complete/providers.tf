provider "aws" {
  region = "ap-southeast-2"
  assume_role {
    role_arn     = "arn:aws:iam::171101346296:role/DeveloperAccessRole"
    session_name = "terraform"
  }
}

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}