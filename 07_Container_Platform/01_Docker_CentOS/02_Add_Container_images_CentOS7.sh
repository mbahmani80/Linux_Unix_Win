# Docker : Add Container images you created.
#=======================================================================
# This example is based on the environment below.

+---------------------------+    |    +------------------------+
| NFS Server, www Server    |    |    | Docker CE, NFS Client  |
| Docker Registry,Docker CE |    |    |                        |
| masternode1.itstorage.net +----+----+ docker1.itstorage.net  |
| 192.168.37.50             |         | 192.168.37.51          |
+---------------------------+         +------------------------+

#1	For exmaple, update official image with installing Nginx and add it as a new image for container. The container is generated every time for executing docker run command, so add the latest executed container like follows.
# show images
[root@docker1:~]# docker images

# start a Container and install nginx
[root@docker1:~]# docker run centos /bin/bash -c "yum -y install nginx"
[root@docker1:~]# docker ps -a | head -2


# add the image
[root@docker1:~]# docker commit 12e2766b510e itstorage.net/centos-nginx
sha256:6adb1438d24f7f1f55438f9ff86d67b78f05ccee8bca7464247473aa588691be

[root@docker1:~]# docker images

# Generate a Container from the new image and execute [which] to make sure nginx exists
[root@docker1:~]# docker run itstorage.net/centos-nginx /usr/bin/whereis nginx

#-----------------------------------------------------------------------
# Reference
https://www.howtoforge.com/tutorial/monitoring-of-a-ceph-cluster-with-ceph-dash/
https://www.server-world.info/
https://docs.ceph.com/en/mimic/mgr/dashboard/
