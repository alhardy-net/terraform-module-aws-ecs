data "template_file" "adot_config" {
  template = file("${path.module}/adot-config.yaml")
  vars = {
    service_name   = var.service_name
    ecs_cluster    = var.cluster_name
    ecs_revision   = aws_ecs_task_definition.this.revision
    container_port = var.container_definition.port
    env            = var.env
  }
}

resource "aws_ssm_parameter" "otel_config" {
  name  = "otel-collector-config-${var.service_name}"
  type  = "String"
  value = data.template_file.adot_config.rendered
}