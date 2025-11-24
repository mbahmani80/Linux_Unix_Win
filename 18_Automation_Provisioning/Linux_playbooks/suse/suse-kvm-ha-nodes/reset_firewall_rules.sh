#!/bin/bash

LOGFILE=/var/log/reset_firewall_rules.log
exec > >(tee -a $LOGFILE) 2>&1

echo "Starting firewall reset..."

# Zones to clean
zones=("trusted" "data" "public" "cluster")

# Interfaces to remove
IFACES=$(ls /sys/class/net | grep -vE '^(lo|virbr|vnet|tap)')

# Function to delete all rich rules from a zone
delete_rich_rules() {
  local zone=$1
  local rules
  rules=$(firewall-cmd --permanent --zone="$zone" --list-rich-rules)
  if [ -n "$rules" ]; then
    while read -r rule; do
      if [ -n "$rule" ]; then
        echo "Removing rich rule from zone $zone: $rule"
        firewall-cmd --permanent --zone="$zone" --remove-rich-rule="$rule"
      fi
    done <<< "$rules"
  else
    echo "No rich rules found in zone $zone."
  fi
}

# Remove interfaces from their current active zones
for iface in $IFACES; do
  current_zone=$(firewall-cmd --get-active-zones | grep -w $iface -B1 | head -n1 | awk '{print $1}')
  if [ -n "$current_zone" ]; then
    echo "Removing interface $iface from $current_zone"
    firewall-cmd --zone=$current_zone --remove-interface=$iface
    firewall-cmd --zone=$current_zone --remove-interface=$iface --permanent
  else
    echo "Interface $iface not assigned to any active zone."
  fi
done

# Clean each zone
for zone in "${zones[@]}"; do
  echo "Processing zone: $zone"

  # Remove all services
  services=$(firewall-cmd --permanent --zone="$zone" --list-services)
  for service in $services; do
    echo "Removing service '$service' from zone $zone"
    firewall-cmd --permanent --zone="$zone" --remove-service="$service"
  done

  # Remove all ports
  ports=$(firewall-cmd --permanent --zone="$zone" --list-ports)
  for port in $ports; do
    echo "Removing port '$port' from zone $zone"
    firewall-cmd --permanent --zone="$zone" --remove-port="$port"
  done

  # Disable masquerading
  echo "Disabling masquerading in zone $zone"
  firewall-cmd --permanent --zone="$zone" --remove-masquerade || true

  # Delete all rich rules
  delete_rich_rules "$zone"
done

echo "Firewall reset completed. Reloading..."
firewall-cmd --reload
echo "Done."

