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

cat > /home/stack/user-data-scripts/userdata-sriov_$portname << EOF
#cloud-config
disable_root: false
chpasswd:
  list: |
    root:redhat
  expire: false
runcmd:
 -  sed -i'.orig' -e's/without-password/yes/' /etc/ssh/sshd_config
 -  service sshd restart
EOF

