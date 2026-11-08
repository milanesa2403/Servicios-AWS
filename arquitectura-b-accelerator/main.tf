module "backend_primaria" {
  source        = "../modules/backend"
  providers     = { aws = aws.primaria }
  name          = "${var.name}-1"
  vpc_cidr      = "10.10.0.0/16"
  instance_type = var.instance_type
}

module "backend_secundaria" {
  source        = "../modules/backend"
  providers     = { aws = aws.secundaria }
  name          = "${var.name}-2"
  vpc_cidr      = "10.20.0.0/16"
  instance_type = var.instance_type
}

resource "aws_globalaccelerator_accelerator" "this" {
  provider        = aws.global
  name            = "${var.name}-accelerator"
  ip_address_type = "IPV4"
  enabled         = true
}

resource "aws_globalaccelerator_listener" "http" {
  provider        = aws.global
  accelerator_arn = aws_globalaccelerator_accelerator.this.arn
  protocol        = "TCP"
  client_affinity = "NONE"

  port_range {
    from_port = 80
    to_port   = 80
  }
}

locals {
  regiones = {
    primaria = {
      region = var.region_primaria
      alb    = module.backend_primaria.alb_arn
      dial   = var.dial_primaria
    }
    secundaria = {
      region = var.region_secundaria
      alb    = module.backend_secundaria.alb_arn
      dial   = var.dial_secundaria
    }
  }
}

resource "aws_globalaccelerator_endpoint_group" "this" {
  for_each = local.regiones
  provider = aws.global

  listener_arn            = aws_globalaccelerator_listener.http.arn
  endpoint_group_region   = each.value.region
  traffic_dial_percentage = each.value.dial

  health_check_protocol         = "HTTP"
  health_check_port             = 80
  health_check_path             = "/api/health"
  health_check_interval_seconds = 10
  threshold_count               = 2

  endpoint_configuration {
    endpoint_id                    = each.value.alb
    weight                         = 100
    client_ip_preservation_enabled = true
  }
}
