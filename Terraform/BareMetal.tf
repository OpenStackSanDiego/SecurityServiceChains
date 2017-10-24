provider "packet" {
  auth_token = "${var.packet_auth_token}"
}

resource "packet_device" "controller" {
  hostname = "${format("lab%02d", count.index)}"

  count = "${var.openstack_controller_count}"

  operating_system = "centos_7"
  plan             = "${var.packet_controller_type}"
  connection {
    user = "root"
    private_key = "${file("${var.cloud_ssh_key_path}")}"
  }
  user_data     = "#cloud-config\n\nssh_authorized_keys:\n  - \"${file("${var.cloud_ssh_public_key_path}")}\""
  facility      = "${var.packet_facility}"
  project_id    = "${var.packet_project_id}"
  billing_cycle = "hourly"

  public_ipv4_subnet_size  = "29"

  provisioner "remote-exec" {
    inline = [
      "yum -y update > baremetal-yum-update.out"
    ]
  }

  # failsafe console login
  # admin/openstack with sudo and ssh using root SSH key
  provisioner "remote-exec" {
    inline = [
       "adduser -p 42ZTHaRqaaYvI --group wheel admin",
       "cp -R ~root/.ssh ~admin/",
       "chown -R admin.admin ~admin/.ssh/",
    ]
  }
}
