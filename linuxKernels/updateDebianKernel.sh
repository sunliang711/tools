#!/bin/bash

# tested on debian 8,9 ubuntu 16
# TODO test on ubuntu 14 18

if [ "$EUID" -ne 0 ];then
    echo "Need root privilege!"
    exit 1
fi
usage(){
    cat<<EOF
Usage: $(basename $0) Options

Options:
        -h    print help msg
        -p    set proxy for curl cmd
EOF
exit 1
}

while getopts ":hp:" opt;do
    case $opt in
        h)
            usage
            ;;
        p)
            proxy=$1
            echo "use proxy: $proxy"
            ;;
    esac
done

shift $(($OPTIND-1))

kernelURL=${1:-"http://kernel.ubuntu.com/~kernel-ppa/mainline/v4.14.12/linux-image-4.14.12-041412-generic_4.14.12-041412.201801051649_amd64.deb"}

if [ -n "$proxy" ];then
    curl -LO -x "$proxy" "$kernelURL" || { echo "Download kernel failed!"; exit 1; }
else
    curl -LO "$kernelURL" || { echo "Download kernel failed!"; exit 1; }
fi

okernel="linux-image-$(uname -r)"
dpkg -i linux-image-4.*.deb || { echo "install new kernel error!"; exit 1; }

apt-get purge -y "$okernel"

update-grub

rm linux-image-4.*.deb
read -p "reboot ? [y/n]" re
if [ "$re" == "y" ];then
    reboot
fi

