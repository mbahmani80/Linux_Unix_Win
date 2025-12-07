#!/bin/sh
# Installing FreeBSD 14x / 15x alongside linux and windows with ZFS on UEFI Systems
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

DISK=/dev/nda1            # Disk to install FreeBSD on (e.g., /dev/nda1)
PARTITION=/dev/nda1p6     # your dedicated FreeBSD partition
ZNAME=zroot               # ZFS pool name
ZLABEL=disk0              # Partition label for ZFS root
COMPRESSION=lz4           # ZFS compression algorithm
MOUNT=/tmp/mnt            # Temporary mount point for installation
TMPFS=/tmp/tmpfs          # Temporary tmpfs for caching
IP_ADDR=192.168.1.50      # Static IP for FreeBSD installer
NETMASK=255.255.255.0
GATEWAY=192.168.1.1
EFI_PART=/dev/nda1p1      # Shared EFI partition
NIC=em0                   # Network interface
USB_drive_P3=/dev/da0s3              # data partition of USB drive. all scripts and base.txz, kernel.txz, lib32.txz are stored here.
USB_drive_P3_Mount=/tmp/usb # Temporary mount point for USB  data partition
Offline=yes

#mkdir ${USB_drive_P3_Mount}
#mount -t msdosfs ${USB_drive_P3} ${USB_drive_P3_Mount}
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
# Testing and collecting technical information 
# =============================
dmesg > ${TMPFS}/dmesg.out.txt
pciconf -lv > ${TMPFS}/pciconf.out.txt
devinfo -v > ${TMPFS}/devinfo.out.txt
acpidump -dt > ${TMPFS}/acpidump.out.txt

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
# Install base system
# =============================

if [ "$Offline" = "yes" ]; then
    echo "Performing offline installation..."
    cd "${USB_drive_P3_Mount}" || exit 1
    tar -xpf base.txz -C "${MOUNT}/"
    [ -f lib32.txz ] && tar -xpf lib32.txz -C "${MOUNT}/"
    tar -xpf kernel.txz -C "${MOUNT}/"
else
    echo "Performing online installation..."
    cd "${TMPFS}" || exit 1
    fetch https://download.freebsd.org/ftp/releases/amd64/15.0-RELEASE/base.txz
    fetch https://download.freebsd.org/ftp/releases/amd64/15.0-RELEASE/kernel.txz
    fetch https://download.freebsd.org/ftp/releases/amd64/15.0-RELEASE/lib32.txz || true  # skip if not available

    tar -xpf base.txz -C "${MOUNT}/"
    [ -f lib32.txz ] && tar -xpf lib32.txz -C "${MOUNT}/"
    tar -xpf kernel.txz -C "${MOUNT}/"
fi

# Copy zpool cache if exists
[ -f "${TMPFS}/zpool.cache" ] && cp "${TMPFS}/zpool.cache" "${MOUNT}/boot/zfs/zpool.cache"

# =============================
# Configure network
# =============================
ifconfig ${NIC} inet ${IP_ADDR} netmask ${NETMASK} up
route add default ${GATEWAY}
# Persist configuration
echo "ifconfig_${NIC}=\"inet ${IP_ADDR} netmask ${NETMASK}\"" >> ${MOUNT}/etc/rc.conf
echo "defaultrouter=\"${GATEWAY}\"" >> ${MOUNT}/etc/rc.conf

# =============================
# fstab ZFS manages mounted filesystems
# only tmpfs is added.
# =============================
echo 'tmpfs /tmp tmpfs rw,mode=1777 0 0' >> ${MOUNT}/etc/fstab

# =============================
# Configure UEFI bootloader
# =============================
mkdir -p /tmp/efi
mount -t msdosfs ${EFI_PART} /tmp/efi
mkdir -p /tmp/efi/EFI/freebsd
cp ${MOUNT}/boot/loader.efi /tmp/efi/EFI/freebsd/BOOTX64.EFI

# =============================
# Configure /boot/loader.conf
# =============================
cat <<EOF > ${MOUNT}/boot/loader.conf
# ----------------------------------------
# BOOT LOADER APPEARANCE
# ----------------------------------------
loader_logo="beastie"
# grep loader_logo /boot/defaults/loader.conf
# loader_logo="orbbw"            # Desired logo: orbbw, orb, fbsdbw, beastiebw, beastie, none

# ----------------------------------------
# FILESYSTEM: ZFS ROOT
# ----------------------------------------
zfs_load="YES"
#vfs.root.mountfrom="zfs:zroot"
vfs.root.mountfrom="zfs:${ZNAME}"

# ----------------------------------------
# CPU / POWER MANAGEMENT
# ----------------------------------------
hint.p4tcc.0.disabled="1"
hint.acpi_throttle.0.disabled="1"
hw.pci.do_power_nodriver=3

# Fully disable suspend-to-RAM
hw.acpi.enable_sleep=0

# ----------------------------------------
# LINUX COMPAT
# ----------------------------------------
linux_load="YES"

# ----------------------------------------
# USB CORE + KEY DEVICE DRIVERS
# (These MUST be loaded early)
# ----------------------------------------
usb_load="YES"
ukbd_load="YES"
ums_load="YES"

# Optional USB extras (safe to load in rc.conf instead)
u3g_load="YES"
umass_load="YES"

