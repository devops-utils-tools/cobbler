#!/usr/bin/env bash
#cobbler init scripts By:liuwei Mail:al6008@163.com
#export static_ip=172.17.0.3
#export dhcp_route=172.17.0.3
#export dhcp_network=172.17.0
source /etc/profile
export static_ip=${LOCAL_IP:-"192.168.1.2"}
export dhcp_route=${DHCP_ROUTE:-"192.168.1.254"}
export dhcp_network=${DHCP_NETWORK:-"192.168.100"}
export COBBLER_PASSWORD=${COBBLER_PASSWORD:-"al6008@163.com"}
export cobbler_password=$(openssl passwd -1 -salt 'salt' ${COBBLER_PASSWORD})

if [ ! -e /etc/cobbler/cobbler.init ];then
    #配置文件
    tar xf /tmp/cobbler.tar.gz -C /

    #back config file
    test -f /etc/cobbler/settings.default ||cp /etc/cobbler/settings /etc/cobbler/settings.default
    test -f /etc/cobbler/dhcp.template.default ||cp /etc/cobbler/dhcp.template /etc/cobbler/dhcp.template.default
    test -f /etc/debmirror.conf.defalt ||cp /etc/debmirror.conf.defalt

    #cobbler
    \cp -f /etc/cobbler/settings.default /etc/cobbler/settings
    sed -i "s/^server: .*/server: ${static_ip}/" /etc/cobbler/settings
    sed -i "s/^next_server: .*/next_server: ${static_ip}/" /etc/cobbler/settings
    sed -i 's/manage_dhcp: 0/manage_dhcp: 1/' /etc/cobbler/settings
    sed -i 's/pxe_just_once: 0/pxe_just_once: 1/' /etc/cobbler/settings
    sed -ri "/default_password_crypted/s#(.*: ).*#\1\"${cobbler_password}\"#" /etc/cobbler/settings
    grep -Ev "^$|#" /etc/cobbler/settings

    #tftpd
    sed -i '/disable/s#yes#no#' /etc/xinetd.d/tftp


    #dhcp
    \cp -f /etc/cobbler/dhcp.template.default  /etc/cobbler/dhcp.template
    #sed  "/option routers/s@.*\.@     option routers         ${dhcp_route};@g" /etc/cobbler/dhcp.template
    sed -i "/option routers/s@192.168.1.5@${dhcp_route}@g" /etc/cobbler/dhcp.template
    sed -i "s@192.168.1@${dhcp_network}@g" /etc/cobbler/dhcp.template
    grep -Ev "^$|#" /etc/cobbler/dhcp.template

    #deb
    sed -i 's/@dists="sid";/#@dists="sid";/g' /etc/debmirror.conf
    sed -i 's/@arches="i386";/#@arches="i386"/g' /etc/debmirror.conf

    #run server
    systemctl enable rsyncd
    systemctl restart rsyncd&&systemctl restart tftp.socket
    systemctl restart cobblerd.service
    systemctl restart httpd.service&&systemctl restart cobblerd.service

    #配置密码
    /usr/bin/expect << EOF
    set timeout 30
    spawn htdigest /etc/cobbler/users.digest "Cobbler" cobbler
    expect {
        "New password:" { send "${COBBLER_PASSWORD}\r"; exp_continue}
        "Re-type new password:" { send "${COBBLER_PASSWORD}\r"; exp_continue}
        eof { exit }
    }
EOF
    /usr/bin/expect << EOF
    set timeout 30
    spawn htdigest /etc/cobbler/users.digest "Cobbler" admin
    expect {
        "New password:" { send "${COBBLER_PASSWORD}\r"; exp_continue}
        "Re-type new password:" { send "${COBBLER_PASSWORD}\r"; exp_continue}
        eof { exit }
    }
EOF

    #sync check
    /usr/bin/sleep 15
    cobbler get-loaders
    cobbler sync && true
    touch /etc/cobbler/cobbler.init
else
    systemctl enable rsyncd
    systemctl restart rsyncd&&systemctl restart tftp.socket
    systemctl restart cobblerd.service
    systemctl restart httpd.service&&systemctl restart cobblerd.service
fi

#check init 
if [ $(cobbler check |wc -l) -ge 3 ];then
    echo --------------------
    echo  Cobbler init Fail ! ! ! ! ! !
    echo                By:liuwei Mail:al6008@163.com
    echo --------------------
    exit 1
else
    echo --------------------
    echo  Cobbler init Success
    echo                By:liuwei Mail:al6008@163.com
    echo --------------------
    exit 0
fi
