#!/bin/bash

time openstack overcloud deploy \
-n ~/templates/network_data.yaml \
-r ~/templates/roles_data.yaml \
--answers-file ~/answers.yaml \
--stack-only
