#!/bin/bash

# tested on debian 8,9 ubuntu 14 16
#https://github.com/iMeiji/shadowsocks_install/wiki/%E5%BC%80%E5%90%AFTCP-BBR%E6%8B%A5%E5%A1%9E%E6%8E%A7%E5%88%B6%E7%AE%97%E6%B3%95
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
            proxy=$OPTARG
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

