output "Controllers:" {
  value = "${packet_device.controller.*.access_public_ipv4}"
}
