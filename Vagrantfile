# frozen_string_literal: true

# -*- mode: ruby -*-
# vi:set ft=ruby sw=2 ts=2 sts=2:

# Define the number of master and worker nodes
# If this number is changed, remember to update setup-hosts.sh script
# with the new hosts IP details in /etc/hosts of each VM.
NUM_MASTER_NODE = 1
NUM_WORKER_NODE = 2

IP_NW = '192.168.5.'
MASTER_IP_START = 10
NODE_IP_START = 20
LB_IP_START = 30
VAGRANT_BOX = ENV['BOX'].nil? ? 'ubuntu/bionic64' : ENV['BOX']

OS, NET_IFC = case VAGRANT_BOX
              when /centos/
                %w[centos eth0]
              when /ubuntu/
                %w[ubuntu enp0s8]
              end
PROVIDER = ENV['DEFAULT_PROVIDER'].nil? ? 'virtualbox' : ENV['DEFAULT_PROVIDER']

Vagrant.configure('2') do |config|
  config.vm.box = VAGRANT_BOX
  config.vm.box_check_update = false
  config.vm.box_download_insecure = true

  # Provision controller nodes
  (1..NUM_MASTER_NODE).each do |i|
    config.vm.define "controller-#{i}" do |node|
      node.vm.provider PROVIDER do |vb|
        vb.name = "kubernetes-ha-master-#{i}"
        vb.memory = 2048
        vb.cpus = 2
      end
      node.vm.hostname = "controller-#{i}"
      node.vm.network :private_network, ip: "#{IP_NW}#{MASTER_IP_START + i}"

      node.vm.provision 'setup-hosts', type: 'shell', path: 'provision/vagrant/setup-hosts.sh' do |s|
        s.args = [NET_IFC]
      end

      node.vm.provision 'file', source: './provision/cert_verify.sh', destination: '$HOME/'
    end
  end

  # Provision Load Balancer Node
  config.vm.define 'loadbalancer' do |node|
    node.vm.provider PROVIDER do |vb|
      vb.name = 'kubernetes-ha-lb'
      vb.memory = 512
      vb.cpus = 1
    end
    node.vm.hostname = 'loadbalancer'
    node.vm.network :private_network, ip: "#{IP_NW}#{LB_IP_START}"

    node.vm.provision 'setup-hosts', type: 'shell', path: 'provision/vagrant/setup-hosts.sh' do |s|
      s.args = [NET_IFC]
    end
  end

  # Provision Worker Nodes
  (1..NUM_WORKER_NODE).each do |i|
    config.vm.define "worker-#{i}" do |node|
      node.vm.provider PROVIDER do |vb|
        vb.name = "kubernetes-ha-worker-#{i}"
        vb.memory = 512
        vb.cpus = 1
      end
      node.vm.hostname = "worker-#{i}"
      node.vm.network :private_network, ip: "#{IP_NW}#{NODE_IP_START + i}"

      node.vm.provision 'setup-hosts', type: 'shell', path: 'provision/vagrant/setup-hosts.sh' do |s|
        s.args = [NET_IFC]
      end

      node.vm.provision 'install-docker', type: 'shell', path: 'provision/install-docker-2.sh' do |s|
        s.args = [OS]
      end
      node.vm.provision 'allow-bridge-nf-traffic', type: 'shell', path: 'provision/allow-bridge-nf-traffic.sh'
      node.vm.provision 'file', source: './provision/cert_verify.sh', destination: '$HOME/'
    end
  end
end
