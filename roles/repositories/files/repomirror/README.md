# CentOS

### Install podman, slirp4netns and fuse3-devel packages.
```
$ sudo yum install -y podman slirp4netns fuse3-devel
```

### Enable user namespaces:

```
$ sudo sysctl user.max_user_namespaces=1000
```

### Make it persistent:
```
$ sudo cat << EOF > /etc/sysctl.d/user-namespaces.conf
user.max_user_namespaces=1000
EOF
```

### Podman should be working now. Login to registry.access.redhat.com
```
$ podman login registry.access.redhat.com
```

### Pull ubi7 and ubi8 images

```
$ podman pull registry.access.redhat.com/ubi7
$ podman pull registry.access.redhat.com/ubi8
```

### Create common/config file - check provided sample (common/config.sample).

```
export ORG_ID="YOUR_ORG_ID_GOES_HERE"
export ACTIVATION_KEY="YOUR_ACTIVATION_KEY_NAME_GOES_HERE"
export REPOMIRROR_PATH="/home/nfs/repomirror"
export RHEL7_REPOS_TO_SYNC="
  rhel-7-server-rpms
  rhel-7-server-extras-rpms
  rhel-7-server-rh-common-rpms
  rhel-ha-for-rhel-7-server-rpms
  rhel-7-server-openstack-13-rpms
  rhel-7-server-openstack-14-rpms
  rhel-7-server-rhceph-3-tools-rpms
  "
export RHEL8_REPOS_TO_SYNC="
  rhel-8-for-x86_64-baseos-rpms
  rhel-8-for-x86_64-appstream-rpms
  rhel-8-for-x86_64-highavailability-rpms
  ansible-2.8-for-rhel-8-x86_64-rpms
  satellite-tools-6.5-for-rhel-8-x86_64-rpms
  openstack-beta-for-rhel-8-x86_64-rpms
  rhceph-4-tools-for-rhel-8-x86_64-rpms
  "
```

### Build images:

```
$ cd rhel7
$ ./build.sh

$ cd rhel8
$ ./build.sh
```



### Start reposync container

```
$ cd rhel7
$ ./run.sh

$ cd rhel8
$ ./run.sh
```

