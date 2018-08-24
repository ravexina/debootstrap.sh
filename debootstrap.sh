#!/bin/bash

# --------------------------------------------------------------------------------------------------
#       	I M P O R T A N T		Y O U		M U S T		R E A D
# --------------------------------------------------------------------------------------------------

# THIS IS A PRIVATE SCRIPT

# YOU ARE NOT ALLOWED TO USE THIS SCRIPT

# IF THIS SCRIPT CAUSES ANY HARM TO YOUR SYSTEM YOU ARE RESPONSIBLE AND NOT THE AUTHOR OF THIS SCRIPT

# THIS SCRIPT WILL FORMAT ANYTHING IS ON YOUR DISK

# __________________________________________________________________________________________________

# 		 /		/boot		/home
# $PARAMETERS	 /dev/sdxY	/dev/sdxZ	/dev/sdxA


# --- QEMU ---
# qemu-img create -f qcow2 debian.qcow2 2G
# modprobe nbd max_part=16
# qemu-nbd -c /dev/nbd0 debian.qcow2
# ------------

# TODO:
# 	Get device to create partitions  [ ]
#	Add HOME to fstab		 [ ]
#	Add BOOT to fstab		 [ ]
#

# STOP AFTER ANY ERROR
#set -e
#set -v

# COLORS
RED='\033[0;31m'
LRED='\033[0;33m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
NC='\033[0m' 
DONE="${GREEN}DONE${NC}"

echo
echo ' ---------------------------------------------------------------------- '
echo -e " ${RED}!!! - - - - This script might DESTROY your DISK and SYSTEM - - - - !!!${NC} "
echo ' ---------------------------------------------------------------------- '
echo

sleep 2

echo '-----------------------------------------'
echo -e "${LRED}- - USE   IT   AT   YOUR   OWN   RISK - -${NC}"
echo '-----------------------------------------'

sleep 2

echo
echo -e "${RED}If you keep runing the script everything that happens is on YOU!${NC}"
echo -e "${CYAN}Please press Ctrl+C to stop the script${NC}"

read

echo ' -----------------------------------------------------------------------'

echo

# Set script directory
SCRIPT_DIR=$(dirname "$(realpath "$0")")

# Install debootstrap if it's not installed already
dpkg -l debootstrap &> /dev/null || sudo apt install debootstrap -y

ROOT="$1"
BOOT="$2"
HOME="$3"

echo "Script DIR is: $SCRIPT_DIR"
echo "The root partition is $ROOT"
echo "The boot partition is $BOOT"
echo "The home partition is $HOME"
echo

echo "IF the paths are correct enter YES"
read CHECK
if [ "$CHECK" != "YES" ]
then
	echo 'Run the script again and choose correct devices'
	exit 1
fi

# ------------- FORMATING THE ROOT --------------
echo
echo 'Formatting the root partition:'
echo "> sudo mkfs.ext4 $ROOT"
echo
echo "Should I continue? [Enter to FORMAT / Ctrl-C to stop / S for skip format]"
read SKIP

# Ctrl-C 	 Breaks the script
# Nothing:	 Coninue and formats
# S:		 Continue and skip format

if [ "$SKIP" != 'S' ]
then
	echo 'Start formatting..'
	sudo mkfs.ext4 "$ROOT"

	echo -e "$DONE"
else
	echo 'Skipping the format.'
fi

# ----------- MOUNTING THE ROOT -----------------
echo
echo 'Mounting the root partition'

# Check if somthing is mounted at /mnt
mountpoint /mnt &> /dev/null

if [ "$?" -eq 1 ]; then
	# Nothing is mounted there
	sudo mount "$ROOT" /mnt
	echo -e "$DONE"
else
	# Check what it is
	SRC=$(df /mnt --output=source | sed -n 2p)

	if [ "$SRC" == "$ROOT" ]; then
		echo "$SRC is already mounted at /mnt"
		echo "Continue..."
	else
		echo "$SRC is mounted at /mnt"
		echo "Breaking the script."
		exit 1
	fi
fi

echo

# ---------- ADD NESSECARY PATHS ---------------

# Make system cache available to chroot environment
echo 'Copying the necessary packages'
sudo mkdir -p /mnt/var/cache/apt/archives
sudo cp -nv ./pkgs/*.deb /mnt/var/cache/apt/archives/
#sudo ln -fs "${SCRIPT_DIR}/archives" /mnt/var/cache/apt/archives
echo -e "$DONE"
echo

# Force apt to don't clean the cache
echo 'Add keep debs config file'
sudo mkdir -p /mnt/etc/apt/apt.conf.d/
echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' | sudo tee /mnt/etc/apt/apt.conf.d/01-keep-debs
echo -e "$DONE"
echo

echo 'Running debootstrap'
# arch: amd64, arm64, armhf, i386, powerpc, ppc64el, or s390x
sudo /usr/sbin/debootstrap --include=nano --arch amd64 bionic /mnt/ | sudo tee /mnt/debootstrap.logs
echo -e "$DONE"
echo

# debootstrap failed
if [ "$?" -eq 1 ]; then
	echo -e "${RED}debootstrap failed${NC}"
	echo -e "${LRED}view log at /mnt/debootstrap.log${LRED}"
	exit 1
fi

echo 'Creating sources.list'
sudo tee /mnt/etc/apt/sources.list <<E
deb http://archive.ubuntu.com/ubuntu bionic main universe
deb http://archive.ubuntu.com/ubuntu bionic-updates main universe
deb http://security.ubuntu.com/ubuntu bionic-security main universe
E
echo -e "$DONE"
echo

echo 'Adding the fstab file'
ROOT_UUID=$(sudo blkid "$ROOT" -o value | head -1)
echo "UUID=$ROOT_UUID	/	ext4	defaults	0	1" | sudo tee /mnt/etc/fstab
echo

# Mount necessary paths to chroot
echo 'Bind necessary paths'
mountpoint /mnt/dev -q 
if [ "$?" -eq 0 ]; then
        echo -e "${RED}Something is already mounted at /mnt/dev"
        echo -e "${CYAN}SKIPPING...${NC}"
else
        sudo mount --bind /dev /mnt/dev
        echo -e "$DONE"
fi

#sudo mount --bind /dev/pts /mnt/dev/pts
# For LVM
#sudo mount --bind /run /mnt/run
#sudo mount --bind /run/lvm /mnt/run/lvm
#sudo mount -t proc /proc /mnt/proc
#sudo mount -t sysfs /sys  /mnt/sys

echo

# Chroot and run the other script to install apps
echo 'CP installation script to /mnt'
sudo cp ./install.sh /mnt
echo -e "$DONE"
echo
echo -e "${CYAN}Environment is ready to use${NC}"
echo
echo 'TO CHROOT:'
echo 'sudo chroot /mnt'
echo
echo 'Then run:'
echo './install.sh'
echo
echo -e "${RED}Remember to run: sudo umount -R /mnt  After all${NC}"
echo -e "${GREEN}"
echo '		Everything went well.                 '
echo '			Have a nice day...	      '
echo -e "${NC}"

exit 0
