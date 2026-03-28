variable "ecr_repositories" {
  description = "ECR repositories keyed by container role"
  type        = map(string)
  default = {
    nginx = "nginx"
    php   = "php"
  }
}
variable "aws_region" {
  type    = string
  default = "us-east-2"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "project_name" {
  type    = string
  default = "php-nginx-app"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "azs" {
  type = list(string)
  default = [
    "us-east-2a",
    "us-east-2b"
  ]
}

variable "public_subnet_cidrs" {
  type = list(string)
  default = [
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]
}

variable "private_app_subnet_cidrs" {
  type = list(string)
  default = [
    "10.0.11.0/24",
    "10.0.12.0/24"
  ]
}

variable "private_db_subnet_cidrs" {
  type = list(string)
  default = [
    "10.0.21.0/24",
    "10.0.22.0/24"
  ]
}

variable "cluster_version" {
  type    = string
  default = "1.31"
}

variable "node_instance_types" {
  type    = list(string)
  default = ["t3.small"]
}

variable "desired_size" {
  type    = number
  default = 2
}

variable "min_size" {
  type    = number
  default = 2
}

variable "max_size" {
  type    = number
  default = 4
}


variable "db_name" {
  type    = string
  default = "laravel"
}

variable "db_username" {
  type    = string
  default = "root"
}

variable "db_password" {
  type      = string
  sensitive = true
  default   = "rootpass"
}

variable "db_instance_class" {
  type    = string
  default = "db.t4g.micro"
}
