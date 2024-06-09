#!/bin/sh

if [ "$(whoami)" != "root" ]; then
  echo "Need root"
  exit
fi
# allow loading of nvidia modules
mv /etc/modprobe.d/disable-nvidia.conf /etc/modprobe.d/disable-nvidia.conf.disable

# remove card
echo -n 1 > /sys/bus/pci/devices/0000\:01\:00.0/remove
sleep 1

# change power control
echo -n on > /sys/bus/pci/devices/0000\:00\:01.0/power/control
sleep 1

# rescan for card
echo -n 1 > /sys/bus/pci/rescan

# modprobe to load module
modprobe nvidia
