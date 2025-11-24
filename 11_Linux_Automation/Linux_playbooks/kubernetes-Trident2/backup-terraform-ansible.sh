#!/bin/bash

rsync -avHAX --delete /home/sysadmin/my_netapp_playbook /home/sysadmin/backup-terraform-ansible/
rsync -avHAX --delete /home/sysadmin/my_sysadmin_playbook /home/sysadmin/backup-terraform-ansible/
rsync -avHAX --delete /home/sysadmin/terraform /home/sysadmin/backup-terraform-ansible/
rsync -avHAX --delete /home/sysadmin/my_kubernetes_ymls /home/sysadmin/backup-terraform-ansible/
sudo tar -cvvf /home/ubuntu/Documents/backup/backup-terraform-ansible_$(date +%d-%m-%Y).tar /home/sysadmin/backup-terraform-ansible
sudo chown ubuntu:ubuntu /home/ubuntu/Documents/backup/backup-terraform-ansible_$(date +%d-%m-%Y).tar
