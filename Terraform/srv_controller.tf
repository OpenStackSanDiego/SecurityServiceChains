# somewhat recent version is needed for DNSimple
terraform {
  required_version = ">= 0.9.3"
}

resource "packet_device" "controller" {
  count = "${var.server_count}"

  hostname = "${format("ewr%03d", count.index + 1)}"

  plan = "baremetal_1"
  facility = "ewr1"
  operating_system = "centos_7"
  billing_cycle = "hourly"
  project_id = "${var.packet_project_id}"
  public_ipv4_subnet_size = "29"

  connection {
        type = "ssh"
        user = "root"
        port = 22
        timeout = "${var.ssh-timeout}"
        private_key = "${file("~/.ssh/OpenStackWorkshop.rsa")}"
  }
  
  provisioner "file" {
    source      = "../setup.sh"
    destination = "/tmp/setup.sh"
  }

  provisioner "remote-exec" {
       inline = [
        "chmod +x /tmp/setup.sh",
        "/tmp/setup.sh",
       ]
  }
}
