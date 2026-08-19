
#=================================================================
#  S3 bucket for logs
#=================================================================

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "ec2ssm-logs-bucket" {
  
  bucket        = "zeus-ec2ssm-logsbu"
  force_destroy = true
  tags          = var.tags
}
resource "aws_s3_bucket_ownership_controls" "ec2ssm-logs-bucket" {
  bucket = aws_s3_bucket.ec2ssm-logs-bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "ec2ssm-logs-bucket" {
  depends_on = [aws_s3_bucket_ownership_controls.ec2ssm-logs-bucket]

  bucket = aws_s3_bucket.ec2ssm-logs-bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "ec2ssm-logs-bucket" {
  bucket = aws_s3_bucket.ec2ssm-logs-bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "ec2ssm-logs-bucket" {
  bucket = aws_s3_bucket.ec2ssm-logs-bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_key_id
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled  =true
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "ec2ssm-logs-bucket" {
  bucket = aws_s3_bucket.ec2ssm-logs-bucket.id

  rule {
    id     = "archive_ssm_logs"
    status = "Enabled"

    filter {
      prefix = "ssmlogs/"
    }

    transition {
      days          = var.log_archive_days
      storage_class = "GLACIER"
    }

    expiration {
      days = var.log_expire_days
    }
  }

  # New rule for artifacts - different retention policy
  rule {
    id     = "artifact_retention"
    status = "Enabled"

    filter {
      prefix = "artifacts/"
    }

    transition {
      days          = 90  # Move to Glacier after 90 days
      storage_class = "GLACIER"
    }

    expiration {
      days = 180
    } 
  }
}

resource "aws_s3_bucket_public_access_block" "ec2ssm-logs-bucket" {
  bucket                  = aws_s3_bucket.ec2ssm-logs-bucket.id
  block_public_acls       = true    # block new acls that allow public access
  block_public_policy     = true    # block bucket policy that allow public access
  ignore_public_acls      = true    # ignore existing acls that have been allowing pu access
  restrict_public_buckets = true    #
}

resource "aws_s3_object" "bucket_prefixes" {
  for_each = toset(["ssmlogs/" , "artifacts/"])
  bucket   = aws_s3_bucket.ec2ssm-logs-bucket.id
  key      = each.key
}

# Add the Bucket Policy allowing CloudTrail to write into the cloudtrail-logs/ prefix

resource "aws_s3_bucket_policy" "cloudtrail_s3_write_policy" {
  bucket = aws_s3_bucket.ec2ssm-logs-bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.ec2ssm-logs-bucket.arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.ec2ssm-logs-bucket.arn}/cloudtrail-logs/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

################################################################
#  S3 bucket for Zeus static assets
###############################################################

# Create the S3 Bucket
resource "aws_s3_bucket" "static_assets" {
  bucket        = "zeus-app-static-assets" 
  force_destroy = true                       
}

# Disable "Block Public Access" so browsers can fetch images
resource "aws_s3_bucket_public_access_block" "allow_public" {
  bucket = aws_s3_bucket.static_assets.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = false
  restrict_public_buckets = false
}

# Attach the Public Read Policy
resource "aws_s3_bucket_policy" "public_read_policy" {
  # Wait until the public access blocks are safely updated first
  depends_on = [aws_s3_bucket_public_access_block.allow_public]
  bucket     = aws_s3_bucket.static_assets.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.static_assets.arn}/*"
      }
    ]
  })
}

################################################################
#  Allow cross-origin requests from your app domains
###############################################################

resource "aws_s3_bucket_cors_configuration" "assets_cors" {
  bucket = aws_s3_bucket.static_assets.id

  cors_rule {
    
    allowed_origins = ["*"] 
    
    allowed_methods = ["GET", "HEAD"]
    
    allowed_headers = ["*"]
    
    # Cache the security authorization for 1 hour
    max_age_seconds = 3600 
  }
}


