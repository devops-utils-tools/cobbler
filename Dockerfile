from centos:7.6.1810
maintainer By:liuwei Mail:al6008@163.com
run rm -rf /etc/localtime && ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime &&\
    yum install -y libX11-common  net-tools epel-release &&\
    yum install -y httpd curl wget which expect  &&\
    yum -y install cobbler cobbler-web dhcp tftp-server httpd pykickstart python2-pip &&\
    yum -y install cman debmirror pykickstart  fence-agents createrepo &&\
    pip uninstall Django -y &&\
    pip install Django==1.8.19 &&\
    rm -rf /tmp/* &&\
    yum clean all
env LC_ALL en_US.utf8
env TZ Asia/Shanghai
workdir /tmp
LABEL maintainer="Cobbler Docker Maintainers <al6008@163.com>"
copy run-docker.service  /lib/systemd/system/run-docker.service
copy run.sh /etc/rc.d/run.sh
run systemctl disable tftp.socket ;\
    systemctl disable rsyncd.service ;\
    systemctl disable dhcpd.service ;\
    systemctl disable httpd.service ;\
    systemctl disable cobblerd.service ;\
    cd / &&tar czf cobbler.tar.gz /etc/cobbler /var/lib/cobbler ;\
    mv /cobbler.tar.gz /tmp/cobbler.tar.gz ;\
    touch /lib/systemd/system/run-docker.service ;\
    systemctl daemon-reload||true ;\
    systemctl enable run-docker.service||true ;\
    echo "/usr/bin/env > /tmp/run.env" >>  /etc/rc.d/rc.local ;\
    chmod a+x /etc/rc.d/rc.local
volume [/sys/fs/cgroup:/sys/fs/cgroup:ro]
#cmd ["/usr/sbin/init"]
entrypoint ["/usr/sbin/init"]
