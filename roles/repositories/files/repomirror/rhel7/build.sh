#!/bin/bash
source ../common/config
podman build $1 --build-arg ORG_ID=${ORG_ID} --build-arg ACTIVATION_KEY=${ACTIVATION_KEY} -t repomirror-rhel7 .

