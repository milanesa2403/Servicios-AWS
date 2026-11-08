output "url" {
  description = "Entrada unica de la arquitectura A"
  value       = "https://${aws_cloudfront_distribution.this.domain_name}"
}

output "distribution_id" {
  value = aws_cloudfront_distribution.this.id
}

output "alb_dns_directo" {
  description = "No debe responder desde internet: el SG solo acepta la prefix list de CloudFront"
  value       = "http://${module.backend.alb_dns_name}"
}

output "bucket_frontend" {
  description = "Bucket privado: la URL directa de S3 debe devolver 403"
  value       = "https://${module.frontend.bucket_regional_domain_name}/index.html"
}

output "waf_acl" {
  value = aws_wafv2_web_acl.this.name
}

output "instancias" {
  value = module.backend.instance_ids
}
