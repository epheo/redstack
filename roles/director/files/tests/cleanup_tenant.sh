#!/bin/bash
source ~stack/stackrc
RCFILE="$(openstack stack list -c 'Stack Name' -f value)rc"
source ~stack/$RCFILE

project=$1

if [ -z $1 ]; 
  then echo 'Need to specify a project as $1';
  exit 1
fi;

echo "Deleting resources from project"

openstack server delete $(openstack server list --project  $project -c ID -f value)
openstack floating ip delete $(openstack floating ip list --project $project -c ID -f value)

for router in $(openstack router list --project $project -c ID -f value); 
do openstack router unset $router --external-gateway; 
   for i in $(openstack router show -c interfaces_info -f value $router \
                |jq . \
                |grep subnet_id \
                |awk '{print $2}' \
                |sed s/\"//g \
                |uniq)
   do openstack router remove subnet $router $i
   done
done
openstack router delete $(openstack router list --project $project -c ID -f value)

for i in $(openstack loadbalancer list --project $project -c id -f value); 
do openstack loadbalancer delete --cascade $i; 
done

for i in port \
         subnet \
         network \
         server \
         volume \
         'security group' \
         'network qos policy' ;
do openstack $i delete $(openstack $i list --project $project -c ID -f value) ;
done

openstack user delete $(openstack user list --project $project -c ID -f value |grep -v redhat)
openstack project delete $(openstack project list -c ID -c Name -f value |grep $project |awk '{print $1}')

rm ~stack/rcfiles/$project'rc'