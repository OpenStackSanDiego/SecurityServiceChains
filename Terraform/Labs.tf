resource "null_resource" "labs" {
  count = "${var.openstack_controller_count}"

  depends_on = [ "null_resource.openstack",
                 "null_resource.physical_network" ]

  connection {
    host = "${element(packet_device.controller.*.access_public_ipv4, count.index)}"
    private_key = "${file("${var.cloud_ssh_key_path}")}"
  }

  provisioner "file" {
    source      = "Labs.sh"
    destination = "Labs.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "bash Labs.sh > Labs.out",
    ]
  }
}
