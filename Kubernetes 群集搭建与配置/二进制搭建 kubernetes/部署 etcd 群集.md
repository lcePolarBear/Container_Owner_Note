## 部署 etcd 集群（每个节点都要完成此操作）

__创建群集的集中配置路径__
```
mkdir -p /opt/etcd/{bin,cfg,ssl}
```

__部署所需要的执行文件、证书__
- [获取 etcd](https://github.com/etcd-io/etcd/releases/download/v3.3.13/etcd-v3.3.13-linux-amd64.tar.gz)
- 解压后将 __etcd__ 和 __etcdctl__ 放入 /opt/etcd/bin 路径下
- 生成 etcd 运行所需要的 [ssl 证书](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/%E9%83%A8%E7%BD%B2%E8%BF%87%E7%A8%8B/%E7%94%9F%E6%88%90%20etcd%20%E8%AF%81%E4%B9%A6.md)
- 将证书放入 /opt/etcd/ssl 路径下

__配置 etcd 配置文件__
- 将 etcd 所需的配置文件放入 /opt/etcd/cfg/ 下
- `etcd.conf`
    ```conf
    #[Member]
    ETCD_NAME="etcd-1"
    ETCD_DATA_DIR="/var/lib/etcd/default.etcd"
    ETCD_LISTEN_PEER_URLS="https://192.168.1.11:2380"
    ETCD_LISTEN_CLIENT_URLS="https://192.168.1.11:2379"

    #[Clustering]
    ETCD_INITIAL_ADVERTISE_PEER_URLS="https://192.168.1.11:2380"
    ETCD_ADVERTISE_CLIENT_URLS="https://192.168.1.11:2379"
    ETCD_INITIAL_CLUSTER="etcd-1=https://192.168.1.11:2380,etcd-2=https://192.168.1.12:2380,etcd-3=https://192.168.1.13:2380"
    ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
    ETCD_INITIAL_CLUSTER_STATE="new"
    ```
    > 注意修改 URLS 的地址为本机的地址， ETCD_INITIAL_CLUSTER 参数为 etcd 群集的所有 ip 地址

__将 etcd 作为 service 使用 systemctl 来管理__
- 将文件 [etcd.service](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/%E6%89%80%E9%9C%80%E8%A6%81%E7%9A%84%E6%96%87%E4%BB%B6/etcd.service) 放入 /usr/lib/systemd/system/ 路径下
- 更新 service 并启动 etcd
    ```
    systemctl daemon-reload -a
    systemctl start etcd
    ```
    - 把所有节点的 etcd 都启动后 systemctl 才能执行成功
    - 如果因为配置文件写错了导致 etcd 启动有问题，除了修改 etcd.confg 之外还要把 /var/lib/etcd/ 路径下的内容删除掉

__检查群集状态__

- 等到 master 和 node 都正确部署完 etcd 可检查群集健康状态
- 执行以下命令
    ```bash
    /opt/etcd/bin/etcdctl \
    --ca-file=/opt/etcd/ssl/ca.pem --cert-file=/opt/etcd/ssl/server.pem --key-file=/opt/etcd/ssl/server-key.pem \
    --endpoints="https://192.168.1.11:2379,https://192.168.1.12:2379,https://192.168.1.13:2379" \
    cluster-health
    ```