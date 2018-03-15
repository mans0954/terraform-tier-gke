variable "gcp_region" {
  default = "europe-west2-a"
}

provider "google" {
  region      = "${var.gcp_region}"
}

