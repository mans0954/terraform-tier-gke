# Terraform TIER components to Google Cloud

This terraform deploys TIER components to Google Kubernetes Engine.

# Google Cloud Project for Terraform

Start by seting a name for the project and a location for the credentials. These can be what you like, but the project name must be globally unique.

```
export GOOGLE_PROJECT=${USER}-terraform-tier
export GOOGLE_APPLICATION_CREDENTIALS=~/.config/gcloud/terraform-tier.json
```
If not already done, install and initialise the SDK https://cloud.google.com/sdk/.
Create the project:
```
gcloud projects create ${GOOGLE_PROJECT}
```
Create a service account called `terraform` in the `${GOOGLE_PROJECT}` project for Terraform to use:
```
gcloud iam service-accounts create terraform --display-name "Terraform admin account" --project ${GOOGLE_PROJECT}
```
Create a local JSON file to allow Terraform to authenticate:
```
gcloud iam service-accounts keys create ${GOOGLE_APPLICATION_CREDENTIALS} --iam-account terraform@${GOOGLE_PROJECT}.iam.gserviceaccount.com
```
Since some of this stuff costs money, the project needs to be linked to a billing account. To see a list of billing accounts, run `gcloud alpha billing accounts list`
```
gcloud beta billing projects link ${GOOGLE_PROJECT} --billing-account {insert your billing account no here}
```
Create a storage bucket under `${GOOGLE_PROJECT}`, with URL `gs://${GOOGLE_PROJECT}` and enable versioning.
```
gsutil mb -p ${GOOGLE_PROJECT} gs://${GOOGLE_PROJECT}
gsutil versioning set on gs://${GOOGLE_PROJECT}
```
Give the `terraform` service account the rights to administer storage:
```
gcloud projects add-iam-policy-binding ${GOOGLE_PROJECT} --member serviceAccount:terraform@${GOOGLE_PROJECT}.iam.gserviceaccount.com --role roles/storage.admin
```
Enable the GKE API for this project, and give the `terraform` service account permission to use it
```
gcloud services enable container.googleapis.com --project ${GOOGLE_PROJECT}
gcloud projects add-iam-policy-binding ${GOOGLE_PROJECT} --member serviceAccount:terraform@${GOOGLE_PROJECT}.iam.gserviceaccount.com --role roles/container.clusterAdmin
```
It seems some further permissions are required:
```
gcloud projects add-iam-policy-binding ${GOOGLE_PROJECT} --member serviceAccount:terraform@${GOOGLE_PROJECT}.iam.gserviceaccount.com --role roles/iam.serviceAccountUser
gcloud projects add-iam-policy-binding ${GOOGLE_PROJECT} --member serviceAccount:terraform@${GOOGLE_PROJECT}.iam.gserviceaccount.com --role roles/viewer
```
Further roles for configuring DNS:
```
gcloud projects add-iam-policy-binding ${GOOGLE_PROJECT} --member serviceAccount:terraform@${GOOGLE_PROJECT}.iam.gserviceaccount.com --role roles/dns.admin
```
# kubectl

Set up your local copy of `kubectl` to be able to interact with the terraform generated cluster
```
gcloud container clusters get-credentials tier-cluster --project=$GOOGLE_PROJECT
```

# Using Terraform
```
terraform init --backend-config="bucket=${GOOGLE_PROJECT}" --backend-config="project=${GOOGLE_PROJECT}"
terraform plan
terraform apply
```
To avoid having to enter variables each time, create a `terraform.tfvars` file e.g.
```
domain = "example.com"
region = "europe-west2-a"
project = "<user>-terraform-tier"
```

(unfortunately there doesn't appear to be a straight-forward way to get Terraform to read $GOOGLE_PROJECT).

# Notes

Note we configure the cluster with the `https://www.googleapis.com/auth/ndev.clouddns.readwrite` scope so that the external-dns pod can modify the DNS. Presumably this means that any pod in the cluster could modify the DNS. Is this a concern?

# References

* https://cloud.google.com/community/tutorials/managing-gcp-projects-with-terraform
