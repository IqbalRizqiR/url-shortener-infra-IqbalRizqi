# TODO: ADD PROPER KEYS AND VALUES TO RESOURCE BELOW

resource "aws_dynamodb_table" "cache" {
  name = "lks-url-cache-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key = "code"
  attribute {
    name = "code"
    type = "S"
  }
  ttl {
    attribute_name = "ttl"
    enabled = true
  }
  tags = {
    Name    = "lks-url-cache-table"
    Project = "lks-url"
  }
}
