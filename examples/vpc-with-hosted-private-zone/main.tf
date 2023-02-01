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
  source                         = "../../"
  vpc_cidr                       = "10.0.0.0/16"
  azs                            = ["us-east-1a", "us-east-1b", "us-east-1c"]
  create_internet_gateway        = true
  create_nat_gateway             = true
  create_private_subnets         = true
  create_public_subnets          = true
  crate_flow_logs                = true
  create_r53_private_hosted_zone = true
  r53_private_domain_name        = "test.local"
  name_tag                       = "test-environment"
  shared_ngw                     = false
}