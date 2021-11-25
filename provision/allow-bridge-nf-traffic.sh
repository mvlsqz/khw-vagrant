#!/bin/bash

if [ $1 == 'centos' ]
then
  modprobe br_netfilter
fi
sysctl net.bridge.bridge-nf-call-iptables=1
