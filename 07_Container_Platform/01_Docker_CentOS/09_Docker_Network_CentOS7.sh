# Docker : Docker Network
# This is the basic usage to configure Docker Network.

# This example is based on the environment below.
+---------------------------+    |    +------------------------+
| NFS Server, www Server    |    |    | Docker CE, NFS Client  |
| Docker Registry,Docker CE |    |    |                        |
| masternode1.itstorage.net +----+----+ docker1.itstorage.net  |
| 192.168.37.50             |         | 192.168.37.51          |
+---------------------------+         +------------------------+


#1	When running containers without specifying network, default [bridge] network is assigned.
# display network list
[root@docker1 ~]# docker network ls
NETWORK ID     NAME           DRIVER    SCOPE
ad04ec5023ed   bridge         bridge    local
b286cf81a5f1   host           host      local
681a4b1d762a   none           null      local
66ce864f00b6   root_default   bridge    local

# display details of [bridge]
[root@docker1 ~]# docker network inspect bridge
[
    {
        "Name": "bridge",
        "Id": "ad04ec5023edd53519fcd444a0a2dc401c4536ab2d02bb350e57f6e9b132740d",
        "Created": "2021-05-24T12:49:06.10578464+09:00",
        "Scope": "local",
        "Driver": "bridge",
        "EnableIPv6": false,
        "IPAM": {
            "Driver": "default",
            "Options": null,
            "Config": [
                {
                    "Subnet": "172.17.0.0/16"
                }
            ]
        },
        "Internal": false,
        "Attachable": false,
        "Ingress": false,
        "ConfigFrom": {
            "Network": ""
        },
        "ConfigOnly": false,
        "Containers": {},
        "Options": {
            "com.docker.network.bridge.default_bridge": "true",
            "com.docker.network.bridge.enable_icc": "true",
            "com.docker.network.bridge.enable_ip_masquerade": "true",
            "com.docker.network.bridge.host_binding_ipv4": "0.0.0.0",
            "com.docker.network.bridge.name": "docker0",
            "com.docker.network.driver.mtu": "1500"
        },
        "Labels": {}
    }
]

# [bridge] is assigned as container network by default
[root@docker1 ~]# docker run centos /usr/sbin/ip route
default via 172.17.0.1 dev eth0
172.17.0.0/16 dev eth0 proto kernel scope link src 172.17.0.2
#-----------------------------------------------------------------------
#2	If you'd like to assign another network, set like follows.
# create network [network01] with [192.168.100.0/24] subnet
[root@docker1 ~]# docker network create --subnet 192.168.100.0/24 network01
77474ec94a19fdf87642200fde8f74e4a16aa4e31127ee57f6f6538e8da892c0

[root@docker1 ~]# docker network ls
NETWORK ID     NAME           DRIVER    SCOPE
ad04ec5023ed   bridge         bridge    local
b286cf81a5f1   host           host      local
77474ec94a19   network01      bridge    local
681a4b1d762a   none           null      local
66ce864f00b6   root_default   bridge    local

# run a container with specifying [network01]
[root@docker1 ~]# docker run --net network01 centos /usr/sbin/ip route
default via 192.168.100.1 dev eth0
192.168.100.0/24 dev eth0 proto kernel scope link src 192.168.100.2

# to attach the network to existing running container, set like follows
[root@docker1 ~]# docker ps
CONTAINER ID   IMAGE                    COMMAND                  CREATED         STATUS         PORTS                                   NAMES
cdaad345a525   itstorage.net/centos-httpd   "/usr/sbin/httpd -D …"   7 seconds ago   Up 5 seconds   0.0.0.0:8081->80/tcp, :::8081->80/tcp   admiring_sammet

[root@docker1 ~]# docker exec cdaad345a525 ip route
default via 172.17.0.1 dev eth0
172.17.0.0/16 dev eth0 proto kernel scope link src 172.17.0.2

# attach network to specify an IP address in the subnet
[root@docker1 ~]# docker network connect --ip 192.168.100.10 network01 cdaad345a525
[root@docker1 ~]# docker exec cdaad345a525 ip route
default via 172.17.0.1 dev eth0
172.17.0.0/16 dev eth0 proto kernel scope link src 172.17.0.2
192.168.100.0/24 dev eth1 proto kernel scope link src 192.168.100.10

# to disconnect the network, set like follows
[root@docker1 ~]# docker network disconnect network01 cdaad345a525
[root@docker1 ~]# docker exec cdaad345a525 ip route
default via 172.17.0.1 dev eth0
172.17.0.0/16 dev eth0 proto kernel scope link src 172.17.0.2
#-----------------------------------------------------------------------
#3	To remove docker networks, set like follows.
[root@docker1 ~]# docker network ls
NETWORK ID     NAME           DRIVER    SCOPE
ad04ec5023ed   bridge         bridge    local
b286cf81a5f1   host           host      local
77474ec94a19   network01      bridge    local
681a4b1d762a   none           null      local
66ce864f00b6   root_default   bridge    local

# remove [network01]
[root@docker1 ~]# docker network rm network01
network01
# remove networks which containers don't use at all
[root@docker1 ~]# docker network prune
WARNING! This will remove all custom networks not used by at least one container.
Are you sure you want to continue? [y/N] y
Deleted Networks:
root_default
#-----------------------------------------------------------------------
#4	To connect to Host network, not bridge, set like follows.
[root@docker1 ~]# docker network ls
NETWORK ID     NAME      DRIVER    SCOPE
ad04ec5023ed   bridge    bridge    local
b286cf81a5f1   host      host      local
681a4b1d762a   none      null      local

[root@docker1 ~]# docker images
REPOSITORY               TAG       IMAGE ID       CREATED          SIZE
itstorage.net/centos-httpd   latest    7cf442f4e930   34 minutes ago   250MB
itstorage.net/centos-nginx   latest    6adb1438d24f   38 minutes ago   289MB
mariadb                  latest    2a2c18b8e036   10 days ago      405MB
registry                 2         1fd8e1b0bb7e   5 weeks ago      26.2MB
centos                   latest    300e315adb2f   5 months ago     209MB

# run a container with [host] network
[root@docker1 ~]# docker run -d --net host itstorage.net/centos-httpd
ad46dd88090c87dc4418a5044ec4dd722bff19bb9b56521815e8983a75733f97

[root@docker1 ~]# docker ps
CONTAINER ID   IMAGE                    COMMAND                  CREATED         STATUS         PORTS     NAMES
ad46dd88090c   itstorage.net/centos-httpd   "/usr/sbin/httpd -D …"   6 seconds ago   Up 4 seconds             goofy_heisenberg

# the port [httpd] service listens on container is used on Host network
[root@docker1 ~]# ss -napt
State     Recv-Q    Send-Q       Local Address:Port        Peer Address:Port
.....
.....
LISTEN     0      128       [::]:80                    [::]:*                   users:(("httpd",pid=15204,fd=4),("httpd",pid=15203,fd=4),("httpd",pid=15202,fd=4),("httpd",pid=15186,fd=4))

[root@docker1 ~]# curl localhost
Index.html on Aapche httpd


#-----------------------------------------------------------------------
# Reference
https://www.howtoforge.com/tutorial/monitoring-of-a-ceph-cluster-with-ceph-dash/
https://www.server-world.info/
https://docs.ceph.com/en/mimic/mgr/dashboard/
