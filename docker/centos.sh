#https://blog.csdn.net/kinginblue/article/details/73527832
root(){
    if [ $EUID -ne 0 ];then
        echo "need root"
        exit 1
    fi
}

c6(){
    root
    rpm -iUvh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
    yum update -y
    yum install docker-io -y
}

c7(){
    root
    yum update -y
    yum install docker -y
}

install(){
    local version=`bash -c "$(curl -fsSL https://raw.githubusercontent.com/sunliang711/tools/master/version.sh)"`
    echo "version: $version"
    case $version in
        centos-6*)
            c6
            ;;
        centos-7*)
            c7
            ;;
        *)
            echo "Not support your os."
            exit 1
            ;;
    esac
}
install
