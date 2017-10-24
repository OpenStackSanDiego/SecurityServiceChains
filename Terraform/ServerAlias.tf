
resource "null_resource" "server_alias" {
  count = "${var.openstack_controller_count}"

  depends_on = [ "null_resource.openstack" ]

  connection {
    host = "${element(packet_device.controller.*.access_public_ipv4, count.index)}"
    private_key = "${file("${var.cloud_ssh_key_path}")}"
  }

  provisioner "remote-exec" {
    inline = [
      "sed -i \"/\\#\\# Server aliases/a \\ \\ ServerAlias ${element(dnsimple_record.dns.*.name,count.index)}.${element(dnsimple_record.dns.*.domain,count.index)}\" /etc/httpd/conf.d/15-horizon_vhost.conf",
      "systemctl restart httpd.service",
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
