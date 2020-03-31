# -*- mode: ruby -*-
# vi: set ft=ruby :

def loadToEnv(file)
  # https://stackoverflow.com/a/22049005
  # Find variables in the general form of "export x=y"
  env_vars = File.read(file).scan /^export\s+(\S+)=(\S+)/
  # Parse each variable into the Ruby ENV key/value pair, removing outer quotes on the value if present.
  env_vars.each { |v| ENV[v.first] = v.last.gsub /\A['"]|["']\Z/, '' }
end

loadToEnv('./etc/env')

Vagrant.configure("2") do |config|
  config.vm.box = "debian/contrib-stretch64"

  if ENV.has_key?('VAGRANT_HOSTMANAGER_ENABLED') and ENV['VAGRANT_HOSTMANAGER_ENABLED'] == 'true'
    config.hostmanager.enabled = true
    config.hostmanager.manage_host = true
  end

  config.vm.define 'm2-vagrant' do |node|
    node.vm.post_up_message = false
    node.vm.hostname = ENV['VAGRANT_HOST']

    if ENV.has_key?('VAGRANT_PUBLIC') and ENV['VAGRANT_PUBLIC'] == 'true'
      node.vm.network 'public_network', ip: ENV['VAGRANT_IP']
    else
      node.vm.network 'private_network', ip: ENV['VAGRANT_IP']
    end

    if ENV.has_key?('VAGRANT_FORWARD_PORTS') and ENV['VAGRANT_FORWARD_PORTS'] == 'true'
      node.vm.network 'forwarded_port', guest: 80, host: ENV['VAGRANT_FORWARD_PORT_HTTP']
      node.vm.network 'forwarded_port', guest: 443, host: ENV['VAGRANT_FORWARD_PORT_HTTPS']
    end

    node.vm.synced_folder '.', '/vagrant', type: 'virtualbox'

    node.vm.provider 'virtualbox' do |vb|
      vb.memory = ENV['VAGRANT_MEMORY']
      vb.cpus = ENV['VAGRANT_CPUS']
    end
  end

  config.vm.provision 'provision-setup', type: 'shell', path: 'scripts/vagrant-setup.sh', keep_color: true
  config.vm.provision 'provision-test',  type: 'shell', path: 'scripts/vagrant-test.sh', run: 'always', keep_color: true
end
