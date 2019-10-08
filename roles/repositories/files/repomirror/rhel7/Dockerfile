FROM ubi7
RUN mkdir /repomirror && \
    rm /etc/rhsm-host && \
    subscription-manager register --org ${ORG_ID} --activationkey ${ACTIVATION_KEY} && \
    yum install -y yum-utils createrepo
VOLUME /repomirror
WORKDIR /root
COPY reposync.sh /root/reposync.sh
RUN chmod 755 /root/reposync.sh
CMD /root/reposync.sh
