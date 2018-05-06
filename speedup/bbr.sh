#!/bin/bash

root(){
    if [ "$EUID" -ne 0 ];then
        echo "Need root privilege!"
        exit 1
    fi
}
usage(){
    cat<<EOF
Usage: $(basename $0) install|uninstall
EOF
}

checkKernel(){
    major=$(uname -r | awk -F. '{print $1}')
    minor=$(uname -r | awk -F. '{print $2}')
    if (( $major >=4 && $minor >= 9 ));then
        return 0
    fi
    return 1
}
installKernel(){
    version=$(bash -c "$(curl -fsSL https://raw.githubusercontent.com/sunliang711/tools/master/version.sh)")
    echo "Detect os: $version"
    case "$version" in
        ubuntu*)
            bash -c "$(curl -fsSL https://raw.githubusercontent.com/sunliang711/tools/linuxKernels/updateDebianKernel.sh)"
            ;;
        debian*)
            bash -c "$(curl -fsSL https://raw.githubusercontent.com/sunliang711/tools/linuxKernels/updateDebianKernel.sh)"
            ;;
        centos*)
            bash -c "$(curl -fsSL https://raw.githubusercontent.com/sunliang711/tools/linuxKernels/updateCentosKernel.sh)"
            ;;
        *)
            echo "Not support your OS."
            exit 1
            ;;
    esac
}
#enable bbr
conf=/etc/sysctl.d/bbr.conf
enableBBR(){
    cat<<EOF>"$conf"
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
EOF
sysctl -p
}

checkBBR(){
    #check bbr
    sysctl net.ipv4.tcp_available_congestion_control
    lsmod | grep bbr
}


install(){
    root
    if checkKernel;then
        enableBBR
        checkBBR
    else
        echo "BBR need linux kernel >= 4.9"
        exit 1
    fi
}

uninstall(){
    root
    rm "$conf"
}

case $1 in
    install)
        install
        ;;
    uninstall)
        uninstall
        ;;
    *)
        usage
        ;;
esac
