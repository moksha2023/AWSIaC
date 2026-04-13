variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "eu-central-1"
}

variable "environment_name" {
  description = "Prefix for resource naming"
  type        = string
  default     = "thesis-tf"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "RDS database name"
  type        = string
  default     = "thesisdb"
}

variable "db_username" {
  description = "RDS master username"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "RDS master password"
  type        = string
  default     = "ThesisPass2026!"
  sensitive   = true
}

variable "asg_desired_capacity" {
  description = "ASG desired instance count"
  type        = number
  default     = 2
}

variable "asg_min_size" {
  description = "ASG minimum instance count"
  type        = number
  default     = 1
}

variable "asg_max_size" {
  description = "ASG maximum instance count"
  type        = number
  default     = 4
}
