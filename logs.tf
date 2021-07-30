resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/${var.service_name}"
  retention_in_days = 90
}

resource "aws_cloudwatch_log_stream" "this" {
  name           = "${var.service_name}-log-stream"
  log_group_name = aws_cloudwatch_log_group.this.name
}