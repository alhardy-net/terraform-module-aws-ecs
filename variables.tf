variable "aws_region" {
  description = "The AWS region for the resources."
  type        = string
}

variable "cluster_name" {
  description = "The name of the ECS cluster"
  type        = string
}

variable "service_name" {
  description = "The name of the ECS service"
  type        = string
}

variable "env" {
  description = "The environment the service is running in"
  type        = string
}

variable "vpc_id" {
  description = "The VPC Identifier"
  type        = string
}

variable "subnets" {
  description = "The subnets to assign the ECS service"
  type        = list(string)
}

variable "service_discovery_namespace_id" {
  description = "The namespace id of the private dns namespace"
  type        = string
}

variable "service_discovery_namespace_name" {
  description = "The namespace name of the private dns namespace"
  type        = string
}

variable "backend_virtual_service" {
  description = "The name of the backend virtual service to add the the app mesh node"
  type        = list(string)
  default     = []
}

variable "security_group_ids" {
  description = "The security groups to assign the ECS Service"
  type        = list(string)
}

variable "app_mesh_virtual_gateway_name" {
  description = "The name of the virtual gateway if adding a gateway route"
  type        = string
  default     = ""
}

variable "app_mesh_virtual_gateway_match_prefix" {
  description = "The match prefix for the gateway route if a gateway is specified"
  type        = string
  default     = ""
}

variable "app_mesh_name" {
  description = "The name of the App Mesh"
  type        = string
}

variable "task_definition" {
  description = "Configuration for the task definition"
  type = object({
    family             = string,
    execution_role_arn = string,
    task_role_arn      = string,
    cpu                = number,
    memory             = number,
    desired_count      = number
  })
}

variable "container_definition" {
  description = "Configuration for the container definition"
  type = object({
    name        = string,
    port        = number,
    host_port   = number,
    environment = list(object({ name = string, value = string }))
  })
}

variable "autoscaling" {
  description = "Autoscaling configuration"
  type = object({
    min_capacity              = number
    max_capacity              = number
    cooldown_scale_up         = number
    cooldown_scale_down       = number
    metric_aggregation_type   = string
    adjustment_type           = string
    max_cpu_evaluation_period = string // The number of periods over which data is compared to the specified threshold for max cpu metric alarm
    max_cpu_period            = string // The period in seconds over which the specified statistic is applied for max cpu metric alarm
    max_cpu_threshold         = string // Threshold for max CPU usage
    min_cpu_evaluation_period = string // The number of periods over which data is compared to the specified threshold for min cpu metric alarm
    min_cpu_period            = string // The period in seconds over which the specified statistic is applied for min cpu metric alarm
    min_cpu_threshold         = string // Threshold for min CPU usage
  })
}

variable "envoy_image" {
  description = "The image to use for the envoy proxy"
  type        = string
  default     = "840364872350.dkr.ecr.ap-southeast-2.amazonaws.com/aws-appmesh-envoy:v1.18.3.0-prod"
}

variable "xray_image" {
  description = "The image to use for the xray daemon"
  type        = string
  default     = "amazon/aws-xray-daemon:1"
}

variable "fluent_bit_loki_image" {
  description = "The image used for the loki sidecar"
  type        = string
  default     = "grafana/fluent-bit-plugin-loki:latest"
}