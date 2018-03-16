variable "aws_region" {
  default = "eu-west-2"
}

variable "aws_profile" {}

provider "aws" {
  profile    = "${var.aws_profile}"
  region     = "${var.aws_region}"
}

data "aws_route53_zone" "selected" {
  name = "${var.domain}."
}

resource "aws_route53_record" "tier" {
  zone_id = "${data.aws_route53_zone.selected.zone_id}"
  name    = "tier.${data.aws_route53_zone.selected.name}"
  type    = "NS"
  ttl     = "300"
  records = ["${google_dns_managed_zone.tier.name_servers}"]
}
