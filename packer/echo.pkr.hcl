variable "folder_id" {
  type    = string
  default = "${env("YC_FOLDER_ID")}"
}

variable "subnet_id" {
  type    = string
  default = "${env("YC_BUILD_SUBNET")}"
}

locals { timestamp = regex_replace(timestamp(), "[- TZ:]", "") }

source "yandex" "echo" {
  disk_size_gb         = 32
  disk_type            = "network-ssd"
  folder_id            = var.folder_id
  image_description    = "Echo server"
  image_family         = "echo"
  image_name           = "echo-${local.timestamp}"
  source_image_family  = "ubuntu-2404-lts-oslogin"
  ssh_username         = "ubuntu"
  subnet_id            = var.subnet_id
  use_ipv4_nat         = true
  zone                 = "ru-central1-a"
}

build {
  sources = ["source.yandex.echo"]

  provisioner "shell" {
    scripts = ["install.sh"]
  }
}
