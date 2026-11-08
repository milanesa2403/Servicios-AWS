variable "name" {
  description = "Prefijo corto (max ~20 caracteres, el ALB admite 32)"
  type        = string
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "app_port" {
  type    = number
  default = 80
}

variable "alb_ingress_prefix_list_id" {
  description = "Prefix list que puede entrar al ALB (la de CloudFront en la arquitectura A). null = internet"
  type        = string
  default     = null
}

variable "tags" {
  type    = map(string)
  default = {}
}
