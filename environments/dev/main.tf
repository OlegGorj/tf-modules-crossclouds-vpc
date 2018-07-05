# vars
variable "env" {
}
variable "region" {
}
variable "billing_account" {
}
variable "org_id" {
}
variable "credentials_file_path" {
  default = ""
}
variable "tf_ssh_key" {
  default = ""
}
variable "tf_ssh_private_key_file"{
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
variable "devops_net_cidr" {
  default = "10.10.0.0/20"
}
variable "devops_northamerica_northeast1_subnet1_cidr" {
  default = "10.10.0.0/24"
}
variable "devops_northamerica_northeast1_region" {
  default = "northamerica-northeast1"
}
variable "region_zones" {
  type = "list"
  default = ["northamerica-northeast1-a"]
}


###############################################################################
# RESOURCES
###############################################################################
provider "google" {
  region = "${var.region}"
#  credentials = "${file("${var.credentials_file_path}")}"
}
#resource "google_storage_bucket_acl" "image-store-acl" {
#  bucket = "${google_storage_bucket.blue-world-tf-state.name}"
#  predefined_acl = "publicreadwrite"
#}

resource "google_compute_shared_vpc_host_project" "host_project" {
  project    = "${var.admin_project}"
}

module "devops_project_1" {
  source          = "../../modules/project"
  name            = "service-prj-1-${var.env}"
  region          = "${var.region}"
  billing_account = "${var.billing_account}"
  org_id          = "${var.org_id}"
  folder_id       = "${var.g_folder_id}"
  domain          = "${var.domain}"
}
# Enable shared VPC in the two service projects and services need to be enabled on all new projects
# Service project #1
resource "google_project_services" "devops_project_1" {
  project = "${module.devops_project_1.project_id}"
#  service = "compute.googleapis.com"
  services = [
    "iam.googleapis.com",
    "compute-component.googleapis.com",
    "container.googleapis.com",
    "servicemanagement.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "storage-api.googleapis.com",
    "dns.googleapis.com",
    "oslogin.googleapis.com"
  ]
}
resource "google_compute_shared_vpc_service_project" "devops_project_1" {
  host_project    = "${var.admin_project}"
  service_project = "${module.devops_project_1.project_id}"
  depends_on = [
    "module.devops_project_1"
  ]
}

# Service project #2
module "devops_project_2" {
  source          = "../../modules/project"
  name            = "service-prj-2-${var.env}"
  region          = "${var.region}"
  billing_account = "${var.billing_account}"
  org_id          = "${var.org_id}"
  folder_id       = "${var.g_folder_id}"
  domain = "${var.domain}"
}
resource "google_project_service" "devops_project_2" {
  project = "${module.devops_project_2.project_id}"
  service = "compute.googleapis.com"
}
resource "google_compute_shared_vpc_service_project" "devops_project_2" {
  host_project    = "${var.admin_project}"
  service_project = "${module.devops_project_2.project_id}"

  depends_on = [
    "module.devops_project_2"
  ]
}


#module "devops_shared_network" {
#  source                    = "../../modules/network/compute_network"
#  name                      = "devops-shared-network"
#  project                   = "${var.admin_project}"
#  auto_create_subnetworks   = "false"
#  ip_cidr_range             = "${var.devops_net_cidr}"
#}
resource "google_compute_network" "devops_shared_network" {
  name                    = "devops-shared-network"
#  auto_create_subnetworks = "false"
  project                 = "${var.admin_project}"
#  ipv4_range              = "${var.devops_net_cidr}"
}

module "devops_northamerica_northeast1_subnet1" {
  source          = "../../modules/network/subnet"
  name            = "${var.env}-${var.devops_northamerica_northeast1_region}-devops-subnet1"
  project         = "${var.admin_project}"
  region          = "${var.devops_northamerica_northeast1_region}"
  network         = "${google_compute_network.devops_shared_network.self_link}"
  ip_cidr_range   = "${var.devops_northamerica_northeast1_subnet1_cidr}"
}


# Allow access DevOPS network only bastion instances  and limited source range
resource "google_compute_firewall" "devops_deploymentrange_sshport_bastion_fw" {
  name    = "allow-deploymentrange-sshport-bastion"
  network = "${google_compute_network.devops_shared_network.self_link}"
  project = "${google_compute_network.devops_shared_network.project}"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["${var.source_ranges_ips}"]

  target_tags = ["bastion", "vpn"]
}


resource "google_compute_firewall" "devops_network_https_bastion_fw" {
  name    = "allow-all-httpsports-bastion"
  network = "${google_compute_network.devops_shared_network.self_link}"
  project = "${google_compute_network.devops_shared_network.project}"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["443", "80", "8080", "8443"]
  }

  source_ranges = ["0.0.0.0/0"]

  target_tags = ["bastion"]
}


module "bastion_instance" {
  source                = "../../modules/network/bastion"
  name                  = "vpn-${var.env}-instance"
  hostname              = "vpn.${var.env}.${var.domain}"
  project               = "${google_compute_network.devops_shared_network.project}"
  zones                 = "${var.region_zones}"
  subnetwork            = "${module.devops_northamerica_northeast1_subnet1.self_link}"
  ssh_user              = "ubuntu"
  ssh_key               = "${var.tf_ssh_key}"
  ssh_private_key_file  = "${var.tf_ssh_private_key_file}"
  environment           = "${var.env}"
  domain                = "${var.domain}"
  tags                  = ["bastion", "vpn", "${var.env}"]
}

