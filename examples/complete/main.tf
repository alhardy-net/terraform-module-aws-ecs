locals {
  service_name                       = "service-bff"
  vpc_id                             = "vpc-0ce11926c4fd3dc8b"
  aws_region                         = "ap-southeast-2"
  app_mesh_name                      = "alhardynet"
  cluster_name                       = "alhardynet"
  task_definition_family             = "service-bff"
  security_group_ingress_cidr_blocks = ["10.0.0.0/16"]
  service_discovery_namespace_id     = "ns-4es6nkt2iug7jezx"
  service_discovery_namespace_name   = "alhardynet.local"
  subnets                            = ["subnet-07c034e2e3b748cbd", "subnet-0bac18630707f271a"]
  role_arn                           = "arn:aws:iam::171101346296:role/EcsClusteralhardynetDefaultTaskRole"
  app_mesh_virtual_gateway_name      = "alhardynet-vg"
}

resource "aws_security_group" "this" {
  name        = "${local.service_name}-SG"
  description = "Security group for service to communicate in and out"
  vpc_id      = local.vpc_id

  ingress {
    from_port   = 80
    protocol    = "TCP"
    to_port     = 80
    cidr_blocks = local.security_group_ingress_cidr_blocks
  }

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.service_name}-SG"
  }
}

module "ecs_service" {
  source        = "../../"
  app_mesh_name = local.app_mesh_name
  aws_region    = local.aws_region
  cluster_name  = local.cluster_name
  container_definition = {
    name      = "service-bff-api"
    port      = 80
    host_port = 80
    environment = [
      {
        name  = "ASPNETCORE_ENVIRONMENT"
        value = "Development"
      },
      {
        name  = "CustomerApiBaseAddress"
        value = "http://customers-api.alhardynet.local"
      }
    ]
  }
  security_group_ids               = [aws_security_group.this.id]
  service_discovery_namespace_id   = local.service_discovery_namespace_id
  service_discovery_namespace_name = local.service_discovery_namespace_name
  service_name                     = local.service_name
  subnets                          = local.subnets
  task_definition = {
    family             = local.task_definition_family
    execution_role_arn = local.role_arn
    task_role_arn      = local.role_arn
    cpu                = 256
    memory             = 512
    desired_count      = 1
  }
  vpc_id                                = local.vpc_id
  app_mesh_virtual_gateway_name         = local.app_mesh_virtual_gateway_name
  app_mesh_virtual_gateway_match_prefix = "/"
}