# ----------------------------------------
# SOUND SYSTEM
# (snd_hda alone is usually enough)
# ----------------------------------------
sound_load="YES"
snd_hda_load="YES"

# ----------------------------------------
# TOUCHSCREEN
# ----------------------------------------
utouch_load="YES"

# ----------------------------------------
# THINKPAD ACPI EXTENSIONS
# ----------------------------------------
acpi_ibm_load="YES"

# ----------------------------------------
# DEVICE DRIVER MANAGEMENT
# ----------------------------------------
devmatch_blocklist="if_iwm"
#devmatch_blocklist="if_iwlwifi"
EOF

# =============================
# Configure /etc/rc.conf
# =============================
cat >> ${MOUNT}/etc/rc.conf << 'EOF'

########## BASE SYSTEM ##########
# System hostname
hostname="mbctux.lab.local"

# Disable crash dumps
dumpdev="NO"

# ZFS filesystem support
zfs_enable="YES"

# Mouse support in console
moused_enable="YES"

# Power management settings
powerd_enable="YES"
powerd_flags="-a maximum -b adaptive -i 85 -r 60 -p 100"
performance_cx_lowest="HIGH"
performance_cpu_freq="NONE"
economy_cx_lowest="HIGH"
economy_cpu_freq="NONE"

# Network time synchronization
ntpd_enable="YES"
ntpd_sync_on_start="YES"

########## DESKTOP / GUI ##########
# Display manager (KDE/Plasma)
sddm_enable="YES"

# User filesystem helpers
fusefs_enable="YES"
automount_enable="YES"
automountd_enable="YES"
autounmountd_enable="YES"
dsbmd_enable="YES"

########## AUDIO / IPC ##########
# Desktop communication bus (required by most GUI apps)
# Enables the system message bus so desktop applications can communicate and function correctly.
dbus_enable="YES"

# Hardware event manager (automatic driver/hotplug detection)
# Enables automatic hardware detection, driver loading, and device event handling.
devd_enable="YES"

# PipeWire audio server
pipewire_enable="YES"
wireplumber_enable="YES"

########## NVIDIA / GPU ##########
# Enable Linux binary compatibility (needed for NVIDIA CUDA)
linux_enable="YES"

# Load NVIDIA driver modules
nvidia_load="YES"
kld_list="${kld_list} nvidia-modeset"

# Enable headless NVIDIA Xorg (DISPLAY :8)
nvidia_xorg_enable="YES"

# Intel GPU kernel module (for fallback or hybrid graphics)
kld_list="${kld_list} i915kms.ko"

########## LOCALE / INPUT ##########
# Keyboard layout
keymap="german.iso.acc.kbd"

########## SERVICES ##########
# SSH remote access
sshd_enable="YES"

# Packet Filter firewall
pf_enable="YES"

########## NETWORK ##########
# Ethernet (em0)
ifconfig_em0="DHCP"
# ifconfig_em0="inet 192.168.212.10 netmask 255.255.255.0"

# Wi-Fi (Intel iwlwifi)
wlans_iwlwifi0="wlan0"
ifconfig_wlan0="WPA SYNCDHCP"

# Alternative Wi-Fi (iwm0) — disabled
# wlans_iwm0="wlan0"
# ifconfig_wlan0="WPA SYNCDHCP"

EOF

# =============================
# Configure sysctl
# =============================
cat <<EOF >> ${MOUNT}/etc/sysctl.conf
########## CORE DUMP CONTROL ##########
kern.coredump=0
kern.corefile=/dev/null

########## NETWORK TUNING ##########
net.inet.tcp.delayed_ack=0

# Local UNIX socket buffer tuning (desktop / KDE / D-Bus performance)
net.local.stream.recvspace=65536
net.local.stream.sendspace=65536

########## USER FILESYSTEMS ##########
# Allow regular users to mount filesystems
vfs.usermount=1

########## OPTIMIZED ACPI (NO SUSPEND, HIBERNATE VIA DEVD) ##########
# Do not reset GPU during ACPI events
hw.acpi.reset_video=0

# Power button → Shutdown
hw.acpi.power_button_state=S5

# Lid action handled by devd (shutdown)
hw.acpi.lid_switch_state=NONE

# Disable sleep button
hw.acpi.sleep_button_state=NONE

# ACPI event delay (set to 0 for instant action)
hw.acpi.sleep_delay=0

# Helpful for debugging ACPI issues
hw.acpi.verbose=1

########## CONSOLE BEHAVIOR ##########
hw.syscons.sc_no_suspend_vtswitch=1

########## THINKPAD EXTRAS ##########
# Enable brightness, volume, Fn keys
dev.acpi_ibm.0.events=1
EOF

# =============================
# Lid closed → Immediate shutdown
# =============================

cat <<EOF >> ${MOUNT}/usr/local/etc/devd/lid_shutdown.conf
notify 10 {
    match "system" "ACPI";
    match "subsystem" "Lid";
    match "notify" "0";
    action "/sbin/shutdown -p now";
};
EOF

# =============================
# Critical battery → Hibernate (S4)
# =============================

cat <<EOF >> ${MOUNT}/usr/local/etc/devd/battery_low.conf
notify 10 {
    match "system" "ACPI";
    match "subsystem" "CMBAT";
    match "notify" "0x80";
    action "/sbin/acpiconf -s 4";
};
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