# allow ssh access to other instances only from bastion
resource "google_compute_firewall" "devops_network_internal_fw" {
  name    = "allow-all-internal-devops-shared-network"
  network = "${google_compute_network.devops_shared_network.self_link}"
  project = "${google_compute_network.devops_shared_network.project}"

  allow {
      protocol = "tcp"
      ports = ["1-65535"]
  }
  allow {
      protocol = "udp"
      ports = ["1-65535"]
  }
  allow {
      protocol = "icmp"
  }

  source_ranges = ["${module.devops_northamerica_northeast1_subnet1.ip_range}"]
}

# allow 22 port to all instances with tag `devops`
resource "google_compute_firewall" "devops_network_sshvpn_fw" {
  name    = "allow-sshvpn-devops-shared-network"
  network = "${google_compute_network.devops_shared_network.self_link}"
  project = "${google_compute_network.devops_shared_network.project}"

  allow {
      protocol = "icmp"
  }
  allow {
      protocol = "tcp"
      ports = ["22"]
  }

  target_tags = ["devops"]
  source_ranges = ["0.0.0.0/0"]
}

# open admin ports to manage openvpn
resource "google_compute_firewall" "devops_network_adminports_openvpn_fw" {
  name    = "allow-adminports-bastion-fw"
  network = "${google_compute_network.devops_shared_network.self_link}"
  project = "${google_compute_network.devops_shared_network.project}"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["8080", "943", "9443"]
  }
  allow {
    protocol = "udp"
    ports    = ["1194", "943"]
  }

  source_ranges = ["0.0.0.0/0"]

  target_tags = ["bastion", "vpn", "openvpn"]
}

#
# DNS
#
# TODO: move DNS zones part to AWS
#
resource "google_dns_managed_zone" "dns-zone" {
  name        = "dns-managed-zone"
  dns_name    = "${var.domain}."
  description = "DNS zone"
  project     = "${var.admin_project}"
}

resource "google_dns_record_set" "dev-dns-zone" {
  project       = "${var.admin_project}"
  name          = "vpn.dev.${google_dns_managed_zone.dns-zone.dns_name}"
  type          = "A"
  ttl           = 300
  managed_zone  = "${google_dns_managed_zone.dns-zone.name}"
  rrdatas       = ["${module.bastion_instance.public_ip}"]
}


## Create VM instances for each project
## Instance #1
module "devops_instance_vm1" {
  source                = "../../modules/instance/compute"
  name                  = "devops-instance-vm1"
  project               = "${google_compute_network.devops_shared_network.project}"
  zone                  = "${element(var.region_zones, 0)}"
  network               = "${google_compute_network.devops_shared_network.self_link}"
  startup_script        = "VM_NAME=VM1\n${file("../../modules/instance/compute/scripts/install_vm.sh")}"
  tags                  = ["devops", "${var.env}", "apache2"]
  environment           = "${var.env}"
  instance_description  = "VM Instance dedicated to Devops"
  ssh_user              = "ubuntu"
  ssh_key               = "${var.tf_ssh_key}"
  ssh_private_key_file  = "${var.tf_ssh_private_key_file}"
}

## Instance #2 - ngnix on docker
#data "template_file" "docker_init_script" {
#  template = "${file("${path.module}/../../modules/instance/compute/scripts/docker_install.sh")}"
#  vars {
#      TERRAFORM_user      = "ubuntu"
#  }
#}
#data "template_file" "ngnix_init_script" {
#  template = "${file("${path.module}/../../modules/instance/compute/scripts/ngnix_install.sh")}"
#  vars {
#      TERRAFORM_user      = "ubuntu"
#  }
#}
#data "template_file" "ngnix_init_cc_config" {
#  template = "${file("${path.module}/../../modules/instance/compute/scripts/ngnix_install.yml")}"
#  vars {
#      TERRAFORM_user      = "ubuntu"
#  }
#}
#data "template_cloudinit_config" "webserver_init" {
#  part {
#    content_type = "text/x-shellscript"
#    content      = "${data.template_file.ngnix_init_script.rendered}"
#  }
#}
#data "template_cloudinit_config" "ngnix_init" {
#  gzip          = false
#  base64_encode = false
#
#  part {
#    filename     = "ngnix_install.yml"
#    content_type = "text/cloud-config"
#    content    = "${data.template_file.ngnix_init_cc_config.rendered}"
#  }
#}
#module "devops_instance_vm2" {
#  source                = "../../modules/instance/compute"
#  name                  = "devops-instance-vm2"
#  project               = "${module.devops_project_2.project_id}"
#  zone                  = "${element(var.region_zones, 0)}"
#  network               = "${module.devops_shared_network.self_link}"
##  startup_script        = "TERRAFORM_user=ubuntu\n${file("${path.module}/../../modules/instance/compute/scripts/docker_install.sh")}\n${file("${path.module}/../../modules/instance/compute/scripts/ngnix_install.sh")}"
##  startup_script        = "${data.template_cloudinit_config.ngnix_init.rendered}"
#  startup_script        = "TERRAFORM_user=ubuntu\n${file("${path.module}/../../modules/instance/compute/scripts/ngnix_install.sh")}"
#  tags         = ["devops", "ngnix", "ubuntu-1604", "${var.env}", "docker"]
#  environment           = "${var.env}"
#  instance_description  = "VM Instance dedicated to Devops"
#}


##
