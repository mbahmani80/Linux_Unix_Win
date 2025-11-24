# Use Registry

# What is Docker container registry?
# Container Registry is a single place for your team to manage Docker images, perform vulnerability analysis, and decide who can access what with fine-grained access control. Existing CI/CD integrations let you set up fully automated Docker pipelines to get fast feedback.

# This example is based on the environment below.

+---------------------------+    |    +------------------------+
| NFS Server, www Server    |    |    | Docker CE, NFS Client  |
| Docker Registry,Docker CE |    |    |                        |
| masternode1.itstorage.net +----+----+ docker1.itstorage.net  |
| 192.168.37.50             |         | 192.168.37.51          |
+---------------------------+         +------------------------+

#1	Pull the Registry image and run it.
# Container Images are located under [/var/lib/regstry] on Registry v2 Container,
# so map to mount [/var/lib/docker/registry] on parent Host for Registry Container to use as Persistent Storage.
[root@masternode1 ~]# docker pull registry:2
[root@masternode1 ~]# mkdir /var/lib/docker/registry
[root@masternode1 ~]# docker run -d -p 5000:5000 \
-v /var/lib/docker/registry:/var/lib/registry \
registry:2
996e918ad31f0ebcbc27187c18b5f70876e840f5c447ad370844b984bdcf0f9d

[root@masternode1 ~]# docker ps
CONTAINER ID   IMAGE        COMMAND                  CREATED         STATUS         PORTS                                       NAMES
996e918ad31f   registry:2   "/entrypoint.sh /etc…"   8 seconds ago   Up 7 seconds   0.0.0.0:5000->5000/tcp, :::5000->5000/tcp   peaceful_solomon

# if Firewalld is running, allow ports
[root@masternode1 ~]# firewall-cmd --add-port=5000/tcp --permanent
[root@masternode1 ~]# firewall-cmd --reload
# to use the Registry from other Docker Client Hosts, set like follows
[root@docker1 ~]# vi /etc/docker/daemon.json
# create new or add
# add Hosts you allow HTTP connection (default is HTTPS)
{
  "insecure-registries":
    [
      "docker.internal:5000",
      "masternode1.itstorage.net:5000"
    ]
}

[root@docker1 ~]# systemctl restart docker
[root@docker1 ~]# docker tag nginx masternode1.itstorage.net:5000/nginx:my-registry
[root@docker1 ~]# docker push masternode1.itstorage.net:5000/nginx:my-registry
[root@docker1 ~]# docker images
REPOSITORY                 TAG           IMAGE ID       CREATED       SIZE
nginx                      latest        f0b8a9a54136   11 days ago   133MB
masternode1.itstorage.net:5000/nginx   my-registry   f0b8a9a54136   11 days ago   133MB

#-----------------------------------------------------------------------
#2 Create SSL Certificates
#2.1 Create Self sign Certificate
# Create own-created SSL Certificates. However, If you use your server as a business, it had better buy and use a Formal Certificate from Verisigh and so on.
[root@masternode1 ~]# cd /etc/pki/tls/certs
[root@masternode1 certs]# make server.key
umask 77 ; \
/usr/bin/openssl genrsa -aes128 2048 > server.key
Generating RSA private key, 2048 bit long modulus
...
...
e is 65537 (0x10001)
Enter pass phrase:     # set passphrase
Verifying - Enter pass phrase:     # confirm
# remove passphrase from private key
[root@masternode1 certs]# openssl rsa -in server.key -out server.key
Enter pass phrase for server.key:     # input passphrase
writing RSA key
[root@masternode1 certs]# make server.csr
umask 77 ; \
/usr/bin/openssl req -utf8 -new -key server.key -out server.csr
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Country Name (2 letter code) [XX]:IR     # country
State or Province Name (full name) []:Tehran   # state
Locality Name (eg, city) [Default City]:Tehran     # city
Organization Name (eg, company) [Default Company Ltd]:ITStorage   # company
Organizational Unit Name (eg, section) []:IT   # department
Common Name (eg, your name or your servers hostname) []:masternode1.itstorage.net  
Email Address []:admin@itstorage.net      # email address
Please enter the following 'extra' attributes
to be sent with your certificate request
A challenge password []:     # Enter
An optional company name []:     # Enter
[root@masternode1 certs]# openssl x509 -in server.csr -out server.crt -req -signkey server.key -days 3650
Signature ok
subject=/C=IR/ST=Tehran/L=Tehran/O=ITStorage/OU=IT/CN=masternode1.itstorage.net/emailAddress=admin@itstorage.net
Getting Private key
#-----------------------------------------------------------------------
#2.1.1 This example is based on that certificate were created under the [/etc/pki/tls/certs] directory.

[root@masternode1 ~]# docker run -d -p 5000:5000 \
-e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/server.crt \
-e REGISTRY_HTTP_TLS_KEY=/certs/server.key \
-v /etc/pki/tls/certs:/certs \
-v /var/lib/docker/registry:/var/lib/registry \
registry:2
2d8b71a51f374154f5d8d331ca8b9d0a773598defcbf264834d71a2cec466b8b

