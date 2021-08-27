data "aws_ecs_task_definition" "existing" {
  task_definition = var.task_definition.family
}

data "aws_ecs_container_definition" "existing" {
  container_name  = var.container_definition.name
  task_definition = var.task_definition.family
}

data "aws_secretsmanager_secret_version" "platform" {
  secret_id = "platform/shared"
}

locals {
  platform_creds   = jsondecode(data.aws_secretsmanager_secret_version.platform.secret_string)
  loki_url         = "https://${local.platform_creds.grafana_userid}:${local.platform_creds.grafana_apikey}@logs-prod-us-central1.grafana.net/loki/api/v1/push"
  loki_remove_keys = "container_id,ecs_task_arn"
  loki_label_keys  = "container_name,ecs_task_definition,source,ecs_cluster"
  loki_labels      = "{ecs_service=\"${var.service_name}\", env=\"${var.env}\"}"
}

resource "aws_ecs_task_definition" "this" {
  family = var.task_definition.family
  requires_compatibilities = [
    "FARGATE",
  ]
  execution_role_arn = var.task_definition.execution_role_arn
  task_role_arn      = var.task_definition.task_role_arn
  network_mode       = "awsvpc"
  cpu                = var.task_definition.cpu
  memory             = var.task_definition.memory

  proxy_configuration {
    container_name = "envoy"
    type           = "APPMESH"
    properties = {
      AppPorts         = var.container_definition.port
      EgressIgnoredIPs = "169.254.170.2,169.254.169.254"
      IgnoredUID       = "1337"
      ProxyEgressPort  = 15001
      ProxyIngressPort = 15000
    }
  }
  container_definitions = jsonencode([
    {
      name      = var.container_definition.name
      image     = data.aws_ecs_container_definition.existing.image
      essential = true
      portMappings = [
        {
          containerPort = var.container_definition.port
          hostPort      = var.container_definition.host_port
        }
      ]
      environment = var.container_definition.environment
      logConfiguration = {
        logDriver = "awsfirelens"
        secretOptions : null
        options = {
          Name       = "loki",
          Url        = local.loki_url
          Labels     = local.loki_labels
          RemoveKeys = local.loki_remove_keys
          LabelKeys  = local.loki_label_keys
          LineFormat = "key_value"
        }
      }
    },
    {
      name  = "envoy",
      image = var.envoy_image
      environment = [
        {
          name  = "APPMESH_VIRTUAL_NODE_NAME"
          value = "mesh/${var.app_mesh_name}/virtualNode/${var.service_name}-node"
        },
        {
          name  = "ENABLE_ENVOY_XRAY_TRACING"
          value = "1"
        },
        {
          name  = "ENVOY_LOG_LEVEL"
          value = "info"
        }
      ]
      healthCheck = {
        retries = 3
        command = [
          "CMD-SHELL",
          "curl -s http://localhost:9901/server_info | grep state | grep -q LIVE"
        ]
        timeout     = 2
        interval    = 5
        startPeriod = 10
      }
      user = "1337"
      logConfiguration = {
        logDriver = "awsfirelens"
        secretOptions : null
        options = {
          Name       = "loki",
          Url        = local.loki_url
          Labels     = ""
          RemoveKeys = local.loki_remove_keys
          LabelKeys  = local.loki_label_keys
          LineFormat = "key_value"
        }
      }
    },
    {
      name  = "xray-daemon"
      image = var.xray_image
      portMappings = [
        {
          hostPort      = 2000
          containerPort = 2000
          protocol      = "udp"
        }
      ]
      logConfiguration = {
        logDriver = "awsfirelens"
        secretOptions : null
        options = {
          Name       = "loki",
          Url        = local.loki_url
          Labels     = local.loki_labels
          RemoveKeys = local.loki_remove_keys
          LabelKeys  = local.loki_label_keys
          LineFormat = "key_value"
        }
      }
    },
    {
      essential = true,
      image     = var.fluent_bit_loki_image,
      name      = "log_router",
      firelensConfiguration : {
        type = "fluentbit",
        options : {
          enable-ecs-log-metadata = "true"
        }
      },
      logConfiguration : {
        logDriver : "awslogs",
        options : {
          awslogs-group         = "firelens-container",
          awslogs-region        = var.aws_region,
          awslogs-create-group  = "true",
          awslogs-stream-prefix = "firelens"
        }
      },
      memoryReservation : 50
    }
  ])
}

resource "aws_ecs_service" "service" {
  name            = var.service_name
  cluster         = var.cluster_name
  task_definition = "${aws_ecs_task_definition.this.family}:${max(aws_ecs_task_definition.this.revision, data.aws_ecs_task_definition.existing.revision)}"
  desired_count   = 1

  network_configuration {
    subnets          = var.subnets
    security_groups  = var.security_group_ids
    assign_public_ip = false
  }

  service_registries {
    registry_arn   = aws_service_discovery_service.this.arn
    container_name = var.container_definition.name
  }

  deployment_controller {
    type = "ECS"
  }
  capacity_provider_strategy {
    base              = 0
    capacity_provider = "FARGATE"
    weight            = 100
  }
}

resource "aws_service_discovery_service" "this" {
  name = var.service_name

  dns_config {
    namespace_id = var.service_discovery_namespace_id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}