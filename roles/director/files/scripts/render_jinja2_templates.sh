#!/bin/sh

cd /usr/share/openstack-tripleo-heat-templates

./tools/process-templates.py \
     --roles-data ~/templates/roles_data.yaml \
     --network-data ~/templates/network_data.yaml \
     -o ~/openstack-tripleo-heat-templates-rendered