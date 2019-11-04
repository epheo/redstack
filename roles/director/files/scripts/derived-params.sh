#!/bin/bash

openstack overcloud deploy \
--update-plan-only \
 --templates  \
  -n ~/templates/network_data.yaml \
  -r ~/templates/roles_data.yaml \
  -e /usr/share/openstack-tripleo-heat-templates/environments/network-isolation.yaml \
  -e /usr/share/openstack-tripleo-heat-templates/environments/network-environment.yaml \
  -e /usr/share/openstack-tripleo-heat-templates/environments/host-config-and-reboot.yaml \
  -e ~/templates/environments/99-extra.yaml \
  -e ~/templates/environments/10-global.yaml \
  -e ~/templates/environments/40-network.yaml \
  -e ~/templates/environments/30-ceph.yaml \
  -e ~/templates/overcloud_images.yaml \
  -p /usr/share/openstack-tripleo-heat-templates/plan-samples/plan-environment-derived-params.yaml
