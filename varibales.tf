variable "name_tag" {
  type        = string
  description = "The value of name tag to used on all resources"
}
variable "vpc_cidr" {
  type        = string
  description = "IPv4 CIDR for VPC"
}
variable "azs" {
  description = "List of availability zones names"
  type        = list(string)
}
variable "enable_dns_hostnames" {
  type        = bool
  description = "Should enable DNS hostname"
  default     = true
}
variable "enable_dns_support" {
  type        = bool
  description = "Should enable DNS support"
  default     = true
}
variable "instance_tenancy" {
  description = "Instances tenancy to launch into the VPC"
  type        = string
  default     = "default"
}
variable "create_public_subnets" {
  description = "Should create public subnets"
  type        = bool
}
variable "create_private_subnets" {
  description = "Should create private subnets"
  type        = bool
}
variable "create_internet_gateway" {
  description = "Should Create Internet Gateway"
  type        = bool
}
variable "create_nat_gateway" {
  description = "Should Create Nat Gateway"
  type        = bool
}
variable "shared_ngw" {
  description = "Should create a shared NAT Gateway"
  type        = bool
  default     = true
}
variable "create_r53_private_hosted_zone" {
  description = "Should create private R53 hosted zone"
  type        = bool
  default     = false
}
variable "r53_private_domain_name" {
  description = "private R53 domain name"
  type        = string
  default     = null
}
variable "crate_flow_logs" {
  description = "Should create VPC flow logs"
  type        = bool
  default     = false
}