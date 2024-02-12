#!/bin/bash
set -euxo pipefail

project="trunk"

cd $( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
../new_identity.sh $project
source ~stack/rcfiles/$project'rc'

echo "Create 2 networks with a segmentation_type VXLAN."
neutron net-create vlan300
neutron net-create vlan301
neutron net-create private
neutron subnet-create --name vlan300-subnet vlan300 192.168.230.0/24
neutron subnet-create --name vlan301-subnet vlan301 192.168.231.0/24
neutron subnet-create --name private-subnet private 172.16.42.0/24

echo "Create parent ports for 2 instances"
openstack port create --network private trunk1
openstack port create --network private trunk2

echo "Create subports with the same MAC address as the parent port"
openstack port create --network vlan300 --mac-address $(openstack port list |grep trunk1\  |awk '{print $6}') trunk1-vlan300
openstack port create --network vlan301 --mac-address $(openstack port list |grep trunk1\  |awk '{print $6}') trunk1-vlan301
openstack port create --network vlan300 --mac-address $(openstack port list |grep trunk2\  |awk '{print $6}') trunk2-vlan300
openstack port create --network vlan301 --mac-address $(openstack port list |grep trunk2\  |awk '{print $6}') trunk2-vlan301

echo "Link parent ports and subports together by creating and setting the trunk ports"
openstack network trunk create --parent-port trunk1 trunk1
openstack network trunk create --parent-port trunk2 trunk2

openstack network trunk set --subport port=trunk1-vlan300,segmentation-type=vlan,segmentation-id=300 trunk1
openstack network trunk set --subport port=trunk1-vlan301,segmentation-type=vlan,segmentation-id=301 trunk1
openstack network trunk set --subport port=trunk2-vlan300,segmentation-type=vlan,segmentation-id=300 trunk2
openstack network trunk set --subport port=trunk2-vlan301,segmentation-type=vlan,segmentation-id=301 trunk2

cat > /home/stack/user-data-scripts/userdata-trunk << EOF
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
  - path: "/etc/sysconfig/network-scripts/ifcfg-vlan300"
    permissions: "0644"
    owner: "root"
    content: |
      DEVICE="eth0.300"
      BOOTPROTO="dhcp"
      BOOTPROTOv6="dhcp"
      ONBOOT="yes"
      USERCTL="yes"
      PEERDNS="yes"
      IPV6INIT="yes"
      PERSISTENT_DHCLIENT="1"
      VLAN=yes
  - path: "/etc/sysconfig/network-scripts/ifcfg-vlan301"
    permissions: "0644"
    owner: "root"
    content: |
      DEVICE="eth0.301"
      BOOTPROTO="dhcp"
      BOOTPROTOv6="dhcp"
      ONBOOT="yes"
      USERCTL="yes"
      PEERDNS="yes"
      IPV6INIT="yes"
      PERSISTENT_DHCLIENT="1"
      VLAN=yes
runcmd:
 -  sed -i'.orig' -e's/without-password/yes/' /etc/ssh/sshd_config
 -  service sshd restart
 - 'systemctl restart network'
EOF

openstack server create trunk_1 \
  --config-drive true \
  --user-data /home/stack/user-data-scripts/userdata-trunk \
  --key-name undercloud-key \
  --flavor  m1.medium \
  --image fedora-rawhide \
  --security-group allowall_trunk \
  --nic port-id=trunk1

openstack server create trunk_2 \
  --config-drive true \
  --user-data /home/stack/user-data-scripts/userdata-trunk \
  --key-name undercloud-key \
  --flavor  m1.medium \
  --image fedora-rawhide \
  --security-group allowall_trunk \
  --nic port-id=trunk2
