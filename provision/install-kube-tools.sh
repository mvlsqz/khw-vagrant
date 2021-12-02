#!/bin/bash -xe

if [ $1 == 'centos' ]
then
  yum makecache fast
  yum install -y \
    iproute-tc kubectl \
    --disableexcludes=kubernetes 

  yum clean all \
    && rm -rf /var/cache/yum

elif [ $1 == 'ubuntu' ]
then
  export DEBIAN_FRONTEND=noninteractive
  apt-get install -y kubectl
else
  echo 'Not yet supported'
fi

swapoff -a
