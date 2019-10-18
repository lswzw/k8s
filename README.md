---------------
by: Lswzw...
---------------
系统： CentOS-7-x86_64-Minimal-1810.iso
基本小化安装。
root密码设置为 123456
配置好固定IP

sh k8s.sh masterip nodeip
例如：
sh k8s.sh 192.168.4.4 192.168.4.5

单独加node节点。 运行
sh addnode.sh nodeip nodehostname
例如：(nodehostname 不能为 node)
sh addnode.sh 192.168.4.6 node02


镜像包和rpm文件都为空文件. 真实文件打包在云盘.
