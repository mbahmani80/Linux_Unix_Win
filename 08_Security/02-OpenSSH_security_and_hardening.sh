#!/bin/bash

# 02-OpenSSH_security_and_hardening.sh
#-----------------------------------------------------------------------
# Today, the most common method of communication between servers and network equipment is through the SSH (Secure Shell) communication protocol. Therefore, the rigidity of its settings is of great importance.
#-----------------------------------------------------------------------
# 2. Securing the OpenSSH service
# 2.1 OpenSSH server hardening
	MaxSessions
	MaxAuthTries
	Change LogLevel
	Change Default Port
	Set SSH protocol
	Disable root login
	Empty passwords
	Use HashKnownHosts
	DNS hostname checking
	Public key authentication
	Restrict allowable commands
	Maximum authentication attempts
	Usage of AllowUsers and DenyUsers
	Disable rhosts
	Disable Compression
	Disable TCPKeepAlive
	Disable X11Forwarding
	Disable AllowTcpForwarding
	Change ClientAliveInterval
	Change ClientAliveCountMax
	Disable AllowAgentForwarding

# To configure SSH Server, its service configuration file /etc/ssh /sshd_config must be edited and edited according to its parameters. For convenience, you can install the augtool software and edit all service parameters at once. Or do it manually. I use augtool software.
#-----------------------------------------------------------------------
# 2.2 Augeas installation on RHEL\CentOS and Debian
[root@centos7 ~]# yum -y install augeas
root@deb:~# apt-get install augeas-tools
#-----------------------------------------------------------------------
# 2.2 Configure SSH Server on RHEL\ CentOS and Debian
# First, we make a backup copy of the configuration file.
root@deb:~# cp /etc/ssh/sshd_config /etc/ssh/sshd_config-orig
# Now we apply the desired configuration using augtool software. With this software, you can edit any of your Linux configuration files.
root@deb:~# augtool << EOF
set /files/etc/ssh/sshd_config/ListenAddress 0.0.0.0
set /files/etc/ssh/sshd_config/PermitRootLogin no
set /files/etc/ssh/sshd_config/ChallengeResponseAuthentication no
set /files/etc/ssh/sshd_config/PasswordAuthentication yes
set /files/etc/ssh/sshd_config/UsePAM yes
set /files/etc/ssh/sshd_config/UseDNS no
set /files/etc/ssh/sshd_config/Port 2212
set /files/etc/ssh/sshd_config/Protocol 2
set /files/etc/ssh/sshd_config/LogLevel VERBOSE
set /files/etc/ssh/sshd_config/MaxAuthTries 3
set /files/etc/ssh/sshd_config/MaxSessions 2
set /files/etc/ssh/sshd_config/AllowAgentForwarding no
set /files/etc/ssh/sshd_config/AllowTcpForwarding no
set /files/etc/ssh/sshd_config/X11Forwarding no
set /files/etc/ssh/sshd_config/TCPKeepAlive no
set /files/etc/ssh/sshd_config/Compression no
set /files/etc/ssh/sshd_config/ClientAliveInterval 300
set /files/etc/ssh/sshd_config/ClientAliveCountMax 0
set /files/etc/ssh/sshd_config/IgnoreRhosts yes
set /files/etc/ssh/sshd_config/PubkeyAuthentication yes
set /files/etc/ssh/sshd_config/Protocol 2
set /files/etc/ssh/sshd_config/AllowTcpForwarding no
save
EOF
Saved 1 file(s)
root@deb:~#
#-----------------------------------------------------------------------
# 2.3 Configure Debian and RHEL\CentOS
# Set one of two parameters
AllowGroups ssh
AllowUsers bahmani

# We specify which user or group can ssh. Be careful not to use these two parameters together. Because the combination of both or And becomes.

root@deb:~# groupadd ssh
root@deb:~# usermod -aG ssh bahmani
root@deb:~# sudo cat /etc/ssh/sshd_config
....
AllowGroups ssh
#-----------------------------------------------------------------------
# 2.4 Configure RHEL\ CentOS
 
[root@centos7 ~]# groupadd ssh
[root@centos7 ~]# usermod -aG ssh bahmani
[root@centos7 ~]# cat /etc/ssh/sshd_config
....
AllowGroups ssh
#-----------------------------------------------------------------------
# Check the applied settings
root@deb:~# grep -E 'AllowTcpForwarding|ListenAddress|PubkeyAuthentication|AllowTcpForwarding|Protocol|IgnoreRhosts|PasswordAuthentication|ChallengeResponseAuthentication|Compression|LogLevel|MaxAuthTries|MaxSessions|TCPKeepAlive|X11Forwarding|AllowAgentForwarding|Port|Permit|AllowUsers|ClientAliveInterval|ClientAliveCountMax|AllowGroup' /etc/ssh/sshd_config |grep -v ^#

Port 2212
ListenAddress 0.0.0.0
LogLevel VERBOSE
PermitRootLogin no 
MaxAuthTries 1 
MaxSessions 2 
ChallengeResponseAuthentication no
AllowAgentForwarding no 
AllowTcpForwarding no 
X11Forwarding no 
TCPKeepAlive no 
Compression no 
ClientAliveInterval 300
ClientAliveCountMax 0
PasswordAuthentication no
IgnoreRhosts yes
PubkeyAuthentication yes
Protocol 2
AllowGroups ssh

root@deb:~#
#-----------------------------------------------------------------------
# Fix incorrect permissions for file /root/.ssh

root@deb:~# find ~/.ssh -type f -exec chmod 600 {} \;
root@deb:~# chmod 700 ~/.ssh
root@deb:~# chmod 644 ~/.ssh/authorized_keys
Now, restart sshd service:

root@deb:~# systemctl restart sshd.service
