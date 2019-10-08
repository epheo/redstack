#!/bin/bash
export OS_CACERT=
source ~/stackrc

mkdir /home/stack/ansible
rm -rf /home/stack/ansible/undercloud_inventory

cat > /home/stack/ansible.cfg << EOF
[defaults]
host_key_checking = False
EOF

echo "Creating inventory file..."

for node in $(openstack server list -c ID -f value); do
  data=$(openstack server show $node -c name -c addresses -f value)
  echo "$(echo $data | awk '{print $2}') ansible_user=heat-admin ansible_host=$(echo $data | awk '{print $1}' | awk -F = '{print $2}')" >> /home/stack/ansible/undercloud_inventory
done