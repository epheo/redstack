#!/bin/bash

if [ -z $1 ]; then echo '$1 must be set as new sriov port name'; exit 0; fi
if [ -z $2 ]; then echo '$2 must be set as guest sriov interface'; exit 0; fi
if [ -z $3 ]; then echo '$3 must be set as network'; 3="test130_sriov" ; fi

portname=$1
interface=$2
network=$3

for i in $(openstack port list -c Name -f value); 
do if [ $i == $portname ]; 
     then echo  "Port $portname exists already"; 
     exit 1
   fi;
done

echo "Creating new SR-IOV metadata and ports ..."

openstack port create --network $network --vnic-type direct $portname
#STATIC_IP=$(openstack port show $portname -f value -c fixed_ips | awk -F \' '{print$2}')
STATIC_IP=$(openstack port show $portname -f value -c fixed_ips | awk -F "'" '{print$8}')
STATIC_GW=$(openstack subnet show $(openstack port show $portname -f value -c fixed_ips | awk -F \' '{print$4}') -c gateway_ip -f value)
STATIC_PREFIX=$(openstack subnet show $(openstack port show $portname -f value -c fixed_ips | awk -F \' '{print$4}') -c cidr -f value | awk -F \/ '{print$2}')

cat > /home/stack/user-data-scripts/userdata-sriov_$portname << EOF
#cloud-config
disable_root: false
chpasswd:
  list: |
    root:redhat
  expire: false
write_files:
  - path: "/etc/sysconfig/network-scripts/ifcfg-$interface"
    permissions: "0644"
    owner: "root"
    content: |
      BOOTPROTO=none
      IPADDR=$STATIC_IP
      PREFIX=$STATIC_PREFIX
      GATEWAY=$STATIC_GW
      DEVICE=$interface
      ONBOOT=yes
      TYPE=Ethernet
      USERCTL=no
runcmd:
 -  sed -i'.orig' -e's/without-password/yes/' /etc/ssh/sshd_config
 -  service sshd restart
 - 'systemctl restart network'
 - 'ifup eth0'
EOF

