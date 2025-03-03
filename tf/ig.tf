data "yandex_compute_image" "echo" {
  family    = "echo"
  folder_id = var.folder_id
}

resource "yandex_vpc_network" "ig" {
  folder_id = var.folder_id
  name      = "loadbalancer-demo"
}

locals {
  subnets = {
    "ru-central1-a" : ["10.0.1.0/24"],
    "ru-central1-b" : ["10.0.2.0/24"],
    "ru-central1-d" : ["10.0.3.0/24"],
  }
}

resource "yandex_vpc_subnet" "ig" {
  for_each       = local.subnets
  network_id     = yandex_vpc_network.ig.id
  zone           = each.key
  v4_cidr_blocks = each.value

  route_table_id = yandex_vpc_route_table.egress.id
}

resource "yandex_vpc_gateway" "egress-gateway" {
  name      = "gateway"
  folder_id = var.folder_id
  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "egress" {
  name       = "egress"
  network_id = yandex_vpc_network.ig.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.egress-gateway.id
  }
}

resource "cloudinit_config" "config" {
  gzip          = false
  base64_encode = false

  part {
    filename     = "cloud-config.yaml"
    content_type = "text/cloud-config"

    content = file("./files/${var.example}.yaml")
  }
}


resource "yandex_compute_instance_group" "tcp-ig" {
  name               = "tcp"
  folder_id          = var.folder_id
  service_account_id = yandex_iam_service_account.ig_sa.id
  instance_template {
    platform_id = "standard-v3"
    resources {
      memory = 2
      cores  = 2
    }
    boot_disk {
      mode = "READ_WRITE"
      initialize_params {
        image_id = data.yandex_compute_image.echo.id
        size     = 33
      }
    }
    network_interface {
      network_id = yandex_vpc_network.ig.id
      subnet_ids = [for s in yandex_vpc_subnet.ig : s.id]
    }
    metadata = {
      ssh-keys  = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
      user-data = cloudinit_config.config.rendered
    }
    network_settings {
      type = "STANDARD"
    }
  }

  scale_policy {
    fixed_scale {
      size = 1
    }
  }

  allocation_policy {
    zones = ["ru-central1-a"]
  }

  deploy_policy {
    max_unavailable = 2
    max_creating    = 2
    max_expansion   = 2
    max_deleting    = 2
  }

  dynamic "load_balancer" {
    for_each = var.example == "nlb" ? [1] : []
    content {
      target_group_name = "nlb-targer"
    }
  }

  dynamic "application_load_balancer" {
    for_each = var.example == "alb-l3" ? [1] : []
    content {
      target_group_name = "alb-target-l3"
    }
  }
  dynamic "application_load_balancer" {
    for_each = var.example == "alb-l7" ? [1] : []
    content {
      target_group_name = "alb-target-l7"
    }
  }

  depends_on = [
    yandex_iam_service_account.ig_sa,
    yandex_resourcemanager_folder_iam_binding.ig_sa
  ]
  lifecycle {
    replace_triggered_by = [
      cloudinit_config.config
    ]
  }
}