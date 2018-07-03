
# vars

variable "name" {}
variable "project" {}
variable "region" {}
variable "network" {}
variable "ip_cidr_range" {}

# resources
resource "google_compute_subnetwork" "subnet" {
  name          = "${var.name}"
  project       = "${var.project}"
  region        = "${var.region}"
  network       = "${var.network}"
  ip_cidr_range = "${var.ip_cidr_range}"
//  depends_on    = ["${var.network}"]
}

# outputs
output "ip_range" {
  value = "${google_compute_subnetwork.subnet.ip_cidr_range}"
}

output "self_link" {
  value = "${google_compute_subnetwork.subnet.self_link}"
}

output "project" {
  value = "${var.project}"
}
