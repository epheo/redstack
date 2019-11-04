#!/bin/bash
set -e 

imgpath='/home/stack/images-20191101/'
mkdir $imgpath && cd $imgpath

for i in $(ls /usr/share/rhosp-director-images/overcloud-full-latest*) $(ls /usr/share/rhosp-director-images/ironic-python-agent-latest-*)
 do tar -xvf $i -C $imgpath
done

virt-edit  -a overcloud-full.qcow2 /usr/lib/udev/rules.d/59-fc-wwpn-id.rules -e 's/;/,/g'

mkdir ramdisk && cd ramdisk/
zcat ../ironic-python-agent.initramfs  | cpio -idmv
sed -i 's/;/,/g' usr/lib/udev/rules.d/59-fc-wwpn-id.rules
find . | sudo cpio -o -c | gzip -9 > ../ironic-python-agent.initramfs

source /home/stack/stackrc && openstack overcloud image upload --update-existing --image-path $imgpath

for i in $(openstack baremetal node list -c UUID -f value); do openstack overcloud node configure $i; done

