
# resources should be created with dynamic nested blocks once 0.12 is released
# https://www.hashicorp.com/blog/hashicorp-terraform-0-12-preview-for-and-for-each


## BASTION HOST
resource "openstack_compute_instance_v2" "bastion" {
  name              = "${var.prefix}${var.bastion_name}"
  availability_zone = "${element(var.availability_zones, count.index % length(var.availability_zones))}"
  image_name        = "${var.image_name}"
  flavor_name       = "${var.flavor_name}"
  key_pair          = "${var.key_pair}"
  user_data         = "#include\nhttps://raw.githubusercontent.com/ceesios/terraform-ansible-workshop/master/user_data_workshopserver.sh"
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
  User ubuntu

Host ${var.subnet_wildcard}
  StrictHostKeyChecking no
  UserKnownHostsFile=/dev/null
  User ubuntu
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
#  provisioner "remote-exec" {
#    inline = [
#      "sudo echo '${openstack_compute_keypair_v2.keypair.private_key}' >> /root/.ssh/id_rsa",
#      "sudo chmod 600 /root/.ssh/id_rsa",
#      "sudo echo '${openstack_compute_keypair_v2.keypair.public_key}' >> /root/.ssh/id_rsa.pub",
#      "sudo chmod 644 /root/.ssh/id_rsa.pub"
#    ]
#  }
}




resource "openstack_compute_instance_v2" "web" {
  count             = "${var.web_count}"
  name              = "${var.prefix}web${count.index}"
  availability_zone = "${element(var.availability_zones, count.index % length(var.availability_zones))}"
  image_name        = "${var.image_name}"
  flavor_name       = "${var.flavor_name}"
  key_pair          = "${var.key_pair}"
  security_groups   = ["default", "${openstack_compute_secgroup_v2.secgroup_ssh_private.name}", "${openstack_compute_secgroup_v2.secgroup_icmp_private.name}"]
  user_data         = "${file("bootstrap.sh")}"

  network {
    name = "${openstack_networking_network_v2.network_internal.name}"
  }

  connection {
    type                = "ssh"
    user                = "${var.user}"
#    private_key         = "${var.key_pair}"
    bastion_host        = "${openstack_networking_floatingip_v2.floatip_bastion.address}"
    bastion_port        = 22
    bastion_user        = "${var.user}"

  }

  ## Add the generated bastion key to authorized_keys
#  provisioner "remote-exec" {
#    inline = [
#      "sudo echo '${openstack_compute_keypair_v2.keypair.public_key}' >> /root/.ssh/authorized_keys",
#      "sudo chmod 644 /root/.ssh/authorized_keys"
#    ]
#  }
}

resource "openstack_compute_instance_v2" "db" {
  count             = "${var.db_count}"
  name              = "${var.prefix}db${count.index}"
  availability_zone = "${element(var.availability_zones, count.index % length(var.availability_zones))}"
  image_name        = "${var.image_name}"
  flavor_name       = "${var.flavor_name}"
  key_pair          = "${var.key_pair}"
  security_groups   = ["default", "${openstack_compute_secgroup_v2.secgroup_ssh_private.name}", "${openstack_compute_secgroup_v2.secgroup_icmp_private.name}"]

  network {
    name = "${openstack_networking_network_v2.network_internal.name}"
  }

  connection {
    type            = "ssh"
    user            = "${var.user}"
    bastion_host    = "${openstack_networking_floatingip_v2.floatip_bastion.address}"
  }

  ## Add the generated bastion key to authorized_keys
#  provisioner "remote-exec" {
#    inline = [
#      "sudo echo '${openstack_compute_keypair_v2.keypair.public_key}' >> /root/.ssh/authorized_keys",
#      "sudo chmod 644 /root/.ssh/authorized_keys"
#    ]
#  }
}
