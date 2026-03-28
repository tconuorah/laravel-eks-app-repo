variable "name" { type = string }
variable "vpc_id" { type = string }
variable "db_subnet_ids" { type = list(string) }
variable "app_security_group" { type = string }
variable "app_cidr_blocks" {
  type    = list(string)
  default = []
}
variable "db_name" { type = string }
variable "db_username" { type = string }
variable "db_password" {
  type      = string
  sensitive = true
}
variable "db_instance_class" { type = string }
variable "tags" { type = map(string) }
