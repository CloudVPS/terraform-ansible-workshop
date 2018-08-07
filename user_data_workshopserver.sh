#! /bin/sh -v
apt update; apt install -y git ansible
cd /etc/ansible/roles
git clone https://github.com/CloudVPS/ansible-roles.git /etc/ansible/roles/
git clone https://github.com/CloudVPS/terraform-ansible-workshop.git
