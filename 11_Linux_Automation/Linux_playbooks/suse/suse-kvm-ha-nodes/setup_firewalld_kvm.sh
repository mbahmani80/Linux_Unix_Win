#!/bin/bash

# Script: setup_firewalld_kvm.sh
# Purpose: Configure firewalld for KVM bridges and VLANs with host-to-host trust rules

set -e
LOGFILE=/var/log/setup_firewalld_kvm.log
exec > >(tee -a $LOGFILE) 2>&1

# List of all physical interfaces
echo "Detecting physical interfaces ..."

# Alle Interfaces auflisten, VLANs/Bridges/lo filtern
IFACES=$(ls /sys/class/net | grep -vE '^(lo|virbr|vnet|tap)')

echo "Found physical interfaces: $IFACES"
# Remove all physical interfaces from all zones
for iface in $IFACES; do
  current_zone=$(firewall-cmd --get-active-zones | grep -w $iface -B1 | head -n1 | awk '{print $1}')
  if [ -n "$current_zone" ]; then
    echo "Removing $iface from $current_zone"
    firewall-cmd --zone=$current_zone --remove-interface=$iface
    firewall-cmd --zone=$current_zone --remove-interface=$iface --permanent
  fi
done

echo "Starting firewalld configuration for KVM..."

# Create 'data' zone if it doesn't exist
# Create 'cluster' zone if it doesn't exist
create_zone_if_missing() {
  local ZONE=$1
  if ! firewall-cmd --permanent --get-zones | grep -qw "$ZONE"; then
    echo "Creating zone $ZONE..."
    firewall-cmd --permanent --new-zone="$ZONE"
  else
    echo "Zone $ZONE already exists, skipping."
  fi
}

create_zone_if_missing data
create_zone_if_missing cluster

# Remove interfaces from libvirt/public zone (if present)
for iface in br0 br1 br2 eth0 eth1 eth2; do
  echo "Removing $iface from libvirt/public zone (if exists)..."
  firewall-cmd --permanent --zone=libvirt --remove-interface=$iface || true
  firewall-cmd --permanent --zone=public --remove-interface=$iface || true
done

# Assign interfaces to appropriate zones
echo "Assigning interfaces to zones..."

# br0 = public (Management, CIFS)
firewall-cmd --permanent --zone=public --add-interface=br0

# br1 and VLAN interfaces go to data zone
firewall-cmd --permanent --zone=data --add-interface=br1

# br2 = cluster (ONTAP Select Internal)
firewall-cmd --permanent --zone=cluster --add-interface=br2

# virbr0 stays in libvirt zone
firewall-cmd --permanent --zone=libvirt --add-interface=virbr0

# Ports and services for public zone (br0)
firewall-cmd --permanent --zone=public --add-service=ssh
firewall-cmd --permanent --zone=public --add-service=cockpit

# Ports and services for data zone (Storage & Migration)
firewall-cmd --permanent --zone=data --add-service=ssh
firewall-cmd --permanent --zone=data --add-port=2049/tcp   # NFS
firewall-cmd --permanent --zone=data --add-port=2049/udp   # NFS
firewall-cmd --permanent --zone=data --add-port=3260/tcp   # iSCSI
firewall-cmd --permanent --zone=data --add-port=49152-49261/tcp # Libvirt QEMU migration, etc.
firewall-cmd --permanent --zone=data --add-port=16509/tcp  # Libvirt
firewall-cmd --permanent --zone=data --add-port=16514/tcp  # Libvirt

# Disable masquerading (default)
firewall-cmd --permanent --zone=data --remove-masquerade || true

# Add rich rules for host-to-host trust
echo "Adding host-to-host trust rules..."

for ip in 10.0.2.154 10.0.2.155; do
  firewall-cmd --permanent --zone=public --add-rich-rule="rule family=ipv4 source address=$ip accept"
done
for ip in 192.168.56.154 192.168.56.155; do
  firewall-cmd --permanent --zone=data --add-rich-rule="rule family=ipv4 source address=$ip accept"
done
for ip in 192.168.178.154 192.168.178.155; do
  firewall-cmd --permanent --zone=cluster --add-rich-rule="rule family=ipv4 source address=$ip accept"
done

# Reload firewall to apply changes
echo "Reloading firewall..."
firewall-cmd --reload

echo "firewalld configuration completed."
firewall-cmd --get-active-zones
firewall-cmd --list-all --zone=public
firewall-cmd --list-all --zone=data
firewall-cmd --list-all --zone=cluster
firewall-cmd --list-all --zone=libvirt

