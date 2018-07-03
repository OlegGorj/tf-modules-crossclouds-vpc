# Vars
variable "name" {}
variable "project" {}
variable "machine_type" {
  default = "f1-micro"
}
variable "zone" {
  default = ""
}
variable "network" {
}
variable "environment" {
  default = ""
}
variable "startup_script" {
  default = ""
}
variable "automatic_restart" {
  default = true
}
variable "instance_description" {
  default = "Default instance description"
}
variable "tags" {
  type = "list"
  default = [""]
}
variable "ssh_user" {}
variable "ssh_key" {}
variable "ssh_private_key_file" {}


# Resources
data "google_compute_image" "cos_cloud" {
  family = "cos-stable"
  project = "cos-cloud"
}
resource "google_compute_instance" "instance" {
  description = "description assigned to instances"

  name         = "${var.name}"
  project      = "${var.project}"
  machine_type = "${var.machine_type}"
  zone         = "${var.zone}"

  boot_disk {
    initialize_params {
      image = "${data.google_compute_image.cos_cloud.self_link}"
    }
  }
  metadata_startup_script = "${var.startup_script}"
  network_interface {
    network = "${var.network}"
    access_config {
      // Ephemeral IP
    }
  }

  service_account {
    scopes = ["https://www.googleapis.com/auth/compute.readonly", "storage-ro"]
  }

  metadata {
    ssh-keys = "${var.ssh_user}:${file("${var.ssh_key}")}"
  }

  labels {
    environment   = "${var.environment}"
    machine_type  = "${var.machine_type}"
  }

  tags = "${var.tags}"

  scheduling {
    automatic_restart   = "${var.automatic_restart}"
    on_host_maintenance = "MIGRATE"
  }
}


# Outputs

output "status_page_public_ip" {
  value = "${google_compute_instance.instance.network_interface.0.access_config.0.assigned_nat_ip}"
}
