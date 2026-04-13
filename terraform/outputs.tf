output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "alb_dns_name" {
  description = "Application Load Balancer DNS"
  value       = aws_lb.main.dns_name
}

output "rds_endpoint" {
  description = "RDS Endpoint"
  value       = aws_db_instance.main.endpoint
}

output "app_assets_bucket" {
  description = "S3 App Assets Bucket"
  value       = aws_s3_bucket.app_assets.id
}

output "logs_bucket" {
  description = "S3 Logs Bucket"
  value       = aws_s3_bucket.logs.id
}

output "public_subnet_ids" {
  description = "Public Subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private Subnet IDs"
  value       = aws_subnet.private[*].id
}
