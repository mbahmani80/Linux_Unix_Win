#!/bin/bash

# Script to create bridges br0, br1, br2 with ZONEs and set NICs to BOOTPROTO='none'
#Create bridges br0, br1, br2 based on eth0, eth1, eth2.
#Set the ZONE for each bridge (public, data, cluster).
#Ensure that all physical NICs (eth0, eth1, eth2) have BOOTPROTO='none'.
#Keep existing IP, gateway, DNS from the NICs for the bridges.

# Read bridge info: bridge_name:NIC:ZONE
while IFS=: read -r br nic zone; do
    echo "Configuring bridge $br on NIC $nic with zone $zone..."

    # Copy existing NIC config to bridge config
    cp /etc/sysconfig/network/ifcfg-$nic /etc/sysconfig/network/ifcfg-$br

    # Append bridge-specific settings
    echo "BRIDGE='yes'" >> /etc/sysconfig/network/ifcfg-$br
    echo "BRIDGE_PORTS='$nic'" >> /etc/sysconfig/network/ifcfg-$br
    echo "BRIDGE_STP='off'" >> /etc/sysconfig/network/ifcfg-$br
    echo "BRIDGE_FORWARDDELAY='15'" >> /etc/sysconfig/network/ifcfg-$br
    echo "ZONE='$zone'" >> /etc/sysconfig/network/ifcfg-$br

    # Ensure physical NIC has BOOTPROTO='none'
    sed -i "s/^BOOTPROTO=.*/BOOTPROTO='none'/g" /etc/sysconfig/network/ifcfg-$nic

    # Ensure STARTMODE is set for the NIC
    grep -q "^STARTMODE=" /etc/sysconfig/network/ifcfg-$nic || echo "STARTMODE='auto'" >> /etc/sysconfig/network/ifcfg-$nic

done <<EOF
br0:eth0:public
br1:eth1:data
br2:eth2:cluster
EOF

echo "Bridge configuration completed. Remember to restart the network:"
echo "  sudo systemctl restart network"
echo "or bring up individual bridges manually:"
echo "  sudo ifup br0"
echo "  sudo ifup br1"
echo "  sudo ifup br2"

