output "virtual_service_name" {
  value       = aws_appmesh_virtual_service.this.name
  description = "The name of app mesh virtual service"
}

output "autoscaling_policy_down_arn" {
  value       = aws_appautoscaling_policy.down.arn
  description = "The arn of the down autoscaling policy for the ECS Service"
}

output "autoscaling_policy_up_arn" {
  value       = aws_appautoscaling_policy.up.arn
  description = "The arn of the down autoscaling policy for the ECS Service"
}