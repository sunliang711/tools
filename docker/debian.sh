#!/bin/bash
root(){
    if [ $EUID -ne 0 ];then
        echo "Need root privilege"
        exit 1
    fi
}

d8(){
    root
    apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
    echo 'deb https://apt.dockerproject.org/repo debian-jessie main' >/etc/apt/sources.list.d/docker.list
    apt-get install apt-transport-https ca-certificates -y
    apt-get update && apt-get install docker-engine

}

d9(){
    root
    apt-get update
    apt-get install apt-transport-https ca-certificates curl gnupg2 software-properties-common -y
    curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg | sudo apt-key add -
    apt-key fingerprint 0EBFCD88
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") $(lsb_release -cs) stable"
    apt-get update
    apt-get install docker-ce -y
}

version=$(bash -c "$(curl -fsSL https://raw.githubusercontent.com/sunliang711/tools/master/version.sh)")

case $version in
    debian-8*)
        d8
        ;;
    debian-9*)
        d9
        ;;
    *)
        echo "Not support you OS."
        exit 1
        ;;
esac
