variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "ami" {
  description = "AMI ID"
  type        = string
  default     = "ami-04b4f1a9cf54c11d0"

}

variable "instance_type" {
  description = "Instance type"
  type        = string
  default     = "t2.large"
}

variable "key_name" {
  description = "Key pair name"
  type        = string
}

variable "private_key_path" {
  description = "Path to private key"
  type        = string
}

variable "domain_name" {
  description = "Domain name"
  type        = string
}

variable "route53_zone_id" {
  description = "Route53 zone ID"
  type        = string
}

variable "admin_email" {
  description = "Email for Let's Encrypt certificate"
  type        = string
}

variable "git_repo_url" {
  description = "URL of the Git repository containing the application code"
  type        = string
}

variable "git_branch" {
  description = "Git branch to checkout"
  type        = string
}