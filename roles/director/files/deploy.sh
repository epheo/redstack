#!/bin/bash
source stackrc

time openstack overcloud deploy \
-n ~/templates/network_data.yaml \
-r ~/templates/roles_data.yaml \
--answers-file ~/answers.yaml \
--overcloud-ssh-user heat-admin \
--overcloud-ssh-key ~/.ssh/id_rsa \
--stack-only
