resource "openstack_compute_keypair_v2" "keypair" {
  name = "${var.prefix}keypair"
}
