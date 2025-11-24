# Use External Storage (NFS)
# I run NFS Server on a separate Server.
# This example is based on the environment below.

+---------------------------+    |    +------------------------+
| NFS Server, www Server    |    |    | Docker CE, NFS Client  |
| Docker Registry,Docker CE |    |    |                        |
| masternode1.itstorage.net +----+----+ docker1.itstorage.net  |
| 192.168.37.50             |         | 192.168.37.51          |
+---------------------------+         +------------------------+

#1 Configure NFS Server.
#1.1 Run NFS Server on Master Node
[root@masternode1:~]# yum -y install nfs-utils
[root@masternode1:~]# vi /etc/idmapd.conf
# line 5: uncomment and change to your domain name
Domain = itstorage.net

#1.2 enable services and write settings for NFS exports
[root@masternode1:~]# vi /etc/exports
/home/nfsshare 192.168.37.0/24(rw,no_root_squash)
[root@masternode1:~]# mkdir /home/nfsshare
[root@masternode1:~]# systemctl start rpcbind nfs-server
[root@masternode1:~]# systemctl enable rpcbind nfs-server
[root@masternode1:~]# chmod -R 755 /home/nfsshare
[root@masternode1:~]# chown nfsnobody:nfsnobody /home/nfsshare
[root@masternode1:~]# systemctl enable rpcbind
[root@masternode1:~]# systemctl enable nfs-server
[root@masternode1:~]# systemctl enable nfs-lock
[root@masternode1:~]# systemctl enable nfs-idmap
[root@masternode1:~]# systemctl start rpcbind
[root@masternode1:~]# systemctl start nfs-server
[root@masternode1:~]# systemctl start nfs-lock
[root@masternode1:~]# systemctl start nfs-idmap
#-----------------------------------------------------------------------
#2 If Firewalld is running, allow NFS service.
#2.1 allow NFSv4
[root@masternode1:~]# firewall-cmd --add-service=nfs --permanent
success
#2.2 if allow NFSv3 too, set follows
[root@masternode1:~]# firewall-cmd --add-service={nfs3,mountd,rpc-bind} --permanent
success
[root@masternode1:~]# firewall-cmd --reload
success
#-----------------------------------------------------------------------
#3 Configure & Test NFS client 
[root@docker1:~]# yum install -y nfs-utils
# mount nfs from a client
[root@docker1:~]# mount -t nfs 192.168.37.50:/home/nfsshare /mnt/
#-----------------------------------------------------------------------
#4	Create a volume for NFS and use it.
# create [nfs-volume] volume
[root@docker1 ~]# docker volume create \
--opt type=nfs \
--opt o=addr=192.168.37.50,rw,nfsvers=4 \
--opt device=:/home/nfsshare nfs-volume 
nfs-volume

# display volume list
[root@docker1 ~]# docker volume ls
DRIVER    VOLUME NAME
local     nfs-volume

# display details of [nfs-volume]
[root@docker1 ~]# docker volume inspect nfs-volume
[
    {
        "CreatedAt": "2022-01-22T13:08:36+09:00",
        "Driver": "local",
        "Labels": {},
        "Mountpoint": "/var/lib/docker/volumes/nfs-volume/_data",
        "Name": "nfs-volume",
        "Options": {
            "device": ":/home/nfsshare",
            "o": "addr=192.168.37.50,rw,nfsvers=4",
            "type": "nfs"
        },
        "Scope": "local"
    }
]

# run container with mounting [nfs-volume] to [/nfsshare] on container
[root@docker1 ~]# docker run -it -v nfs-volume:/nfsshare centos
[root@b1fdede0ef99 /]# df -hT /nfsshare
Filesystem      Type  Size  Used Avail Use% Mounted on
:/home/nfsshare nfs4   26G  1.6G   25G   7% /nfsshare


#-----------------------------------------------------------------------
# Reference
https://www.howtoforge.com/tutorial/monitoring-of-a-ceph-cluster-with-ceph-dash/
https://www.server-world.info/
https://docs.ceph.com/en/mimic/mgr/dashboard/
