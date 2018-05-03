#!/bin/bash

# tested on debian 8,9
# TODO test on ubuntu 14 16 18

if [ "$EUID" -ne 0 ];then
    echo "Need root privilege!"
    exit 1
fi

kernelURL=${1:-"http://kernel.ubuntu.com/~kernel-ppa/mainline/v4.14.12/linux-image-4.14.12-041412-generic_4.14.12-041412.201801051649_amd64.deb"}

wget "$kernelURL"

okernel="linux-image-$(uname -r)"
dpkg -i linux-image-4.*.deb || { echo "install new kernel error!"; exit 1; }

apt-get purge -y "$okernel"

update-grub

rm linux-image-4.*.deb
read -p "reboot ? [y/n]" re
if [ "$re" == "y" ];then
    reboot
fi
