#dynamodb, elasticache
//shift + opt + up/down

# -------------------- dynamodb ------------------------- #
resource "aws_dynamodb_table" "urls" {
    name = "${local.prefix}-db-table"
    billing_mode = "PAY_PER_REQUEST"
    hash_key = "${local.prefix}-short_id" //primary key

    attribute {
        name = "${local.prefix}-short_id" //must be the same as hash_key
        type = "S" //string
    }
    tags = local.common_tags
}

# --------------------- elastic cache ------------------------ #
resource "aws_elasticache_serverless_cache" "redis" {
    engine = "redis" //alternative: memcached
    name = "${local.prefix}-cache"

    #sg, placement
    subnet_ids = aws_subnet.private-subnet[*].id
    security_group_ids = [aws_security_group.cache.id]
}
//Consider adding cache_usage_limits to bound max ECPU/storage to cap expenses