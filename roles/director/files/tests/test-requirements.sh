#!/bin/bash
project='redhat'

source ~stack/stackrc
RCFILE="$(openstack stack list -c 'Stack Name' -f value)rc"
if [ ! -f ~stack/$RCFILE ]; then
    echo "~stack/$RCFILE not found!"
    exit -1
fi

cd $( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )

mkdir -p ~stack/rcfiles/
sed -i 's/\/\/v3/\/v3/g' ~stack/$RCFILE

./new_identity.sh $project

source ~/$RCFILE
openstack role add --user redhat --project admin admin

source ~stack/rcfiles/$project'rc'

{% if enable_sriov is sameas true %}
if ! openstack network list |grep  sriov_test_net;
then openstack network create sriov_test_net --share  \
       --provider-network-type vlan \
       --provider-physical-network {{ sriov_test_net.physnet }} \
       --provider-segment {{ sriov_test_net.vlanid }}
       
     openstack subnet create sriov_test_net --no-dhcp  \
       --network sriov_test_net  \
       --subnet-range {{ sriov_test_net.subnet }}
fi
{% endif %}
{% if enable_dpdk is sameas true %}
if ! openstack network list |grep  dpdk_test_net;
then openstack network create dpdk_test_net --share  \
       --provider-network-type vlan \
       --provider-physical-network {{ dpdk_test_net.physnet }} \
       --provider-segment {{ dpdk_test_net.vlanid }}
       
     openstack subnet create dpdk_test_net  \
       --network dpdk_test_net  \
       --subnet-range {{ dpdk_test_net.subnet }} \
       --allocation-pool start={{ dpdk_test_net.pool_start }},end={{ dpdk_test_net.pool_end }}
fi
{% endif %}

echo "Creating user data files..."

mkdir -p /home/stack/user-data-scripts

cat > /home/stack/user-data-scripts/userdata-enableroot << EOF
#cloud-config
# vim:syntax=yaml
debug: True
ssh_pwauth: True
disable_root: false
chpasswd:
  list: |
    root:redhat
  expire: false
runcmd:
 -  sed -i'.orig' -e's/without-password/yes/' /etc/ssh/sshd_config
 -  service sshd restart
 - 'systemctl restart network'
EOF

{% if proxy_url is defined  %}
export http_proxy=http://{{ proxy_url }}
export https_proxy=http://{{ proxy_url }}
export no_proxy={{ undercloud_ip }}
{% endif %}

if ! openstack image list | grep fedora30\  ; then
openstack image create fedora30 --file ~stack/user-images/fedora-30.qcow2 --disk-format qcow2 --container-format bare --public
fi

if ! openstack image list | grep rhel7\  ; then
openstack image create rhel7  --file ~stack/user-images/rhel-7.7.qcow2 --disk-format qcow2 --container-format bare --public
fi

if ! openstack image list | grep rhel8\  ; then
openstack image create rhel8  --file ~stack/user-images/rhel-8.0.qcow2 --disk-format qcow2 --container-format bare --public
fi

echo "Creating flavor..."
if ! openstack flavor list | grep m1.tiny\  ; then
  openstack flavor create --ram 512 --disk 1 --vcpus 1   {% if enable_nfvi is sameas true %}--property epa=false{% endif %}   m1.tiny
fi
if ! openstack flavor list | grep m1.small\  ; then
openstack flavor create --ram 2048 --disk 20 --vcpus 1  {% if enable_nfvi is sameas true %}--property epa=false{% endif %}   m1.small
fi
if ! openstack flavor list | grep m1.medium\  ; then
openstack flavor create --ram 4096 --disk 40 --vcpus 2  {% if enable_nfvi is sameas true %}--property epa=false{% endif %}   m1.medium
fi
if ! openstack flavor list | grep m1.large\  ; then
openstack flavor create --ram 8192 --disk 80 --vcpus 4  {% if enable_nfvi is sameas true %}--property epa=false{% endif %}   m1.large
fi
if ! openstack flavor list | grep m1.xlarge\  ; then
openstack flavor create --ram 16384 --disk 160 --vcpus 8  {% if enable_nfvi is sameas true %}--property epa=false{% endif %}   m1.xlarge
fi

