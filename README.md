# Terraform TIER components to Google Cloud

This terraform deploys TIER components to Google Kubernetes Engine.

# AWS as domain registrar

```
sudo apt install jq
aws iam create-user --user-name terraform-`hostname`
## aws iam attach-user-policy --user-name terraform --policy-arn arn:aws:iam::aws:policy/AmazonRoute53DomainsFullAccess
aws iam attach-user-policy --user-name terraform-`hostname` --policy-arn arn:aws:iam::aws:policy/AmazonRoute53ReadOnlyAccess
aws iam attach-user-policy --user-name terraform-`hostname` --policy-arn arn:aws:iam::aws:policy/AmazonRoute53AutoNamingFullAccess
export AWS_SHARED_CREDENTIALS_FILE=~/.aws/tf_credentials
aws iam create-access-key --user-name terraform-`hostname` | jq -r '.AccessKey | "["+.UserName+"]\naws_access_key_id = "+.AccessKeyId+"\naws_secret_access_key = "+.SecretAccessKey+"\n"' >> $AWS_SHARED_CREDENTIALS_FILE
```

N.B. Both the aws cli and the terraform provider use the AWS_SHARED_CREDENTIALS_FILE variable
to find shared credentials file. Might be better just to leave it to the default!

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
Further roles for configuring DNS and IP:
```
gcloud projects add-iam-policy-binding ${GOOGLE_PROJECT} --member serviceAccount:terraform@${GOOGLE_PROJECT}.iam.gserviceaccount.com --role roles/dns.admin
gcloud projects add-iam-policy-binding ${GOOGLE_PROJECT} --member serviceAccount:terraform@${GOOGLE_PROJECT}.iam.gserviceaccount.com --role roles/compute.networkAdmin
```
Roles for storage:
```
gcloud projects add-iam-policy-binding ${GOOGLE_PROJECT} --member serviceAccount:terraform@${GOOGLE_PROJECT}.iam.gserviceaccount.com --role roles/compute.storageAdmin
```


Note, you can find out which roles grant a particular permission by searching for the permission at https://console.cloud.google.com/iam-admin/roles

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
aws_region = "eu-west-2"
gcp_region = "europe-west2"
zone = "europe-west2-a"
project = "<user>-terraform-tier"
aws_profile = "terraform-squash"
```

(unfortunately there doesn't appear to be a straight-forward way to get Terraform to read $GOOGLE_PROJECT).

# Terraform Helm

```
wget https://github.com/mcuadros/terraform-provider-helm/releases/download/v0.4.0/terraform-provider-helm_v0.4.0_linux_amd64.tar.gz
tar -xvf terraform-provider-helm*.tar.gz
mkdir -p ~/.terraform.d/plugins/
mv terraform-provider-helm*/terraform-provider-helm ~/.terraform.d/plugins/
terraform init --backend-config="bucket=${GOOGLE_PROJECT}" --backend-config="project=${GOOGLE_PROJECT}"
```

# Make Helm repo

```
helm package <path to chart>
helm repo index .
```

# Testing

```
curl -H 'Host:comanage.tier.cshoskin.net' x.x.x.x
```
where x.x.x.x is the fixed IP address passed as an annotation to the ingress controller.

Should return the default Debian Apache page (as comanage is actually at /registry)

This can be found with:
```
kubectl get ingress comanage
```

# Notes

Note we configure the cluster with the `https://www.googleapis.com/auth/ndev.clouddns.readwrite` scope so that the external-dns pod can modify the DNS. Presumably this means that any pod in the cluster could modify the DNS. Is this a concern?

# References

* https://cloud.google.com/community/tutorials/managing-gcp-projects-with-terraform
