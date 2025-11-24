#!/bin/bash

# Define exit status
STATUS_OK=0
STATUS_WARNING=1
STATUS_CRITICAL=2
STATUS_UNKNOWN=3

# Your check logic here

# Generate dummy data for CPU usage (random value between 0 and 100)
cpu_usage=$(shuf -i 0-100 -n 1)

# Generate dummy data for memory usage (random value between 0 and 100)
memory_usage=$(shuf -i 0-100 -n 1)

# Generate dummy data for disk usage (random value between 0 and 100)
disk_usage=$(shuf -i 0-100 -n 1)

# Define thresholds for CPU, memory, and disk usage
CPU_THRESHOLD_CRITICAL=90
CPU_THRESHOLD_WARNING=80

MEMORY_THRESHOLD_CRITICAL=85
MEMORY_THRESHOLD_WARNING=75

DISK_THRESHOLD_CRITICAL=95
DISK_THRESHOLD_WARNING=85

# Define exit statuses based on thresholds
if [ $cpu_usage -gt $CPU_THRESHOLD_CRITICAL ]; then
    CPU_EXIT_STATUS=$STATUS_CRITICAL
elif [ $cpu_usage -gt $CPU_THRESHOLD_WARNING ]; then
    CPU_EXIT_STATUS=$STATUS_WARNING
else
    CPU_EXIT_STATUS=$STATUS_OK
fi

if [ $memory_usage -gt $MEMORY_THRESHOLD_CRITICAL ]; then
    MEMORY_EXIT_STATUS=$STATUS_CRITICAL
elif [ $memory_usage -gt $MEMORY_THRESHOLD_WARNING ]; then
    MEMORY_EXIT_STATUS=$STATUS_WARNING
else
    MEMORY_EXIT_STATUS=$STATUS_OK
fi

if [ $disk_usage -gt $DISK_THRESHOLD_CRITICAL ]; then
    DISK_EXIT_STATUS=$STATUS_CRITICAL
elif [ $disk_usage -gt $DISK_THRESHOLD_WARNING ]; then
    DISK_EXIT_STATUS=$STATUS_WARNING
else
    DISK_EXIT_STATUS=$STATUS_OK
fi

echo "<<<check_mk>>>"
echo "Version: check_mynetapp.py v7.1.5"
echo "AgentOS: Ubuntu Linux Python3 Script"
echo
echo "<<<local>>>"
# Output the data in Checkmk-compatible format
echo "0 \"svm01_nfs:Volumes.Primary.SnapshotCount\" - checked=1,fail=0,max=1"

# Output the data in Checkmk-compatible format
echo "$CPU_EXIT_STATUS \"Dummy_CPU_Usage\" - cpu_usage=$cpu_usage OK - Dummy data generated"
echo "$MEMORY_EXIT_STATUS \"Dummy_Memory_Usage\" - memory_usage=$memory_usage OK - Dummy data generated"
echo "$DISK_EXIT_STATUS \"Dummy_Disk_Usage\" - disk_usage=$disk_usage OK - Dummy data generated"

# Determine overall exit status based on individual metrics
if [ $CPU_EXIT_STATUS -eq $STATUS_CRITICAL ] || [ $MEMORY_EXIT_STATUS -eq $STATUS_CRITICAL ] || [ $DISK_EXIT_STATUS -eq $STATUS_CRITICAL ]; then
    OVERALL_EXIT_STATUS=$STATUS_CRITICAL
elif [ $CPU_EXIT_STATUS -eq $STATUS_WARNING ] || [ $MEMORY_EXIT_STATUS -eq $STATUS_WARNING ] || [ $DISK_EXIT_STATUS -eq $STATUS_WARNING ]; then
    OVERALL_EXIT_STATUS=$STATUS_WARNING
else
    OVERALL_EXIT_STATUS=$STATUS_OK
fi

#echo "0 \"AAAA-testcl1.Cache\" - CheckDate=[26.04.2024 16:40:30], CacheDate=[26.04.2024 16:20:03], CacheAge=[20]minutes"

# Exit with the overall exit status
#exit $OVERALL_EXIT_STATUS
exit 0

