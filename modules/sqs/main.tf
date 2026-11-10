# TODO: ADD MISSING KEYS AND VALUES TO RESOURCE BELOW
resource "aws_sqs_queue" "dlq" {
  name = "lks-url-click-events-dlq"
  message_retention_seconds = 432000
  visibility_timeout_seconds = 30
  tags = {
    Name    = "lks-url-click-events-dlq"
    Project = "lks-url"
  }
}

resource "aws_sqs_queue" "click_events" {
  name = "lks-url-click-events"
  message_retention_seconds = 86400
  visibility_timeout_seconds = 30
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 5
  })
  tags = {
    Name    = "lks-url-click-events"
    Project = "lks-url"
  }
}
