#!/bin/bash


#detailed information and error msg output to stderr
version(){
    case $(uname) in
        Linux)
            versionFile=/etc/os-release
            if [[ -e "$versionFile" ]];then
                #check linux distribution version
                # release=$(grep '^ID' "$versionFile"| grep -oP '(?<=ID=).+' | tr -d '"')
                release=$(grep '^ID=' /etc/os-release | awk -F= '{print $2}' | tr -d '"')
                # version=$(grep '^VERSION_ID' "$versionFile" | grep -oP '(?<=ID=).+' | tr -d '"')
                version=$(grep '^VERSION_ID' /etc/os-release  | awk -F= '{print $2}' | tr -d '"')
                echo "$release-$version"
            else
                #CentOS 6 没有/etc/os-release文件
                versionFile=/etc/centos-release
                if [[ -e "$versionFile" ]];then
                    # echo -n 'centos-';grep -oP '(?<=release )[0-9.]+' "$versionFile"
                    echo -n 'centos-';awk '{print $3}' "$versionFile"
                else
                    ##TODO add other distribution support here
                    echo "Not support your linux distribution now!!" 1>&2
                    exit 1
                fi
            fi
            ;;
        Darwin)
            echo -n "MacOS-";sw_vers -productVersion
            system_profiler SPSoftwareDataType 1>&2
            ;;
        *)
            exit 1
            ;;
    esac
}
version
