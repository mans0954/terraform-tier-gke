variable "domain" {}
variable "project" {}
variable "zone" {}

resource "google_container_cluster" "primary" {
  name = "tier-cluster"
  zone = "${var.zone}"
  initial_node_count = 3
  node_config {
    machine_type = "n1-standard-2"
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/ndev.clouddns.readwrite"
    ]
  }
}

provider "kubernetes" {
  host     = "${google_container_cluster.primary.endpoint}"
  client_certificate     = "${base64decode(google_container_cluster.primary.master_auth.0.client_certificate)}"
  client_key             = "${base64decode(google_container_cluster.primary.master_auth.0.client_key)}"
  cluster_ca_certificate = "${base64decode(google_container_cluster.primary.master_auth.0.cluster_ca_certificate)}"
}


