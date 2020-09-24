


cd $( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
../new_identity.sh $project
source ~stack/rcfiles/$project'rc'

echo "TESTING MANILA..."


##################################################
########## TEST for MANILA CEPHFS driver
##################################################

#manila type-create cephfsnativetype false
#manila type-key cephfsnativetype set vendor_name=Ceph storage_protocol=CEPHFS

#manila create --share-type cephfsnativetype --name cephnativeshare1 cephfs 1

#FULL_PATH=$(manila share-export-location-list cephnativeshare1 | grep : | awk '{print $4}')

#CEPHFS_MONS=$(echo $FULL_PATH | awk -F :/ '{print $1}')
#CEPHFS_MOUNTPOINT="/$(echo $FULL_PATH | awk -F :/ '{print $2}')"

#manila access-allow cephnativeshare1 cephx redhat

#CEPHFS_KEY=$(manila access-list cephnativeshare1 | grep : | awk '{print $12}')

#cat > /home/stack/user-data-scripts/userdata-cephnativeshare1 << EOF
##cloud-config
#write_files:
# - content: |
#       [client.redhat]
#              key = $CEPHFS_KEY
#   path: /root/redhat.keyring
# - content: |
#       [client]
#              client quota = true
#              mon host = $CEPHFS_MONS
#   path: /root/ceph.conf
#packages:
# - ceph-fuse
#runcmd:
# - [ mkdir, -p, /shares ]
# - [ ceph-fuse, /shares, --id=redhat, --conf=/root/ceph.conf, --keyring=/root/redhat.keyring, --client-mountpoint=$CEPHFS_MOUNTPOINT ]
#EOF


#openstack server create  test-manila-1 --wait  --hint group=$ID_antiaff --user-data /home/stack/user-data-scripts/userdata-cephnativeshare1 --key-name undercloud-key --security-group allowall  --flavor  m1.small --image fedora30 --nic net-id=$(openstack network list -f value | grep redhat-internal | awk '{print$1}')


#LAST_FIP=$(openstack floating ip create --subnet floating floating -f value -c floating_ip_address )
#openstack server add floating ip test-manila-1  $LAST_FIP
#echo "Try to connect to $LAST_FIP"


##openstack server create  test-manila-2 --wait  --hint group=$ID_antiaff --user-data /home/stack/user-data-scripts/userdata-cephnativeshare1 --key-name undercloud-key --security-group allowall  --flavor  m1.small --image fedora30 --nic net-id=$(openstack network list -f value | grep redhat-internal | awk '{print$1}')

##LAST_FIP=$(openstack floating ip create --subnet floating floating -f value -c floating_ip_address )
##openstack server add floating ip test-manila-2  $LAST_FIP
##echo "Try to connect to $LAST_FIP"


########################################################################


##################################################
########## TEST for MANILA NFS driver
##################################################


openstack network create --provider-network-type flat --provider-physical-network provider --share shares
openstack subnet create --network shares --subnet-range 172.28.0.0/24 --ip-version 4 --allocation-pool start=172.28.0.21,end=172.28.0.200 --gateway none --dhcp shares


manila type-create cephfsnfstype false
manila type-key cephfsnfstype set vendor_name=Ceph storage_protocol=NFS

manila create --share-type cephfsnfstype --name cephnfsshare1 nfs 1


manila access-allow cephnfsshare1 ip 172.28.0.0/24


FULL_PATH=$(manila share-export-location-list cephnfsshare1 | grep : | awk '{print $4}')


cat > /home/stack/user-data-scripts/userdata-cephnfsshare1 << EOF
#cloud-config
debug: True
ssh_pwauth: True
disable_root: false
chpasswd:
  list: |
    root:redhat
  expire: false
write_files:
  - path: "/etc/sysconfig/network-scripts/ifcfg-eth1"
    permissions: "0644"
    owner: "root"
    content: |
      BOOTPROTO=dhcp
      PEERDNS=no
      DEVICE=eth1
      ONBOOT=yes
      TYPE=Ethernet
      USERCTL=no
packages:
 - nfs-utils
runcmd:
 -  sed -i'.orig' -e's/without-password/yes/' /etc/ssh/sshd_config
 -  service sshd restart
 - 'systemctl restart network'
 - 'mkdir -p /shares'
 - 'mount -vv -t nfs $FULL_PATH /shares'
EOF




# Security group to drop all incomming connections using shares network
openstack security group create no-ingress
openstack port create nfs-port0 --network shares --security-group no-ingress


openstack server create  test-manila-1 --wait  --hint group=$ID_antiaff --user-data /home/stack/user-data-scripts/userdata-cephnfsshare1 --key-name undercloud-key --security-group allowall  --flavor  m1.small --image fedora-rawhide --nic net-id=$(openstack network list -f value | grep redhat-internal | awk '{print$1}') --nic port-id=$(openstack port show nfs-port0 -c id -f value)


LAST_FIP=$(openstack floating ip create --subnet floating floating -f value -c floating_ip_address )
#openstack server add floating ip test-manila-1  $LAST_FIP
PORT_TO_FIP=$(openstack port list -c id -c "Fixed IP Addresses" -f value   | grep $(openstack server show test-manila-1 -f value -c addresses | awk -F = '{print $2}' | awk -F ';' '{print $1}') | awk '{print $1}')
openstack floating ip set --port $PORT_TO_FIP $LAST_FIP


echo "Try to connect to $LAST_FIP"



