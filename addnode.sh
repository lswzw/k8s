#!/bin/bash
nodeip=$1
hostname=$2
echo "$nodeip  $hostname" >> /etc/hosts
echo 'hosts初始化完成！'

echo 'key开始分发！'
sshpass -p 123456 ssh-copy-id -i /root/.ssh/id_rsa.pub -o StrictHostKeyChecking=no root@$hostname &>/dev/null
echo 'key分发完成！'

echo '配置hosts分发！'
hosttext=$(cat /etc/hosts | awk '!/^127./&&!/:/''{print$2}')
for i in $hosttext;
do
sshpass -p 123456 ssh-copy-id -i /root/.ssh/id_rsa.pub -o StrictHostKeyChecking=no root@$i &>/dev/null
scp -i /root/.ssh/id_rsa /etc/hosts root@$i:/etc/hosts &>/dev/null
done
echo 'hosts分发完成！'

#生成配置文件
cp ./shell/node.sh ./shell/$hostname.sh
sed -i "0,/node/s/node/$hostname/" ./shell/$hostname.sh

echo '复制配置文件到node！'
ssh root@$hostname "mkdir -p /root/k8s" &>/dev/null
scp -i /root/.ssh/id_rsa ./images/heapster.tar root@$hostname:/root/k8s/ &>/dev/null
scp -i /root/.ssh/id_rsa ./images/node-v1.15.4.tar root@$hostname:/root/k8s/ &>/dev/null
scp -i /root/.ssh/id_rsa ./shell/$hostname.sh root@$hostname:/root/k8s/node.sh &>/dev/null
scp -i /root/.ssh/id_rsa -r ./rpm/ root@$hostname:/root/k8s/ &>/dev/null
echo '复制配置文件完成！'

echo '远程安装node!'
ssh root@$hostname "sh /root/k8s/node.sh" &>/dev/null
echo 'node初始化完成!'

echo 'node节点加入master!'
kubeadm token create --print-join-command > ./join.sh
scp -i /root/.ssh/id_rsa ./join.sh root@$hostname:/root/k8s/ &>/dev/null
ssh root@$hostname "sh /root/k8s/join.sh" &>/dev/null
echo 'node节点加入master完成!'

