#!/bin/bash
set -x
sudo /usr/bin/find /home/ubuntu/Documents/backup/ -type f -mtime +4 -name '*.tar' -execdir rm -- '{}' \;
#sudo /usr/bin/find /home/sysadmin/my_netapp_playbook/del_snap2/del/log/ -type f -mtime +30 -name '*.txt' -execdir rm -- '{}' \;