# to use the Registry from other Docker Client Hosts, set like follows
# it's not need to add [insecure-registries] but
# need to locate server's certificate on the client side like follows
[root@docker1 ~]# mkdir -p /etc/docker/certs.d/masternode1.itstorage.net:5000
[root@docker1 ~]# scp masternode1.itstorage.net:/etc/pki/tls/certs/server.crt /etc/docker/certs.d/masternode1.itstorage.net:5000/ca.crt
[root@docker1 ~]# docker tag centos masternode1.itstorage.net:5000/centos:my-registry
[root@docker1 ~]# docker push masternode1.itstorage.net:5000/centos:my-registry
[root@docker1 ~]# docker images
REPOSITORY                  TAG           IMAGE ID       CREATED        SIZE
masternode1.itstorage.net:5000/centos   my-registry   300e315adb2f   5 months ago   209MB
centos                      latest        300e315adb2f   5 months ago   209MB
#-----------------------------------------------------------------------
#2.2 Get SSL Certificates (Let's Encrypt)
# Get SSL Certificates from Let's Encrypt who provides Free SSL Certificates.
# Refer to the details for Let's Encrypt official site below.
# ⇒ https://letsencrypt.org/
# By the way, expiration date of a cert is 90 days, so you must update within next 90 days later.
#2.2.1	Install Certbot Client which is the tool to get certificates from Let's Encrypt.
# install from EPEL
[root@masternode1 ~]# yum --enablerepo=epel -y install certbot
#2.2.2	Get certificates.
# It needs Web server like Apache httpd or Nginx must be runing on the server you work.
# Furthermore, it needs that it's possible to access from the Internet to your working server on port 80 because of verification from Let's Encrypt.
# for the option [--webroot], use a directory under the webroot on your server as a working temp
# -w [document root] -d [FQDN you'd like to get certs]
# FQDN (Fully Qualified Domain Name) : Hostname.Domainname
# if you'd like to get certs for more than 2 FQDNs, specify all like below
# ex : if get [itstorage.net] and [masternode1.itstorage.net]
# ⇒ specify [-d itstorage.net -d masternode1.itstorage.net]
[root@masternode1 ~]# certbot certonly --webroot -w /var/www/html -d masternode1.itstorage.net
Saving debug log to /var/log/letsencrypt/letsencrypt.log
Plugins selected: Authenticator webroot, Installer None
Enter email address (used for urgent renewal and security notices) 
# for only initial using, register your email address and agree to terms of use
# specify valid email address
(Enter 'c' to cancel): root@mail.itstorage.net 
Starting new HTTPS connection (1): acme-v01.api.letsencrypt.org

-------------------------------------------------------------------------------
Please read the Terms of Service at
https://letsencrypt.org/documents/LE-SA-v1.2-Jan-15-2022.pdf. You must
agree in order to register with the ACME server at
https://acme-v01.api.letsencrypt.org/directory
-------------------------------------------------------------------------------
# agree to the terms of use
(A)gree/(C)ancel: A

-------------------------------------------------------------------------------
Would you be willing to share your email address with the Electronic Frontier
Foundation, a founding partner of the Let's Encrypt project and the non-profit
organization that develops Certbot? We'd like to send you email about EFF and
our work to encrypt the web, protect its users and defend digital rights.
-------------------------------------------------------------------------------
# answer Yes or No
(Y)es/(N)o: Y
Starting new HTTPS connection (1): supporters.eff.org
Obtaining a new certificate
Performing the following challenges:
http-01 challenge for masternode1.itstorage.net
Using the webroot path /var/www/html for all unmatched domains.
Waiting for verification...
Cleaning up challenges

IMPORTANT NOTES:
 - Congratulations! Your certificate and chain have been saved at:
   /etc/letsencrypt/live/masternode1.itstorage.net/fullchain.pem
   Your key file has been saved at:
   /etc/letsencrypt/live/masternode1.itstorage.net/privkey.pem
   Your cert will expire on 2018-05-22. To obtain a new or tweaked
   version of this certificate in the future, simply run certbot
   again. To non-interactively renew *all* of your certificates, run
   "certbot renew"
 - Your account credentials have been saved in your Certbot
   configuration directory at /etc/letsencrypt. You should make a
   secure backup of this folder now. This configuration directory will
   also contain certificates and private keys obtained by Certbot so
   making regular backups of this folder is ideal.
 - If you like Certbot, please consider supporting our work by:

   #Donating to ISRG / Let's Encrypt:   https://letsencrypt.org/donate
   #Donating to EFF:                    https://eff.org/donate-le

# success if [Congratulations] is shown
# certs are created under the [/etc/letsencrypt/live/(FQDN)/] directory

# cert.pem       ⇒ SSL Server cert(includes public-key)
# chain.pem      ⇒ intermediate certificate
# fullchain.pem  ⇒ combined file cert.pem and chain.pem
# privkey.pem    ⇒ private-key file

