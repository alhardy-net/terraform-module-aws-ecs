resource "aws_appmesh_virtual_node" "this" {
  name      = "${var.service_name}-node"
  mesh_name = var.app_mesh_name

  spec {
    dynamic "backend" {
      for_each = var.backend_virtual_service
      content {
        virtual_service {
          virtual_service_name = backend.value
        }
      }
    }

    listener {
      port_mapping {
        port     = "80"
        protocol = "http"
      }
      health_check {
        protocol            = "http"
        path                = "/"
        port                = 80
        healthy_threshold   = 2
        unhealthy_threshold = 2
        timeout_millis      = 2000
        interval_millis     = 5000
      }
    }

    service_discovery {
      aws_cloud_map {
        service_name   = aws_service_discovery_service.this.name
        namespace_name = var.service_discovery_namespace_name
      }
    }
  }
}

resource "aws_appmesh_virtual_service" "this" {
  name      = "${var.service_name}.${var.service_discovery_namespace_name}"
  mesh_name = var.app_mesh_name

  spec {
    provider {
      virtual_node {
        virtual_node_name = aws_appmesh_virtual_node.this.name
      }
    }
  }
}

resource "aws_appmesh_gateway_route" "route" {
  count                = var.app_mesh_virtual_gateway_name != "" ? 1 : 0
  name                 = "${var.service_name}-route"
  virtual_gateway_name = var.app_mesh_virtual_gateway_name
  mesh_name            = var.app_mesh_name

  spec {
    http_route {
      action {
        target {
          virtual_service {
            virtual_service_name = aws_appmesh_virtual_service.this.name
          }
        }
      }

      match {
        prefix = var.app_mesh_virtual_gateway_match_prefix
      }
    }
  }
}