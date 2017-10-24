resource "null_resource" "physical_network" {
  count = "${var.openstack_controller_count}"

  depends_on = [ "null_resource.openstack",
                 "null_resource.cloud_images",
                 "null_resource.public_network",
                 "null_resource.server_alias",
                 "null_resource.service_chain" ]

  connection {
    host = "${element(packet_device.controller.*.access_public_ipv4, count.index)}"
    private_key = "${file("${var.cloud_ssh_key_path}")}"
  }

  provisioner "file" {
    source      = "PhysicalNetwork.sh"
    destination = "PhysicalNetwork.sh"
  }

  # includes a system reboot
  provisioner "remote-exec" {
    inline = [
      "bash PhysicalNetwork.sh > PhysicalNetwork.out",
    ]
  }

  # wait for reboot
  provisioner "local-exec" {
    command = "sleep 90"
  }

  # wait until it comes back online
  provisioner "local-exec" {
    command = "until ping -c1 ${element(packet_device.controller.*.access_public_ipv4, count.index)} &>/dev/null; do :; done"
  }

  # wait for SSH restart
  provisioner "local-exec" {
    command = "sleep 60"
  }

  provisioner "file" {
    source      = "WaitForOpenStackServices.sh"
    destination = "WaitForOpenStackServices.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "bash WaitForOpenStackServices.sh"
    ]
  }
}
