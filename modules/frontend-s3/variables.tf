variable "name" {
  type = string
}

variable "index_html" {
  description = "Contenido del index.html estatico que sirve CloudFront"
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
