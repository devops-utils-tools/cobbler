#https://www.cnblogs.com/linuxliu/p/7668048.html
rm -rf /data/docker_cobbler
mkdir -p /data/docker_cobbler
cat >/data/docker_cobbler/init.env <<EOF
#本机地址
LOCAL_IP="172.16.110.14"
#路由地址
DHCP_ROUTE="172.16.110.1"
#所在网段
DHCP_NETWORK="172.16.110"
#Cobbler_web密码和安装系统的默认密码
COBBLER_PASSWORD="al6008@163.com"
EOF

docker rm -f cobbler
#docker rmi -f cobbler:2.8.4
docker build  -t cobbler:2.8.4 ./
docker rm -f cobbler
docker run -d --name cobbler --hostname cobbler \
    --privileged --network host \
    -v /data/docker_cobbler/mnt:/mnt \
    -v /data/docker_cobbler/var:/var/lib/cobbler \
    -v /data/docker_cobbler/etc:/etc/cobbler \
    -v /data/docker_cobbler/init.env:/etc/init.env:ro \
cobbler:2.8.4
sleep 5
docker exec -it cobbler journalctl -u run-docker -f

docker restart cobbler
docker exec -it cobbler journalctl -u run-docker -f

#    -p 80:80 -p 443:443 -p 78:78/udp -p 69:69/udp -p 67:67/udp\

#https://172.16.110.14/cobbler_web admin/cobbler al6008@163.com
