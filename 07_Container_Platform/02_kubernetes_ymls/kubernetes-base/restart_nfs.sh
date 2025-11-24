#!/bin/bash
set -x


# To free pagecache
udo echo 1 > /proc/sys/vm/drop_caches

# To free dentries and inodes
#sudo echo 2 > /proc/sys/vm/drop_caches

# To free pagecache, dentries and inodes
#sudo echo 3 > /proc/sys/vm/drop_caches

#sudo killall rpc.mountd ; sudo  /usr/sbin/rpc.mountd

sudo systemctl restart nfs-server.service  nfs-kernel-server.service nfs-utils.service nfs-mountd.service nfs-idmapd.service nfsdcld.service nfs-blkmap.service
sudo exportfs -a
sudo showmount -a | grep ip_address_of_nfs_client
