#!/bin/bash
set -x
source stackrc

for i in $(openstack baremetal node list -c Name -f value); 
do 
  case "$i" in
    *ceph* ) 
      openstack baremetal node set --property capabilities='profile:ceph-storage,boot_option:local' $(openstack baremetal node list -f value -c Name -c UUID |grep $i |awk '{print $1}')
      root_dev="$(cat ~stack/introspection/$i.json |jq '.inventory.disks[0].serial')"
      openstack baremetal node set --property root_device="{\"serial\": $root_dev }" $(openstack baremetal node list -f value -c Name -c UUID |grep $i |awk '{print $1}')
    ;;
    *control* ) 
      openstack baremetal node set --property capabilities='profile:control,boot_option:local' $(openstack baremetal node list -f value -c Name -c UUID |grep $i |awk '{print $1}')
      root_dev="$(cat ~stack/introspection/$i.json |jq '.inventory.disks[0].serial')"
      openstack baremetal node set --property root_device="{\"serial\": $root_dev }" $(openstack baremetal node list -f value -c Name -c UUID |grep $i |awk '{print $1}')
    ;;
    *compute* ) 
      openstack baremetal node set --property capabilities='profile:compute,boot_option:local' $(openstack baremetal node list -f value -c Name -c UUID |grep $i |awk '{print $1}')
      root_dev="$(cat ~stack/introspection/$i.json |jq '.inventory.disks[0].serial')"
      openstack baremetal node set --property root_device="{\"serial\": $root_dev }" $(openstack baremetal node list -f value -c Name -c UUID |grep $i |awk '{print $1}')
    ;;
    * ) echo "Error...";;
  esac
done