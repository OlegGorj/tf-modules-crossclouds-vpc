# vars
variable "name" {}
variable "region" {}
variable "billing_account" {
  description = "The ID of the associated billing account (optional)."
}
variable "org_id" {
  description = "The ID of the Google Cloud Organization."
}
variable "domain" {}
variable "folder" {
  default = ""
}
variable "folder_id" {
  default = ""
}
#variable "credentials_file_path" {}

# resources
#provider "google" {
#  region = "${var.region}"
##  credentials = "${file("${var.credentials_file_path}")}"
#}

data "google_organization" "theorganization" {
  domain = "${var.domain}"
}

resource "random_id" "id" {
  byte_length = 4
  prefix      = "${var.name}-"
}

resource "google_project" "project" {
  name            = "${var.name}"
  project_id      = "${random_id.id.hex}"
  billing_account = "${var.billing_account}"
  folder_id       = "${var.folder_id}"
}

resource "google_project_service" "project_compute_service" {
  project = "${google_project.project.project_id}"
  service = "compute.googleapis.com"
}
#resource "google_project_service" "project_iam_service" {
#  project = "${google_project.project.project_id}"
#  service = "iam.googleapis.com"
#}
#resource "google_project_service" "project_sqladmin_service" {
#  project = "${google_project.project.project_id}"
#  service = "sqladmin.googleapis.com"
#}

# outputs
output "org_id" {
  value = "${data.google_organization.theorganization.id}"
}
output "project_id" {
  value = "${google_project.project.id}"
}
output "name" {
  value = "${google_project.project.name}"
}
