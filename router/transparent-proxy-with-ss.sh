#!/bin/bash
#tested on ubuntu 16.04 server
#记得把本机ip_forward 和做SNAT 以及iptables 的filter表的FORWARD链放开,具体参考linux as router

#/etc/resolv.conf -> dnsmasq -> dnsmasq.d/gfwlist.conf -> ss-tunnel -> ipset gfwlist -> iptables redir to 1080

if (($EUID != 0));then
    echo "Need root!"
    exit 1
fi

if ! command -v ipset >/dev/null 2>&1;then
    apt install -y ipset
fi

if ! command -v ss-redir >/dev/null 2>&1;then
    apt install software-properties-common -y
    add-apt-repository ppa:max-c-lv/shadowsocks-libev -y
    apt update
    apt install shadowsocks-libev -y
fi

apt install -y dnsmasq
systemctl stop dnsmasq

if ! grep -q '^conf-dir' /etc/dnsmasq.conf ;then
cat>>/etc/dnsmasq.conf<<EOF
conf-dir=/etc/dnsmasq.d/,*.conf
server=114.114.114.114
EOF
fi
dnsmasqDir=/etc/dnsmasq.d
if [ ! -d $dnsmasqDir ];then
    mkdir $dnsmasqDir
fi
cd $dnsmasqDir

## adblock
if [ ! -e adblock.conf ];then
    wget https://gist.githubusercontent.com/Hurray0/59f9232e045717791c7859c2dcb4fd8f/raw/8bb57c25cf76c00ee27b1b06b27c2863621518bb/adblock.conf
fi
## gfwlist
if [ ! -e dnsmasq_list.conf ];then
    wget https://gist.githubusercontent.com/Hurray0/36d61523582f998888b6311b891b1a8f/raw/1343b9482723f342ec9e71a910612cf94a2f3619/dnsmasq_list.conf
fi

cd -
script=ss.sh
cat>${script}<<'EOF'
#!/bin/bash
if (($EUID != 0));then
    echo "Need root!"
    exit 1
fi
REDIR_PID=/var/run/redir.pid
TUNNEL_PID=/var/run/tunnel.pid
SERVER=35.201.213.22
PORT=9527
PASS=9527
METHOD=chacha20
LOCAL_PORT=1080

DNS=8.8.8.8:53
TUNNEL_PORT=5353

start(){
    #start ss-redir
    /usr/bin/ss-redir -s ${SERVER} -p ${PORT} -k ${PASS} -l ${LOCAL_PORT} -m ${METHOD}  -f ${REDIR_PID} -b 0.0.0.0  -u
    #start ss-tunnel
    /usr/bin/ss-tunnel -s ${SERVER} -p ${PORT} -k ${PASS} -l ${TUNNEL_PORT} -m ${METHOD} -L ${DNS} -f ${TUNNEL_PID} -b 0.0.0.0 -u
    #create ipset
    ipset -N gfwlist iphash
    #set iptables for gfwlist
    iptables -t nat -A PREROUTING -p tcp -m set --match-set gfwlist dst -j REDIRECT --to-port ${LOCAL_PORT}
    iptables -t nat -A OUTPUT -p tcp -m set --match-set gfwlist dst -j REDIRECT --to-port ${LOCAL_PORT}
    #start dnsmasq
    systemctl start dnsmasq
}
stop(){
    #ipset -X gfwlist
    kill -kill $(cat ${REDIR_PID})
    kill -kill $(cat ${TUNNEL_PID})

    iptables -t nat -D PREROUTING -p tcp -m set --match-set gfwlist dst -j REDIRECT --to-port ${LOCAL_PORT}
    iptables -t nat -D OUTPUT -p tcp -m set --match-set gfwlist dst -j REDIRECT --to-port ${LOCAL_PORT}
    systemctl stop dnsmasq
    ipset -X gfwlist
}

case $1 in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        stop
        start
        ;;
     *)
        echo "$(basename $0) start|stop"
        exit 1
        ;;
esac
EOF
chmod +x $script
