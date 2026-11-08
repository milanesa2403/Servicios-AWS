variable "region" {
  description = "Region unica de la arquitectura A"
  type        = string
  default     = "us-east-2"
}

variable "name" {
  type    = string
  default = "rm-a"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "waf_rate_limit" {
  description = "Peticiones por IP en 5 minutos antes de responder 429. Alto para las pruebas de latencia y carga; para la prueba del WAF aplicar con -var waf_rate_limit=100"
  type        = number
  default     = 100000
}

variable "price_class" {
  description = "PriceClass_All incluye los puntos de presencia de Sudamerica (Lima, Santiago, Sao Paulo...)"
  type        = string
  default     = "PriceClass_All"
}

locals {
  tags = {
    Proyecto     = "reclutamiento-minero"
    Comparativa  = "cloudfront-vs-global-accelerator"
    Arquitectura = "A-cloudfront"
  }
}
