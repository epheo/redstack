# RedStack
Deployment Automation for Red Hat Solutions 


ansible-playbook -i inventory.lab -e @secrets/lab.yaml playbook.yml

The following variables can be set:

```
   telegram:
     token: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
     chat_id: -xxxxxxxxx
   
   ## Undercloud
   customer_name: xxxxxxxxxxxxxxx
   
   rh_service:
     username: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
     token: xxxxxxxxxxxxx
   
   undercloud_br_nic: nic1
   undercloud.ip: 'xxxxxxxxxxxx'
   undercloud_admin: 'xxxxxxxxxxxx'
   undercloud_public: 'xxxxxxxxxxxx'
   
   dns_ip: '1.1.1.1'
   ntp_ip: 'xxxxxxxxxxxx'
   
   hypervisor_ip: 'xxxxxxxxxxxxx'
   
   guests_pubkey: 
     - 'ssh-rsa AAAAxxxxxxx'
   guests_passwd: xxxxxxxxxxx
   
   subscription:
     org: xxxxxxxx
     activation_key: 'xxxxxxxxxxxxxxxx'
   '
   
   private_cdn:
     url: https://xxxxxxxxxxxxxxxx/
     username: 'xxxxxx'
     password: 'xxxxxx'
   
   guests_rootimg:
     - localpath: Downloads/rhel-8.1.qcow2
       name: rhel-8.1.qcow2 
     - localpath: Downloads/rhel-8.2.qcow2
       name: rhel-8.2.qcow2 
     - localpath: Downloads/fedora-32.qcow2
       name: fedora-32.qcow2 
     - localpath: Downloads/fedora-rawhide.qcow2
       name: fedora-rawhide.qcow2 
   guests_rootdisk_pool: slow
   guests_rootdisk_pool_path: '/home/kvm/libvirt/'
   guests_rootdisk_size: 100
   
   libvirt_storage_pools:
     - name: fast
       path: '/var/lib/libvirt/ssd/'
     - name: slow
       path: '/home/kvm/libvirt/'
   libvirt_networks:
     - name: hypervisor_internal
       gateway: xxxxxxxxx
       netmask: xxxxxxxxxxxxx
   
   libvirt_guests:
     - name: director16
       root: rhel-8.1.qcow2 
       cloudinit: user-data
       ram: 32768000
       vcpu: 4
       ports:
         - name: nic1
           direct: nic1
         - name: nic2
           direct: nic2
         - name: nic3
           network: hypervisor_internal
       # https://cloudinit.readthedocs.io/en/latest/topics/network-config-format-v2.html
       network:
         version: 2
         ethernets:
           eth0: 
             addresses: [ 'xxxxxxxxxxxxx/xx' ]
             routes:
               - to: 'xxxxxxxxxxxxx/xx'
                 via: xxxxxxxxxxxxx
           eth1: { addresses: [ 'xxxxxxxxxxxx/xx' ] }
           eth2:
             addresses: [ 'xxxxxxxxxx/xx' ]
             gateway4: xxxxxxxxx
             nameservers: { addresses: [ '1.1.1.1' ] }
     - name: idm
       root: rhel-8.2.qcow2 
       cloudinit: user-data
       ram: 20480000
       vcpu: 4
       volumes:
         - name: idm-data
           target: sdb
           size: 100
           pool: slow
       ports:
         - name: nic1
           direct: nic1
         - name: nic2
           direct: nic2
         - name: nic3
           network: hypervisor_internal
       network:
         version: 2
         ethernets:
           eth0: 
             addresses: [ 'xxxxxxxxxxxxx/xx' ]
             routes:
               - to: 'xxxxxxxxxxxxx/xx'
                 via: xxxxxxxxxxxxx
           eth1: { addresses: [ 'xxxxxxxxxxxx/xx' ] }
           eth2:
             addresses: [ 'xxxxxxxxxx/xx' ]
             gateway4: xxxxxxxxx
             nameservers: { addresses: [ '1.1.1.1' ] }
     - name: onboarding
       root: rhel-8.2.qcow2 
       cloudinit: user-data
       ram: 20480000
       vcpu: 2
       ports:
         - name: nic1
           direct: nic1
         - name: nic2
           direct: nic2
         - name: nic3
           network: hypervisor_internal
       # https://cloudinit.readthedocs.io/en/latest/topics/network-config-format-v2.html
       volumes:
         - name: onboarding-data
           target: sdb
           size: 100
           pool: slow
       network:
         version: 2
         ethernets:
           eth0: 
             addresses: [ 'xxxxxxxxxxxxx/xx' ]
             routes:
               - to: 'xxxxxxxxxxxxx/xx'
                 via: xxxxxxxxxxxxx
           eth1: { addresses: [ 'xxxxxxxxxxxx/xx' ] }
           eth2:
             addresses: [ 'xxxxxxxxxx/xr' ]
             gateway4: xxxxxxxxx
             nameservers: { addresses: [ '1.1.1.1' ] }
   
   bmc_username: xxxxxx
   bmc_password: xxxxxxxx
   bmc_type: ipmi
   enable_uefi: false
   
   instack_vars:
     - node: xxxx-control
       mac: xxxxxxxxxxxxxxxxx
       addr: xxxxxxxxxxxxx
     - node: xxxx-control
       mac: xxxxxxxxxxxxxxxxx
       addr: xxxxxxxxxxxxx
     - node: xxxx-control
       mac: xxxxxxxxxxxxxxxxx
       addr: xxxxxxxxxxxxx
     - node: xxxx-compute
       mac: xxxxxxxxxxxxxxxxx
       addr: xxxxxxxxxxxxx
     - node: xxxx-comphci
       mac: xxxxxxxxxxxxxxxxx
       addr: xxxxxxxxxxxxx
     - node: xxxx-comphci
       mac: xxxxxxxxxxxxxxxxx
       addr: xxxxxxxxxxxxx
     - node: xxxx-comphci
       mac: xxxxxxxxxxxxxxxxx
       addr: xxxxxxxxxxxxx
   
   ## Overcloud
   
   enable_ceph: True
   enable_ceph_external: False
   enable_dpdk: False
   enable_sriov: True
   enable_ssl: True
   enable_stf: False
   enable_fencing: False
   enable_ovs: True
   enable_lowmemory: False
   enable_pcipassthrough: False
   enable_ironic: False
   enable_telemetry: False
   
   nic_config: 'nic-config.xxxx'
   
   overcloud_vip: xxxxxxxxxxxxx
   
   neutron:
     vlan_ranges: 'physnet0:1:4000'
     bridge_mappings: 'physnet0:br-data'
     flat_networks: 'physnet0'
   
   ctlplane_net:
     subnet: 'xxxxxxxxxxx/xx'
     dhcp_start: 'xxxxxxxxxxxx'
     dhcp_end: 'xxxxxxxxxxxxx'
     inspection_iprange: 'xxxxxxxxxxxxx,xxxxxxxxxxxxx'
     gateway: xxxxxxxxxxxx
   
   internal_net:
     vlanid: xxx
     subnet: 'xxxxxxxxxxxxx/xx'
     pool_start: 'xxxxxxxxxxxxxx'
     pool_end: 'xxxxxxxxxxxxxxx'
   
   storage_net:
     vlanid: xxx
     subnet: 'xxxxxxxxxxxxx/xx'
     pool_start: 'xxxxxxxxxxxxxx'
     pool_end: 'xxxxxxxxxxxxxxx'
   
   storagemgmt_net:
     vlanid: xxx
     subnet: 'xxxxxxxxxxxxx/xx'
     pool_start: 'xxxxxxxxxxxxxx'
     pool_end: 'xxxxxxxxxxxxxxx'
   
   tenant_net:
     vlanid: xxx
     subnet: 'xxxxxxxxxxxxx/xx'
     pool_start: 'xxxxxxxxxxxxxx'
     pool_end: 'xxxxxxxxxxxxxxx'
   
   external_net:
     vlanid: xx
     subnet: 'xxxxxxxxxxxxx/xx'
     gateway: 'xxxxxxxxxxxxx'
     pool_start: 'xxxxxxxxxxxxx'
     pool_end: 'xxxxxxxxxxxxx'
     physnet: physnet0
     fip_pool_start: 'xxxxxxxxxxxxx'
     fip_pool_end: 'xxxxxxxxxxxxx'
   
   provider_net:
     vlanid: xx
     subnet: 'xxxxxxxxxxx/xx'
     gateway: 'xxxxxxxxxxx'
     pool_start: 'xxxxxxxxxxxx'
     pool_end: 'xxxxxxxxxxxxx'
     physnet: physnet0
   
   sriov_test_net:
     vlanid: xx
     subnet: 'xxxxxxxxxxxxx/xx'
     gateway: 'xxxxxxxxxxxxx'
     pool_start: 'xxxxxxxxxxxxx'
     pool_end: 'xxxxxxxxxxxxx'
     physnet: physnet0
   
   ssl:
     countryname: 'xx'
     provincename: 'xxxxxxxx'
     localityname: 'xxxxxx'
     orgname: 'xxxx'
     orgunit: 'xxxxxxxxx'
     commonname: 'xxxxx'
     emailaddress: 'xxx@xxxxxxxxxxxxxxxxx.lab'
```