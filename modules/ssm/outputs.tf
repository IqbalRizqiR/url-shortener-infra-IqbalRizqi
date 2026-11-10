output "db_url_arn" {
  description = "ARN of the /lks-url/db-url SSM parameter"
  value       = aws_ssm_parameter.db_url.arn
}

output "sqs_url_arn" {
  description = "ARN of the /lks-url/sqs-url SSM parameter"
  value       = aws_ssm_parameter.sqs_url.arn
}

output "base_url_arn" {
  description = "ARN of the /lks-url/base-url SSM parameter"
  value       = aws_ssm_parameter.base_url.arn
}

output "port_api_arn" {
  description = "ARN of the /lks-url/port-api SSM parameter"
  value       = aws_ssm_parameter.port_api.arn
}

output "port_analytics_arn" {
  description = "ARN of the /lks-url/port-analytics SSM parameter"
  value       = aws_ssm_parameter.port_analytics.arn
}

output "dynamodb_table_arn" {
  description = "ARN of the /lks-url/dynamodb-table SSM parameter"
  value       = aws_ssm_parameter.dynamodb_table.arn
}

output "dynamodb_region_arn" {
  description = "ARN of the /lks-url/dynamodb-region SSM parameter"
  value       = aws_ssm_parameter.dynamodb_region.arn
}
