#!/bin/bash

if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

iso='dd-megaraid_sas-07.710.50.00-1.el8_2.elrepo.iso'
rpm='kmod-megaraid_sas-07.710.50.00-1.el8_2.elrepo.x86_64.rpm'

GIT_PYTHON_REFRESH=quiet

mkdir -p ~/tmp/overcloud-full-initrd
mkdir ~/tmp/iso

cd ~/tmp/overcloud-full-initrd
/usr/lib/dracut/skipcpio /home/stack/images/overcloud-full.initrd | zcat | cpio -ivd | pax -r

cd ~/tmp/
curl https://elrepo.org/linux/dud/el8/x86_64/$iso > $iso
sudo mount -o loop $iso ~/tmp/iso

cd ~/tmp/overcloud-full-initrd
rpm2cpio ~/tmp/iso/rpms/x86_64/$rpm | cpio -idmv

find . 2>/dev/null | cpio --quiet -c -o | gzip -8  > ~/tmp/overcloud-full-modified.initrd

lsinitrd overcloud-full-modified.initrd > ~/tmp/lsinitrd.log

cp overcloud-full-modified.initrd /home/stack/images/overcloud-full.initrd

source ~stack/stackrc
sudo -E -u stack openstack overcloud image upload --update-existing --image-path /home/stack/images/
sudo -E -u stack openstack image set --property ramdisk_id=$(openstack image list | awk '/overcloud-full.initrd / { print $2 }') overcloud-full

umount ~/tmp/iso && rmdir ~/tmp/iso
cd ~ && rm -rf ~/tmp/

# # baremetal nodes also need to pick up the image metadata update (for initramdisk update)
# openstack baremetal node manage <baremetal_host>
# openstack overcloud node configure --all-manageable