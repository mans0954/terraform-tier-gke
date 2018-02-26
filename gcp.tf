variable "region" {
  default = "europe-west2-a"
}

provider "google" {
  credentials = "${file("~/.config/gcloud/terraform-admin.json")}"
  region      = "${var.region}"
}

