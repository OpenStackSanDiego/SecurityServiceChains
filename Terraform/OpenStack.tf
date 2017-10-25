
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

  provisioner "remote-exec" {
    inline = [
      "sed -i \"/\\#\\# Server aliases/a \\ \\ ServerAlias ${element(dnsimple_record.dns.*.name,count.index)}.${element(dnsimple_record.dns.*.domain,count.index)}\" /etc/httpd/conf.d/15-horizon_vhost.conf",
      "systemctl restart httpd.service",
    ]
  }

  # wait until port 22 (SSH) comes back online
  provisioner "local-exec" {
    command = "until nc -vzw 22 ${element(packet_device.controller.*.access_public_ipv4, count.index)} 22; do sleep 2; done"
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
