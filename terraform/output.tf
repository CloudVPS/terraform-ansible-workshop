output "Loadbalancers floating IP address" {
  value = "${openstack_networking_floatingip_v2.fip_1.address}"
}

output "secret1 - keepalived" {
  value = "${random_string.secret1.result}"
}

output "secret2 - unused" {
  value = "${random_string.secret2.result}"
}
