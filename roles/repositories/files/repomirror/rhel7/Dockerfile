FROM ubi7

RUN mkdir /repomirror && rm /etc/rhsm-host

RUN subscription-manager register --org ${ORG_ID} --activationkey ${ACTIVATION_KEY}

RUN subscription-manager attach --pool=$( \
        subscription-manager list --available --all \
        --matches="Red Hat OpenStack" |grep Pool\ ID |awk -F ' ' '{print $3}' |head -n1 )

RUN subscription-manager repos --disable=*
RUN subscription-manager repos --enable=rhel-7-server-rpms

RUN yum install -y yum-utils createrepo

VOLUME /repomirror
WORKDIR /root
COPY reposync.sh /root/reposync.sh
RUN chmod 755 /root/reposync.sh
CMD /root/reposync.sh
