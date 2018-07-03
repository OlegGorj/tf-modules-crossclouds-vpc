# vars
variable "env" {
  default = "test"
}
variable "region" {
}
variable "region_zone" {
}
variable "billing_account" {
}
variable "org_id" {
}
variable "credentials_file_path" {
  default = ""
}
variable "domain" {
}
variable "admin_project" {
}
variable "g_folder" {
  default = ""
}
variable "g_folder_id" {
  default = ""
}
variable "source_ranges_ips" {
  default = ""
}

###############################################################################
# RESOURCES
###############################################################################

module "service_1_project" {
  source          = "../../modules/project"
  name            = "service-prj-1-${var.env}"
  region          = "${var.region}"
  billing_account = "${var.billing_account}"
  org_id          = "${var.org_id}"
  folder_id       = "${var.g_folder_id}"
  domain          = "${var.domain}"
}

module "service_2_project" {
  source          = "../../modules/project"
  name            = "service-prj-2-${var.env}"
  region          = "${var.region}"
  billing_account = "${var.billing_account}"
  org_id          = "${var.org_id}"
  folder_id       = "${var.g_folder_id}"
  domain = "${var.domain}"
}

resource "google_compute_shared_vpc_host_project" "host_project" {
  project    = "${var.admin_project}"
}

# Enable shared VPC in the two service projects and services need to be enabled on all new projects
# Service project #1
resource "google_project_service" "service_1_project" {
  project = "${module.service_1_project.project_id}"
  service = "compute.googleapis.com"
}
resource "google_compute_shared_vpc_service_project" "service_1_project" {
  host_project    = "${var.admin_project}"
  service_project = "${module.service_1_project.project_id}"

  depends_on = [
    "module.service_1_project"
  ]
}

# Service project #2
resource "google_project_service" "service_2_project" {
  project = "${module.service_2_project.project_id}"
  service = "compute.googleapis.com"
}
resource "google_compute_shared_vpc_service_project" "service_2_project" {
  host_project    = "${var.admin_project}"
  service_project = "${module.service_2_project.project_id}"

  depends_on = [
    "module.service_2_project"
  ]
}

# Create the hosted network.
resource "google_compute_network" "admin_shared_network" {
  name                    = "shared-network"
  auto_create_subnetworks = "true"
  project                 = "${var.admin_project}"

  depends_on = [
    "module.service_1_project",
    "module.service_2_project"
  ]
}

# Allow the hosted network to be hit over ICMP, SSH, and HTTP.
resource "google_compute_firewall" "admin_shared_network" {
  name    = "allow-ssh-icmp-http"
  network = "${google_compute_network.admin_shared_network.self_link}"
  project = "${google_compute_network.admin_shared_network.project}"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22", "80"]
  }
  source_ranges = ["${var.source_ranges_ips}"]
}

# Create VM instances for each project
# Instance #1
module "devops_instance_vm1" {
  source                = "../../modules/instance/compute"
  name                  = "devops-instance-vm1"
  project               = "${module.service_1_project.project_id}"
  zone                  = "${var.region_zone}"
  network               = "${google_compute_network.admin_shared_network.self_link}"
  startup_script        = "VM_NAME=VM1\n${file("../../modules/instance/compute/scripts/install_vm.sh")}"
  instance_tags         = ["devops", "debian-8", "${var.env}", "apache2"]
  environment           = "${var.env}"
  instance_description  = "VM Instance dedicated to Devops"
}

# Instance #2 - ngnix on docker
data "template_file" "docker_init_script" {
  template = "${file("${path.module}/../../modules/instance/compute/scripts/docker_install.sh")}"
  vars {
      TERRAFORM_user      = "ubuntu"
  }
}
data "template_file" "ngnix_init_script" {
  template = "${file("${path.module}/../../modules/instance/compute/scripts/ngnix_install.sh")}"
  vars {
      TERRAFORM_user      = "ubuntu"
  }
}
data "template_file" "ngnix_init_cc_config" {
  template = "${file("${path.module}/../../modules/instance/compute/scripts/ngnix_install.yml")}"
  vars {
      TERRAFORM_user      = "ubuntu"
  }
}
data "template_cloudinit_config" "webserver_init" {
  part {
    content_type = "text/x-shellscript"
    content      = "${data.template_file.ngnix_init_script.rendered}"
  }
}
data "template_cloudinit_config" "ngnix_init" {
  gzip          = false
  base64_encode = false

  part {
    filename     = "ngnix_install.yml"
    content_type = "text/cloud-config"
    content    = "${data.template_file.ngnix_init_cc_config.rendered}"
  }
}
module "devops_instance_vm2" {
  source                = "../../modules/instance/compute"
  name                  = "devops-instance-vm2"
  project               = "${module.service_2_project.project_id}"
  zone                  = "${var.region_zone}"
  network               = "${google_compute_network.admin_shared_network.self_link}"
#  startup_script        = "TERRAFORM_user=ubuntu\n${file("${path.module}/../../modules/instance/compute/scripts/docker_install.sh")}\n${file("${path.module}/../../modules/instance/compute/scripts/ngnix_install.sh")}"
#  startup_script        = "${data.template_cloudinit_config.ngnix_init.rendered}"
  startup_script        = "TERRAFORM_user=ubuntu\n${file("${path.module}/../../modules/instance/compute/scripts/ngnix_install.sh")}"
  instance_tags         = ["devops", "ngnix", "ubuntu-1604", "${var.env}", "docker"]
  environment           = "${var.env}"
  instance_description  = "VM Instance dedicated to Devops"
}


##
