#!/bin/bash

# Disable ipv6
printf "net.ipv6.conf.all.disable_ipv6 = 1\nnet.ipv6.conf.default.disable_ipv6 = 1\nnet.ipv6.conf.lo.disable_ipv6 = 1" >> /etc/sysctl.conf && \sysctl -p || true

# Install nginx and mod the index.html
apt-get update || true
apt-get install -y nginx || true
rm -vf /var/www/html/* || true
echo $(hostname) > /var/www/html/index.html || true
