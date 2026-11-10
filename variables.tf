variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "aws_account_id" {
  description = "AWS account ID"
  type        = string
}

variable "db_username" {
  description = "RDS master username"
  type        = string
  default     = "urlshortener"
}

variable "db_password" {
  description = "RDS master password"
  type        = string
  sensitive   = true
}
variable "aws_access_key_id" {
  description = "AWS account ID"
  type        = string
}

variable "aws_secret_key_access" {
  description = "AWS account ID"
  type        = string
}