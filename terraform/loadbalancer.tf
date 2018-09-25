## LBaaS
#resource "openstack_lb_loadbalancer_v2" "lb_1" {
#  vip_subnet_id      = "${openstack_networking_subnet_v2.subnet_internal.id}"
#  vip_address        = "${var.vip_address}"
#  security_group_ids = ["${openstack_compute_secgroup_v2.secgroup_lb.id}"]
#}
#
#resource "openstack_lb_listener_v2" "listener_1" {
#  protocol        = "HTTP"
#  protocol_port   = 80
#  loadbalancer_id = "${openstack_lb_loadbalancer_v2.lb_1.id}"
#}
#
#resource "openstack_lb_pool_v2" "pool_1" {
#  protocol    = "HTTP"
#  lb_method   = "ROUND_ROBIN"
#  listener_id = "${openstack_lb_listener_v2.listener_1.id}"
#}
#
#resource "openstack_lb_member_v2" "members" {
#  depends_on    = ["openstack_compute_instance_v2.web"]
#  count         = "${var.web_count}"
#  address       = "${element(openstack_compute_instance_v2.web.*.access_ip_v4, count.index)}"
#  protocol_port = 80
#  pool_id       = "${openstack_lb_pool_v2.pool_1.id}"
#  subnet_id     = "${openstack_networking_subnet_v2.subnet_internal.id}"
#}
#
#resource "openstack_lb_monitor_v2" "monitor_1" {
#  pool_id     = "${openstack_lb_pool_v2.pool_1.id}"
#  type        = "PING"
#  delay       = 20
#  timeout     = 10
#  max_retries = 5
#}
#
#resource "openstack_networking_floatingip_associate_v2" "fip_1" {
#  floating_ip = "${openstack_networking_floatingip_v2.fip_1.address}"
#  port_id     = "${openstack_lb_loadbalancer_v2.lb_1.vip_port_id}"
#}



## LOADBALANCER instances with VRRP
resource "openstack_networking_port_v2" "port_ha_vip" {
  name              = "${var.prefix}port_ha_vip"
  network_id        = "${openstack_networking_network_v2.network_internal.id}"
  security_group_ids = ["${data.openstack_networking_secgroup_v2.secgroup_default.id}", "${openstack_compute_secgroup_v2.secgroup_web_public.id}", "${openstack_compute_secgroup_v2.secgroup_icmp_public.id}"]
  admin_state_up    = "true"

  fixed_ip {
    "subnet_id"     = "${openstack_networking_subnet_v2.subnet_internal.id}"
    "ip_address"    = "${var.vip_address}"
  }

  depends_on        = ["data.openstack_networking_secgroup_v2.secgroup_default", "openstack_networking_router_interface_v2.router_interface", "openstack_compute_secgroup_v2.secgroup_web_public", "openstack_compute_secgroup_v2.secgroup_icmp_public"]

}

resource "openstack_networking_port_v2" "port_lb" {
  count             = "${var.lb_count}"
  name              = "${var.prefix}lb-${count.index}-port"
  network_id        = "${openstack_networking_network_v2.network_internal.id}"
  security_group_ids = ["${data.openstack_networking_secgroup_v2.secgroup_default.id}", "${openstack_compute_secgroup_v2.secgroup_web_public.id}", "${openstack_compute_secgroup_v2.secgroup_icmp_public.id}"]
  admin_state_up    = "true"

  fixed_ip {
    "subnet_id"     = "${openstack_networking_subnet_v2.subnet_internal.id}"
  }

  allowed_address_pairs {
    ip_address      = "${openstack_networking_port_v2.port_ha_vip.fixed_ip.0.ip_address}"
  }

  allowed_address_pairs {
    ip_address      = "1.0.0.0/0"
  }

  depends_on        = ["openstack_networking_router_interface_v2.router_interface", "openstack_networking_floatingip_v2.fip_1"]

}

resource "openstack_compute_instance_v2" "lb" {
  count             = "${var.lb_count}"
  name              = "${var.prefix}lb-${count.index}"
  availability_zone = "${element(var.availability_zones, count.index % length(var.availability_zones))}"
  image_name        = "${var.image_name}"
  flavor_name       = "${var.flavor_name}"
  key_pair          = "${var.key_pair}"
  user_data         = "${file("user_data_common.sh")}"
  depends_on        = ["openstack_compute_secgroup_v2.secgroup_web_public", "openstack_compute_secgroup_v2.secgroup_icmp_public", "openstack_compute_instance_v2.bastion"]

  network {
    name            = "${openstack_networking_network_v2.network_internal.name}"
    port            = "${element(openstack_networking_port_v2.port_lb.*.id, count.index)}"
  }
  
  metadata {
    ha_vip_address                = "${openstack_networking_port_v2.port_ha_vip.fixed_ip.0.ip_address}"
    ha_floatingips                = "${openstack_networking_floatingip_v2.fip_1.address}"
    ha_execution                  = "1"
    keepalived.notification_email = "cees@cloudvps.com"
    keepalived.pass               = "${random_string.secret1.result}"
    keepalived.intvip             = "${openstack_networking_port_v2.port_ha_vip.fixed_ip.0.ip_address}"
    keepalived.intnic             = "eth0"
  }

}  