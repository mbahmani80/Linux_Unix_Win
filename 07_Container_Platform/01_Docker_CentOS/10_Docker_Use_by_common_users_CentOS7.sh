# Docker : Use by common users
#It's possible to use Docker containers by common users.

#1	To assign sub UID/GIDs that are used on user name spaces to common users, users can run [Docker] commands.
# install Rootless package (generally it's already installed for dependency)
[root@docker1 ~]# yum --enablerepo=docker-ce-stable -y install docker-ce-rootless-extras
[root@docker1 ~]# echo 63175 > /proc/sys/user/max_user_namespaces
[root@docker1 ~]# cat /proc/sys/user/max_user_namespaces
63175
# for example, assign sub UID/GID to [cent] user
[root@docker1 ~]# echo "cent:100000:65536" > /etc/subuid
[root@docker1 ~]# echo "cent:100000:65536" > /etc/subgid
[root@docker1 ~]# cat /etc/subgid /etc/subgid
cent:100000:65536
cent:100000:65536
#-----------------------------------------------------------------------
#2	It's possible to run [docker] by common users.
# setup rootless mode by each user itself
[bahmani@docker1 ~]$ dockerd-rootless-setuptool.sh install
[INFO] systemd not detected, dockerd-rootless.sh needs to be started manually:

PATH=/bin:/sbin:/usr/sbin:$PATH dockerd-rootless.sh

[INFO] Creating CLI context "rootless"
Successfully created context "rootless"

[INFO] Make sure the following environment variables are set (or add them to ~/.bashrc):

# WARNING: systemd not found. You have to remove XDG_RUNTIME_DIR manually on every logout.
export XDG_RUNTIME_DIR=/home/cent/.docker/run
export PATH=/bin:$PATH
export DOCKER_HOST=unix:///home/cent/.docker/run/docker.sock

# load displayed environment variables
[bahmani@docker1 ~]$ export XDG_RUNTIME_DIR=/home/cent/.docker/run
[bahmani@docker1 ~]$ export PATH=/usr/bin:$PATH
[bahmani@docker1 ~]$ export DOCKER_HOST=unix:///home/cent/.docker/run/docker.sock
# start dockerd-rootless
[bahmani@docker1 ~]$ dockerd-rootless.sh &
[bahmani@docker1 ~]$ docker pull centos
[bahmani@docker1 ~]$ docker images
REPOSITORY   TAG       IMAGE ID       CREATED        SIZE
centos       latest    300e315adb2f   5 months ago   209MB

[bahmani@docker1 ~]$ docker run centos echo "run rootless containers"
run rootless containers
# containers related files are located under the [$HOME/.local] directory
[bahmani@docker1 ~]$ ll ~/.local/share/docker
total 0
drwx--x--x. 4 cent cent 120 May 24 13:41 buildkit
drwx--x--x. 3 cent cent  20 May 24 13:41 containerd
drwx-----x. 4 cent cent 150 May 24 13:43 containers
drwx------. 3 cent cent  17 May 24 13:41 image
drwxr-x---. 3 cent cent  19 May 24 13:41 network
drwx------. 4 cent cent  32 May 24 13:41 plugins
drwx------. 2 cent cent   6 May 24 13:41 runtimes
drwx------. 2 cent cent   6 May 24 13:42 tmp
drwx------. 2 cent cent   6 May 24 13:41 trust
drwx-----x. 3 cent cent  17 May 24 13:42 vfs
drwx-----x. 2 cent cent  25 May 24 13:41 volumes

# for port mapping,
# it's impossible to use less than [1024] ports on Host machine by common users
# possible to use over [1024] ports
[bahmani@docker1 ~]$ docker run -t -d -p 1023:80 itstorage.net/centos-nginx /usr/sbin/nginx -g "daemon off;"
docker: Error response from daemon: driver failed programming external connectivity on endpoint thirsty_haibt (31bd9b8058f11434e0ffc33209359f35574699caf5bc27a7e9e1b90f53095351): Error starting userland proxy: error while calling PortManager.AddPort(): cannot expose privileged port 1023, you can add 'net.ipv4.ip_unprivileged_port_start=1023' to /etc/sysctl.conf (currently 1024), or set CAP_NET_BIND_SERVICE on rootlesskit binary, or choose a larger port number (>= 1024): listen tcp 0.0.0.0:1023: bind: permission denied.

[bahmani@docker1 ~]$ docker run -t -d -p 1024:80 itstorage.net/centos-nginx /usr/sbin/nginx -g "daemon off;"
[bahmani@docker1 ~]$ docker ps
CONTAINER ID   IMAGE                    COMMAND                  CREATED          STATUS        PORTS                                   NAMES
210870d6b13a   itstorage.net/centos-nginx   "/usr/sbin/nginx -g …"   10 seconds ago   Up 1 second   0.0.0.0:1024->80/tcp, :::1024->80/tcp   charming

#-----------------------------------------------------------------------
# Reference
https://www.howtoforge.com/tutorial/monitoring-of-a-ceph-cluster-with-ceph-dash/
https://www.server-world.info/
https://docs.ceph.com/en/mimic/mgr/dashboard/
