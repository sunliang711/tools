#!/bin/bash
if [ "$EUID" -ne 0 ];then
    echo "Need root"
    exit 1
fi
if [ "$#" -lt 1 ];then
    echo "Usage: $(basename $0) exportInterface"
    exit 1
fi
defaultExtDev=$(ip route | grep default | awk '{print $5}')
extDev=${defaultExtDev}

#enable ip forward
cat>/etc/sysctl.d/ip_forward.conf<<EOF
net.ipv4.ip_forward=1
EOF

sysctl -p

#FORWARD chain
iptables -P FORWARD ACCEPT

#SNAT
iptables -t nat -A POSTROUTING -o $extDev -j MASQUERADE
