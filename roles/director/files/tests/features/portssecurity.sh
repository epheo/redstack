#!/bin/bash
project='portsecurity'

cd $( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
../new_identity.sh $project
source ~stack/rcfiles/$project'rc'

echo "Configuring Security Groups..."
openstack security group create no_icmp
openstack security group rule create no_icmp --protocol tcp --dst-port 1:65535
openstack security group rule create no_icmp --protocol udp --dst-port 1:65535

openstack security group create allow_icmp
openstack security group rule create allow_icmp --protocol tcp --dst-port 1:65535
openstack security group rule create allow_icmp --protocol udp --dst-port 1:65535
openstack security group rule create allow_icmp --protocol icmp --dst-port -1

openstack port create --network private --security-group no_icmp no_icmp
openstack port create --network private --security-group allow_icmp allow_icmp

openstack server create  test-port-security \
  --user-data /home/stack/user-data-scripts/userdata-enableroot \
  --key-name undercloud-key \
  --flavor  m1.medium \
  --image rhel7  \
  --nic port-id=$(neutron port-list | grep allow_icmp | awk '{print $2}') \
  --nic port-id=$(neutron port-list | grep no_icmp | awk '{print $2}') 

openstack server create test-port-security \
  --user-data /home/stack/user-data-scripts/userdata-enableroot \
  --key-name undercloud-key \
  --flavor  m1.medium \
  --security-group allowall_$project \
  --image rhel7  \
  --network private