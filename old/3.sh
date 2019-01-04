from centos:7.5.1804
maintainer By:liuwei Mail:al6008@163.com
run rm -rf /etc/localtime && ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime &&\
    yum install -y iproute libX11-common  net-tools python2-pip unzip screen epel-release &&\
    yum install -y httpd curl which tmux vim  &&\
    yum -y install cobbler cobbler-web dhcp tftp-server httpd pykickstart &&\
    yum -y install cman debmirror pykickstart  fence-agents createrepo &&
    rm -rf /tmp/* &&\
    yum clean all
env LC_ALL en_US.utf8
env TZ Asia/Shanghai
workdir /tmp
cmd ["/bin/bash","/run.sh"]



from centos:7.5.1804
maintainer By:liuwei Mail:al6008@163.com
copy run.service  /lib/systemd/system/run.service
run rm -rf /etc/localtime && ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime &&\
    yum install -y libX11-common  net-tools epel-release &&\
    yum install -y httpd curl expect  &&\
    yum -y install cobbler cobbler-web dhcp tftp-server httpd pykickstart &&\
    yum -y install cman debmirror pykickstart  fence-agents createrepo &&\
    systemctl daemon-reload||true &&\
    systemctl enable run.service||true &&\
    rm -rf /tmp/* &&\
    yum clean all
env LC_ALL en_US.utf8
env TZ Asia/Shanghai
copy cobbler.tar.gz /tmp
copy run.sh /run.sh
workdir /tmp
volume [/sys/fs/cgroup:/sys/fs/cgroup:ro]
cmd ["/usr/sbin/init"]

