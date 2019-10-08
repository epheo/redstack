#!/bin/bash
set -x

source /home/stack/stackrc

RCFILE="$(openstack stack list -c 'Stack Name' -f value)rc"
EXTVLANID={{ external_guest_net.vlanid }}
NETEXT={{ external_guest_net.subnet }}
EXTGW={{ external_guest_net.gateway }}
EXTSTART={{ external_guest_net.fip_pool_start }}
EXTEND={{ external_guest_net.fip_pool_end }}

source ~/$RCFILE

openstack network create private --share
openstack subnet create private --subnet-range 172.16.42.0/24   --network private
openstack router create external
openstack router add subnet external private

openstack network create external_datacentre --external --provider-network-type vlan --provider-physical-network datacentre --provider-segment $EXTVLANID --mtu 1500 --share
openstack subnet create  external_datacentre --network external_datacentre --allocation-pool start=$EXTSTART,end=$EXTEND --gateway $EXTGW --subnet-range $NETEXT

openstack router set external --external-gateway external_datacentre