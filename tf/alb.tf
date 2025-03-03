resource "yandex_alb_backend_group" "http-backend-group" {
  count = var.example == "alb-l7" ? 1 : 0
  name  = "backend-group"

  http_backend {
    name   = "echo-backend"
    weight = 1
    port   = 8080
    target_group_ids = [
      yandex_compute_instance_group.tcp-ig.application_load_balancer[0].target_group_id,
    ]
    load_balancing_config {
      panic_threshold = 50
    }
    healthcheck {
      timeout          = "10s"
      interval         = "10s"
      healthcheck_port = 8080
      http_healthcheck {
        path = "/"
      }
    }
  }
}

resource "yandex_alb_backend_group" "stream-backend-group" {
  count = var.example == "alb-l3" ? 1 : 0
  name  = "stream-backend-group"

  stream_backend {
    name                  = "echo-backend"
    weight                = 1
    port                  = 8080
    enable_proxy_protocol = true
    target_group_ids = [
      yandex_compute_instance_group.tcp-ig.application_load_balancer[0].target_group_id,
    ]
    load_balancing_config {
      panic_threshold = 50
    }
    healthcheck {
      interval = "10s"
      timeout  = "10s"
      stream_healthcheck {}
    }
  }
}


resource "yandex_alb_http_router" "router" {
  count = var.example == "alb-l7" ? 1 : 0
  name  = "http-router"
}

resource "yandex_alb_virtual_host" "virtual-host" {
  count          = var.example == "alb-l7" ? 1 : 0
  name           = "virtual-host"
  http_router_id = yandex_alb_http_router.router[0].id
  route {
    name = "echo-route"
    http_route {
      http_route_action {
        backend_group_id = yandex_alb_backend_group.http-backend-group[0].id
        timeout          = "3s"
      }
    }
  }
}

resource "yandex_alb_load_balancer" "balancer" {
  count = var.example != "nlb" ? 1 : 0
  name  = "alb"

  network_id = yandex_vpc_network.ig.id

  allocation_policy {
    location {
      zone_id   = "ru-central1-a"
      subnet_id = yandex_vpc_subnet.ig["ru-central1-a"].id
    }

  }

  listener {
    name = "echo-listener"
    endpoint {
      address {
        external_ipv4_address {
        }
      }
      ports = [8080]
    }
    dynamic "http" {
      for_each = var.example == "alb-l7" ? [1] : []
      content {
        handler {
          http_router_id = yandex_alb_http_router.router[0].id
        }
      }
    }

    dynamic "stream" {
      for_each = var.example == "alb-l3" ? [1] : []
      content {
        handler {
          backend_group_id = yandex_alb_backend_group.stream-backend-group[0].id
        }
      }
    }
  }
}