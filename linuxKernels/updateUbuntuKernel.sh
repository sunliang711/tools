#!/bin/bash
if (($EUID != 0));then
    echo "Need root privilege!"
    exit 1
fi
#apt-get install openssh-server -y
#./enableRootSSH.sh
#service ssh restart

version=${1:-"4.11.0-14"}
if [ -z "$(apt-cache search linux-image-extra-$version-generic)" ];then
    echo "Only Support ubuntu 16.04"
    exit 1
fi

if dpkg -l | grep linux-image | grep -q "$version";then
    echo "Already $version"
    exit 1
fi


#install kernel
echo "install linux-image-extra-$version-generic"
apt-get install linux-image-extra-$version-generic -y
if (($?!=0));then
    echo 'Install kernel: "linux-image-extra-$version-generic" failed!'
    exit 1
fi

#delete old kernel
apt-get -y purge linux-image-$(uname -r) linux-image-extra-$(uname -r)


currentKernels=$(dpkg -l | grep linux-image | grep -v linux-image-generic | grep -v "$version" | awk '{print $2}')
echo "currentKernels: $currentKernels"
oldIFS=$IFS
IFS=$'\n'
echo "purge old kernels"
for eachKernel in $currentKernels;do
    apt-get -y purge $eachKernel
done
IFS=$oldIFS

echo "update-grub"
update-grub

echo "reboot"
reboot
