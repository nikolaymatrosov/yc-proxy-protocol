resource "yandex_iam_service_account" "ig_sa" {
  name      = "ig-sa"
  folder_id = var.folder_id
}

resource "yandex_resourcemanager_folder_iam_binding" "ig_sa" {
  for_each = toset([
    "compute.admin",
    "vpc.admin",
    "load-balancer.admin",
    "alb.admin",
  ])
  role      = each.value
  folder_id = var.folder_id
  members   = [
    "serviceAccount:${yandex_iam_service_account.ig_sa.id}",
  ]
}