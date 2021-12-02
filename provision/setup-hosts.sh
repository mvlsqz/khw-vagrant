#!/bin/bash
set -xe
net=$1
if [ ! -f /etc/hosts.provision ]
then
  IFFACES=$(netstat -i | tail -n +3 | awk '{print $1}')
  for ifface in ${IFFACES}
  do
    address="$(ip -4 addr show ${ifface} | grep -oP '(?<=inet\s)\d+(\.\d+){3}')"
    if [[ "${address}" == *"${net}"* ]]
    then
      ADDRESS=${address}
    fi
  done
   
  sed -e "s/^.*${HOSTNAME}.*//" -i /etc/hosts
 
  # remove ubuntu-bionic entry
  sed -e '/^.*ubuntu.*/d' -i /etc/hosts

  # remove empty lines
  sed '/^$/d' -i /etc/hosts

  # Update /etc/hosts about other hosts
  cat >> /etc/hosts <<EOF
${ADDRESS}  ${HOSTNAME} ${HOSTNAME}.local
192.168.5.11  controller-1
192.168.5.21  worker-1
192.168.5.22  worker-2
192.168.5.30  lb
EOF

  touch /etc/hosts.provision
fi

