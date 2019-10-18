#!/bin/bash

hostnamectl set-hostname node

# 关闭 防火墙
systemctl stop firewalld
systemctl disable firewalld

# 关闭 SeLinux
setenforce 0
sed -i "s/SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config

# 关闭 swap
swapoff -a
yes | cp /etc/fstab /etc/fstab_bak
cat /etc/fstab_bak |grep -v swap > /etc/fstab

#关闭无用服务
systemctl stop postfix
systemctl disable postfix

# 修改 /etc/sysctl.conf
modprobe br_netfilter
cat <<EOF >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
vm.swappiness=0
EOF
sysctl -p /etc/sysctl.d/k8s.conf

#开启 ipvs
cat > /etc/sysconfig/modules/ipvs.modules <<EOF
#!/bin/bash
modprobe -- ip_vs
modprobe -- ip_vs_rr
modprobe -- ip_vs_wrr
modprobe -- ip_vs_sh
modprobe -- nf_conntrack_ipv4
EOF
chmod 755 /etc/sysconfig/modules/ipvs.modules && bash /etc/sysconfig/modules/ipvs.modules && lsmod | grep -e ip_vs -e nf_conntrack_ipv4

# 设置 yum repository
rpm -ivh /root/k8s/rpm/repo/* --nodeps --force

# 安装并启动 docker
rpm -ivh /root/k8s/rpm/docker/* --nodeps --force

# 安装kubelet、kubeadm、kubectl
rpm -ivh /root/k8s/rpm/k8s/* --nodeps --force

# 修改docker Cgroup Driver为systemd
mkdir -p /etc/docker/
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "registry-mirrors": ["http://hub-mirror.c.163.com"]
}
EOF

# 重启 docker，并启动 kubelet
systemctl daemon-reload
systemctl restart docker
systemctl enable docker
systemctl enable kubelet
#kubelet 不用启动 会在kubeadm init 时被自动调用开启
docker load -i /root/k8s/node-v1.15.4.tar
docker load -i /root/k8s/heapster.tar
