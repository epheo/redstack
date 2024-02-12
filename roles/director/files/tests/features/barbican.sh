echo "TESTING BARBICAN..."
echo "**********************************"

openstack role create creator
openstack role add --user redhat --project redhat creator
openstack role add --user redhat --project admin creator

openstack secret store --name testSecret --payload 'TestPayload'

openstack secret order create --name testSymmetricKey --algorithm aes --mode ctr --bit-length 256 --payload-content-type=application/octet-stream key
