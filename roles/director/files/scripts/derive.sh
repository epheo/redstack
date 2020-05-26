#!/bin/bash

time openstack overcloud deploy \
-n ~/templates/network_data.yaml \
-r ~/templates/roles_data.yaml \
--answers-file ~/answers.yaml \
--update-plan-only \
-p /usr/share/openstack-tripleo-heat-templates/plan-samples/plan-environment-derived-params.yaml