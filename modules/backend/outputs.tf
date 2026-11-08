output "alb_arn" {
  value = aws_lb.this.arn
}

output "alb_dns_name" {
  value = aws_lb.this.dns_name
}

output "instance_ids" {
  value = aws_instance.app[*].id
}

output "target_group_arn" {
  value = aws_lb_target_group.app.arn
}

output "region" {
  value = local.region
}
