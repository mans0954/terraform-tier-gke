resource "google_container_cluster" "primary" {
  name = "tier-cluster"
  zone = "${var.region}"
  initial_node_count = 1
}
