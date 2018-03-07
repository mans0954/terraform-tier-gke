variable "domain" {}
variable "project" {}

resource "google_container_cluster" "primary" {
  name = "tier-cluster"
  zone = "${var.region}"
  initial_node_count = 1
  node_config {
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

resource "google_dns_managed_zone" "tier" {
  name        = "tier"
  dns_name    = "tier.${var.domain}."
  description = "tier.${var.domain} DNS zone"
}

resource "kubernetes_pod" "external-dns" {
  metadata {
    name = "external-dns"
  }

  spec {
    container {
      image = "registry.opensource.zalan.do/teapot/external-dns:v0.4.8"
      name  = "external-dns"
      args  = ["--source=service","--source=ingress","--domain-filter=tier.${var.domain}","--provider=google","--google-project=${var.project}","--registry=txt","--txt-owner-id=terraform"]
    }
  }
}

