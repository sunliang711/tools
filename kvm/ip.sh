#!/bin/bash
vm=$1
#[ "$vm" ] && arp -n | grep $(sudo virsh domiflist $vm | sed -n '3p' | awk '{print $NF}')|awk '{print $1}'|uniq
if [ ! "$vm" ];then
    cat<<EOF
Usage: $(basename $0) vm-name
EOF
    exit 1
fi

arp -n | grep $(sudo virsh domiflist $vm | sed -n '3p' | awk '{print $NF}')|awk '{print $1}'|uniq
