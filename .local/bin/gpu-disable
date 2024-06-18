#!/bin/sh

if [ "$(whoami)" != "root" ]; then
  echo "Need root"
  exit
fi
# this isn't recommended really it's like unplugging the GPU
rmmod nvidia_drm
rmmod nvidia_uvm
rmmod nvidia_modeset
rmmod nvidia
#modprobe -r nvidia_drm
#modprobe -r nvidia_uvm
#modprobe -r nvidia_modeset
#modprobe -r nvidia


# change power control
echo -n auto > /sys/bus/pci/devices/0000\:01\:00.0/power/control
sleep 1

# change power control
echo -n auto > /sys/bus/pci/devices/0000\:00\:01.0/power/control
sleep 1

# lock reloading the nvidia module
mv /etc/modprobe.d/disable-nvidia.conf.disable /etc/modprobe.d/disable-nvidia.conf
