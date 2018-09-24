
# resources should be created with dynamic nested blocks once 0.12 is released
# https://www.hashicorp.com/blog/hashicorp-terraform-0-12-preview-for-and-for-each


## BASTION HOST
resource "openstack_compute_instance_v2" "bastion" {
  name              = "${var.prefix}${var.bastion_name}"
  availability_zone = "${element(var.availability_zones, count.index % length(var.availability_zones))}"
  image_name        = "${var.image_name}"
  flavor_name       = "${var.flavor_name}"
  key_pair          = "${var.key_pair}"
#  user_data         = "#include\nhttps://raw.githubusercontent.com/ceesios/terraform-ansible-workshop/master/user_data_workshopserver.sh"
  security_groups   = ["default", "${openstack_compute_secgroup_v2.secgroup_ssh_public.name}"]
  network {
    name            = "${openstack_networking_network_v2.network_internal.name}"
  }
  
  connection {
    type            = "ssh"
    user            = "${var.user}"
    host            = "${openstack_networking_floatingip_v2.floatip_bastion.address}"
  }
  # Enter the bastion host into .ssh/config
  provisioner "local-exec" {
    command =  <<EOT
      sed -i '/[T]ERRAFORM_SSH_CONFIG_START/,/[T]ERRAFORM_SSH_CONFIG_END/d' ~/.ssh/config
      echo '# TERRAFORM_SSH_CONFIG_START
Host ${var.bastion_name} ${openstack_networking_floatingip_v2.floatip_bastion.address}
  StrictHostKeyChecking no
  UserKnownHostsFile=/dev/null
  Hostname ${openstack_networking_floatingip_v2.floatip_bastion.address}
  User ${var.user}

Host ${var.subnet_wildcard}
  StrictHostKeyChecking no
  UserKnownHostsFile=/dev/null
  User ${var.user}
  ProxyCommand ssh ${var.bastion_name} exec nc %h %p 2>/dev/null
# TERRAFORM_SSH_CONFIG_END' >> ~/.ssh/config
      
    EOT
  }
}


resource "openstack_compute_floatingip_associate_v2" "fip_bastion" {
  floating_ip = "${openstack_networking_floatingip_v2.floatip_bastion.address}"
  instance_id = "${openstack_compute_instance_v2.bastion.id}"

  # Provision after associating a floating IP
  connection {
    type            = "ssh"
    user            = "${var.user}"
    host            = "${openstack_networking_floatingip_v2.floatip_bastion.address}"
  }
  ## Provisioner is done on the floating IP
  provisioner "remote-exec" {
    inline = [
      "apt update",
      "apt install python -y"
    ]
  }
}


resource "openstack_compute_instance_v2" "web" {
  count             = "${var.web_count}"
  name              = "${var.prefix}web${count.index}"
  availability_zone = "${element(var.availability_zones, count.index % length(var.availability_zones))}"
  image_name        = "${var.image_name}"
  flavor_name       = "${var.flavor_name}"
  key_pair          = "${var.key_pair}"
  security_groups   = ["default", "${openstack_compute_secgroup_v2.secgroup_ssh_private.name}", "${openstack_compute_secgroup_v2.secgroup_icmp_private.name}"]
  user_data         = "${file("user_data_web.sh")}"

  network {
    name = "${openstack_networking_network_v2.network_internal.name}"
  }

  depends_on        = ["openstack_compute_secgroup_v2.secgroup_ssh_private", "openstack_compute_secgroup_v2.secgroup_icmp_private", "openstack_compute_instance_v2.bastion"]

}


resource "openstack_compute_instance_v2" "db" {
  count             = "${var.db_count}"
  name              = "${var.prefix}db${count.index}"
  availability_zone = "${element(var.availability_zones, count.index % length(var.availability_zones))}"
  image_name        = "${var.image_name}"
  flavor_name       = "${var.flavor_name}"
  key_pair          = "${var.key_pair}"
  security_groups   = [ "default"]
  user_data         = "${file("user_data_common.sh")}"

  network {
    name = "${openstack_networking_network_v2.network_internal.name}"
  }

  depends_on        = ["openstack_compute_instance_v2.bastion"]

}
