#!/bin/bash
# orchestrate.bash
# Uses ceph-deploy to setup a 3 node ceph cluster
# -- 

sudo apt-get install --yes ceph-deploy
sudo puppet apply -e "package { 'sshpass': ensure => 'installed' }"
ssh-keygen -t rsa -N '' -f ~vagrant/.ssh/id_rsa

for node in node-1 node-2 node-3; do
    ssh-keyscan $node >> ~vagrant/.ssh/known_hosts
    sshpass -p 'vagrant' ssh-copy-id -i ~vagrant/.ssh/id_rsa vagrant@$node
done

mkdir cluster01
cd cluster01

# write out a new `ceph.conf`
ceph-deploy new node-1

echo 'osd pool default size = 3' >> ceph.conf
echo 'osd pool default pg num = 200' >> ceph.conf
echo 'osd pool default pgp num = 200' >> ceph.conf
echo 'public network = 192.168.20.0/24' >> ceph.conf

# Install Ceph Packages
ceph-deploy install node-1 node-2 node-3

# Gather all the keys 
ceph-deploy mon create-initial

# --
# Note: Old Procedure for OSD
#  explicitly format, fstab mount, prepare and activate OSDs
#  these steps are now replaced via `ceph-deploy osd create` seen further below
# --
#  ssh node-1 'sudo mkdir -p /srv/osd0; sudo mkfs.xfs -f /dev/sdb; sudo mount /dev/sdb /srv/osd0'
#  ssh node-1 'sudo mkdir -p /srv/osd1; sudo mkfs.xfs -f /dev/sdc; sudo mount /dev/sdc /srv/osd1'
#  ssh node-2 'sudo mkdir -p /srv/osd2; sudo mkfs.xfs -f /dev/sdb; sudo mount /dev/sdb /srv/osd2'
#  ssh node-2 'sudo mkdir -p /srv/osd3; sudo mkfs.xfs -f /dev/sdc; sudo mount /dev/sdc /srv/osd3'
#  ssh node-3 'sudo mkdir -p /srv/osd4; sudo mkfs.xfs -f /dev/sdb; sudo mount /dev/sdb /srv/osd4'
#  ssh node-3 'sudo mkdir -p /srv/osd5; sudo mkfs.xfs -f /dev/sdc; sudo mount /dev/sdc /srv/osd5'
# --
#  ssh node-1 'sudo echo "/dev/sdb /srv/osd0 xfs defaults 1 2" | sudo tee /etc/fstab'
#  ssh node-1 'sudo echo "/dev/sdc /srv/osd1 xfs defaults 1 2" | sudo tee /etc/fstab'
#  ssh node-2 'sudo echo "/dev/sdb /srv/osd2 xfs defaults 1 2" | sudo tee /etc/fstab'
#  ssh node-2 'sudo echo "/dev/sdc /srv/osd3 xfs defaults 1 2" | sudo tee /etc/fstab'
# --
#  ceph-deploy osd prepare node-1:/srv/osd0; ceph-deploy osd activate node-1:/srv/osd0
#  ceph-deploy osd prepare node-1:/srv/osd1; ceph-deploy osd activate node-1:/srv/osd1
#  ceph-deploy osd prepare node-2:/srv/osd2; ceph-deploy osd activate node-2:/srv/osd2
#  ceph-deploy osd prepare node-2:/srv/osd3; ceph-deploy osd activate node-2:/srv/osd3
#  ceph-deploy osd prepare node-3:/srv/osd4; ceph-deploy osd activate node-2:/srv/osd4
#  ceph-deploy osd prepare node-3:/srv/osd5; ceph-deploy osd activate node-2:/srv/osd5
# --

# --
# Note: `ceph-deploy osd create` 
#   Auto format to xfs; prepare OSDs; then activate OSDs; Manage mount with Udev
#   Uses `ceph osd prepare` and `ceph osd activate` subcommands to create an OSD.
#   Udev is used to auto mount at start of OSD daemon at `/var/lib/ceph/osd/ceph-<id#>`
# --
ceph-deploy osd create node-1:/dev/sdb node-1:/dev/sdc
ceph-deploy osd create node-2:/dev/sdb node-2:/dev/sdc
ceph-deploy osd create node-3:/dev/sdb node-3:/dev/sdc


# Push conf and client.admin key to remote
ceph-deploy admin node-1 node-2 node-3

# Create mon,mds services on ceph nodes
ceph-deploy mon create node-1 node-2 node-3
ceph-deploy mds create node-1 node-2 node-3

# Set weight 1 for OSDs so that Ceph can replicate, defaults to 0
ceph -c ceph.conf -k ceph.client.admin.keyring osd crush add osd.0 1 host=node-1
ceph -c ceph.conf -k ceph.client.admin.keyring osd crush add osd.1 1 host=node-1
ceph -c ceph.conf -k ceph.client.admin.keyring osd crush add osd.2 1 host=node-2
ceph -c ceph.conf -k ceph.client.admin.keyring osd crush add osd.3 1 host=node-2
ceph -c ceph.conf -k ceph.client.admin.keyring osd crush add osd.4 1 host=node-3
ceph -c ceph.conf -k ceph.client.admin.keyring osd crush add osd.5 1 host=node-3

sleep 10	

ceph -c ceph.conf -k ceph.client.admin.keyring osd tree
ceph -c ceph.conf -k ceph.client.admin.keyring health detail
ceph -c ceph.conf -k ceph.client.admin.keyring status 

