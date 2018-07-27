
# resources should be created with dynamic nested blocks once 0.12 is released
# https://www.hashicorp.com/blog/hashicorp-terraform-0-12-preview-for-and-for-each


## BASTION HOST
resource "openstack_compute_instance_v2" "bastion" {
  name              = "${var.prefix}${var.bastion_name}"
  availability_zone = "${element(var.availability_zones, count.index % length(var.availability_zones))}"
  image_name        = "${var.image_name}"
  flavor_name       = "${var.flavor_name}"
  key_pair          = "${var.key_pair}"
  security_groups   = ["default", "${openstack_compute_secgroup_v2.secgroup_ssh_public.name}"]
  network {
    name            = "${openstack_networking_network_v2.network_internal.name}"
  }
  
  connection {
    type            = "ssh"
    user            = "root"
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
      User root

      Host ${var.subnet_wildcard}
      StrictHostKeyChecking no
      UserKnownHostsFile=/dev/null
      User root
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
    user            = "root"
    host            = "${openstack_networking_floatingip_v2.floatip_bastion.address}"
  }
  ## Provisioner is done on the floating IP
  provisioner "remote-exec" {
    inline = [
      "echo '${openstack_compute_keypair_v2.keypair.private_key}' >> ~/.ssh/id_rsa",
      "chmod 600 ~/.ssh/id_rsa",
      "echo '${openstack_compute_keypair_v2.keypair.public_key}' >> ~/.ssh/id_rsa.pub",
      "chmod 644 ~/.ssh/id_rsa.pub"
    ]
  }
}




resource "openstack_compute_instance_v2" "web" {
  count             = "${var.web_count}"
  name              = "${var.prefix}web${count.index}"
  availability_zone = "${element(var.availability_zones, count.index % length(var.availability_zones))}"
  image_name        = "${var.image_name}"
  flavor_name       = "${var.flavor_name}"
  key_pair          = "${var.prefix}keypair"
  security_groups   = ["default", "${openstack_compute_secgroup_v2.secgroup_ssh_private.name}", "${openstack_compute_secgroup_v2.secgroup_icmp_private.name}"]
  user_data         = "${file("bootstrap.sh")}"

  network {
    name = "${openstack_networking_network_v2.network_internal.name}"
  }
}

resource "openstack_compute_instance_v2" "db" {
  count             = "${var.db_count}"
  name              = "${var.prefix}db${count.index}"
  availability_zone = "${element(var.availability_zones, count.index % length(var.availability_zones))}"
  image_name        = "${var.image_name}"
  flavor_name       = "${var.flavor_name}"
  key_pair          = "${var.prefix}keypair"
  security_groups   = ["default", "${openstack_compute_secgroup_v2.secgroup_ssh_private.name}", "${openstack_compute_secgroup_v2.secgroup_icmp_private.name}"]

  network {
    name = "${openstack_networking_network_v2.network_internal.name}"
  }
}
