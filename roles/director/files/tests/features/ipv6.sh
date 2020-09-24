#!/bin/bash
project="ipv6"

cd $( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
../new_identity.sh $project
source ~stack/rcfiles/$project'rc'

antiaff=$(openstack server group create \
              --policy anti-affinity gr-antiaff-$project \
              -c id -f value)

openstack security group rule create allowall_$project --protocol tcp --dst-port 1:65535  --ethertype IPv6
openstack security group rule create allowall_$project --protocol udp --dst-port 1:65535  --ethertype IPv6
openstack security group rule create allowall_$project --protocol icmp --dst-port -1      --ethertype IPv6

echo "Creating IPv6 Network and Subnet in Slaac mode"
#neutron net-create 131_ipv6  --provider:physical_network datacentre --provider:network_type vlan --provider:segmentation_id 131
#neutron subnet-create 131_ipv6 2001:db8:fd00:6000::/64 --ipv6-ra-mode slaac --ipv6-address-mode slaac --ip-version 6 --name 131_ipv6

# neutron net-create public --router:external --provider:physical_network datacentre --provider:network_type vlan --provider:segmentation_id 132
# neutron subnet-create public 2001:db8:0:2::/64 --ip-version 6 --gateway 2001:db8::1 --allocation-pool start=2001:db8:0:2::2,end=2001:db8:0:2::ffff --ip-version 6 --ipv6_address_mode=slaac --ipv6_ra_mode=slaac
# 
# neutron router-create public-router
# neutron router-gateway-set public-router public

neutron net-create ipv6_slaac
neutron subnet-create ipv6_slaac 2001:db8:fd00:6001::/64 --ipv6-ra-mode slaac --ipv6-address-mode slaac --ip-version 6 --name ipv6_slaac

neutron net-create ipv6_dhcpv6
neutron subnet-create ipv6_dhcpv6 2001:db8:fd00:6002::/64 --ipv6-ra-mode dhcpv6-stateful --ipv6-address-mode dhcpv6-stateful --ip-version 6 --name ipv6_dhcpv6

neutron net-create dualstack
openstack subnet create ipv6 --network dualstack \
  --subnet-range 2001:db8:fd00:6003::/64 \
  --ipv6-ra-mode slaac \
  --ipv6-address-mode slaac \
  --ip-version 6
openstack subnet create ipv4 --network dualstack \
  --subnet-range 172.16.160.0/24

cat > /home/stack/user-data-scripts/userdata-slaac-$project << EOF
#cloud-config
# vim:syntax=yaml
debug: True
ssh_pwauth: True
disable_root: false
chpasswd:
  list: |
    root:redhat
  expire: false
write_files:
  - path: "/etc/sysconfig/network-scripts/ifcfg-eth0"
    permissions: "0644"
    owner: "root"
    content: |
      DEVICE=eth0
      TYPE=Ethernet
      ONBOOT=yes
      IPV6INIT=yes
      IPV6_AUTOCONF=yes
      IPV6_DEFROUTE=yes
      IPV6_FAILURE_FATAL=no
      IPV6_PEERROUTES=yes
runcmd:
 -  sed -i'.orig' -e's/without-password/yes/' /etc/ssh/sshd_config
 -  service sshd restart
 - 'systemctl restart network'
EOF

cat > /home/stack/user-data-scripts/userdata-dualstack-$project << EOF
#cloud-config
# vim:syntax=yaml
debug: True
ssh_pwauth: True
disable_root: false
chpasswd:
  list: |
    root:redhat
  expire: false
write_files:
  - path: "/etc/sysconfig/network-scripts/ifcfg-eth0"
    permissions: "0644"
    owner: "root"
    content: |
      DEVICE=eth0
      TYPE=Ethernet
      ONBOOT=yes
      IPV6INIT=yes
      BOOTPROTO=dhcp
      IPV6_AUTOCONF=yes
      IPV6_DEFROUTE=yes
      IPV6_FAILURE_FATAL=no
      IPV6_PEERROUTES=yes
runcmd:
 -  sed -i'.orig' -e's/without-password/yes/' /etc/ssh/sshd_config
 -  service sshd restart
 - 'systemctl restart network'
EOF

cat > /home/stack/user-data-scripts/userdata-dhcpv6-$project << EOF
#cloud-config
# vim:syntax=yaml
debug: True
ssh_pwauth: True
disable_root: false
chpasswd:
  list: |
    root:redhat
  expire: false
write_files:
  - path: "/etc/sysconfig/network-scripts/ifcfg-eth0"
    permissions: "0644"
    owner: "root"
    content: |
      DEVICE=eth0
      TYPE=Ethernet
      DHCPV6C=yes
      ONBOOT=yes
runcmd:
 -  sed -i'.orig' -e's/without-password/yes/' /etc/ssh/sshd_config
 -  service sshd restart
 - 'systemctl restart network'
EOF

openstack server create $project'_slaac_1' \
  --config-drive true \
  --user-data /home/stack/user-data-scripts/userdata-slaac-$project \
  --key-name undercloud-key \
  --flavor m1.medium \
  --image fedora-rawhide \
  --security-group allowall_$project \
  --network ipv6_slaac

openstack server create $project'_slaac_2' \
  --config-drive true \
  --user-data /home/stack/user-data-scripts/userdata-slaac-$project \
  --key-name undercloud-key \
  --flavor m1.medium \
  --image fedora-rawhide \
  --security-group allowall_$project \
  --network ipv6_slaac


openstack server create $project'_dualstack_1' \
  --config-drive true \
  --user-data /home/stack/user-data-scripts/userdata-dualstack-$project \
  --key-name undercloud-key \
  --flavor m1.medium \
  --image fedora-rawhide \
  --security-group allowall_$project \
  --network dualstack

openstack server create $project'_dualstack_2' \
  --config-drive true \
  --user-data /home/stack/user-data-scripts/userdata-dualstack-$project \
  --key-name undercloud-key \
  --flavor m1.medium \
  --image fedora-rawhide \
  --security-group allowall_$project \
  --network dualstack


openstack server create $project'_dhcpv6_1' \
  --config-drive true \
  --user-data /home/stack/user-data-scripts/userdata-dhcpv6-$project \
  --key-name undercloud-key \
  --flavor  m1.medium \
  --image fedora-rawhide \
  --security-group allowall_$project \
  --network ipv6_dhcpv6

openstack server create $project'_dhcpv6_2' \
  --config-drive true \
  --user-data /home/stack/user-data-scripts/userdata-dhcpv6-$project \
  --key-name undercloud-key \
  --flavor m1.medium \
  --image fedora-rawhide \
  --security-group allowall_$project \
  --network ipv6_dhcpv6