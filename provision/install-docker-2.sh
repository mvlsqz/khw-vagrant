if [ $1 == 'ubuntu' ]
then
  cd /tmp
  curl -fsSL https://get.docker.com -o get-docker.sh
  sh /tmp/get-docker.sh
elif [ $1 == 'centos' ]
then
  yum install -y yum-utils
  yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo
  yum install -y docker-ce docker-ce-cli containerd.io
else
  echo "$1 not yet supported"
fi

