resource "yandex_lb_network_load_balancer" "nlb" {
  count = var.example == "nlb" ? 1 : 0
  name     = "dnat-demo"

  listener {
    name = "test"
    port = 8080
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_compute_instance_group.tcp-ig.load_balancer[0].target_group_id

    healthcheck {
      name = "tcp"
      tcp_options {
        port = 8080
      }
    }
  }
}