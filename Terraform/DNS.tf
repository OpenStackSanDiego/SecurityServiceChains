#provider "dnsimple" {
#}

#
# DNS requires the use of an external DNS provider (DNSSimple)
# DNS is not required for the default setup
#
# These environment variables need to be set from your DNSSimple account
# export DNSIMPLE_ACCOUNT=
# export DNSIMPLE_TOKEN=
#
# $5 off using the link below...
# https://dnsimple.com/r/5e6042aedef10a
#

resource "dnsimple_record" "dns" {

  count = "${var.openstack_controller_count}"

  domain = "openstacksandiego.us"
  name   = "${format("lab%d.chains", count.index)}"
  value  = "${element(packet_device.controller.*.access_public_ipv4, count.index)}"
  type   = "A"
  ttl    = 300
}

