resource "null_resource" "public_network" {
  count = "${var.openstack_controller_count}"

  depends_on = [ "null_resource.openstack" ]

  connection {
    host = "${element(packet_device.controller.*.access_public_ipv4, count.index)}"
    private_key = "${file("${var.cloud_ssh_key_path}")}"
  }

  provisioner "file" {
    source      = "PublicNetwork.sh"
    destination = "PublicNetwork.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "bash PublicNetwork.sh"
    ]
  }
}
