# Kubernetes repository
cat <<-EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0
EOF

# Docker Comunity Edition repos
yum install -y yum-utils \
  && yum-config-manager --add-repo \
  https://download.docker.com/linux/centos/docker-ce.repo \
