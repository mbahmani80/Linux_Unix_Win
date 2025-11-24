#!/bin/bash
# grafana-backup  restore 202405151001.tar.gz --components=dashboards
source /home/ubuntu/.bash_profile
cd /home/ubuntu/05_grafana-backup/grafana-backup_Checkmk-test/
grafana-backup save
rsync -avHAX --delete /home/ubuntu/grafana-backup_Checkmk-test sysadmin@172.28.30.16:/home/sysadmin/01_mycolap/mycolap/01_tools/05_grafana-backup/

cd /home/ubuntu/05_grafana-backup/
ssh  sysadmin@172.28.30.16 '/home/sysadmin/01_mycolap/mycolap/01_tools/05_grafana-backup/./grafana_bk.sh'
rsync -avHAX --delete sysadmin@172.28.30.16:/home/sysadmin/01_mycolap/mycolap/01_tools/05_grafana-backup/grafana-backup_vml-mbahmani /home/ubuntu/05_grafana-backup/
