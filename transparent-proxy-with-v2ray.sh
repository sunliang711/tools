#!/bin/bash
#TODO
#udp proxy

upPort=5353
ipsetTab=gfwlist

check(){
    if [ "$EUID" -ne 0 ];then
        echo "Need root privilege!"
        exit 1
    fi
    version=$(bash -c "$(curl -fsSL https://raw.githubusercontent.com/sunliang711/tools/master/version.sh)")
    case $version in
        ubuntu-1*)
            echo "ok: support your os."
            ;;
        *)
            echo "not support your os"
            exit 1
            ;;
    esac
    if [ ! -e /lib/systemd/system/dnsmasq.service ] && [ ! -e /etc/systemd/system/dnsmasq.service ];then
        echo "need dysnamsq systemctl service."
        exit 1
    fi
    if ! command -v ipset >/dev/null 2>&1;then
        echo "need ipset."
        exit 1
    fi
}

installV2ray(){
    if [ ! -e /usr/bin/v2ray/v2ray ];then
        echo "install v2ray..."
        bash <(curl -L -s https://install.direct/go.sh)
    fi
    if [ ! -e /usr/bin/v2ray/v2ray ];then
        echo "install v2ray failed!"
        exit 1
    fi
}

setDnsmasq(){
    dnsmasqDir=/etc/dnsmasq.d
    if ! grep -q '^conf-dir' /etc/dnsmasq.conf ;then
        cat>>/etc/dnsmasq.conf<<EOF
conf-dir=/etc/dnsmasq.d/,*.conf
server=114.114.114.114
EOF
    fi
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
        #NOTE upstream server is localhost:5353,returned ip save in ipset 'gfwlist'
        wget https://gist.githubusercontent.com/Hurray0/36d61523582f998888b6311b891b1a8f/raw/1343b9482723f342ec9e71a910612cf94a2f3619/dnsmasq_list.conf
        #TODO replace upstream port and ipset table name with upPort ipsetTab
        sed -i -e "s/#5353/#$upPort/" -e "s/gfwlist/$ipsetTab/" dnsmasq_list.conf
    fi
    cd - >/dev/null 2>&1
}

setV2ray(){
    #TODO
    vpsAddr=g.eagle711.win
    vpsPort=41754
    protocol=vmess
    id="e2791dbb-f340-4a71-998a-da3b184a1cef"
    streamSettingsNetwork=ws
    #listen on 5353 to redirect udp dns request to 8.8.8.8:53
    remoteServer=8.8.8.8
    remotePort=53
    #listen on 1060 to redirect network traffict to vps
    redirectPort=1060
    socks5Port=1090

    cat<<EOF>/etc/v2ray/config.json
{
  "log": {
    "access": "/var/log/v2ray/access.log",
    "error": "/var/log/v2ray/error.log",
    "loglevel": "debug"
    },

  "outbound": {
    "protocol": "$protocol",
    "settings":{
        "vnext":[
            {
                "address":"$vpsAddr",
                "port": $vpsPort,
                "users": [
                    {
                    "id": "$id",
                    "level": 1,
                    "alterId": 64
                    }
                ]
            }
        ]
    },
    "streamSettings": {
        "network": "$streamSettingsNetwork"
      }
},
  "inbound": {
  "protocol": "dokodemo-door",
  "port": $upPort, //Dnsmasq查询代理
  "settings": {
    "address": "$remoteServer",
    "port": $remotePort,
    "network": "udp",
    "timeout": 0,
    "followRedirect": false
    }
},
"inboundDetour": [
        {
            "domainOverride":["http", "tls"], //如果有需要直连访问某个境外域名，需要加上这句，并在routing里设置相关域名
            "protocol": "dokodemo-door",
            "port":$redirectPort, //所有1060 tcp udp端口流量走v2ray代理
            "settings":{
                        "network": "tcp,udp",
                        "timeout": 30,
                        "followRedirect": true
                       }
        },
        {
        "protocol":"socks",
        "port":$socks5Port,
        "settings":{
                "auth":"noauth",
                "udp":false
                }
        }
    ]
}
EOF
}

createScript(){
cat>transparent.sh<<EOF
#!/bin/bash
if [ \$EUID -ne 0 ];then
    echo "need root privilege."
    exit 1
fi
setIptables(){
    echo "setIptables..."
    iptables -t nat -A PREROUTING -p tcp -m set --match-set $ipsetTab dst -j REDIRECT --to-port $redirectPort
    iptables -t nat -A OUTPUT -p tcp -m set --match-set $ipsetTab dst -j REDIRECT --to-port $redirectPort

    #ip rule add fwmark 1 table 100
    #ip route add local 0.0.0.0/0 dev lo table 100
    #iptables -t mangle -A PREROUTING -p udp -j TPROXY --on-port $redirectPort --tproxy-mark 0x01/0x01
    #iptables -t mangle -A OUTPUT -p udp -j TPROXY --on-port $redirectPort --tproxy-mark 0x01/0x01
}
unsetIptables(){
    echo "unsetIptables..."
    iptables -t nat -D PREROUTING -p tcp -m set --match-set $ipsetTab dst -j REDIRECT --to-port $redirectPort
    iptables -t nat -D OUTPUT -p tcp -m set --match-set $ipsetTab dst -j REDIRECT --to-port $redirectPort

    #iptables -t mangle -D PREROUTING -p udp -j TPROXY --on-port $redirectPort --tproxy-mark 0x01/0x01
    #iptables -t mangle -D OUTPUT -p udp -j TPROXY --on-port $redirectPort --tproxy-mark 0x01/0x01
}

setIpset(){
    echo "setIpset..."
    ipset -N $ipsetTab iphash
}
unsetIpset(){
    echo "unsetIpset..."
    ipset -X $ipsetTab
}

start(){
    setIpset
    setIptables
    systemctl start dnsmasq
    systemctl start v2ray
    # nohup /usr/bin/v2ray/v2ray -config /etc/v2ray/config.json &
}
stop(){
    unsetIptables
    unsetIpset
    systemctl stop dnsmasq
    systemctl stop v2ray
    #pid=\$(ps aux | grep v2ray | grep -v grep | awk '{print $2}')
    #if [ -n "\$pid" ];then
    #    kill -9 \$pid
    #fi
}

case \$1 in
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
        echo 'usage: $(basename $0) start|stop|restart'
        ;;
esac
EOF
chmod +x transparent.sh
}

check
installV2ray
setDnsmasq
setV2ray
createScript
echo 'Done.'

#v2ray server config
# {
#   "log" : {
#     "access": "/var/log/v2ray/access.log",
#     "error": "/var/log/v2ray/error.log",
#     "loglevel": "warning"
#   },
#   "inbound": {
#     "port": 41754,
#     "protocol": "vmess",
#     "settings": {
#       "clients": [
#         {
#           "id": "e2791dbb-f340-4a71-998a-da3b184a1cef",
#           "level": 1,
#           "alterId": 64
#         }
#       ]
#     },
#     "streamSettings": {
# 	    "network":"ws"
#     }
#   },
#   "outbound": {
#     "protocol": "freedom",
#     "settings": {}
#   }
# }
