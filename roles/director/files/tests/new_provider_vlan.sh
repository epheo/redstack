#!/bin/bash
set -euxo pipefail

echo "Creating new provider Vlan ..."

if [ -z $1 ]; then echo '$1 must be set as name'; exit 0; 
              else name=$1
fi
if [ -z $2 ]; then echo '$2 must be set as segmentation id';
                   segid=$(( ( RANDOM % 130 ) + 50 ))
                   echo "Segmentation ID is now $2";
              else segid=$2; 
fi
if [ -z $3 ]; then network="10.8.$2.0/24" ;
              else network=$3
fi

mask=$(echo $network |sed 's/.0\/24//g')

if ! openstack network list |grep $name$segid'_datacentre';
then openstack network create $name$segid'_datacentre' \
       --share  \
       --mtu 1500 \
       --provider-network-type vlan \
       --provider-physical-network datacentre \
       --provider-segment $segid

     openstack subnet create $name$segid'_datacentre' \
       --network $name$segid'_datacentre' \
       --subnet-range $network \
       --allocation-pool 'start='$mask'.128,end='$mask'.191'
fi   

if ! openstack network list |grep $name$segid'_sriov';
then openstack network create $name$segid'_sriov' \
       --share  \
       --mtu 1500 \
       --provider-network-type vlan \
       --provider-physical-network sriov \
       --provider-segment $segid

     openstack subnet create $name$segid'_sriov' --no-dhcp  \
       --network $name$segid'_sriov'  \
       --subnet-range $network \
       --gateway $mask'.1' 
       #--allocation-pool 'start='$mask'.5,end='$mask'.127'
fi

if ! openstack network list |grep $name$segid'_dpdk';
then openstack network create $name$segid'_dpdk' \
       --share  \
       --mtu 1500 \
       --provider-network-type vlan \
       --provider-physical-network dpdk \
       --provider-segment $segid

     openstack subnet create $name$segid'_dpdk' \
       --network $name$segid'_dpdk'  \
       --subnet-range $network \
       --allocation-pool 'start='$mask'.193,end='$mask'.254'
fi
