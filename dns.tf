# Set up the tier managed zone
resource "google_dns_managed_zone" "tier" {
  name        = "tier"
  dns_name    = "tier.${var.domain}."
  description = "tier.${var.domain} DNS zone"
}

# Reserve an IP address for comanage
resource "google_compute_address" "comanange-ip" {
  name = "comanage-ip"
}

# Point comanage.tier.<domain> at the reserved IP
resource "google_dns_record_set" "comanage" {
  name = "comanage.${google_dns_managed_zone.tier.dns_name}"
  type = "A"
  ttl  = 300

  managed_zone = "${google_dns_managed_zone.tier.name}"

  rrdatas = ["${google_compute_address.comanange-ip.address}"]
}

output "name_servers" {
  value = "${google_dns_managed_zone.tier.name_servers}"
}

output "ip" {
  value = "${google_compute_address.comanange-ip.address}"
}

