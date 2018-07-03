
# Vars
variable "name" {}
variable "hostname" {
  default = ""
}
variable "project" {}
variable "zones" {
  type = "list"
}
variable "subnetwork" {}
variable "domain" {}
variable "instance_type" {
  default = "f1-micro"
}

variable "ssh_user" {}
variable "ssh_key" {}
variable "ssh_private_key_file" {}

variable "environment" {
  default = ""
}
variable "instance_description" {
  default = "Bastion instance"
}
variable "tags" {
  type = "list"
}

#data "google_compute_image" "cos_cloud" {
#  family = "cos-stable"
#  project = "cos-cloud"
#}

# main.tf
resource "google_compute_instance" "bastion" {
  name         = "${var.name}"
  project      = "${var.project}"
  machine_type = "${var.instance_type}"
  zone         = "${element(var.zones, 0)}"

  boot_disk {
    initialize_params {
      #image = "${data.google_compute_image.cos_cloud.self_link}"
      image = "ubuntu-1604-lts"
    }
  }
#  boot_disk {
#    initialize_params {
#      image = "${var.image}"
#    }
#  }

  network_interface {
    subnetwork = "${var.subnetwork}"
    access_config {
      # Ephemeral IP - leaving this block empty will generate a new external IP and assign it to the machine
    }
  }

  service_account {
     scopes = ["userinfo-email", "compute-ro", "storage-ro"]
  }

  metadata {
    ssh-keys = "${var.ssh_user}:${file("${var.ssh_key}")}"
    myid = "${count.index}"
    domain = "${var.domain}"
    subnetwork = "${var.subnetwork}"
#    hostname = "vpn.${var.environment}.${var.domain}"
  }
  # define default connection for remote provisioners
  connection {
    type = "ssh"
    user = "${var.ssh_user}"
    private_key = "${file(var.ssh_private_key_file)}"
  }
  # install haproxy, docker, openvpn, and configure the node
  provisioner "file" {
      source      = "${path.module}/scripts/sethostname.sh"
      destination = "/tmp/sethostname.sh"
  }
  provisioner "remote-exec" {
  inline = [
      "chmod +x /tmp/sethostname.sh",
      "/tmp/sethostname.sh ${var.hostname}",
    ]
  }
  
  provisioner "remote-exec" {
  scripts = [
      "${path.module}/scripts/common_install_ubuntu.sh",
      "${path.module}/scripts/deploy_docker_openvpn.sh",
      "${path.module}/scripts/haproxy_install.sh"
    ]
  }
  tags = "${var.tags}"
}

# Outputs
output "private_ip" {
  value = "${google_compute_instance.bastion.network_interface.0.address}"
}
output "public_ip" {
  value = "${google_compute_instance.bastion.network_interface.0.access_config.0.assigned_nat_ip}"
}
