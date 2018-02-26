variable "region" {
  default = "europe-west2-a"
}

provider "google" {
  region      = "${var.region}"
}

