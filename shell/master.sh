#!/bin/bash

hostnamectl set-hostname master
# 设置 hostname 解析
#ipaddr=$(ip addr | awk '/^[0-9]+: / {}; /inet.*global/ {print gensub(/(.*)\/(.*)/, "\\1", "g", $2)}'|awk 'NR==1{print}')
#获取ip地址
#echo "$nodeip  node" >> /etc/hosts


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
chmod 755 /etc/sysconfig/modules/ipvs.modules && bash /etc/sysconfig/modules/ipvs.modules

# 设置 yum repository
rpm -ivh ./rpm/repo/* --nodeps --force

# 安装并启动 docker
rpm -ivh ./rpm/docker/* --nodeps --force

# 安装kubelet、kubeadm、kubectl
rpm -ivh ./rpm/k8s/* --nodeps --force

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
docker load -i ./images/k8s-v1.15.4.tar

#lsmod | grep -e ip_vs -e nf_conntrack_ipv4
#docker version


#初始化
kubeadm init --config ./conf/kubeadm.yaml
mkdir ~/.kube
cp /etc/kubernetes/admin.conf ~/.kube/config

#运行flannel和dashboard
kubectl apply -f ./conf/kube-flannel.yml
kubectl apply -f ./conf/kube-dashboard.yml

#再次查看join信息。
#kubeadm token create --print-join-command

kubeadm token create --print-join-command > ./join.sh
