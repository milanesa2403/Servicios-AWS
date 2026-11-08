variable "region_primaria" {
  type    = string
  default = "us-east-2"
}

variable "region_secundaria" {
  type    = string
  default = "sa-east-1"
}

variable "name" {
  type    = string
  default = "rm-b"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "dial_primaria" {
  type    = number
  default = 100
}

variable "dial_secundaria" {
  type    = number
  default = 100
}

locals {
  tags = {
    Proyecto     = "reclutamiento-minero"
    Comparativa  = "cloudfront-vs-global-accelerator"
    Arquitectura = "B-global-accelerator"
  }
}
