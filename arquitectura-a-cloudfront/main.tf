data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

module "backend" {
  source                     = "../modules/backend"
  name                       = var.name
  instance_type              = var.instance_type
  alb_ingress_prefix_list_id = data.aws_ec2_managed_prefix_list.cloudfront.id
}

module "frontend" {
  source     = "../modules/frontend-s3"
  name       = var.name
  index_html = <<-HTML
    <!DOCTYPE html>
    <html lang="es">
    <head><meta charset="UTF-8"><title>Plataforma de Reclutamiento Minero</title></head>
    <body>
      <h1>Plataforma de Reclutamiento Minero</h1>
      <p>Pagina estatica servida desde S3 por CloudFront (en cache).</p>
      <p>Servidor que atiende la API: <a href="/api/info">/api/info</a></p>
    </body>
    </html>
  HTML
}

resource "aws_wafv2_web_acl" "this" {
  provider = aws.us_east_1
  name     = "${var.name}-waf"
  scope    = "CLOUDFRONT"

  default_action {
    allow {}
  }

  custom_response_body {
    key          = "demasiadas"
    content      = "{\"error\":\"Demasiadas peticiones, intenta en unos minutos\"}"
    content_type = "APPLICATION_JSON"
  }

  rule {
    name     = "limite-por-ip"
    priority = 1

    action {
      block {
        custom_response {
          response_code            = 429
          custom_response_body_key = "demasiadas"
        }
      }
    }

    statement {
      rate_based_statement {
        limit                 = var.waf_rate_limit
        aggregate_key_type    = "IP"
        evaluation_window_sec = 300
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "limite-por-ip"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.name}-waf"
    sampled_requests_enabled   = true
  }
}

data "aws_cloudfront_cache_policy" "optimized" {
  name = "Managed-CachingOptimized"
}

data "aws_cloudfront_cache_policy" "disabled" {
  name = "Managed-CachingDisabled"
}

data "aws_cloudfront_origin_request_policy" "all_viewer_except_host" {
  name = "Managed-AllViewerExceptHostHeader"
}

resource "aws_cloudfront_origin_access_control" "s3" {
  name                              = "${var.name}-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "this" {
  enabled             = true
  comment             = "Arquitectura A - portal reclutamiento minero"
  default_root_object = "index.html"
  price_class         = var.price_class
  web_acl_id          = aws_wafv2_web_acl.this.arn
  http_version        = "http2and3"

  origin {
    origin_id                = "s3-frontend"
    domain_name              = module.frontend.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.s3.id
  }

  origin {
    origin_id   = "alb-api"
    domain_name = module.backend.alb_dns_name

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    target_origin_id       = "s3-frontend"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    cache_policy_id        = data.aws_cloudfront_cache_policy.optimized.id
    compress               = true
  }

  ordered_cache_behavior {
    path_pattern             = "/api/*"
    target_origin_id         = "alb-api"
    viewer_protocol_policy   = "redirect-to-https"
    allowed_methods          = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods           = ["GET", "HEAD"]
    cache_policy_id          = data.aws_cloudfront_cache_policy.disabled.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewer_except_host.id
    compress                 = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

resource "aws_s3_bucket_policy" "frontend" {
  bucket = module.frontend.bucket_id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "SoloCloudFront"
      Effect    = "Allow"
      Principal = { Service = "cloudfront.amazonaws.com" }
      Action    = "s3:GetObject"
      Resource  = "${module.frontend.bucket_arn}/*"
      Condition = {
        StringEquals = { "AWS:SourceArn" = aws_cloudfront_distribution.this.arn }
      }
    }]
  })
}
