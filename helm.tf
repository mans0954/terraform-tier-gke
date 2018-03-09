resource "helm_repository" "mans0954" {
    name = "mans0954"
    url  = "https://mans0954.github.io/helm-repo/"
}


resource "helm_release" "comanage" {
	name	= "comanage"
	chart	= "mans0954/comanage"
}
