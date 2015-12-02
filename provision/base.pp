# base.pp
# Baseline configuration for all nodes in Ceph cluster
# --

host { 'node-1':      ip  => '192.168.20.21' }
host { 'node-2':      ip  => '192.168.20.22' }
host { 'node-3':      ip  => '192.168.20.23' }
host { 'ceph-admin':  ip  => '192.168.20.254' }

$package_list = [ 
  'ceph-mds' , 
  'ceph-common', 
  'ceph-fs-common', 
  'xfsprogs',
  'gdisk',
  'ntp'
]

package { $package_list: 
    ensure  => installed,
}

# Ensure apt updates everytime a package resource dependency is called 
exec { "apt-update":
      command => "/usr/bin/apt-get update"
}

Exec["apt-update"] -> Package <| |>
