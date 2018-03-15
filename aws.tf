variable "aws_region" {
  default = "eu-west-2"
}

provider "aws" {
  profile    = "terraform"
  region     = "${var.aws_region}"
}

data "aws_route53_zone" "selected" {
  name = "${var.domain}."
}
