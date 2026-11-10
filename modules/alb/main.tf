# TODO: ADD MISSING VALUES TO RESOURCES BELOW
resource "aws_lb" "main" {
  name               = "lks-url-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnet_ids

  tags = {
    Name    = "lks-url-alb"
    Project = "lks-url"
  }
}

# Target group: frontend
# TODO: ADD MISSING KEYS AND VALUES TO RESOURCE BELOW
resource "aws_lb_target_group" "frontend" {
  name = "lks-url-tg-frontend"
  port = 80
  protocol = "HTTP"
  target_type = "ip"
  vpc_id = var.vpc_id
  health_check {
    enabled = true
    healthy_threshold = 2
    unhealthy_threshold = 3
    interval = 30
    timeout = 5
    path = "/"
    matcher = "200"
  }
  tags = {
    Name    = "lks-url-tg-frontend"
    Project = "lks-url"
  }
}

# Target group: api-service
# TODO: ADD MISSING KEYS AND VALUES TO RESOURCE BELOW
resource "aws_lb_target_group" "api" {
  name = "lks-url-tg-api"
  port = 3000
  protocol = "HTTP"
  target_type = "ip"
  vpc_id = var.vpc_id
  health_check {
    enabled = true
    healthy_threshold = 2
    unhealthy_threshold = 3
    timeout = 5
    interval = 30
    path = "/api/health"
    matcher = "200"
  }
  tags = {
    Name    = "lks-url-tg-api"
    Project = "lks-url"
  }
}

# Target group: analytics-service
# TODO: ADD MISSING KEYS AND VALUES TO RESOURCE BELOW
resource "aws_lb_target_group" "analytics" {
  name = "lks-url-tg-analytics"
  port = 3001
  protocol = "HTTP"
  target_type = "ip"
  vpc_id = var.vpc_id
  health_check {
    enabled = true
    healthy_threshold = 2
    unhealthy_threshold = 3
    timeout = 5
    interval = 30
    path = "/api/health"
    matcher = "200"
  }
  tags = {
    Name    = "lks-url-tg-analytics"
    Project = "lks-url"
  }
}

# HTTP listener
# TODO: ADD MISSING KEYS AND VALUES TO RESOURCES BELOW
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type = "forward"

    forward {
      target_group {
        arn    = aws_lb_target_group.frontend.arn
        weight = 100
      }
    }
  }
}

# TODO: ADD MISSING KEYS AND VALUES TO RESOURCES BELOW
resource "aws_lb_listener_rule" "analytics" {
  listener_arn = aws_lb_listener.http.arn
  priority = 99
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.analytics.arn
  }
  condition {
    path_pattern {
      values = ["/api/stats*"]
    }
  }
}

# TODO: ADD MISSING KEYS AND VALUES TO RESOURCES BELOW
resource "aws_lb_listener_rule" "api" {
  listener_arn = aws_lb_listener.http.arn
  priority = 98
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }
  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }
}

# TODO: ADD MISSING KEYS AND VALUES TO RESOURCES BELOW
resource "aws_lb_listener_rule" "redirect" {
  listener_arn = aws_lb_listener.http.arn
  priority = 100
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }
  condition {
    path_pattern {
      values = ["/s/*"]
    }
  }
}
