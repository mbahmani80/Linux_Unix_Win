#!/bin/sh
# FreeBSD 15 UEFI ZFS Install Script for Dual-Boot with openSUSE
# WARNING: This script will DESTROY ALL DATA on the specified partition!
# Verify disk, partition, and labels before running.

echo "=============================================================="
echo "HINT: Before continuing, verify your partition layout!"
echo "Use the following command to see all disks and partitions:"
echo "  gpart show"
echo "Make sure you know which partition you will use for FreeBSD."
echo "=============================================================="
read -p "Press Enter to continue after verifying, or Ctrl+C to abort."

# =============================
# Configuration - CHANGE CAREFULLY
# =============================

DISK=/dev/da0                  # Disk to install FreeBSD on (e.g., /dev/da0)
PARTITION=/dev/da0s3           # your dedicated FreeBSD partition
ZNAME=zroot               # ZFS pool name
ZLABEL=disk0              # Partition label for ZFS root
COMPRESSION=lz4           # ZFS compression algorithm
MOUNT=/tmp/mnt            # Temporary mount point for installation
TMPFS=/tmp/tmpfs          # Temporary tmpfs for caching
IP_ADDR=192.168.1.50      # Static IP for FreeBSD installer
NETMASK=255.255.255.0
GATEWAY=192.168.1.1
EFI_PART=/dev/da0s1        # Shared EFI partition from openSUSE
NIC=em0                   # Network interface

# =============================
# Warning and confirmation
# =============================
echo "=============================================================="
echo "WARNING: This script will DESTROY ALL DATA on the specified partition ${PARTITION}!"
echo "Do NOT run this on the wrong partition."
echo "ZFS pool name: ${ZNAME}"
echo "EFI partition used: ${EFI_PART} (will NOT be formatted)"
echo "Double-check everything before continuing!"
echo "=============================================================="

read -p "Type 'yes' to continue: " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo "Aborting installation."
    exit 1
fi

# =============================
# Environment checks
# =============================
VER=`uname -r | cut -d. -f1`
ARCH=`uname -p`

if [ "$VER" != "15" ] && [ "$VER" != "14" ]; then
    echo "Unsupported FreeBSD version: $VER"
    exit 1
fi
if [ "$ARCH" != "amd64" ]; then
    echo "Unsupported architecture: $ARCH"
    exit 1
fi

# =============================
# Prepare tmpfs and mount points
# =============================
mkdir -p ${MOUNT} ${TMPFS}
TMPFS_MOD=$(kldstat | grep tmpfs | awk '{print $6}')
if [ -z "$TMPFS_MOD" ]; then
    kldload tmpfs
fi
mount -t tmpfs -o size=4G tmpfs ${TMPFS}

# =============================
# Destroy existing ZFS pool if exists
# =============================
PCHECK=$(zfs list 2>/dev/null | grep -w ${ZNAME} | awk '{print $1}')
if [ "$PCHECK" = "$ZNAME" ]; then
    echo "Destroying existing ZFS pool: ${ZNAME}"
    zpool destroy ${ZNAME}
fi

# =============================
# Create ZFS partition (on disk, leave EFI untouched)
# =============================
gpart show -p
echo "Creating FreeBSD ZFS partition on ${DISK}..."
gpart add -t freebsd-zfs -l ${ZLABEL} ${DISK}
gpart show -p

# =============================
# Create ZFS pool
# =============================
zpool create -o altroot=${MOUNT} -o cachefile=${TMPFS}/zpool.cache -f ${ZNAME} /dev/gpt/${ZLABEL}
zpool set bootfs=${ZNAME} ${ZNAME}
zfs set checksum=fletcher4 ${ZNAME}
zfs set mountpoint=/ ${ZNAME}

# =============================
# Create ZFS datasets
# =============================
zfs create ${ZNAME}/usr
zfs create ${ZNAME}/usr/home
zfs create ${ZNAME}/var
zfs create -o compression=${COMPRESSION} -o exec=on -o setuid=off ${ZNAME}/tmp
zfs create -o compression=${COMPRESSION} -o setuid=off ${ZNAME}/usr/ports
zfs create -o compression=off -o exec=off -o setuid=off ${ZNAME}/usr/ports/distfiles
zfs create -o compression=off -o exec=off -o setuid=off ${ZNAME}/usr/ports/packages
zfs create -o compression=${COMPRESSION} -o exec=off -o setuid=off ${ZNAME}/usr/src
zfs create -o compression=${COMPRESSION} -o exec=off -o setuid=off ${ZNAME}/var/crash
zfs create -o exec=off -o setuid=off ${ZNAME}/var/db
zfs create -o compression=${COMPRESSION} -o exec=on -o setuid=off ${ZNAME}/var/db/pkg
zfs create -o exec=off -o setuid=off ${ZNAME}/var/empty
zfs create -o compression=${COMPRESSION} -o exec=off -o setuid=off ${ZNAME}/var/log
zfs create -o compression=${COMPRESSION} -o exec=off -o setuid=off ${ZNAME}/var/mail
zfs create -o exec=off -o setuid=off ${ZNAME}/var/run
zfs create -o compression=${COMPRESSION} -o exec=on -o setuid=off ${ZNAME}/var/tmp

