# Docker : Use External Storage
	
# When containers are removed, data in them are also lost, so it's necessary to use external filesystem in containers as persistent storages if you need.

# This example is based on the environment below.

+---------------------------+    |    +------------------------+
| NFS Server, www Server    |    |    | Docker CE, NFS Client  |
| Docker Registry,Docker CE |    |    |                        |
| masternode1.itstorage.net +----+----+ docker1.itstorage.net  |
| 192.168.37.50             |         | 192.168.37.51          |
+---------------------------+         +------------------------+
#-----------------------------------------------------------------------
#1	It's possible to mount a directory on Docker Host into containers.
# create a directory for containers data
[root@docker1:~]# mkdir -p /var/lib/docker/disk01
[root@docker1:~]# echo "persistent storage" >> /var/lib/docker/disk01/testfile.txt
# run a container with mounting the directory above on [/mnt]
[root@docker1:~]# docker run -it -v /var/lib/docker/disk01:/mnt centos /bin/bash
[root@323d67542d8d /]# df -hT
Filesystem              Type     Size  Used Avail Use% Mounted on
overlay                 overlay   26G  2.5G   24G  10% /
tmpfs                   tmpfs     64M     0   64M   0% /dev
tmpfs                   tmpfs    1.9G     0  1.9G   0% /sys/fs/cgroup
shm                     tmpfs     64M     0   64M   0% /dev/shm
/dev/mapper/centos-root xfs       26G  2.5G   24G  10% /mnt
tmpfs                   tmpfs    1.9G     0  1.9G   0% /proc/acpi
tmpfs                   tmpfs    1.9G     0  1.9G   0% /proc/scsi
tmpfs                   tmpfs    1.9G     0  1.9G   0% /sys/firmware

[root@323d67542d8d /]# cat /mnt/testfile.txt
persistent storage
#-----------------------------------------------------------------------
#2	It's also possible to configure external storage by Docker Data Volume command.
# create [volume01] volume
[root@docker1:~]# docker volume create volume01
volume01
# display volume list
[root@docker1:~]# docker volume ls
DRIVER    VOLUME NAME
local     volume01

# display details of [volume01]
[root@docker1:~]# docker volume inspect volume01
[
    {
        "CreatedAt": "2021-05-24T13:01:43+09:00",
        "Driver": "local",
        "Labels": {},
        "Mountpoint": "/var/lib/docker/volumes/volume01/_data",
        "Name": "volume01",
        "Options": {},
        "Scope": "local"
    }
]

# run a container with mounting [volume01] to [/mnt] on container
[root@docker1:~]# docker run -it -v volume01:/mnt centos
[root@405c1c283bc2 /]# df -hT /mnt
Filesystem              Type  Size  Used Avail Use% Mounted on
/dev/mapper/centos-root xfs    26G  2.5G   24G  10% /mnt

[root@405c1c283bc2 /]# echo "Docker Volume test" > /mnt/testfile.txt
[root@405c1c283bc2 /]# exit
[root@docker1:~]# cat /var/lib/docker/volumes/volume01/_data/testfile.txt
Docker Volume test
# possible to mount from other containers
[root@docker1:~]# docker run -v volume01:/var/volume01 centos /usr/bin/cat /var/volume01/testfile.txt
Docker Volume test
# to remove volumes, do like follows
[root@docker1:~]# docker volume rm volume01
Error response from daemon: remove volume01: volume is in use - [405c1c283bc2e8dca69ee997b27f416cbb92fa79020200bb81487e3995087579, 2891a2fd78232b80fce78aaa38531abc24c926496a3c0670690bdca595b3b9b7]

# if some containers are using the volume you'd like to remove like above,
# it needs to remove target containers before removing a volume
[root@docker1:~]# docker rm 405c1c283bc2e8dca69ee997b27f416cbb92fa7902020
[root@docker1:~]# docker rm 2891a2fd78232b80fce78aaa38531abc24c926496a3c0
[root@docker1:~]# docker volume rm volume01
volume01

#-----------------------------------------------------------------------
# Reference
https://www.howtoforge.com/tutorial/monitoring-of-a-ceph-cluster-with-ceph-dash/
https://www.server-world.info/
https://docs.ceph.com/en/mimic/mgr/dashboard/
