terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

module "vpc" {
  source                  = "../../"
  vpc_cidr                = "10.0.0.0/16"
  azs                     = ["us-east-1a", "us-east-1b", "us-east-1c"]
  create_internet_gateway = false
  create_nat_gateway      = false
  create_private_subnets  = false
  create_public_subnets   = false
  crate_flow_logs         = true
  name_tag                = "test-environment"
}