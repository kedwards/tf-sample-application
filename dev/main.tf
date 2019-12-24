terraform {
  required_version = ">= 0.12.16"
}

provider "aws" {
  version = "~> 2.0"
  region  = "us-east-1"
}

data "template_file" "app_user_data" {
  template = file("./templates/user_data.tpl")
  vars = {
    mongo_address = module.mongodb.private_ip
  }
}

data "template_file" "db_user_data" {
  template = file("./files/user_data.sh")
}


locals {
  ami              = "ami-04b9e92b5572fa0d1" # replace with lookup from packer build.
  app_port         = "8080"
  name             = "keca"
  provisioning_key = "aws-provisioning-key-name"
  tags = {
    Environment = "dev"
    Owner       = "Kevin Edwards"
    Terraform   = true
  }
}

module "vpc" {
  source = "git::git@github.com:kedwards/tf-vpc.git?ref=v1.0.0"

  azs                  = ["us-east-1a", "us-east-1b", "us-east-1c"]
  cidr                 = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_nat_gateway   = true
  name                 = local.name
  private_subnets      = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets       = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  tags = local.tags
}

module "app_sg" {
  source = "git::git@github.com:kedwards/tf-security-group.git?ref=v1.0.0"

  ingress_rules = [
    ["22", "22", "tcp", "Allow ssh traffic to application", ["174.0.188.16/32"]],
    [local.app_port, local.app_port, "tcp", "Allow http traffic to application", ["0.0.0.0/0"]]
  ]
  egress_rules = [
    ["0", "0", "-1", "Allow all access out", ["0.0.0.0/0"]]
  ]
  name   = "${local.name}-application"
  vpc_id = module.vpc.vpc_id

  tags = local.tags
}

module "alb_sg" {
  source = "git::git@github.com:kedwards/tf-security-group.git?ref=v1.0.0"

  ingress_rules = [
    ["80", "80", "tcp", "Allow http traffic to alb", ["0.0.0.0/0"]]
  ]
  egress_rules = [
    ["0", "0", "-1", "Allow all access out", ["0.0.0.0/0"]]
  ]
  name   = "${local.name}-alb"
  vpc_id = module.vpc.vpc_id

  tags = local.tags
}

module "db_sg" {
  source = "git::git@github.com:kedwards/tf-security-group.git?ref=v1.0.0"

  ingress_rules = [
    ["27017", "27017", "tcp", "Allow traffic to db", ["0.0.0.0/0"]]
  ]
  egress_rules = [
    ["0", "0", "-1", "Allow all access out", ["0.0.0.0/0"]]
  ]
  name   = "${local.name}-mongo"
  vpc_id = module.vpc.vpc_id

  tags = local.tags
}

module "mongodb" {
  source = "git::git@github.com:kedwards/tf-ec2.git?ref=v1.0.0"

  ami              = local.ami
  instance_count   = 1
  name             = "keca-mongodb"
  provisioning_key = local.provisioning_key
  subnet           = module.vpc.private_subnets[0]
  user_data        = data.template_file.db_user_data.rendered
  security_groups = [
    module.db_sg.security_group_id
  ]

  tags = merge(
    local.tags,
    {
      Name = "Mongo01"
      Type = "Database"
    }
  )
}

module "app_platform" {
  source = "git::git@github.com:kedwards/tf-platform.git?ref=v1.0.0"

  ami                 = local.ami
  alb_security_groups = [module.alb_sg.security_group_id]
  app_subnets         = module.vpc.public_subnets
  name                = local.name
  path                = "/test.htm"
  provisioning_key    = local.provisioning_key
  protocol            = "HTTP"
  security_groups     = module.app_sg.security_group_id
  target_group_port   = local.app_port
  user_data           = base64encode(data.template_file.app_user_data.rendered)
  vpc_id              = module.vpc.vpc_id

  tags = local.tags
}
