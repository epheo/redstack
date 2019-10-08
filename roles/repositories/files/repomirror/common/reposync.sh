#!/bin/bash
RHEL=$(grep -oP '(?<=VERSION_ID=")([[:digit:]]+)' /etc/os-release)
if [[ ! -z ${REPOS_TO_SYNC} ]]
then
  case ${RHEL} in
    7)
      EXITCODE=0
      EXITCODE_C=0
      set -x
      subscription-manager attach --pool=$( \
        subscription-manager list --available --all \
        --matches="Red Hat OpenStack" |grep Pool\ ID |awk -F ' ' '{print $3}' |head -n1 )
      subscription-manager repos --disable=* && yum clean all
      for REPO in ${REPOS_TO_SYNC}
      do
        subscription-manager repos --enable=${REPO}
        reposync -n --gpgcheck -l --repoid=${REPO} --download-metadata --downloadcomps --download_path=/repomirror
        EXITCODE_C=$?
        EXITCODE=$(( ${EXITCODE} + ${EXITCODE_C} ))
        if [[ $EXITCODE_C -eq 0 ]]
        then
          createrepo -v /repomirror/${REPO}/ -g /repomirror/${REPO}/comps.xml
        fi
      done
      exit ${EXITCODE}
    ;;
    8)
      EXITCODE=0
      set -x
      subscription-manager attach --pool=$( \
        subscription-manager list --available --all \
        --matches="Red Hat OpenStack" |grep Pool\ ID |awk -F ' ' '{print $3}' |head -n1 )
      subscription-manager repos --disable=* && dnf clean all
      case $REPOS_TO_SYNC in
        *advanced-virt*)
          echo "Enabling Virt:8.0 Module..."
          dnf -y module disable virt:rhel
          dnf -y module enable virt:8.0
          ;;
      esac
      for REPO in ${REPOS_TO_SYNC}
      do
        subscription-manager repos --enable=${REPO}
        reposync -n -p /repomirror --newest --download-metadata --setopt=repo_id.module_hotfixes=1 --repo ${REPO} 
        EXITCODE=$(( ${EXITCODE} + $? ))
      done
      exit ${EXITCODE}
      #subscription-manager repos ${REPOS_TO_ENABLE}
    ;;
    *)
      echo "Something isn't right. I couldn't establish RHEL version which supposed to be either 7 or 8 but I got ${RHEL} instead."
      echo "I will die now."
      exit 1
  esac
else
  echo "Please ensure you've provided a list of repository IDs to sync in REPOS_TO_SYNC variable."
  exit 1
fi
