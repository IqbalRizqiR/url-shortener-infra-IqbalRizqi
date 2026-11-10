output "dynamodb_table_name" {
  description = "DynamoDB cache table name"
  value       = aws_dynamodb_table.cache.name
}
