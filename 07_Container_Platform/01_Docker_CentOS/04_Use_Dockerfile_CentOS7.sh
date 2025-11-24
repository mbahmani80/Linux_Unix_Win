# Docker : Use Dockerfile
# Use Dockerfile and create Docker images automatically.
# It is also useful for configuration management.
# This example is based on the environment below.

+---------------------------+    |    +------------------------+
| NFS Server, www Server    |    |    | Docker CE, NFS Client  |
| Docker Registry,Docker CE |    |    |                        |
| masternode1.itstorage.net +----+----+ docker1.itstorage.net  |
| 192.168.37.50             |         | 192.168.37.51          |
+---------------------------+         +------------------------+

# For example, Create a Dockerfile that Apache httpd is installed and started.
[root@docker1:~]# vi Dockerfile
# create new
FROM centos
MAINTAINER ITStorage <admin@itstorage.net>

RUN yum -y install httpd
RUN echo "Dockerfile Test on Aapche httpd" > /var/www/html/index.html

EXPOSE 80
CMD ["-D", "FOREGROUND"]
ENTRYPOINT ["/usr/sbin/httpd"]

# build image ⇒ docker build -t [image name]:[tag] .
[root@docker1:~]# docker build -t itstorage.net/centos-httpd:latest ./
Sending build context to Docker daemon  11.78kB
Step 1/7 : FROM centos
 ---> 300e315adb2f
Step 2/7 : MAINTAINER ITStorage <admin@itstorage.net>
 ---> Running in 6e83e9b69134
Removing intermediate container 6e83e9b69134
 ---> 3b1af99319a3
Step 3/7 : RUN yum -y install httpd
 ---> Running in 3680093e103f
 
.....
.....

Successfully built 7cf442f4e930
Successfully tagged itstorage.net/centos-httpd:latest

[root@docker1:~]# docker images
REPOSITORY               TAG       IMAGE ID       CREATED          SIZE
itstorage.net/centos-httpd   latest    7cf442f4e930   39 seconds ago   250MB
itstorage.net/centos-nginx   latest    6adb1438d24f   4 minutes ago    289MB
centos                   latest    300e315adb2f   5 months ago     209MB

# run container
[root@docker1:~]# docker run -d -p 8081:80 itstorage.net/centos-httpd
fbbe54203409556b8f5946163829bb38d0477322132d25d4b34e950c3a99a14b
[root@docker1:~]# docker ps
CONTAINER ID   IMAGE                    COMMAND                  CREATED         STATUS         PORTS                                   NAMES
fbbe54203409   itstorage.net/centos-httpd   "/usr/sbin/httpd -D …"   7 seconds ago   Up 6 seconds   0.0.0.0:8081->80/tcp, :::8081->80/tcp   compassionate_taussig

# verify accesses
[root@docker1:~]# curl localhost:8081
Dockerfile Test on Aapche httpd


# The format of Dockerfile is [INSTRUCTION arguments] .
# Refer to the following description for INSTRUCTION.
#INSTRUCTION	Description
#-----------    -----------
FROM			It sets the Base Image for subsequent instructions.
MAINTAINER		It sets the Author field of the generated images.
RUN				It will execute any commands when Docker image will be created.
CMD				It will execute any commands when Docker container will be executed.
ENTRYPOINT		It will execute any commands when Docker container will be executed.
LABEL			It adds metadata to an image.
EXPOSE			It informs Docker that the container will listen on the specified network ports at runtime.

ENV				It sets the environment variable.
ADD				It copies new files, directories or remote file URLs.
COPY			It copies new files or directories.
				#The differences of [ADD] are that it's impossible to specify remore URL and also it will not extract archive files automatically.

VOLUME			It creates a mount point with the specified name and marks it as holding externally mounted volumes from native host or other containers

USER			It sets the user name or UID.
WORKDIR			It sets the working directory.

#-----------------------------------------------------------------------
# Reference
https://www.howtoforge.com/tutorial/monitoring-of-a-ceph-cluster-with-ceph-dash/
https://www.server-world.info/
https://docs.ceph.com/en/mimic/mgr/dashboard/
