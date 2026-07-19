resource "aws_cloudwatch_log_group" "app" {
  name              = "${local.prefix}-cloudwatch-log-group"
  retention_in_days = 7
  tags              = local.common_tags
}