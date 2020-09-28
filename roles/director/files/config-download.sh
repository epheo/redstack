#!/bin/bash
source stackrc

openstack overcloud config download \
  --name overcloud \
  --config-dir ~/config-download

cd ~/config-download

tripleo-ansible-inventory \
  --ansible_ssh_user heat-admin \
  --static-yaml-inventory inventory.yaml

ansible-playbook \
  -i inventory.yaml \
  --private-key ~/.ssh/id_rsa \
  --become \
  ~/config-download/deploy_steps_playbook.yaml

cd -