#2.2.3	If no Web Server is running on your working server, it's possbile to get certs with using Certbot's Web Server feature. Anyway, it needs that it's possible to access from the Internet to your working server on port 80 because of verification from Let's Encrypt.
# for the option [--standalone], use Certbot's Web Server feature
# -d [FQDN you'd like to get certs]
# FQDN (Fully Qualified Domain Name) : Hostname.Domainname
# if you'd like to get certs for more than 2 FQDNs, specify all like below
# ex : if get [itstorage.net] and [masternode1.itstorage.net]
# ⇒ specify [-d itstorage.net -d masternode1.itstorage.net]
[root@masternode1 ~]# certbot certonly --standalone -d mail.itstorage.net
Saving debug log to /var/log/letsencrypt/letsencrypt.log
Plugins selected: Authenticator standalone, Installer None
Starting new HTTPS connection (1): acme-v01.api.letsencrypt.org
Obtaining a new certificate
Performing the following challenges:
http-01 challenge for mail.itstorage.net
Waiting for verification...
Cleaning up challenges

IMPORTANT NOTES:
 - Congratulations! Your certificate and chain have been saved at:
   /etc/letsencrypt/live/mail.itstorage.net/fullchain.pem
   Your key file has been saved at:
   /etc/letsencrypt/live/mail.itstorage.net/privkey.pem
   Your cert will expire on 2018-05-22. To obtain a new or tweaked
   version of this certificate in the future, simply run certbot
   again. To non-interactively renew *all* of your certificates, run
   "certbot renew"
 - If you like Certbot, please consider supporting our work by:

   #Donating to ISRG / Let's Encrypt:   https://letsencrypt.org/donate
   #Donating to EFF:                    https://eff.org/donate-le

#2.2.4	For Updating existing certs, Do like follows.
# update all certs which has less than 30 days expiration
# if you'd like to update certs which has more than 30 days expiration, add [--force-renew] option
[root@masternode1 ~]# certbot renew

#2.2.5	If you'd like to convert certificates to PKCS12 (PFX) format for Windows, do like follows.
[root@masternode1 ~]# openssl pkcs12 -export -in fullchain.pem -inkey privkey.pem -out dlp_for_iis.pfx
Enter Export Password:     # set any export password
Verifying - Enter Export Password:
#-----------------------------------------------------------------------
#2.2.6 This example is based on that certificate were created under the [/etc/letsencrypt] directory.
[root@masternode1 ~]# docker run -d -p 5000:5000 \
-e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/fullchain.pem \
-e REGISTRY_HTTP_TLS_KEY=/certs/privkey.pem \
-v /etc/letsencrypt/live/masternode1.itstorage.net:/certs \
-v /var/lib/docker/registry:/var/lib/registry \
registry:2
28512a4b96d93172b7af66f6b7263fdbff8d729a76659c8b955c60800b557f4f

# to use the Registry from other Docker Client Hosts, set like follows
# it's not need to change any specific settings, it can use with default
[root@docker1 ~]# docker tag nginx masternode1.itstorage.net:5000/my-nginx:my-registry
[root@docker1 ~]# docker push masternode1.itstorage.net:5000/my-nginx:my-registry
[root@docker1 ~]# docker images
masternode1.itstorage.net:5000/my-nginx    my-registry   7ce4f91ef623   6 days ago     133MB
nginx                          latest        7ce4f91ef623   6 days ago     133MB
#-----------------------------------------------------------------------
#3	To enable Basic authentication, Configure like follows.
[root@masternode1 ~]# yum install httpd-tools
# add users
# add [-c] at initial file creation
[root@masternode1 ~]# htpasswd -Bc /etc/docker/.htpasswd admin
New password:
Re-type new password:
Adding password for user admin

[root@masternode1 ~]# docker run -d -p 5000:5000 \
-v /var/lib/docker/registry:/var/lib/docker/registry \
-v /etc/docker:/auth \
-e REGISTRY_AUTH=htpasswd \
-e REGISTRY_AUTH_HTPASSWD_PATH=/auth/.htpasswd \
-e REGISTRY_AUTH_HTPASSWD_REALM="Registry Realm" \
registry:2 
77c4b2db35af4cf06b09474062767ec9c6e5b19465d6686843d847a35f464a2f

[root@dlp ~]# docker ps
CONTAINER ID   IMAGE                    COMMAND                  CREATED              STATUS              PORTS                                       NAMES
77c4b2db35af   registry:2               "/entrypoint.sh /etc…"   17 seconds ago       Up 16 seconds       0.0.0.0:5000->5000/tcp, :::5000->5000/tcp   great_curran

# verify possible to access
# authenticate by a user added with [htpasswd]
[root@docker1 ~]# docker login masternode1.itstorage.net:5000
Username: admin
Password:
Login Succeeded

[root@docker1 ~]# docker pull masternode1.itstorage.net:5000/nginx:my-registry
[root@docker1 ~]# docker images
REPOSITORY                 TAG           IMAGE ID       CREATED       SIZE
masternode1.itstorage.net:5000/nginx   my-registry   62d49f9bab67   4 weeks ago   133MB

#-----------------------------------------------------------------------
# Reference
https://www.howtoforge.com/tutorial/monitoring-of-a-ceph-cluster-with-ceph-dash/
https://www.server-world.info/
https://docs.ceph.com/en/mimic/mgr/dashboard/
