output "gcp_instance_external_ip" {
  value =
"${google_compute_instance.gcp-vm.network_interface.0.access_config.0.assigned_nat_ip}"
}

output "gcp_instance_internal_ip" {
  value = "${google_compute_instance.gcp-vm.network_interface.0.address}"
}

