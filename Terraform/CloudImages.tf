resource "null_resource" "cloud_images" {
  count = "${var.openstack_controller_count}"

  depends_on = [ "null_resource.openstack" ]

  connection {
    host = "${element(packet_device.controller.*.access_public_ipv4, count.index)}"
    private_key = "${file("${var.cloud_ssh_key_path}")}"
  }

  provisioner "file" {
    source      = "WaitForGlance.sh"
    destination = "WaitForGlance.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "bash WaitForGlance.sh"
    ]
  }

  provisioner "file" {
    source      = "CloudImages.sh"
    destination = "CloudImages.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "bash CloudImages.sh",
    ]
  }
}
