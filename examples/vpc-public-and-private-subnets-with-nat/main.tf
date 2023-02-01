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
  azs                     = ["us-east-1a", "us-east-1b", "us-east-1c"]
  vpc_cidr                = "10.0.0.0/16"
  create_internet_gateway = true
  create_nat_gateway      = true
  create_private_subnets  = true
  create_public_subnets   = true
  crate_flow_logs         = false
  name_tag                = "test-environment"
  shared_ngw              = true // To create multiple Nat Gateway in each availability zone the value should be false
}