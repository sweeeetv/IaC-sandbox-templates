output "app_url" {
  description = "cf endpoint"
  value       = "https://${aws_cloudfront_distribution.api_cdn.domain_name}"
}

output "ecr_repository_url" {
  description = "Push images here (docker push ...)"
  value       = aws_ecr_repository.app.repository_url
}

output "alb_dns_name" {
  description = "Direct ALB endpoint, for debugging only (bypasses CF/WAF)"
  value       = aws_lb.fargate_app.dns_name
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.urls.name
}

output "redis_endpoint" {
  value = aws_elasticache_serverless_cache.redis.endpoint[0].address
} // useful for manually inspect data (aws dynamodb scan, redis-cli) while debugging

output "ecs_cluster_name" {
  value = aws_ecs_cluster.app.name
} //saves a console lookup when running [ aws ecs update-service ] to force a redeploy after pushing a new image.

//