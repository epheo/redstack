#!/bin/bash
project='dpdk'

cd $( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
../new_identity.sh $project
source ~stack/rcfiles/$project'rc'

echo "Creating DPDK VMs ..."
hyperid=$(openstack server create dpdk-$project \
  --wait \
  --config-drive true \
  --user-data /home/stack/user-data-scripts/userdata-enableroot  \
  --key-name undercloud-key \
  --flavor epa.medium \
  --image rhel7 \
  --network dpdk_test_net \
  --network private \
  --availability-zone NFVI \
  -c OS-EXT-SRV-ATTR:hypervisor_hostname -f value)

ssh="ssh heat-admin@$( . ~/stackrc; openstack server list -c Name -c Networks -f value |grep $(echo $hyperid |awk -F'.' '{print $1}') |awk -F'=' '{print $2}')"

$ssh sudo ovs-appctl dpif/show
$ssh sudo ovs-ofctl dump-ports br-int
$ssh sudo ovs-appctl dpctl/dump-flows
$ssh sudo ovs-appctl dpctl/show --statistics
$ssh sudo ovs-appctl dpif-netdev/pmd-stats-show
$ssh sudo ovs-appctl dpif-netdev/pmd-stats-clear
$ssh sudo ovs-appctl dpif-netdev/pmd-rxq-show