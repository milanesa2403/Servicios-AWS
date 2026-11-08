output "ips_estaticas" {
  description = "Las 2 IPs anycast fijas del acelerador"
  value       = flatten([for s in aws_globalaccelerator_accelerator.this.ip_sets : s.ip_addresses])
}

output "url" {
  description = "Entrada unica de la arquitectura B"
  value       = "http://${aws_globalaccelerator_accelerator.this.dns_name}"
}

output "alb_primaria" {
  value = "http://${module.backend_primaria.alb_dns_name}"
}

output "alb_secundaria" {
  value = "http://${module.backend_secundaria.alb_dns_name}"
}

output "instancias_primaria" {
  value = module.backend_primaria.instance_ids
}

output "instancias_secundaria" {
  value = module.backend_secundaria.instance_ids
}

output "accelerator_arn" {
  value = aws_globalaccelerator_accelerator.this.arn
}