{% if enable_nfvi is sameas true %}
if ! openstack flavor list | grep epa.tiny\  ; then
openstack flavor create --ram 512 --disk 1 --vcpus 1  --property epa=true  epa.tiny
nova flavor-key epa.tiny set hw:cpu_policy=dedicated
nova flavor-key epa.tiny set hw:cpu_thread_policy=isolate
nova flavor-key epa.tiny set hw:mem_page_size=1048576
nova flavor-key epa.tiny set hw:numa_mempolicy=strict
fi
if ! openstack flavor list | grep epa.small\  ; then
openstack flavor create --ram 2048 --disk 20 --vcpus 2  --property epa=true   epa.small
nova flavor-key epa.small set hw:cpu_policy=dedicated
nova flavor-key epa.small set hw:cpu_thread_policy=isolate
nova flavor-key epa.small set hw:mem_page_size=1048576
nova flavor-key epa.small set hw:numa_mempolicy=strict
fi
if ! openstack flavor list | grep epa.medium\  ; then
openstack flavor create --ram 4096 --disk 40 --vcpus 2  --property epa=true   epa.medium
nova flavor-key epa.medium set hw:cpu_policy=dedicated
nova flavor-key epa.medium set hw:cpu_thread_policy=isolate
nova flavor-key epa.medium set hw:mem_page_size=1048576
nova flavor-key epa.medium set hw:numa_mempolicy=strict
fi
if ! openstack flavor list | grep epa.large\  ; then
openstack flavor create --ram 8192 --disk 80 --vcpus 4  --property epa=true   epa.large
nova flavor-key epa.large set hw:cpu_policy=dedicated
nova flavor-key epa.large set hw:cpu_thread_policy=isolate
nova flavor-key epa.large set hw:mem_page_size=1048576
nova flavor-key epa.large set hw:numa_mempolicy=strict
fi
if ! openstack flavor list | grep epa.xlarge\  ; then
openstack flavor create --ram 16384 --disk 160 --vcpus 8  --property epa=true   epa.xlarge
nova flavor-key epa.xlarge set hw:cpu_policy=dedicated
nova flavor-key epa.xlarge set hw:cpu_thread_policy=isolate
nova flavor-key epa.xlarge set hw:mem_page_size=1048576
nova flavor-key epa.xlarge set hw:numa_mempolicy=strict
fi
{% endif %}


{% if enable_nfvi is sameas true %}
openstack aggregate create --zone LOW --property epa=false low
for i in $(openstack hypervisor list --matching compute- -f value -c 'Hypervisor Hostname'); do
 openstack aggregate add host low $i
done

openstack aggregate create --zone NFVI --property epa=true nfvi
for i in $(openstack hypervisor list --matching computenfvi- -f value -c 'Hypervisor Hostname'); do
  openstack aggregate add host nfvi $i
done
{% endif %}

#ID_antiaff=$(openstack server group create --policy anti-affinity gr-antiaff -c id -f value)
#ID_aff=$(openstack server group create --policy affinity gr-aff -c id -f value)

{% if external_net.fip_pool_start is defined %}

if ! openstack network list |grep private\ ;
then 
  openstack network create private --share
  openstack subnet create private --subnet-range 172.16.42.0/24   --network private
fi
if ! openstack router list |grep external\ ;
then 
  openstack router create external
  openstack router add subnet external private
fi

if ! openstack network list |grep public\ ;
then 
  openstack network create public --external --provider-network-type vlan --provider-physical-network {{ external_net.physnet | default('datacentre')  }} --provider-segment {{ external_net.vlanid }} --mtu 1500 --share
  openstack subnet  create public --network public --allocation-pool start={{ external_net.fip_pool_start }},end={{ external_net.fip_pool_end }} --gateway {{ external_net.gateway }} --subnet-range {{ external_net.subnet }}
  openstack router set external --external-gateway public
fi
{% endif %}

{% if provider_networks is defined %}

{% for net in provider_networks %}
if ! openstack network list |grep {{ net.name }}\ ;
then 
  openstack network create {{ net.name }} \
   --external --provider-network-type vlan \
   --provider-physical-network {{ net.physnet }} \
   --provider-segment {{ net.vlanid }} \
   --mtu 1500 --share
  openstack subnet  create {{ net.name }} \
    --network {{ net.name }} \
{% if net.pool_start is defined %}
    --allocation-pool start={{ net.pool_start }},end={{ net.pool_end }} \
{% endif %}
{% if net.gateway is defined %}
    --gateway {{ net.gateway }} \
{% endif %}
    --subnet-range {{ net.subnet }}
fi
{% endfor %}

{% endif %}


openstack flavor create --ram 16384 --disk 50 --vcpus 4  epa.xlarge
nova flavor-key epa.openshift set hw:cpu_policy=dedicated
nova flavor-key epa.openshift set hw:cpu_thread_policy=isolate
nova flavor-key epa.openshift set hw:mem_page_size=1048576
nova flavor-key epa.openshift set hw:numa_mempolicy=strict