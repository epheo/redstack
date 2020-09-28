# RedStack
Deployment Automation for Red Hat Solutions 


ansible-playbook -i inventory.lab -e @secrets/lab.yaml playbook.yaml


## Variables

The following variables can be set:

```

   ## Global
   telegram:
     token: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
     chat_id: -xxxxxxxxx
   
   hypervisor_ip: 'xxx.xxx.xxx.xxx'
   
   subscription:
     org: xxxxxxxx
     activation_key: 'xxxxxxxxxxxxxxxx'
   
   private_cdn:
     url: https://xxxxxxxxxxxxxxxx/
     username: 'xxxxxx'
     password: 'xxxxxx'
   
   guests:
     rootimgs:
       - localpath: Downloads/rhel-8.1.qcow2
         name: rhel-8.1.qcow2 
       - localpath: Downloads/rhel-8.2.qcow2
         name: rhel-8.2.qcow2 
       - localpath: Downloads/fedora-32.qcow2
         name: fedora-32.qcow2 
       - localpath: Downloads/fedora-rawhide.qcow2
         name: fedora-rawhide.qcow2 
     rootdisk:
       pool: fast
       pool_path: '/var/lib/libvirt/images/'
       size: 100
     pubkey: 
       - 'ssh-rsa AAAAXXXXXXXXXXXXX'
     passwd: xxxxxxxxxxx
   
   libvirt:
     storage_pools:
       - name: fast
         path: '/var/lib/libvirt/images/'
       - name: slow
         path: '/mnt/data/vm_storage/'
     networks:
       - name: internal
       - name: external
       - name: hypervisor
         gateway: 10.0.42.1
         netmask: 255.255.255.0
     guests:
       - name: director16
         root: rhel-8.2.qcow2 
         cloudinit: user-data
         ram: 32768000
         vcpu: 4
         ports:
           - name: eth0
             network: internal
           - name: eth1
             network: external
           - name: eth2
             network: hypervisor
         network:
           version: 2
           ethernets:
             eth0: { addresses: [ '172.16.0.10/24' ] }
             eth2:
               addresses: [ '10.0.42.10/24' ]
               gateway4: 10.0.42.1
               nameservers: { addresses: [ '1.1.1.1' ] }
           vlans: 
             vlan14:
               id: 14
               link: eth1
               addresses: [ '172.16.14.10/24' ]
   
   
   ## OpenStack - Undercloud
   undercloud:
     br_nic: eth0
     ip: '172.16.0.10'
     netmask: 24
     admin_ip: '172.16.0.8'
     public_ip: '172.16.0.9'
   
   dns_ip: '1.1.1.1'
   ntp_ip: '0.rhel.pool.ntp.org'
   
   rh_service:
     username: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
     token: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   
   
   ## OpenStack - OverCloud
   cloud:
     name: cloud
     customer_name: epheo
     customer_extention: lab
   
   enable_ceph: False
   enable_ceph_external: False
   enable_dpdk: False
   enable_sriov: False
   enable_ssl: True
   enable_stf: False
   enable_fencing: False
   enable_ovs: True
   enable_lowmemory: False
   enable_pcipassthrough: False
   enable_ironic: False
   enable_telemetry: False
   enable_uefi: True
   
   bmc_username: xxxx
   bmc_password: 'xxxxxxx'
   bmc_type: ipmi
   
   nic_config: 'nic-config'
   
   neutron:
     vlan_ranges: 'physnet0:0:4000'
     bridge_mappings: 'physnet0:br-ex'
     flat_networks: 'physnet0'
   
   ctlplane_net:
     subnet: '172.16.0.0/24'
     dhcp_start: '172.16.0.100'
     dhcp_end: '172.16.0.200'
     inspection_iprange: '172.16.0.201,172.16.0.250'
     gateway: 172.16.0.10
   
   internal_net:
     vlanid: 11
     subnet: '172.16.11.0/24'
     pool_start: '172.16.11.100'
     pool_end: '172.16.11.200'
   
   storage_net:
     vlanid: 12
     subnet: '172.16.12.0/24'
     pool_start: '172.16.12.100'
     pool_end: '172.16.12.200'
   
   tenant_net:
     vlanid: 13
     subnet: '172.16.13.0/24'
     pool_start: '172.16.13.100'
     pool_end: '172.16.13.200'
   
   external_net:
     vlanid: 14
     subnet: '172.16.14.0/24'
     gateway: '172.16.14.10'
     pool_start: '172.16.14.100'
     pool_end: '172.16.14.200'
     physnet: physnet0
     fip_pool_start: '172.16.14.201'
     fip_pool_end: '172.16.14.250'
     vip: 172.16.14.5
   
   ssl:
     countryname: 'FR'
     provincename: 'IdF'
     localityname: 'Paris'
     orgname: 'RedHat'
     orgunit: 'SSA'
     commonname: 'redhat'
     emailaddress: 'xxx@xxxxxx.xxx'

```


## Play

Deploy the Undercloud
---

```

   ansible-playbook -i inventory.lab -e @secrets/lab.yaml \
     01-download_bits.yaml
   
   ansible-playbook -i inventory.lab -e @secrets/lab.yaml \
     10-hypervisor_prepare.yaml
   
   ansible-playbook -i inventory.lab -e @secrets/lab.yaml \
     11-guests_prepare.yaml
   
   ansible-playbook -i inventory.lab -e @secrets/lab.yaml \
     60-undercloud_install.yaml
   
   ansible-playbook -i inventory.lab -e @secrets/lab.yaml \
     61-undercloud_prepare_templates.yaml

```

Deploy the OverCloud
---

```

   ansible-playbook -i inventory.lab -e @secrets/lab.yaml \
     -e @roles/director/vars/overcloud-reducedscale.yaml  \
     11-guests_prepare.yaml

   ansible-playbook -i inventory.lab -e @secrets/lab.yaml \
     -e @roles/director/vars/overcloud-reducedscale.yaml  \
     70-overcloud_vbmc.yaml
   
   ansible-playbook -i inventory.lab -e @secrets/lab.yaml \
     -e @roles/director/vars/overcloud-reducedscale.yaml  \
     71-overcloud_baremetal_prepare.yaml

```

Delete the existing
---

```

   ansible-playbook -i inventory.lab -e @secrets/lab.yaml \
     79-overcloud_delete.yaml

   ansible-playbook -i inventory.lab -e @secrets/lab.yaml \
     -e @roles/director/vars/overcloud-reducedscale.yaml  \
     12-guests_delete.yaml

   ansible-playbook -i inventory.lab -e @secrets/lab.yaml \
     12-guests_delete.yaml

```