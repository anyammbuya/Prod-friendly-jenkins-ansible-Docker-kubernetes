
output "valkey_serverless_endpoint" {
  description = "The direct endpoint domain"
  value       = aws_elasticache_serverless_cache.zeus_session_cache.endpoint[0].address
}