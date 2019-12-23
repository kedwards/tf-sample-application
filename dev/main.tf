terraform {
  required_version = ">= 0.12.16"
}

provider "aws" {
  version = "~> 2.0"
  region  = "us-east-1"
}

module "vpc" {
  source = "git::git@github.com:kedwards/tf-vpc.git"

  name                    = var.name
  cidr                    = var.cidr
  enable_dns_hostnames    = var.enable_dns_hostnames
  enable_dns_support      = var.enable_dns_support
  create_internet_gateway = var.create_internet_gateway

  tags = {
    Owner       = var.owner
    Environment = var.environment
  }
}