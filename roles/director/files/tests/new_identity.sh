#!/bin/bash
source ~stack/stackrc
RCFILE="$(openstack stack list -c 'Stack Name' -f value)rc"
source ~stack/$RCFILE

if [ -z $1 ]
then echo "Please call with $1"
     exit 1
fi
project=$1

echo "******************"
echo $project
echo "******************"

for i in $(openstack project list -c Name -f value); 
do if [ $i == $project ]; 
     then echo "Project $project exists already"; 
     exit 1
   fi;
done

echo "Creating new identity ..."

openstack project create $project

openstack user create --project $project --password redhat $project
openstack role add --user $project --project $project admin


cp ~stack/$RCFILE ~stack/rcfiles/$project'rc'
sed -i -- "s/OS_USERNAME=admin/OS_USERNAME=$project/g" ~stack/rcfiles/$project'rc'
sed -i  '/OS_PASSWORD/d' ~stack/rcfiles/$project'rc' ;  echo export OS_PASSWORD=redhat >> ~stack/rcfiles/$project'rc'
sed -i -- "s/OS_TENANT_NAME=admin/OS_TENANT_NAME=$project/g" ~stack/rcfiles/$project'rc'
sed -i -- "s/OS_PROJECT_NAME=admin/OS_PROJECT_NAME=$project/g" ~stack/rcfiles/$project'rc'
echo "export project=$project" >> ~stack/rcfiles/$project'rc'

source ~stack/rcfiles/$project'rc'

openstack quota set --cores 100 --instances 50 --ram 131072 --floating-ips 50  $project

openstack keypair create --public-key ~stack/.ssh/id_rsa.pub undercloud-key

echo "Configuring Security Groups..."
openstack security group create allowall_$project
openstack security group rule create allowall_$project --protocol tcp --dst-port 1:65535
openstack security group rule create allowall_$project --protocol udp --dst-port 1:65535
openstack security group rule create allowall_$project --protocol icmp --dst-port -1