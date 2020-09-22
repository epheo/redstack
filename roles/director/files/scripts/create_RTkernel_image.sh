#!/bin/bash

cd ~/images
cp overcloud-full.qcow2 overcloud-realtime-compute.qcow2

sudo yum -y install libguestfs-tools

virt-customize -a overcloud-realtime-compute.qcow2 --run-command \
  "subscription-manager register \
    --org={{ subscription.org }} \
    --activationkey={{ subscription.activation_key }}"

pool_id=$(sudo subscription-manager list \
  --available --all \
  --matches="Red Hat OpenStack" |grep "Pool ID" |awk '{print $3}' |head -n1)
  
virt-customize -a overcloud-realtime-compute.qcow2 --run-command \
  "subscription-manager attach --pool $pool_id"

virt-customize -a overcloud-realtime-compute.qcow2 --run-command \
  'subscription-manager repos --enable=rhel-7-server-nfv-rpms \
  --enable=rhel-7-server-rpms \
  --enable=rhel-7-server-rh-common-rpms \
  --enable=rhel-7-server-extras-rpms \
  --enable=rhel-7-server-openstack-13-rpms'

cat <<'EOF' > rt.sh
  #!/bin/bash
  set -eux
  yum -v -y --setopt=protected_packages= erase kernel.$(uname -m)
  yum -v -y install kernel-rt kernel-rt-kvm tuned-profiles-nfv-host
EOF

virt-customize -a overcloud-realtime-compute.qcow2 -v --run rt.sh 2>&1 | tee virt-customize.log

cat virt-customize.log | grep Verifying

virt-customize -a overcloud-realtime-compute.qcow2 --selinux-relabel

mkdir image
guestmount -a overcloud-realtime-compute.qcow2 -i --ro image
cp image/boot/vmlinuz-*.x86_64 ./overcloud-realtime-compute.vmlinuz
cp image/boot/initramfs-*.x86_64.img ./overcloud-realtime-compute.initrd
guestunmount image
rmdir image

source ~/stackrc
openstack overcloud image upload --update-existing --os-image-name overcloud-realtime-compute.qcow2