
resource "null_resource" "service_chain" {

  count = "${var.openstack_controller_count}"

  depends_on = [ "null_resource.openstack" ]

  connection {
    host = "${element(packet_device.controller.*.access_public_ipv4, count.index)}"
    private_key = "${file("${var.cloud_ssh_key_path}")}"
  }

  provisioner "file" {
    source      = "ServiceChain.sh"
    destination = "ServiceChain.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "bash ServiceChain.sh > ServiceChain.out",
    ]
  }
}
