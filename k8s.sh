#!/bin/bash
masterip=$1
nodeip=$2
echo "$masterip  master" >> /etc/hosts
echo "$nodeip  node" >> /etc/hosts
echo 'hosts初始化完成！'
echo 'key开始分发！'
rpm -ivh ./rpm/sshpass-1.06-2.el7.x86_64.rpm &>/dev/null
ssh-keygen -t rsa -f ~/.ssh/id_rsa -N "" -q
sshpass -p 123456 ssh-copy-id -i /root/.ssh/id_rsa.pub -o StrictHostKeyChecking=no root@node &>/dev/null
echo 'key分发完成！'
echo '复制配置文件到node！'
scp -i /root/.ssh/id_rsa /etc/hosts root@node:/etc/hosts &>/dev/null
ssh root@node "mkdir -p /root/k8s" &>/dev/null
scp -i /root/.ssh/id_rsa ./images/heapster.tar root@node:/root/k8s/ &>/dev/null
scp -i /root/.ssh/id_rsa ./images/node-v1.15.4.tar root@node:/root/k8s/ &>/dev/null
scp -i /root/.ssh/id_rsa ./shell/node.sh root@node:/root/k8s/ &>/dev/null
scp -i /root/.ssh/id_rsa -r ./rpm/ root@node:/root/k8s/ &>/dev/null
echo '复制配置文件完成！'
echo '远程安装node!'
ssh root@node "sh /root/k8s/node.sh" &>/dev/null
echo 'node初始化完成!'
echo '初始化master!'
sh ./shell/master.sh &>/dev/null
echo '初始化master完成!'
echo 'node节点加入master!'
scp -i /root/.ssh/id_rsa ./join.sh root@node:/root/k8s/ &>/dev/null
ssh root@node "sh /root/k8s/join.sh" &>/dev/null
echo 'node节点加入master完成!'
echo '安装k8s监控!'
sh ./shell/heapster.sh &>/dev/null
echo '安装k8s监控完成!'
echo '主要信息：'
echo 'dashboard端口30000 && grafana端口300001'
echo ' '
echo 'dashboard 登录 token 运行 sh ./token.sh'
