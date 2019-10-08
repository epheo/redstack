#!/bin/bash

openstack overcloud deploy \
--update-plan-only \
 --templates  \
  -n ~/templates/network_data.yaml \
  -r ~/templates/roles_data.yaml \
  -e /usr/share/openstack-tripleo-heat-templates/environments/network-isolation.yaml \
  -e /usr/share/openstack-tripleo-heat-templates/environments/network-environment.yaml \
  -e ~/templates/environments/10-deployment-environment.yaml \
  -e ~/templates/environments/40-network-override-environment.yaml \
  -e ~/templates/environments/99-extraconfig-environment.yaml \
  -e ~/templates/environments/30-storage-environment.yaml \
  -e /usr/share/openstack-tripleo-heat-templates/environments/host-config-and-reboot.yaml \
  -e ~/templates/overcloud_images.yaml \
  -p /usr/share/openstack-tripleo-heat-templates/plan-samples/plan-environment-derived-params.yaml
