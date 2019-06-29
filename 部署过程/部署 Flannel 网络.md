## 部署 Flannel 网络

__准备工作__
- 创建 kubernetes 工作路径
    ```
    mkdir -p /opt/kubernetes/{bin,cfg,ssl}
    ```
- flannel 的运行需要 [ssl 证书的认证](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/部署过程/准备%20etcd%20%26%20flannel%20证书.md)工作，若在部署 etcd 时已部署过证书则无需再生成

__在 master 下__

写入分配的子网段到 etcd 供 flanneld 使用，在 /opt/etcd/ssl 下执行
```
/opt/etcd/bin/etcdctl \
--ca-file=/opt/etcd/ssl/ca.pem --cert-file=/opt/etcd/ssl/server.pem --key-file=/opt/etcd/ssl/server-key.pem \
--endpoints="https://192.168.10.110:2379,https://192.168.10.111:2379,https://192.168.10.112:2379" \
set /coreos.com/network/config  '{ "Network": "172.17.0.0/16", "Backend": {"Type": "vxlan"}}'
```
可将 set 改为 get 来查验是否配置成功

__在 node 下__

- 下载 [flanneld](https://github.com/coreos/flannel/releases/) 并将其中的 mk-docker-opts 和 flanneld 放入到 /opt/kubernetes/bin 路径下
- 自动化脚本 [flannel.sh](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/config-files/flannel.sh) 执行 flannel 部署
- /run/flannel/subnet.env 文件可以查看 flannel 分配的 ip 地址，此文件需事先创建，不然 docker 无法正常启动




__查验连接状态__
>两个 node 节点的网段不一样是正常的 但 docker 必须跟 node 结点下的 flannel 同一网段
只要 node 节点之间相互能 ping 通 docker 的 ip 地址就说明正常了

- 我们可以在 /opt/etcd/ssl/ 路径下通过以下命令来查看 flannel 维护的路由信息
    ```
    /opt/etcd/bin/etcdctl \
    --ca-file=/opt/etcd/ssl/ca.pem \
    --cert-file=/opt/etcd/ssl/server.pem \
    --key-file=/opt/etcd/ssl/server-key.pem \
    --endpoints="https://192.168.10.110:2379,https://192.168.10.111:2379,https://192.168.10.112:2379" ls /coreos.com/network/subnets
    ```
    结果正好是两个 node 节点分配的网段

    可以将 ls 替换成 get 来查看这些网段文件里的信息，其中主要可以看到节点的 ip 地址