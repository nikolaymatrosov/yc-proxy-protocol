variable "cloud_id" {
  type = string
}

variable "folder_id" {
  type = string
}

variable "zone" {
  type    = string
  default = "ru-central1-a"
}

variable "example" {
  type    = string
  default = "nlb"
  validation {
    condition     = contains(["nlb", "alb-l3", "alb-l7"], var.example)
    error_message = "Must be either \"nlb\" or \"alb-l3\", or \"alb-l7\"."
  }
}