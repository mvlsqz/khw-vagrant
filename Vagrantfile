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
STORAGE_POOL = ENV['STORAGE_POOL'].nil? ? 'default' : ENV['STORAGE_POOL']

OS = case VAGRANT_BOX
              when /centos/
                'centos'
              when /ubuntu/
                'ubuntu'
              end
PROVIDER = ENV['VAGRANT_DEFAULT_PROVIDER'].nil? ? 'virtualbox' : ENV['VAGRANT_DEFAULT_PROVIDER']

Vagrant.configure('2') do |config|
  config.vm.box_check_update = false
  config.vm.box = VAGRANT_BOX

  # Provision controller nodes
  (1..NUM_MASTER_NODE).each do |i|
    config.vm.define "controller-#{i}" do |node|
      node.vm.network :forwarded_port, guest: 6443, host: 6443
      node.vm.provider PROVIDER do |vb|
        if PROVIDER == 'libvirt'
          vb.storage_pool_name = STORAGE_POOL
        end
        vb.memory = 2048
        vb.cpus = 2
      end
      node.vm.hostname = "controller-#{i}"
      node.vm.network :private_network, ip: "#{IP_NW}#{MASTER_IP_START + i}"

      node.vm.provision 'setup-hosts',
        type: 'shell',
        path: 'provision/setup-hosts.sh' do |s|
          s.args = [IP_NW]
        end

      node.vm.provision 'allow-bridge-nf-traffic', 
        type: 'shell', 
        path: 'provision/allow-bridge-nf-traffic.sh'

      case OS
      when 'ubuntu'
        node.vm.provision 'setup-repositories',
          type: 'shell',
          path: 'provision/apt-repos.sh'
      when 'centos'
        node.vm.provision 'setup-repositories', 
          type: 'shell', 
          path: 'provision/yum-repos.sh'
      end

      node.vm.provision 'install-kube-tools', 
        type: 'shell', 
        path: 'provision/install-kube-tools.sh' do |s|
          s.args = [OS]
        end
    end
  end

  # Provision Load Balancer Node
  config.vm.define 'loadbalancer' do |node|
    node.vm.provider PROVIDER do |vb|
      if PROVIDER == 'libvirt'
        vb.storage_pool_name = STORAGE_POOL
      end
      vb.memory = 512
      vb.cpus = 1
    end
    node.vm.hostname = 'loadbalancer'
    node.vm.network :private_network, ip: "#{IP_NW}#{LB_IP_START}"

    node.vm.provision 'allow-bridge-nf-traffic', type: 'shell', path: 'provision/allow-bridge-nf-traffic.sh' do |s|
      s.args = [OS]
    end
  end

  # Provision Worker Nodes
  (1..NUM_WORKER_NODE).each do |i|
    config.vm.define "worker-#{i}" do |node|
      node.vm.provider PROVIDER do |vb|
        if PROVIDER == 'libvirt'
          vb.storage_pool_name = STORAGE_POOL
        end
        vb.memory = 1024
        vb.cpus = 1
      end
      node.vm.hostname = "worker-#{i}"
      
      node.vm.network :private_network, ip: "#{IP_NW}#{NODE_IP_START + i}"

      node.vm.provision 'setup-hosts',
        type: 'shell',
        path: 'provision/setup-hosts.sh' do |s|
          s.args = [IP_NW]
        end

      node.vm.provision 'allow-bridge-nf-traffic',
        type: 'shell',
        path: 'provision/allow-bridge-nf-traffic.sh'

      case OS
      when 'ubuntu'
        node.vm.provision 'setup-repositories',
          type: 'shell',
          path: 'provision/apt-repos.sh'
      when 'centos'
        node.vm.provision 'setup-repositories',
          type: 'shell',
          path: 'provision/yum-repos.sh'
      end

      node.vm.provision 'install-kube-tools',
        type: 'shell',
        path: 'provision/install-kube-tools.sh' do |s|
          s.args = [OS]
        end
    end
  end
end
