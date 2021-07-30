output "virtual_service_name" {
  value       = aws_appmesh_virtual_service.this.name
  description = "The name of app mesh virtual service"
}