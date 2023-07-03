data "openstack_networking_network_v2" "external" {
  name = var.public_network.name
}

data "openstack_networking_network_v2" "internal" {
  name = var.private_network.name
}

data "openstack_images_image_v2" "htcondor-image" {
  name        = var.image.name
  most_recent = true
}

data "openstack_compute_keypair_v2" "cloud-key" {
  name = var.public_key.name
}

data "cloudinit_config" "nfs-share" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/x-shellscript"
    content      = file("${path.module}/files/create_share.sh")
  }

  part {
    content_type = "text/cloud-config"
    content      = <<-EOF
    #cloud-config
    write_files:
    - content: |
        /data/share *(rw,sync)
      owner: root:root
      path: /etc/exports
      permissions: '0644'
    runcmd:
      - [systemctl, enable, nfs-server]
      - [systemctl, start, nfs-server]
      - [exportfs, -avr]
    ssh_authorized_keys:
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC49BanKDSkoT22TWvNeL+4x/qcRi0a7Nuf+GmDXEEaCWlhvD7oeYoqVm/Jbbxo0FSDENwpMds5nR8MrdInOL1Ycp9sOoOsi0Sf1mMKhErHE2O+SHmQrPiKphams3wNSllKV80171E+7+ljYcUPREybBomZgYWlqeh46q+41AEFWxn6MYlQud/pa7TTnu/1egaWhX5W+P3l9Mo+x13LOywqbTl+545gvKg2bAHdkFkj/k/YKqM/DSFXT4Cx2r/OWZuR6oBLvsjmsld6rUdDhgIKqxQgK523NJv2gm0TS2JBXzFLsnH+ByIF55r1VCQlhYqfbl0w1O6exbc7pUnRy+ch
  EOF
  }
}
