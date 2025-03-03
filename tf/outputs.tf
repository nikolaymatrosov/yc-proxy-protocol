locals {
  bastion_ip=yandex_compute_instance.bastion.network_interface[0].nat_ip_address
  ig_ip=yandex_compute_instance_group.tcp-ig.instances[0].network_interface[0].ip_address
}

output "bastion" {
  value = "ssh -A -J ubuntu@${local.bastion_ip} ubuntu@${local.ig_ip}"
}