# =============================
# Create ZFS swap
# =============================
zfs create -V 4G ${ZNAME}/swap
zfs set org.freebsd:swap=on ${ZNAME}/swap
zfs set checksum=off ${ZNAME}/swap

# =============================
# Set permissions and home symlink
# =============================
chmod 1777 ${MOUNT}/tmp
cd ${MOUNT}
ln -s usr/home home
chmod 1777 ${MOUNT}/var/tmp

# =============================
# Configure network
# =============================
ifconfig ${NIC} inet ${IP_ADDR} netmask ${NETMASK} up
route add default ${GATEWAY}
# Persist configuration
echo "ifconfig_${NIC}=\"inet ${IP_ADDR} netmask ${NETMASK}\"" >> ${MOUNT}/etc/rc.conf
echo "defaultrouter=\"${GATEWAY}\"" >> ${MOUNT}/etc/rc.conf

# =============================
# Install base system
# =============================
cd ${TMPFS}
fetch https://download.freebsd.org/ftp/releases/amd64/15.0-RELEASE/base.txz
fetch https://download.freebsd.org/ftp/releases/amd64/15.0-RELEASE/kernel.txz
fetch https://download.freebsd.org/ftp/releases/amd64/15.0-RELEASE/lib32.txz

tar -xpf base.txz -C ${MOUNT}/
tar -xpf lib32.txz -C ${MOUNT}/
tar -xpf kernel.txz -C ${MOUNT}/

cp ${TMPFS}/zpool.cache ${MOUNT}/boot/zfs/zpool.cache

# =============================
# Configure UEFI bootloader
# =============================
mkdir -p /tmp/efi
mount -t msdosfs ${EFI_PART} /tmp/efi
mkdir -p /tmp/efi/EFI/freebsd
cp ${MOUNT}/boot/loader.efi /tmp/efi/EFI/freebsd/BOOTX64.EFI

cat <<EOF > ${MOUNT}/boot/loader.conf
loader_logo="beastie"
zfs_load="YES"
linux_load="YES"
vfs.root.mountfrom="zfs:${ZNAME}"
hint.p4tcc.0.disabled="1"
hint.acpi_throttle.0.disabled="1"
hw.pci.do_power_nodriver=3
hw.snd.latency=7
EOF

# =============================
# Configure rc.conf
# =============================
cat <<EOF > ${MOUNT}/etc/rc.conf
zfs_enable="YES"
moused_enable="YES"
powerd_enable="YES"
powerd_flags="-a maximum -b adaptive -i 85 -r 60 -p 100"
performance_cx_lowest="HIGH"
performance_cpu_freq="NONE"
economy_cx_lowest="HIGH"
economy_cpu_freq="NONE"
dumpdev="NO"
sshd_enable="YES"
EOF

# =============================
# Configure sysctl
# =============================
cat <<EOF >> ${MOUNT}/etc/sysctl.conf
kern.coredump=0
kern.corefile=/dev/null
net.inet.tcp.delayed_ack=0
EOF

# =============================
# Configure make.conf
# =============================
cat <<EOF >> ${MOUNT}/etc/make.conf
CPUTYPE?=core2
CFLAGS=-O2 -pipe
COPTFLAGS=-O2 -pipe
FORCE_MAKE_JOBS=yes
MAKE_JOBS_NUMBER=4
OPTIMIZED_CFLAGS=YES
BUILD_OPTIMIZED=YES
WITH_CPUFLAGS=YES
WITH_OPTIMIZED_CFLAGS=YES
WITH_KMS=YES
WITH_NEW_XORG=YES
WITH_SIMD=YES
WITH_OPENMP=YES
WITH_THREADS=YES
EOF

# =============================
# Finish Installation
# =============================
cd /
zfs unmount -a
umount /tmp/efi

echo "=============================================================="
echo "FreeBSD 15 installation complete!"
echo "Reboot and set root password. Use your GRUB menu to boot FreeBSD."
echo "FreeBSD OpenSSH server is enabled on port 22."
echo "=============================================================="

reboot

