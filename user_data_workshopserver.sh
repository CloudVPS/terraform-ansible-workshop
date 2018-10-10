#!/bin/bash
set -ex

export DEBIAN_FRONTEND=noninteractive

TERRAFORM_VERSION=0.11.7
TERRAFORM_CHECKSUM=6b8ce67647a59b2a3f70199c304abca0ddec0e49fd060944c26f666298e23418

# Disable ipv6
echo "net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1" >> /etc/sysctl.conf
sysctl -p


# Upgrade packages
apt-get update && \
    apt-get upgrade -y -o Dpkg::Options::="--force-confold" || true

# Install packages
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common \
    unzip \
    wget || true

# Install Git & Gitflow toolset
apt-get install -y git-flow || true

# Install OpenStack client
apt-get install -y python-openstackclient || true

# Install Terraform
wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    echo "${TERRAFORM_CHECKSUM}  terraform_${TERRAFORM_VERSION}_linux_amd64.zip" > terraform.checksum && \
    sha256sum --strict --check terraform.checksum && \
    unzip -u terraform_${TERRAFORM_VERSION}_linux_amd64.zip -d /usr/local/bin && \
    rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip terraform.checksum || true

# Install Ansible
apt-add-repository -y ppa:ansible/ansible && \
    apt-get update && \
    apt-get install -y ansible || true

# Install Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - && \
    add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) edge" && \
    apt-get update && \
    apt-get install -y docker-ce && \
    usermod -aG docker ubuntu || true

# Install golang
apt install -y golang || true

# Set env. variables on next logon
echo "export GOPATH=~/go
#export TF_STATE=~/terraform-ansible-workshop/terraform/terraform.tfstate" >> /home/ubuntu/.bashrc
echo "export GOPATH=~/go
#export TF_STATE=~/terraform-ansible-workshop/terraform/terraform.tfstate" >> /root/.bashrc

# Install terraform inventory
export GOPATH=~/go; go get github.com/adammck/terraform-inventory
sudo su - ubuntu -c "export GOPATH=~/go; go get github.com/adammck/terraform-inventory"


# Clone the ansible roles
git clone https://github.com/CloudVPS/ansible-roles.git /etc/ansible/roles/ || true

# Clone the workshop
git clone https://github.com/CloudVPS/terraform-ansible-workshop.git /root/terraform-ansible-workshop/ || true
sudo su - ubuntu -c "git clone https://github.com/CloudVPS/terraform-ansible-workshop.git /home/ubuntu/terraform-ansible-workshop/" || true

# Generate ssh keys and allow ssh to localhost
ssh-keygen -b 2048 -t rsa -f ~/.ssh/id_rsa -q -N "" 
cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys

sudo su - ubuntu -c "ssh-keygen -b 2048 -t rsa -f /home/ubuntu/.ssh/id_rsa -q -N ''"
cat /home/ubuntu/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys
cat /home/ubuntu/.ssh/id_rsa.pub >> /home/ubuntu/.ssh/authorized_keys
# Clean
# apt-get clean && \
#     rm -rf /var/lib/apt/lists/* /var/tmp/* /tmp/*
