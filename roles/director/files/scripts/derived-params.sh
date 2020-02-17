#!/bin/bash

openstack overcloud deploy \
-n ~/templates/network_data.yaml \
-r ~/templates/roles_data.yaml \
-p /usr/share/openstack-tripleo-heat-templates/plan-samples/plan-environment-derived-params.yaml \
--update-plan-only \
--answers-file ~/answers.yaml \
--log-file overcloud-derived-params.log