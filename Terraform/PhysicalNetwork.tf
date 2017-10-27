resource "null_resource" "physical_network" {
  count = "${var.openstack_controller_count}"

  depends_on = [ "null_resource.openstack",
                 "null_resource.cloud_images",
                 "null_resource.public_network",
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
    command = "sleep 60"
  }

  # wait until port 22 (SSH) comes back online
  provisioner "local-exec" {
    command = "until nc -vzw 5 ${element(packet_device.controller.*.access_public_ipv4, count.index)} 22 2> /dev/null; do sleep 60 ; echo 'waiting for SSH port post reboot'; done"
  }

  # wait for OpenStack services which take longer than SSH to restart
  provisioner "local-exec" {
    command = "sleep 30"
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
