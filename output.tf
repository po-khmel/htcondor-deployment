output "node_name" {
  value = openstack_compute_instance_v2.central-manager.name
}

output "ip_v4_internal" {
  value = openstack_compute_instance_v2.central-manager.network.0.fixed_ip_v4
}

output "floating_IP" {
  value = openstack_networking_floatingip_v2.pub_ip.address
}
