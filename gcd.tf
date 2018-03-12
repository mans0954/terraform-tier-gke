resource "google_compute_disk" "tier-databases" {
  name  = "tier-databases"
  type  = "pd-ssd"
  zone  = "${var.zone}"
  size  = "1"
}


resource "kubernetes_persistent_volume" "database" {
  metadata {
    name = "database"
  }
  spec {
    capacity {
      storage = "200M"
    }
    access_modes = ["ReadWriteMany"]
    persistent_volume_source {
      gce_persistent_disk {
        pd_name  = "${google_compute_disk.tier-databases.name}"
      } 
    }
  }
}

