
    yum -y install cobbler cobbler-web dhcp tftp-server httpd pykickstart &&\
    yum -y install cman debmirror pykickstart  fence-agents createrepo

#!/bin/bash
#cobbler init scripts By:liuwei Mail:al6008@163.com
#export static_ip=172.17.0.3 
#export dhcp_route=172.17.0.3 
#export dhcp_network=172.17.0
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
    systemctl restart rsyncd
    # nohup /usr/bin/rsync --daemon --no-detach &>/dev/null &
    systemctl restart tftp.socket
    systemctl restart cobblerd.service
    systemctl restart httpd.service    

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
    sleep 30
    cobbler sync
    if [ $(cobbler check |wc -l) -ge 3 ];then
        echo --------------------
        echo Cobbler init Fail ! ! ! ! ! !
        echo                By:liuwei Mail:al6008@163.com
        echo --------------------
        exit 1
    else 
        touch /etc/cobbler/cobbler.init
    fi
else
    echo Cobbler is init Done
fi
echo --------------------
echo  Cobbler init Success
echo                By:liuwei Mail:al6008@163.com
echo --------------------
exit 0



docker rm -f cobber
docker build  -t cobbler:2.8.3 ./
docker run -d --name cobber --hostname cobbler \
    --privileged --network host \
    -p 80:80 -p 443:443 -p 78:78/udp -p 69:69/udp \
    -v /mnt/cobbler:/mnt/cobbler \
    -v /var/lib/cobbler:/var/lib/cobbler \
    -e LOCAL_IP="172.16.110.14"  \
    -e DHCP_ROUTE="172.16.110.1" \
    -e DHCP_NETWORK="172.16.110" \
    -e COBBLER_PASSWORD="al6008@163.com" \
cobbler:2.8.3
docker exec -it cobber bash

cobbler_password












nohup /usr/bin/rsync --daemon --no-detach &>/dev/null &
nohup /usr/sbin/httpd -DFOREGROUND &>/dev/null &
nohup /usr/bin/python2 -s /usr/bin/cobblerd -F &>/dev/null &


http://idcos.github.io/osinstall-doc/bootos/BootOS重新打包.html
BootOS重新打包
解压BootOS
# mkdir bootos
# cd bootos
# wget -O - http://osinstall.idcos.com/bootos/initrd.img | xz -d | cpio -id
安装最新的igb驱动包
# cp /path/of/igb-5.3.2-1.x86_64.rpm .
# chroot $PWD ‘rpm -Uvh igb-5.3.2-1.x86_64.rpm’
Preparing...                ########################################### [100%]
   1:igb                    ########################################### [100%]
original pci.ids saved in /usr/local/share/igb
重新打包BootOS
# find . | cpio -co | xz -9 --format=lzma > /path/of/initrd.img
测试最新的驱动
# modinfo igb | head
filename:       /lib/modules/2.6.32-573.el6.x86_64/kernel/drivers/net/igb/igb.ko
version:        5.3.2
license:        GPL
description:    Intel(R) Gigabit Ethernet Network Driver
author:         Intel Corporation, <e1000-devel@lists.sourceforge.net>
srcversion:     B821C1F6B2F95B48EC6DFDA
alias:          pci:v00008086d000010D6sv*sd*bc*sc*i*
alias:          pci:v00008086d000010A9sv*sd*bc*sc*i*
alias:          pci:v00008086d000010A7sv*sd*bc*sc*i*
alias:          pci:v00008086d000010E8sv*sd*bc*sc*i*





cat /lib/systemd/system/run.service

cat > run.service <<EOF
[Unit]
Description=init run
Documentation=http://www.wl166.com

[Service]
Type=notify

ExecStart=/bin/bash /run.sh

Restart=no
KillMode=process

[Install]
WantedBy=multi-user.target
EOF














