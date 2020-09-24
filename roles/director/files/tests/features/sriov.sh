#!/bin/bash
project='sriov'

cd $( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
../new_identity.sh $project
source ~stack/rcfiles/$project'rc'

portname='vf0'
../new_sriov_userdata.sh $portname eth0 sriov_test_net

echo "Creating SR-IOV VMs ..."
openstack server create rawhide-$project \
  --config-drive true \
  --user-data /home/stack/user-data-scripts/userdata-sriov_$portname \
  --key-name undercloud-key \
  --security-group allowall_$project \
  --flavor epa.medium \
  --image fedora-rawhide \
  --nic port-id=$(openstack port list | grep $portname"\ " | awk '{print $2}')