
resource "aws_cloudtrail" "zeus_trail" {
  name                          = "zeus-management-trail"
  s3_bucket_name                = var.bucket_name
  s3_key_prefix                 = "cloudtrail-logs" # Writes into your prefix folder
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true


  tags = var.tags
}