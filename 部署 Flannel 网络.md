## 部署 Flannel 网络

__网络基础知识__
Flannel 是 覆盖网络的一种，将数据源包封装在另一种网络包里面进行转发和通信

在 master 下
---------------------
写入分配的子网段到 etcd 供 flanneld 使用。在 /opt/kubernetes/ssl 下执行
```
/opt/kubernetes/bin/etcdctl \
--ca-file=ca.pem --cert-file=server.pem --key-file=server-key.pem \
--endpoints="https://192.168.10.110:2379,https://192.168.10.141:2379,https://192.168.10.145:2379" \
set /coreos.com/network/config '{"Network":"172.17.0.0/16","Backend":{"Type":"vxlan"}}'
```
可将 set 改为 get 来查验是否配置成功

node 下
---------------------
下载 [flanneld 下载地址](https://github.com/coreos/flannel/releases/) 并将其中的 mk-docker-opts.sh 和 flanneld 放入到 /opt/kubernetes/bin 要有执行权限
创建 flanneld 配置文件
vi /opt/kubernetes/cfg/flanneld
```
FLANNEL_OPTIONS="--etcd-endpoints=https://192.168.10.110:2379,https://192.168.10.141:2379,https://192.168.10.145:2379 -etcd-cafile=/opt/kubernetes/ssl/ca.pem -etcd-certfile=/opt/kubernetes/ssl/server.pem -etcd-keyfile=/opt/kubernetes/ssl/server-key.pem"
```
由此可以看出需要ca、server、server-key 证书
再写一个systemd去管理 vi /usr/lib/systemd/system/flanneld.service
创建 /run/flannel/subnet.env
```
[Unit]
Description=Flanneld overlay address etcd agent
After=network-online.target network.target
Before=docker.service

[Service]
Type=notify
EnvironmentFile=/opt/kubernetes/cfg/flanneld
ExecStart=/opt/kubernetes/bin/flanneld --ip-masq $FLANNEL_OPTIONS
ExecStartPost=/opt/kubernetes/bin/mk-docker-opts.sh -k DOCKER_NETWORK_OPTION -d /run/flannel/subnet.env
Restart=on-failure

[Install]
WantedBy=multi-user.target
```
cat /run/flannel/subnet.env 可以查看flannel分配的ip地址
将 DOCKER_NETWORK_OPTION 应用于docker
vi /usr/lib/systemd/system/docker.service
```
EnvironmentFile=/run/flannel/subnet.env
ExecStart=/usr/bin/dockerd $DOCKER_NETWORK_OPTION
```
两个 node 节点的网段不一样是正常的 但 docker 必须跟node结点下的flannel同一网段
只要node节点之间相互能ping通docker的ip地址就说明正常了

我们可以通过以下命令来查看flannel维护的路由信息
```
/opt/kubernetes/bin/etcdctl \
--ca-file=ca.pem --cert-file=server.pem --key-file=server-key.pem \
--endpoints="https://192.168.10.110:2379,https://192.168.10.141:2379,https://192.168.10.145:2379" \
ls /coreos.com/network/subnets
```
正好是两个node节点分配的网段
可以将ls替换成get来查看这些网段文件里有哪些信息
主要包含着节点的ip地址