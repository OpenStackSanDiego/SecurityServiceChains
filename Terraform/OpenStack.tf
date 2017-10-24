
resource "null_resource" "openstack" {

  count = "${var.openstack_controller_count}"

  connection {
    host = "${element(packet_device.controller.*.access_public_ipv4, count.index)}"
    private_key = "${file("${var.cloud_ssh_key_path}")}"
  }

  provisioner "file" {
    source      = "OpenStack.sh"
    destination = "OpenStack.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "bash OpenStack.sh > OpenStack.out",
    ]
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
