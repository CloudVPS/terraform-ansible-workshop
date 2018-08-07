#! /bin/sh -v
sudo apt update; apt install -y git ansible golang-go zip
sudo git clone https://github.com/CloudVPS/ansible-roles.git /etc/ansible/roles/
sudo git clone https://github.com/CloudVPS/terraform-ansible-workshop.git
sudo wget https://releases.hashicorp.com/terraform/0.11.7/terraform_0.11.7_linux_amd64.zip
sudo unzip terraform_0.11.7_linux_amd64.zip -d /bin/
sudo go get github.com/adammck/terraform-inventory

