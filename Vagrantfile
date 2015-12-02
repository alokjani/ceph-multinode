# -*- mode: ruby -*-
# vi: set ft=ruby :

BOX = "trusty64"
MEM = 512 

Vagrant.configure(2) do |config|

  hosts = [
    { name: 'node-1', disk1: '/tmp/node-1-disk-1.vdi', disk2: '/tmp/node-1-disk-2.vdi', ip:'192.168.20.21' },
    { name: 'node-2', disk1: '/tmp/node-2-disk-1.vdi', disk2: '/tmp/node-2-disk-2.vdi', ip:'192.168.20.22' },
    { name: 'node-3', disk1: '/tmp/node-3-disk-1.vdi', disk2: '/tmp/node-3-disk-2.vdi', ip:'192.168.20.23' },
  ]

  hosts.each do |host|
    config.vm.define host[:name] do |node|
      node.vm.hostname = host[:name]
      node.vm.box = BOX
      node.vm.network :private_network, ip: host[:ip] 
      node.vm.provider :virtualbox do |vb|
        vb.name = host[:name]
        vb.memory = MEM 
        vb.customize ['createhd', '--filename', host[:disk1], '--size', 10*1024]
        vb.customize ['createhd', '--filename', host[:disk2], '--size', 10*1024]
        vb.customize ['storageattach', :id, '--storagectl', 
                  "SATAController", '--port', 1, '--device', 0, '--type', 'hdd', '--medium', host[:disk1] ]
        vb.customize ['storageattach', :id, '--storagectl', 
                  "SATAController", '--port', 2, '--device', 0, '--type', 'hdd', '--medium', host[:disk2] ]
      end
          
      node.vm.provision :puppet do |puppet|
        puppet.manifests_path = "provision/"
        puppet.manifest_file  = "base.pp"
        puppet.options        = "--verbose --debug"
      end 

    end
  end

  config.vm.define "ceph-admin" do |node|
    node.vm.box = BOX
    node.vm.hostname = "ceph-admin"
    node.vm.network :private_network, ip: '192.168.20.254'
    node.vm.network :forwarded_port, protocol:'tcp', guest: 5000, host: 9090  # For ceph-dash dashboard 
    node.vm.provider :virtualbox do |vb|
      vb.name   = 'ceph-admin'
      vb.memory = '256'
    end

    node.vm.provision :puppet do |puppet|
      puppet.manifests_path = "provision/"
      puppet.manifest_file  = "base.pp"
      puppet.options        = "--verbose --debug"
    end 

    # Run the orchestrator which actually gets Ceph daemons running
    node.vm.provision :shell do |sh|
    sh.path = "provision/orchestrate.bash"
      sh.privileged = false     # run as `vagrant` instead of `root` 
    end

  end

end
