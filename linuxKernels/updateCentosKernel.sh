#/bin/bash

root(){
    if [ "$EUID" -ne 0 ];then
        echo "Need root privilege."
        exit 1
    fi
}

c6(){
    root
    rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org || { echo "import GPG KEY error!"; exit 1; }
    rpm -Uvh http://www.elrepo.org/elrepo-release-6-8.el6.elrepo.noarch.rpm || { echo "install elrepo-release-6-8.el6.elrepo.noarch.rpm error!"; exit 1; }
    yum --enablerepo=elrepo-kernel install kernel-ml -y || { echo "install mainline kernel error!"; exit 1; }
    #backup /etc/grub.conf
    grub=/etc/grub.conf
    cp "$grub" "${grub}.bak"
    sed -i 's/^\(default=\)[0-9]\+/\10/' $grub
    read -p "reboot ? [y/n] " re
    if [ "$re" == 'y' ];then
        reboot
    fi
}

c7(){
    root
    rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org || { echo "import GPG KEY error!"; exit 1; }
    rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm || { echo "install elrepo-release-7.0-3.el7.elrepo.noarch.rpm error!"; exit 1; }
    yum --enablerepo=elrepo-kernel install kernel-ml -y || { echo "install mainline kernel error!"; exit 1; }

    grub=/etc/default/grub
    cp "$grub" "${grub}.bak"
    sed -i 's/^\(GRUB_DEFAULT=\).\+/\10/' $grub
    grub2-mkconfig -o /etc/grub2.conf
    read -p "reboot ? [y/n] " re
    if [ "$re" == 'y' ];then
        reboot
    fi


}
usage(){
    cat<<EOF
Usage: $(basename $0) install|uninstall

EOF
    exit 1
}

install(){
    local version="$(bash -c $(curl -fsSL https://raw.githubusercontent.com/sunliang711/tools/master/version.sh))"
    echo "version: $version"
    case "$version" in
        centos-6*)
            c6
            ;;
        centos-7*)
            c7
            ;;
        *)
            echo "only support centos6 or centos7"
            exit 1
    esac
}
case $1 in
    install)
        install
        ;;
    -h|--help)
        usage
        ;;
esac
