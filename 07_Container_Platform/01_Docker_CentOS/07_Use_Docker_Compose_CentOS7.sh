# Use Docker Compose

# Docker Compose is a tool that was developed to help define and share multi-container applications. With Compose, we can create a YAML file to define the services and with a single command, can spin everything up or tear it all down.

# The big advantage of using Compose is you can define your application stack in a file, keep it at the root of your project repo (it’s now version controlled), and easily enable someone else to contribute to your project. Someone would only need to clone your repo and start the compose app. In fact, you might see quite a few projects on GitHub/GitLab doing exactly this now.

# This example is based on the environment below.

+---------------------------+    |    +------------------------+
| NFS Server, www Server    |    |    | Docker CE, NFS Client  |
| Docker Registry,Docker CE |    |    |                        |
| masternode1.itstorage.net +----+----+ docker1.itstorage.net  |
| 192.168.37.50             |         | 192.168.37.51          |
+---------------------------+         +------------------------+

# To Install Docker Compose, it's easy to configure and run multiple containers as a Docker application.
#1	Install Docker Compose.
[root@docker1 ~]# sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
[root@docker1 ~]# chmod 755 /usr/local/bin/docker-compose
[root@docker1 ~]# docker-compose --version
#-----------------------------------------------------------------------
#2	For example, Configure an application that has Web and DB services with Docker Compose.
# define Web service container
[root@docker1 ~]# vi Dockerfile
FROM centos
MAINTAINER ServerWorld <admin@itstorage.net>

RUN yum -y install nginx

EXPOSE 80
CMD ["/usr/sbin/nginx", "-g", "daemon off;"]

# define application configration
[root@docker1 ~]# vi docker-compose.yml
version: '3'
services:
  db:
    image: mariadb
    volumes:
      - /var/lib/docker/disk01:/var/lib/mysql
    environment:
      MYSQL_ROOT_PASSWORD: password
      MYSQL_USER: cent
      MYSQL_PASSWORD: password
      MYSQL_DATABASE: cent_db
    ports:
      - "3306:3306"
  web:
    build: .
    ports:
      - "80:80"
    volumes:
      - /var/lib/docker/disk02:/usr/share/nginx/html

# buid and run
[root@docker1 ~]# docker-compose up -d
Creating network "root_default" with the default driver
Building web
Step 1/5 : FROM centos
 ---> 300e315adb2f
Step 2/5 : MAINTAINER ServerWorld <admin@itstorage.net>
 ---> Using cache
 ---> 3b1af99319a3
Step 3/5 : RUN yum -y install nginx
 ---> Running in 55c877260a34

.....
.....

Creating root_web_1 ... done
Creating root_db_1  ... done

[root@docker1 ~]# docker ps
CONTAINER ID   IMAGE      COMMAND                  CREATED         STATUS         PORTS                                       NAMES
fa286dd17bdb   mariadb    "docker-entrypoint.s…"   9 seconds ago   Up 6 seconds   0.0.0.0:3306->3306/tcp, :::3306->3306/tcp   root_db_1
8a0181ea0c35   root_web   "/usr/sbin/nginx -g …"   9 seconds ago   Up 6 seconds   0.0.0.0:80->80/tcp, :::80->80/tcp           root_web_1

# verify accesses
[root@docker1 ~]# mysql -h 127.0.0.1 -u root -p -e "show variables like 'hostname';"
Enter password:
+---------------+--------------+
| Variable_name | Value        |
+---------------+--------------+
| hostname      | fa286dd17bdb |
+---------------+--------------+

[root@docker1 ~]# mysql -h 127.0.0.1 -u cent -p -e "show databases;"
Enter password:
+--------------------+
| Database           |
+--------------------+
| cent_db            |
| information_schema |
+--------------------+

[root@docker1 ~]# echo "Hello Docker Compose World" > /var/lib/docker/disk02/index.html
[root@docker1 ~]# curl 127.0.0.1
Hello Docker Compose World
#-----------------------------------------------------------------------
#3	Other basic operations of Docker Compose are follows.
# verify state of containers
[root@docker1 ~]# docker-compose ps
Name                 Command               State                    Ports
------------------------------------------------------------------------
root_db_1    docker-entrypoint.sh mysqld      Up      0.0.0.0:3306->3306/tcp,:::3306->3306/tcp
root_web_1   /usr/sbin/nginx -g daemon off;   Up      0.0.0.0:80->80/tcp,:::80->80/tcp

# show logs of containers
[root@docker1 ~]# docker-compose logs

# run any commands inside a container
# container name is just the one set in [docker-compose.yml]
[root@docker1 ~]# docker-compose exec db /bin/bash
root@fa286dd17bdb:/#

# stop application and also shutdown all containers
[root@docker1 ~]# docker-compose stop
Stopping root_web_1 ... done
Stopping root_db_1  ... done

# start a service alone in application
# if set dependency, other container starts
[root@docker1 ~]# docker-compose up -d web
Starting root_web_1 ... done
[root@docker1 ~]# docker-compose ps
   Name                 Command               State                 Ports
---------------------------------------------------------------------------------------
root_db_1    docker-entrypoint.sh mysqld      Exit 0
root_web_1   /usr/sbin/nginx -g daemon off;   Up       0.0.0.0:80->80/tcp,:::80->80/tcp

# remove all containers in application
# if a container is running, it won't be removed
[root@docker1 ~]# docker-compose rm
Going to remove root_db_1
Are you sure? [yN] y
Removing root_db_1 ... done


#-----------------------------------------------------------------------
# Reference
https://www.howtoforge.com/tutorial/monitoring-of-a-ceph-cluster-with-ceph-dash/
https://www.server-world.info/
https://docs.ceph.com/en/mimic/mgr/dashboard/
