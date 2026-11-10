# TODO: ADD MISSING VALUES TO RESOURCES BELOW

locals {
  tags = { Project = "lks-url" }
}

resource "aws_db_subnet_group" "main" {
  name       = "lks-url-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = merge(local.tags, { Name = "lks-url-db-subnet-group" })
}

# TODO: ADD PROPER KEYS AND VALUES TO RESOURCE BELOW
resource "aws_db_instance" "main" {
  identifier = "lks-url-db"
  allocated_storage = "20"
  db_name = var.db_username
  username = var.db_username
  password = var.db_password
  publicly_accessible = false
  storage_type = "gp3"
  vpc_id = var.vpc_id
  vpc_security_group_ids = [var.rds_sg_id]
  multi_az = false
  monitoring_interval = 0
  engine = "postgres"
  engine_version = "17.6"
  instance_class = "db.t3.micro"
  tags = merge(local.tags, { Name = "lks-url-db" })
}

