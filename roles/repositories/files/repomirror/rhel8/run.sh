#!/bin/bash
source ../common/config
podman run -it -v ${REPOMIRROR_PATH}:/repomirror --env "REPOS_TO_SYNC=${RHEL8_REPOS_TO_SYNC}" repomirror-rhel8

