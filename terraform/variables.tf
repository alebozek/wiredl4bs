variable "aws_region" {
  description = "Región AWS"
  type        = string
  default     = "eu-south-2"
}

variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
  default     = "wiredl4bs"
}

variable "vpc_cidr" {
  description = "CIDR principal de la VPC"
  type        = string
  default     = "10.10.0.0/16"
}

variable "private_subnet_1" {
  type    = string
  default = "10.10.1.0/24"
}

variable "private_subnet_2" {
  type    = string
  default = "10.10.2.0/24"
}

variable "vpn_client_cidr" {
  description = "Rango asignado a clientes VPN"
  type        = string
  default     = "10.250.0.0/22"
}