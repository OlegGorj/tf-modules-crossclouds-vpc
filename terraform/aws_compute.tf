/*
 * Terraform compute resources for AWS.
 */

 module "ssh_key_pair" {
   source    = "git::https://github.com/OlegGorj/tf-modules-aws-key-pair.git?ref=dev-branch"
   namespace = "namespace"
   stage     = "dev"
   name      = "vm-ssh-key"
   ssh_public_key_path   = "/Users/oleggorj/Downloads/"
   generate_ssh_key      = "true"
   private_key_extension = ".pem"
   public_key_extension  = ".pub"
   chmod_command         = "chmod 600 %v"
 }

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["${var.aws_disk_image}"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_eip" "aws-ip" {
  vpc = true

  instance                  = "${aws_instance.aws-vm.id}"
  associate_with_private_ip = "${var.aws_vm_address}"
}

resource "aws_instance" "aws-vm" {
  ami           = "${data.aws_ami.ubuntu.id}"
  instance_type = "${var.aws_instance_type}"
  subnet_id     = "${aws_subnet.aws-subnet1.id}"
  key_name      = "vm-ssh-key"

  associate_public_ip_address = true
  private_ip = "${var.aws_vm_address}"

  vpc_security_group_ids = [
    "${aws_security_group.aws-allow-icmp.id}",
    "${aws_security_group.aws-allow-ssh.id}",
    "${aws_security_group.aws-allow-vpn.id}",
    "${aws_security_group.aws-allow-internet.id}",
  ]

  user_data = "${replace("${replace("${file("vm_userdata.sh")}", "<EXT_IP>", "${google_compute_address.gcp-ip.address}")}", "<INT_IP>", "${var.gcp_vm_address}")}"

  tags {
    Name = "aws-vm-${var.aws_region}"
  }
}
