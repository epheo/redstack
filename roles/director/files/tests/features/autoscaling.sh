#!/bin/bash
project='octavia-lb'

cd $( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
../new_identity.sh $project
source ~stack/rcfiles/$project'rc'

echo "TESTING LBaaS with AutoScaling ..."

openstack network create net30
openstack subnet create subnet30 \
  --network net30 \
  --subnet-range 172.16.230.0/24

idrouter=$(openstack router create external$project -c id -f value)
openstack router set $idrouter --external-gateway external_datacentre
openstack router add subnet $idrouter subnet30

net_internal=$(openstack network list -f value | grep net30 | awk '{print$1}')
subnet_internal=$(openstack subnet list -f value | grep net30 | awk '{print$1}')
net_external=$(openstack network list -f value | grep external_datacentre | awk '{print$1}')

security_group=$(openstack security group show allowall_$project -c id -f value)

cat > /home/stack/tests/features/autoscaling/environment-autoscaling.yaml << EOF
parameters:
  image: fedora30
  key: undercloud-key
  flavor: m1.small
  database_flavor: m1.small
  network: $net_internal
  subnet_id: $subnet_internal
  database_name: wordpress
  database_user: wordpress
  external_network_id: $net_external
  security_group_front: $security_group
  security_group_db: $security_group
EOF

openstack stack create --wait -e /home/stack/tests/features/autoscaling/environment-autoscaling.yaml -t /home/stack/tests/features/autoscaling/lb-wordpress.yaml test-autoscale

# Command to rise CPU: dd if=/dev/zero of=/dev/null
#     if multiple cores: fulload() { dd if=/dev/zero of=/dev/null | dd if=/dev/zero of=/dev/null | dd if=/dev/zero of=/dev/null | dd if=/dev/zero of=/dev/null & }; fulload; read; killall dd

# Stress has been installed so it could be also something like: "stress --cpu 2 --timeout 180"
