# Docker : Access to Container Services
# If you'd like to access to services like HTTP or SSH which is running in Containers as a daemon, Configure like follows.

# This example is based on the environment below.

+---------------------------+    |    +------------------------+
| NFS Server, www Server    |    |    | Docker CE, NFS Client  |
| Docker Registry,Docker CE |    |    |                        |
| masternode1.itstorage.net +----+----+ docker1.itstorage.net  |
| 192.168.37.50             |         | 192.168.37.51          |
+---------------------------+         +------------------------+

#1	For exmaple, Use a Container image which has Nginx.
# start a Container and also run Nginx
# map the port of Host and the port of Container with [-p xxx:xxx]
[root@docker1:~]# docker run -t -d -p 8081:80 itstorage.net/centos-nginx /usr/sbin/nginx -g "daemon off;"
a8e3bfc7253f4761eb1737c134b79e139cb6e278aa9744a06f5ccb85e1216995

[root@docker1:~]# docker ps
CONTAINER ID   IMAGE                    COMMAND                  CREATED          STATUS         PORTS                                   NAMES
a8e3bfc7253f   itstorage.net/centos-nginx   "/usr/sbin/nginx -g …"   10 seconds ago   Up 8 seconds   0.0.0.0:8081->80/tcp, :::8081->80/tcp   heuristic_margulis

# create a test page
[root@docker1:~]# docker exec a8e3bfc7253f /bin/bash -c 'echo "Nginx on Docker Container" > /usr/share/nginx/html/index.html'
# verify it works normally
[root@docker1:~]# curl localhost:8081
Nginx on Docker Container

#-----------------------------------------------------------------------
# Reference
https://www.howtoforge.com/tutorial/monitoring-of-a-ceph-cluster-with-ceph-dash/
https://www.server-world.info/
https://docs.ceph.com/en/mimic/mgr/dashboard/
