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
  alias  = "us-east-1"
}

provider "aws" {
  region = "us-east-2"
  alias  = "us-east-2"
}

module "vpc" {
  source = "../../"
  providers = {
    aws = aws.us-east-1
  }
  vpc_cidr                = "10.0.0.0/16"
  azs                     = ["us-east-1a", "us-east-1b", "us-east-1c"]
  create_internet_gateway = false
  create_nat_gateway      = false
  create_private_subnets  = true
  create_public_subnets   = false
  name_tag                = "test-environment"
}

module "vpc" {
  source = "../../"
  providers = {
    aws = aws.us-east-2
  }
  vpc_cidr                = "10.2.0.0/16"
  azs                     = ["us-east-2a", "us-east-2b", "us-east-2c"]
  create_internet_gateway = false
  create_nat_gateway      = false
  create_private_subnets  = true
  create_public_subnets   = false
  name_tag                = "dev-environment"
}