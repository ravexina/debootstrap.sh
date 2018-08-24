#!/bin/bash

echo 'mount /proc and /sys'
mount -t proc none /proc
mount -t sysfs none /sys
echo 'Done'
echo

echo 'Updating the sources list"
/usr/bin/apt update
echo 'Done'
echo

# installing the kernel
/usr/bin/apt install linux-image-generic -y

echo 'Enter your desired username:'
read -r USER

echo 'Adding default user'
/usr/sbin/adduser "$USER"

echo 'Add default user to sudoers'
/usr/sbin/usermod -aG sudo "$USER"

echo 'Installing grub'
/usr/sbin/update-grub

echo 'Where should I install grub?'
read DEV
echo "grub-install $DEV"

exit 0
