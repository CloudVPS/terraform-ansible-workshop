## Existing securitygroup
data "openstack_networking_secgroup_v2" "secgroup_default" {
  name = "default"
}


## securitygroups with rules included

resource "openstack_compute_secgroup_v2" "secgroup_ssh_public" {
  name        = "${var.prefix}secgroup_ssh_public"
  description = "${var.prefix} ssh security group"

  rule {
    from_port   = 22
    to_port     = 22
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }
}

resource "openstack_compute_secgroup_v2" "secgroup_ssh_private" {
  name        = "${var.prefix}secgroup_ssh_private"
  description = "${var.prefix} ssh security group"

  rule {
    from_port   = 22
    to_port     = 22
    ip_protocol = "tcp"
    cidr        = "${var.subnet_cidr}"
  }
}

resource "openstack_compute_secgroup_v2" "secgroup_icmp_public" {
  name        = "${var.prefix}secgroup_icmp_public"
  description = "${var.prefix} ssh security group"

  rule {
    from_port   = 0
    to_port     = 0
    ip_protocol = "icmp"
    cidr        = "0.0.0.0/0"
  }
}

resource "openstack_compute_secgroup_v2" "secgroup_icmp_private" {
  name        = "${var.prefix}secgroup_icmp_private"
  description = "${var.prefix} ssh security group"

  rule {
    from_port   = 0
    to_port     = 0
    ip_protocol = "icmp"
    cidr        = "${var.subnet_cidr}"
  }
}

resource "openstack_compute_secgroup_v2" "secgroup_web_public" {
  name        = "${var.prefix}secgroup_web_public"
  description = "${var.prefix} webserver security group"

  rule {
    from_port   = 8000
    to_port     = 8000
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }
  rule {
    from_port   = 80
    to_port     = 80
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }
  rule {
    from_port   = 443
    to_port     = 443
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }
}

resource "openstack_compute_secgroup_v2" "secgroup_web_private" {
  name        = "${var.prefix}secgroup_web_private"
  description = "${var.prefix} webserver security group"

  rule {
    from_port   = 80
    to_port     = 80
    ip_protocol = "tcp"
    cidr        = "${var.subnet_cidr}"
  }
  rule {
    from_port   = 443
    to_port     = 443
    ip_protocol = "tcp"
    cidr        = "${var.subnet_cidr}"
  }
}

resource "openstack_compute_secgroup_v2" "secgroup_db_private" {
  name        = "${var.prefix}secgroup_db_private"
  description = "${var.prefix} webserver security group"

  rule {
    from_port   = 3306
    to_port     = 3306
    ip_protocol = "tcp"
    cidr        = "${var.subnet_cidr}"
  }
}