#!/bin/bash
set -euxo pipefail

project="qos"

cd $( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
../new_identity.sh $project
source ~stack/rcfiles/$project'rc'

echo "Testing QoS..."
# openstack network create test135_$project \
#        --mtu 1500 \
#        --provider-network-type vlan \
#        --provider-physical-network datacentre \
#        --provider-segment 135
# 
# openstack subnet create subnet135_$project \
#   --network test135_$project \
#   --subnet-range 10.8.135.0/24 \
#   --allocation-pool start=10.8.135.6,end=10.8.135.20

openstack network create net1_$project
openstack subnet create subnet1_$project \
  --network net1_$project \
  --subnet-range 172.16.32.0/24 \

idrouter=$(openstack router create external$project -c id -f value)
openstack router set $idrouter --external-gateway external_datacentre
openstack router add subnet $idrouter subnet1_$project

openstack network qos policy create 200limit
openstack network qos rule create --type 'bandwidth-limit' --max-kbps 3000 --max-burst-kbits 3000 --ingress 200limit
openstack network qos rule create --type 'bandwidth-limit' --max-kbps 3000 --max-burst-kbits 3000 --egress 200limit
# openstack network qos rule create --dscp-mark 18 200limit


portname='port200limit'
openstack port create --network net1_$project $portname
openstack port set --security-group allowall_qos --qos-policy 200limit $portname
openstack server create limited_$project \
  --config-drive true \
  --user-data /home/stack/user-data-scripts/userdata-enableroot \
  --key-name undercloud-key \
  --flavor m1.medium \
  --image fedora-rawhide \
  --security-group allowall_$project \
  --nic port-id=$(openstack port list | grep $portname | awk '{print $2}')

portname='portnolimit'
openstack port create --network net1_$project $portname
openstack port set --security-group allowall_qos $portname
openstack server create unlimited_$project \
  --config-drive true \
  --user-data /home/stack/user-data-scripts/userdata-enableroot \
  --key-name undercloud-key \
  --flavor m1.medium \
  --image fedora-rawhide \
  --security-group allowall_$project \
  --nic port-id=$(openstack port list | grep $portname | awk '{print $2}')


openstack floating ip create --port portnolimit external_datacentre
openstack floating ip create --port port200limit external_datacentre

openstack server list



exit 0
# Director config

cat << EOF > /etc/sysconfig/network-scripts/ifcfg-vlan135 
DEVICE=vlan135
ONBOOT=yes
HOTPLUG=no
NM_CONTROLLED=no
PEERDNS=no
DEVICETYPE=ovs
TYPE=OVSIntPort
OVS_BRIDGE=br-ctlplane
OVS_OPTIONS="tag=135"
BOOTPROTO=static
IPADDR=10.8.135.5
PREFIX=24
NETWORK=10.8.135.0
DEFROUTE=no
EOF

ifup vlan135
