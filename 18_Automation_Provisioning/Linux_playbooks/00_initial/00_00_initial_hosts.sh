#0-set hostname
#1-add_admin_user
#2-ssh_trust
#3-ssh_keygen
#4-ssh_config
#5-visudo
#6-change hostname

dnf install python38.x86_64
root@afra-2522-5946:~# vi /etc/hosts
root@afra-2522-5946:~# sudo hostnamectl set-hostname b4
root@afra-2522-5946:~# sudo hostnamectl --static    set-hostname  b4
root@afra-2522-5946:~# sudo hostnamectl --transient set-hostname  b4
root@afra-2522-5946:~# sudo hostnamectl --pretty    set-hostname b4
root@afra-2522-5946:~# systemctl restart systemd-hostnamed
root@afra-2522-5946:~# vi /etc/resolv.conf


ansible -i hosts_new all -m ping -u bahmani
ansible -i hosts_new all -m ping -u root  --ask-pass
ansible-playbook -i hosts_new 00_00_initial_hosts.yml -u root  --ask-pass
#Change passwd bahmani sysadmin root(login and set)
sysadmin@mbctux:~/playbooks_bahmanni$ ssh-copy-id -i ~/.ssh/id_rsa.pub sysadmin@46.102.130.89
ansible-playbook -i hosts_new 04_01_ssh_srv.yml  -u root  --ask-pass
