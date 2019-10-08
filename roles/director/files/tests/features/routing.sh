#!/bin/bash
project='routing'

cd $( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
../new_identity.sh $project
source ~stack/rcfiles/$project'rc'

antiaff=$(openstack server group create \
              --policy anti-affinity gr-antiaff-$project \
              -c id -f value)

aff=$(openstack server group create \
          --policy affinity gr-aff-$project \
          -c id -f value)

set -x
openstack network create net20
openstack network create net21
openstack network create net21a

openstack subnet create subnet20 \
  --network net20 \
  --subnet-range 172.16.220.0/24

openstack subnet create subnet21 \
  --network net21 \
  --subnet-range 172.16.221.0/24

openstack subnet create subnet21a \
  --network net21a \
  --subnet-range 172.16.221.0/24

idrouter=$(openstack router create external-$project -c id -f value)
openstack router set $idrouter --external-gateway external_datacentre
openstack router add subnet $idrouter subnet20
openstack router add subnet $idrouter subnet21

idrouter=$(openstack router create external_a-$project -c id -f value)
openstack router set $idrouter --external-gateway external_datacentre
openstack router add subnet $idrouter subnet21a


openstack server create linux-1-$project \
  --config-drive true \
  --user-data /home/stack/user-data-scripts/userdata-enableroot \
  --hint group=$antiaff \
  --key-name undercloud-key \
  --security-group allowall_$project \
  --flavor  m1.medium \
  --image rhel7 \
  --network net20

openstack floating ip create \
  --port $(openstack port list --server $(openstack server show linux-1-$project -c id -f value) -c ID -f value | head -n1) external_datacentre

openstack server create linux-2-$project \
  --config-drive true \
  --user-data /home/stack/user-data-scripts/userdata-enableroot \
  --hint group=$antiaff \
  --key-name undercloud-key \
  --security-group allowall_$project \
  --flavor  m1.medium \
  --image rhel7 \
  --network net20

openstack server create linux-3-$project \
  --config-drive true \
  --user-data /home/stack/user-data-scripts/userdata-enableroot \
  --hint group=$aff \
  --key-name undercloud-key \
  --security-group allowall_$project \
  --flavor  m1.medium \
  --image rhel7 \
  --network net20

openstack server create linux-4-$project \
  --config-drive true \
  --user-data /home/stack/user-data-scripts/userdata-enableroot \
  --hint group=$aff \
  --key-name undercloud-key \
  --security-group allowall_$project \
  --flavor  m1.medium \
  --image rhel7 \
  --network net21

openstack server create linux-5-$project \
  --config-drive true \
  --user-data /home/stack/user-data-scripts/userdata-enableroot \
  --hint group=$aff \
  --key-name undercloud-key \
  --security-group allowall_$project \
  --flavor  m1.medium \
  --image rhel7 \
  --network net21a