output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "internet_gateway" {
  description = "The ID of the Internet Gateway"
  value       = module.vpc.vpc_igw_id
}

output "public_subnets" {
  description = "The ID of the Internet Gateway"
  value       = module.vpc.public_subnets
}

output "private_subnets" {
  description = "The ID of the Internet Gateway"
  value       = module.vpc.private_subnets
}

output "app_security_group_id" {
  description = "The ID of the security group"
  value       = module.app_sg.security_group_id
}

output "db_security_group_id" {
  description = "The ID of the security group"
  value       = module.db_sg.security_group_id
}

output "database_uri" {
  description = "The adress to connect to the database"
  value       = module.mongodb.private_ip
}

output "application_uri" {
  description = "The adress to connect to the application"
  value       = module.app_platform.dns_name
}