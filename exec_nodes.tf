resource "openstack_compute_instance_v2" "exec-node" {
  count           = var.exec_node_count
  name            = "${var.name_prefix}exec-node-${count.index}"
  flavor_name     = var.flavors.exec-node
  image_id        = data.openstack_images_image_v2.htcondor-image.id
  key_pair        = data.openstack_compute_keypair_v2.cloud-key.name
  security_groups = var.secgroups

  network {
    uuid = data.openstack_networking_network_v2.internal.id
  }

  user_data = <<-EOF
    #cloud-config
    system_info:
      default_user:
        name: rocky
        gecos: RHEL Cloud User
        groups: [wheel, adm, systemd-journal]
        sudo: ["ALL=(ALL) NOPASSWD:ALL"]
        shell: /bin/bash
      distro: rhel
      paths:
        cloud_dir: /var/lib/cloud
        templates_dir: /etc/cloud/templates
      ssh_svcname: sshd
    write_files:
    - content: |
        CONDOR_HOST = ${openstack_compute_instance_v2.central-manager.network.0.fixed_ip_v4}
        ALLOW_WRITE = *
        ALLOW_READ = $(ALLOW_WRITE)
        ALLOW_ADMINISTRATOR = *
        ALLOW_NEGOTIATOR = $(ALLOW_ADMINISTRATOR)
        ALLOW_CONFIG = $(ALLOW_ADMINISTRATOR)
        ALLOW_DAEMON = $(ALLOW_ADMINISTRATOR)
        ALLOW_OWNER = $(ALLOW_ADMINISTRATOR)
        ALLOW_CLIENT = *
        DAEMON_LIST = MASTER, SCHEDD, STARTD
        FILESYSTEM_DOMAIN = ${var.domain_name}
        UID_DOMAIN = ${var.domain_name}
        TRUST_UID_DOMAIN = True
        SOFT_UID_DOMAIN = True
        # run with partitionable slots
        CLAIM_PARTITIONABLE_LEFTOVERS = True
        NUM_SLOTS = 1
        NUM_SLOTS_TYPE_1 = 1
        SLOT_TYPE_1 = 100%
        SLOT_TYPE_1_PARTITIONABLE = True
        ALLOW_PSLOT_PREEMPTION = False
        STARTD.PROPORTIONAL_SWAP_ASSIGNMENT = True
      owner: root:root
      path: /etc/condor/condor_config.local
      permissions: '0644'
    - content: |
        /data           /etc/auto.data          nfsvers=3
      owner: root:root
      path: /etc/auto.master.d/data.autofs
      permissions: '0644'
    - content: |
        share  -rw,hard,intr,nosuid,quota  ${openstack_compute_instance_v2.nfs-server.access_ip_v4}:/data/share
      owner: root:root
      path: /etc/auto.data
      permissions: '0644'
    - content: |
        ---
        - name: Install HTCondor Central Manager
          become: yes
          hosts: all
          connection: local
          roles:
            - name: usegalaxy_eu.htcondor
              vars:
                condor_role: execute
                condor_copy_template: false
                condor_host: ${openstack_compute_instance_v2.central-manager.access_ip_v4}
                condor_password: ${var.condor_pass}
      owner: rocky:rocky
      path: /home/rocky/condor.yml
      permissions: '0644'
    packages: 
      - ansible
    runcmd:
      - python3 -m pip install ansible
      - ansible-galaxy install -p /home/rocky/roles usegalaxy_eu.htcondor
      - ansible-playbook -i 'localhost,' /home/rocky/condor.yml
      - systemctl start condor
    ssh_authorized_keys:
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC49BanKDSkoT22TWvNeL+4x/qcRi0a7Nuf+GmDXEEaCWlhvD7oeYoqVm/Jbbxo0FSDENwpMds5nR8MrdInOL1Ycp9sOoOsi0Sf1mMKhErHE2O+SHmQrPiKphams3wNSllKV80171E+7+ljYcUPREybBomZgYWlqeh46q+41AEFWxn6MYlQud/pa7TTnu/1egaWhX5W+P3l9Mo+x13LOywqbTl+545gvKg2bAHdkFkj/k/YKqM/DSFXT4Cx2r/OWZuR6oBLvsjmsld6rUdDhgIKqxQgK523NJv2gm0TS2JBXzFLsnH+ByIF55r1VCQlhYqfbl0w1O6exbc7pUnRy+ch
  EOF
}