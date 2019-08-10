# -*- mode: ruby -*-
# vi: set ft=ruby :

def loadToEnv(file)
  # https://stackoverflow.com/a/22049005
  # Find variables in the general form of "export x=y"
  env_vars = File.read(file).scan /export\s+(\S+)=(\S+)/
  # Parse each variable into the Ruby ENV key/value pair, removing outer quotes on the value if present.
  env_vars.each { |v| ENV[v.first] = v.last.gsub /\A['"]|["']\Z/, '' }
end

loadToEnv('./etc/env')

$archive = "./source/magento-#{ENV['MAGENTO_REPO_VERSION']}.tar"
if (!File.exists?($archive))
  raise "Magento archive not found at '#{$archive}', run download-magento.sh"
end

Vagrant.configure("2") do |config|
  config.vm.box = "debian/contrib-stretch64"

  config.hostmanager.enabled = true
  config.hostmanager.manage_host = true

  config.vm.define 'm2-vagrant' do |node|
    node.vm.post_up_message = false
    node.vm.hostname = ENV['VAGRANT_HOST']
    node.vm.network :private_network, ip: ENV['VAGRANT_IP']

    node.vm.synced_folder '.', '/vagrant', type: 'virtualbox'

    node.vm.provider 'virtualbox' do |vb|
      vb.memory = ENV['VAGRANT_MEMORY']
      vb.cpus = ENV['VAGRANT_CPUS']
    end
  end

  config.vm.provision 'provision-setup', type: 'shell', path: 'scripts/setup.sh', keep_color: true
  config.vm.provision 'provision-test',  type: 'shell', path: 'scripts/test.sh', run: 'always', keep_color: true
end
