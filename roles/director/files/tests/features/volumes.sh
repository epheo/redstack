#!/bin/bash
project='volumes'

cd $( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
../new_identity.sh $project
source ~stack/rcfiles/$project'rc'

echo "TESTING VOLUMES..."

echo "Creating and attaching volume..."
openstack volume create --size 1 test
openstack server add volume test test

echo "Creating and attaching encrypted volume..."
openstack volume type create --encryption-provider nova.volume.encryptors.luks.LuksEncryptor --encryption-cipher aes-xts-plain64 --encryption-key-size 256 --encryption-control-location front-end LuksEncryptor-Template-256
openstack volume create --size 1 --type LuksEncryptor-Template-256 'Encrypted-Test-Volume'

sleep 15

openstack server add volume test Encrypted-Test-Volume




#echo "Creating instance  boot from volume"

#BOOTVOLID=$(openstack volume create --image $(openstack image list -f value | grep cirros | awk '{print $1}') --size 10 bootable_volume -c id -f value)

#openstack server create --wait --user-data /home/stack/user-data-scripts/userdata-enableroot --key-name undercloud-key --flavor m1.tiny  --security-group allowall --nic net-id=$(openstack network list -f value | grep redhat-internal | awk '{print$1}') \
#  --volume bootable_volume \
#  --block-device source=volume,id=$BOOTVOLID,dest=volume,size=10,shutdown=preserve,bootindex=0 \
#  test-bootvol