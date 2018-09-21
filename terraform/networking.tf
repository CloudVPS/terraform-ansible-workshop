resource "openstack_networking_network_v2" "network_internal" {
  name                = "${var.prefix}network-internal"
  admin_state_up      = "true"
}

resource "openstack_networking_subnet_v2" "subnet_internal" {
  name                = "${var.prefix}subnet-internal"
  network_id          = "${openstack_networking_network_v2.network_internal.id}"
  cidr                = "${var.subnet_cidr}"
  ip_version          = 4
  dns_nameservers     = ["${var.primary_dns}", "${var.secondary_dns}"]
}

resource "openstack_networking_router_v2" "router_internal_to_external" {
  name                = "${var.prefix}router-internal-to-external"
  admin_state_up      = "true"
  external_network_id = "${var.floating_network_id}"
}

resource "openstack_networking_router_interface_v2" "router_interface" {
  router_id           = "${openstack_networking_router_v2.router_internal_to_external.id}"
  subnet_id           = "${openstack_networking_subnet_v2.subnet_internal.id}"
}

## Register LB Floating IP
resource "openstack_networking_floatingip_v2" "fip_1" {
  pool                = "${var.floating_network_name}"
}

## Register bastion Floating IP
resource "openstack_networking_floatingip_v2" "floatip_bastion" {
  pool                = "${var.floating_network_name}"
  }
