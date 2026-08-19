output "s3_bucket_name" {
 
  value       = aws_s3_bucket.ec2ssm-logs-bucket.bucket
}

output "asset_bucket_arn" {
 
  value       = aws_s3_bucket.static_assets.arn
}