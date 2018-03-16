provider "helm" {
  version = "~> 0.5.0"
  kubernetes {
    host     = "${google_container_cluster.primary.endpoint}"
    client_certificate     = "${base64decode(google_container_cluster.primary.master_auth.0.client_certificate)}"
    client_key             = "${base64decode(google_container_cluster.primary.master_auth.0.client_key)}"
    cluster_ca_certificate = "${base64decode(google_container_cluster.primary.master_auth.0.cluster_ca_certificate)}"
  }
}

resource "helm_repository" "mans0954" {
    name = "mans0954"
    url  = "https://mans0954.github.io/helm-repo/"
}


resource "helm_release" "comanage" {
  name	= "comanage"
  chart	= "mans0954/comanage"
  version = "0.1.1"
  set {
    name = "ingress.enabled"
    value = "true"
  }
  values = [
<<EOF
ingress:
  hosts:
    - comanage.${var.dns_zone}.${var.domain}
  path: /*
  annotations: {
    kubernetes.io/ingress.global-static-ip-name: ${google_compute_address.comanange-ip.name}
  }

service:
  type: NodePort
EOF
  ]
}
