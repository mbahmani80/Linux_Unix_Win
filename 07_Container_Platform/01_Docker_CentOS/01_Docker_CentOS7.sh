# Docker : Install
# Install Docker which is the Operating System-Level Virtualization Tool, which automates the deployment of applications inside Containers.
# This example is based on the environment below.

+---------------------------+    |    +------------------------+
| NFS Server, www Server    |    |    | Docker CE, NFS Client  |
| Docker Registry,Docker CE |    |    |                        |
| masternode1.itstorage.net +----+----+ docker1.itstorage.net  |
| 192.168.37.50             |         | 192.168.37.51          |
+---------------------------+         +------------------------+

#1	Install Docker CE.
[root@docker1:~]# curl https://download.docker.com/linux/centos/docker-ce.repo -o /etc/yum.repos.d/docker-ce.repo
[root@docker1:~]# sed -i -e "s/enabled=1/enabled=0/g" /etc/yum.repos.d/docker-ce.repo
[root@docker1:~]# yum --enablerepo=docker-ce-stable -y install docker-ce
[root@docker1:~]# systemctl enable --now docker
[root@docker1:~]# rpm -q docker-ce
[root@docker1:~]# docker version
#-----------------------------------------------------------------------
#2	Download an official image and create a Container and output the words [Welcome to the Docker World] inside the Container.
# download the centos image
[root@docker1:~]# docker pull centos
Using default tag: latest
latest: Pulling from library/centos
7a0437f04f83: Pull complete
Digest: sha256:5528e8b1b1719d34604c87e11dcd1c0a20bedf46e83b5632cdeac91b8c04efc1
Status: Downloaded newer image for centos:latest
docker.io/library/centos:latest

# run echo inside Container
[root@docker1:~]# docker run centos /bin/echo "Welcome to the Docker World"
Welcome to the Docker World
#-----------------------------------------------------------------------
#3	Connect to the interactive session of a Container with [i] and [t] option like follows.
If exit from the Container session, the process of a Container finishes.
[root@docker1:~]# docker run -it centos /bin/bash
[root@0e6c5c3cd68a /]#     # Container's console
[root@0e6c5c3cd68a /]# uname -a
[root@0e6c5c3cd68a /]# exit
exit
[root@docker1:~]#
#-----------------------------------------------------------------------
#4	If exit from the Container session with keeping container's process, push [Ctrl+p] and [Ctrl+q] key.
[root@docker1:~]# docker run -it centos /bin/bash
[root@41ba6a71aea9 /]# [root@docker1:~]#     # Ctrl+p, Ctrl+q
# show docker processes
[root@docker1:~]# docker ps
CONTAINER ID   IMAGE     COMMAND       CREATED         STATUS         PORTS     NAMES
41ba6a71aea9   centos    "/bin/bash"   9 seconds ago   Up 8 seconds             serene_johnson

# connect to container's session
[root@docker1:~]# docker attach 41ba6a71aea9
[root@41ba6a71aea9 /]#
# shutdown container's process from Host's console
[root@docker1:~]# docker kill 41ba6a71aea9
8480e1a203ba
[root@docker1:~]# docker ps
#-----------------------------------------------------------------------
# Install Docker CE on masternode1 for extending LAB
[root@masternode1:~]# curl https://download.docker.com/linux/centos/docker-ce.repo -o /etc/yum.repos.d/docker-ce.repo
[root@masternode1:~]# sed -i -e "s/enabled=1/enabled=0/g" /etc/yum.repos.d/docker-ce.repo
[root@masternode1:~]# yum --enablerepo=docker-ce-stable -y install docker-ce
[root@masternode1:~]# systemctl enable --now docker
[root@masternode1:~]# rpm -q docker-ce
[root@masternode1:~]# docker version
#---------------------------------
# download the centos image
[root@masternode1:~]# docker pull centos
# run echo inside Container
[root@masternode1:~]# docker run centos /bin/echo "Welcome to the Docker World"
Welcome to the Docker World
#---------------------------------

# Reference
https://www.howtoforge.com/tutorial/monitoring-of-a-ceph-cluster-with-ceph-dash/
https://www.server-world.info/
https://docs.ceph.com/en/mimic/mgr/dashboard/
