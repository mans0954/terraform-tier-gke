# Terraform TIER components to Google Cloud

This terraform deploys TIER components to Google Kubernetes Engine.

# Google Cloud Project for Terraform

Note - this is all getting a bit confusing. Think I'll start again with something simpler.

Following https://cloud.google.com/community/tutorials/managing-gcp-projects-with-terraform we'll manually create a GCP project to hold a service account for Terraform to use and a cloud storage bucket to store the Terraform state. The project will be called `${USER}-terraform-admin` (GCP project names have to be globally unique, hopefully the ${USER} will acheive this).

If not already done, install and initialise the SDK https://cloud.google.com/sdk/. Either create a new project `${USER}-terraform-admin` as part of initialisation or if already initialised, run

```
gcloud projects create ${USER}-terraform-admin
```
Create a service account called `terraform` in the `${USER}-terraform-admin` project for Terraform to use:
```
gcloud iam service-accounts create terraform --display-name "Terraform admin account" --project ${USER}-terraform-admin
```
Create a local JSON file to allow Terraform to authenticate:
```
gcloud iam service-accounts keys create ~/.config/gcloud/terraform-admin.json --iam-account terraform@${USER}-terraform-admin.iam.gserviceaccount.com
```
Since this stuff costs money, the project needs to be linked to a billing account:
```
gcloud beta billing projects link ${USER}-terraform-admin --billing-account {insert your billing account no here}
```
Grant the service account permission to view the Admin Project and manage Cloud Storage:
```
gcloud projects add-iam-policy-binding ${USER}-terraform-admin --member serviceAccount:terraform@${USER}-terraform-admin.iam.gserviceaccount.com --role roles/viewer
gcloud projects add-iam-policy-binding ${USER}-terraform-admin --member serviceAccount:terraform@${USER}-terraform-admin.iam.gserviceaccount.com --role roles/storage.admin
```
Create a storage bucket under `${USER}-terraform-admin`, with URL `gs://${USER}-terraform-admin` and enable versioning.
```
gsutil mb -p ${USER}-terraform-admin gs://${USER}-terraform-admin
gsutil versioning set on gs://${USER}-terraform-admin
```
Enable the cloud resource manager API
```
gcloud services enable cloudresourcemanager.googleapis.com --project ${USER}-terraform-admin
```

Initialise Terraform
```
terraform init --backend-config="bucket=${USER}-terraform-admin" --backend-config="project=${USER}-terraform-admin"
```



# Set up

Using the Web interface:

* Log into https://console.cloud.google.com/ and create a project (from the drop down on the top bar)
* Select `IAM & admin` (on the left hand menu)
* Under `IAM` and a new member, and give it the role `Kubernetes Engine Cluster Admin`
* Save the Json Web token as accounts.json

Using the Google Cloud SDK


* 
```
gcloud iam service-accounts create tier-terraform
gcloud projects add-iam-policy-binding kubernetes-195711 --member serviceAccount:tier-terraform@kubernetes-195711.iam.gserviceaccount.com --role roles/container.clusterAdmin
gcloud iam service-accounts keys create account.json --iam-account=tier-terraform@kubernetes-195711.iam.gserviceaccount.com
```
