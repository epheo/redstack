#!/bin/bash
project='octavia-lb'

cd $( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
../new_identity.sh $project
source ~stack/rcfiles/$project'rc'

echo "TESTING LBaaS..."

if ! openstack subnet list |grep subnet22\  ; then
  openstack network create net22
  openstack subnet create subnet22 \
    --network net22 \
    --subnet-range 172.16.223.0/24
fi

if ! openstack router list |grep external-$project  ; then
  idrouter=$(openstack router create external-$project -c id -f value)
  openstack router set $idrouter --external-gateway external_datacentre
  openstack router add subnet $idrouter subnet22
  openstack subnet set --dns-nameserver {{ dns_ip }} subnet22
fi

cat > /home/stack/user-data-scripts/userdata-webserver-$project << EOF
#!/bin/bash
curl -k https://{{ subscription.satellite_ip }}/pub/katello-ca-consumer-latest.noarch.rpm > katello-ca-consumer-latest.noarch.rpm
rpm -i katello-ca-consumer-latest.noarch.rpm
subscription-manager register --org={{ subscription.org }} --activationkey={{ subscription.activation_key }}
yum install -y nc
while true ; do nc -l -p 80 -c 'echo -e "HTTP/1.1 200 OK\n\n  \$(date) on host \$(hostname)"'; done
EOF

openstack server create  test-lb-member1 \
  --config-drive true \
  --user-data /home/stack/user-data-scripts/userdata-webserver-$project \
  --key-name undercloud-key --security-group allowall_octavia-lb  \
  --flavor  m1.medium --image rhel7 \
  --nic net-id=$(openstack network list -f value | grep net22 | awk '{print$1}')

openstack server create  test-lb-member2 --wait \
  --config-drive true \
  --user-data /home/stack/user-data-scripts/userdata-webserver-$project \
  --key-name undercloud-key --security-group allowall_octavia-lb  \
  --flavor  m1.medium --image rhel7 \
  --nic net-id=$(openstack network list -f value | grep net22 | awk '{print$1}')

openstack loadbalancer create --name test-loadbalancer --vip-subnet-id subnet22
sleep 5
  echo "...waiting available status"
  while [ -z  "$(openstack loadbalancer list -f value | grep test-loadbalancer | grep \ ACTIVE\  )" ]; do
        sleep 15
        echo -n "*"
  done
echo "Amphora is ACTIVE"

sleep 10
openstack loadbalancer listener create \
  --name test-lb-http \
  --protocol HTTP \
  --protocol-port 80 \
  test-loadbalancer

sleep 50
openstack loadbalancer pool create \
  --name test-lb-pool-http \
  --lb-algorithm ROUND_ROBIN \
  --listener test-lb-http \
  --protocol HTTP

sleep 10
openstack loadbalancer healthmonitor create  \
    --name test-HTTPmonitor-pool-http \
    --delay 5 \
    --max-retries 2 \
    --timeout 10 \
    --type HTTP \
    --url-path / \
    test-lb-pool-http


for instance in test-lb-member1 test-lb-member2
do
 openstack loadbalancer member create \
    --name $instance \
    --subnet-id subnet22 \
    --address $(openstack server show $instance -c addresses -f value | awk -F '=' '{print $2}') \
    --protocol-port 80 \
    test-lb-pool-http
done

LB_VIP_PORT=$(openstack port list -f value | grep $(openstack loadbalancer list --name test-loadbalancer -c vip_address -f value) | awk '{print $1}')
openstack port set --security-group allowall_octavia-lb $LB_VIP_PORT

LAST_FIP=$(openstack floating ip create --subnet external_datacentre external_datacentre -f value -c floating_ip_address )
openstack floating ip set --port $LB_VIP_PORT $LAST_FIP

echo "LB VIP: $LAST_FIP"
echo ""