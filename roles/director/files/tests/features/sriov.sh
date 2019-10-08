#!/bin/bash
project='sriov'

cd $( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
../new_identity.sh $project
source ~stack/rcfiles/$project'rc'

antiaff=$(openstack server group create \
              --policy anti-affinity gr-antiaff-$project \
              -c id -f value)

portname='vf0'
~stack/scripts/new_sriov_userdata.sh $portname eth1 test130_sriov

echo "Creating SR-IOV VMs ..."
openstack server create sriov-$project \
  --config-drive true \
  --user-data /home/stack/user-data-scripts/userdata-sriov_$portname \
  --hint group=$antiaff \
  --key-name undercloud-key \
  --security-group allowall_$project \
  --flavor epa.medium \
  --image fedora30 \
  --nic port-id=$(openstack port list | grep $portname"\ " | awk '{print $2}') \
  --availability-zone DPDK-INTEL

