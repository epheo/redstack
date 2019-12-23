#!/bin/bash
set -x
source stackrc

for i in $(openstack baremetal node list -c Name -f value); 
do 
  case "$i" in
    *ceph* ) 
      node_uuid=$(openstack baremetal node list -f value -c Name -c UUID |grep $i |awk '{print $1}')
      openstack baremetal node set --property capabilities='profile:ceph-storage{% if enable_uefi is sameas true %},boot_mode:uefi{% endif %},boot_option:local' $node_uuid
      root_dev="$(cat ~stack/introspection/$i.json |jq '.inventory.disks[0].serial')"
      if [ "$root_dev" != null ]; then
        openstack baremetal node set --property root_device="{\"serial\": $root_dev }" $node_uuid
      fi
    ;;
    *control* ) 
      node_uuid=$(openstack baremetal node list -f value -c Name -c UUID |grep $i |awk '{print $1}')
      openstack baremetal node set --property capabilities='profile:control{% if enable_uefi is sameas true %},boot_mode:uefi{% endif %},boot_option:local' $node_uuid
      root_dev="$(cat ~stack/introspection/$i.json |jq '.inventory.disks[0].serial')"
      if [ "$root_dev" != null ]; then
        openstack baremetal node set --property root_device="{\"serial\": $root_dev }" $node_uuid
      fi
    ;;
    *compute* ) 
      node_uuid=$(openstack baremetal node list -f value -c Name -c UUID |grep $i |awk '{print $1}')
      openstack baremetal node set --property capabilities='profile:compute{% if enable_uefi is sameas true %},boot_mode:uefi{% endif %},boot_option:local' $node_uuid
      root_dev="$(cat ~stack/introspection/$i.json |jq '.inventory.disks[0].serial')"
      if [ "$root_dev" != null ]; then
        openstack baremetal node set --property root_device="{\"serial\": $root_dev }" $node_uuid
      fi
    ;;
    * ) echo "Error...";;
  esac
done