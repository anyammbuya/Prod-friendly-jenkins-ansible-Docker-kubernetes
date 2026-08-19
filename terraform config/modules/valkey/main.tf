
# Serverless Cache Cluster (Fully Managed & Automated)

resource "aws_elasticache_serverless_cache" "zeus_session_cache" {
  name                 = "zeus-session-cache"
  description          = "High-availability serverless Valkey engine for active Tomcat user sessions"
  engine               = "valkey" # Drops minimum storage floor to 100MB
  major_engine_version = "9"

  # Networking Setup
  subnet_ids         = var.subnet_ids_private
  security_group_ids = [var.valkey_sg_id]

  cache_usage_limits {
    data_storage {
      maximum = 5 # Caps storage at 5 GB max to avoid out-of-bounds scaling bills
      unit    = "GB"
    }
    ecpu_per_second {
      maximum = 5000
    }
  }

  tags = var.tags
}


