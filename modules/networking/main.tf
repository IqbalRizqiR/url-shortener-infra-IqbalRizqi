locals {
  tags = {
    Project = "lks-url"
  }
}

# VPC
# TODO: ADD MISSING KEYS AND VALUES TO RESOURCE BELOW
resource "aws_vpc" "main" {
  cidr_block = "172.16.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.tags, { Name = "lks-url-vpc" })
}

# Internet Gateway
# TODO: ADD MISSING KEYS AND VALUES TO RESOURCE BELOW
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = merge(local.tags, { Name = "lks-url-igw" })
}

# Subnets
# TODO: ADD MISSING KEYS AND VALUES TO RESOURCE BELOW
resource "aws_subnet" "public_a" {
  vpc_id = aws_vpc.main.id
  cidr_block = "172.16.1.0/24"
  availability_zone = "us-east-1a"
  tags = merge(local.tags, { Name = "lks-url-public-subnet-a" })
}

# TODO: ADD MISSING KEYS AND VALUES TO RESOURCE BELOW
resource "aws_subnet" "public_b" {
  vpc_id = aws_vpc.main.id
  cidr_block = "172.16.2.0/24"
  availability_zone = "us-east-1b"
  tags = merge(local.tags, { Name = "lks-url-public-subnet-b" })
}

# TODO: ADD MISSING KEYS AND VALUES TO RESOURCE BELOW
resource "aws_subnet" "private_a" {
  vpc_id = aws_vpc.main.id
  cidr_block = "172.16.11.0/24"
  availability_zone = "us-east-1a"
  tags = merge(local.tags, { Name = "lks-url-private-subnet-a" })
}

# TODO: ADD MISSING KEYS AND VALUES TO RESOURCE BELOW
resource "aws_subnet" "private_b" {
  vpc_id = aws_vpc.main.id
  cidr_block = "172.16.12.0/24"
  availability_zone = "us-east-1b"
  tags = merge(local.tags, { Name = "lks-url-private-subnet-b" })
}

# NAT Gateway
# TODO: ADD MISSING KEYS AND VALUES TO RESOURCE BELOW
resource "aws_eip" "nat" {
  domain = "vpc"
  tags = merge(local.tags, { Name = "lks-url-nat-eip" })
  depends_on = [aws_internet_gateway.igw]
}

resource "aws_nat_gateway" "nat" {
  subnet_id = aws_subnet.private_a.id
  connectivity_type = "public"
  allocation_id = aws_eip.nat.id
  tags = merge(local.tags, { Name = "lks-url-nat" })
  depends_on = [aws_eip.nat]
}

# Route Tables
# TODO: ADD MISSING KEYS AND VALUES TO RESOURCE BELOW
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = merge(local.tags, { Name = "lks-url-public-rt" })
}

# TODO: ADD MISSING KEYS AND VALUES TO RESOURCE BELOW
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat.id
  }

  tags = merge(local.tags, { Name = "lks-url-private-rt" })
}

# TODO: ADD MISSING KEYS AND VALUES TO RESOURCE BELOW
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

# TODO: ADD MISSING KEYS AND VALUES TO RESOURCE BELOW
resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

# TODO: ADD MISSING KEYS AND VALUES TO RESOURCE BELOW
resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}

# TODO: ADD MISSING KEYS AND VALUES TO RESOURCE BELOW
resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private.id
}

# Security Groups
# TODO: ADD MISSING KEYS AND VALUES TO RESOURCE BELOW
resource "aws_security_group" "alb" {
  name        = "lks-url-alb-sg"
  description = "Allow Web inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.main.id
  tags = merge(local.tags, { Name = "lks-url-alb-sg" })
}

resource "aws_vpc_security_group_ingress_rule" "allow_http_alb" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
  tags = {
    Name = "lks-url-allowHTTPPort"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_https_alb" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
  tags = {
    Name = "lks-url-allowHTTPSPort"
  }
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffics" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4 = "0.0.0.0/0"
  ip_protocol       = "-1"
  tags = {
    Name = "lks-url-allowAllTraffic"
  }
}



# TODO: ADD MISSING KEYS AND VALUES TO RESOURCE BELOW
resource "aws_security_group" "ecs" {
  name        = "lks-url-ecs-sg"
  description = "Allow Web inbound traffic to ALB and all outbound traffic"
  vpc_id      = aws_vpc.main.id
  tags = merge(local.tags, { Name = "lks-url-ecs-sg" })
}

resource "aws_vpc_security_group_ingress_rule" "allow_http_ecs" {
  security_group_id = aws_security_group.ecs.id
  referenced_security_group_id = aws_security_group.alb.id
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
  tags = {
    Name = "lks-url-allowHTTPPortToALB"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_apps_ecs" {
  security_group_id = aws_security_group.ecs.id
  referenced_security_group_id = aws_security_group.alb.id
  from_port         = 3000
  ip_protocol       = "tcp"
  to_port           = 3000
  tags = {
    Name = "lks-url-allow3000PortToALB"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_app_ecs" {
  security_group_id = aws_security_group.ecs.id
  referenced_security_group_id = aws_security_group.alb.id
  from_port         = 3001
  ip_protocol       = "tcp"
  to_port           = 3001
  tags = {
    Name = "lks-url-allow3001PortToALB"
  }
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffics" {
  security_group_id = aws_security_group.rds.id
  cidr_ipv4 = "0.0.0.0/0"
  ip_protocol       = "-1"
  tags = {
    Name = "lks-url-allowAllTraffic"
  }
}



# TODO: ADD MISSING KEYS AND VALUES TO RESOURCE BELOW
resource "aws_security_group" "rds" {
  name        = "lks-url-rds-sg"
  description = "Allow only to application"
  vpc_id      = aws_vpc.main.id
  tags = merge(local.tags, { Name = "lks-url-rds-sg" })
}

resource "aws_vpc_security_group_ingress_rule" "allow_port_rds" {
  security_group_id = aws_security_group.rds.id
  referenced_security_group_id = aws_security_group.ecs.id
  from_port         = 5432
  ip_protocol       = "tcp"
  to_port           = 5432
  tags = {
    Name = "lks-url-allowPostgreSQLToApps"
  }
}

resource "aws_vpc_security_group_egress_rule" "allow_all_trafficECS" {
  security_group_id = aws_security_group.rds.id
  cidr_ipv4 = "0.0.0.0/0"
  ip_protocol       = "-1"
  tags = {
    Name = "lks-url-allowAllTraffic"
  }
}


