terraform {
 backend "gcs" {
   prefix      = "/terraform.tfstate"
   credentials = "~/.config/gcloud/terraform-admin.json"
 }
}
