## 部署 etcd 集群（每个节点都要完成此操作）

__前期准备__
- 创建群集的集中配置路径
    ```
    mkdir -p /opt/etcd/{bin,cfg,ssl}
    ```

__获取证书__
- etcd 的运行需要 ssl 证书的认证
- [获取证书的步骤](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/%E9%83%A8%E7%BD%B2%E8%BF%87%E7%A8%8B/%E5%87%86%E5%A4%87%20etcd%20%E8%AF%81%E4%B9%A6.md)
- 将证书放入 /opt/etcd/ssl 路径下

__部署 etcd__
- [获取 etcd](https://github.com/etcd-io/etcd/releases/tag/v3.3.13)
- 解压后将 __etcd__ 和 __etcdctl__ 放入 /opt/etcd/bin 路径（注意赋予执行权限）
- 编写 `etcd.server` 文件以便用 systemctl 来管理
    ```
    [Unit]
    Description=Etcd Server
    After=network.target
    After=network-online.target
    Wants=network-online.target

    [Service]
    Type=notify
    EnvironmentFile=/opt/etcd/cfg/etcd.conf
    ExecStart=/opt/etcd/bin/etcd \
            --name=${ETCD_NAME} \
            --data-dir=${ETCD_DATA_DIR} \
            --listen-peer-urls=${ETCD_LISTEN_PEER_URLS} \
            --listen-client-urls=${ETCD_LISTEN_CLIENT_URLS},http://127.0.0.1:2379 \
            --advertise-client-urls=${ETCD_ADVERTISE_CLIENT_URLS} \
            --initial-advertise-peer-urls=${ETCD_INITIAL_ADVERTISE_PEER_URLS} \
            --initial-cluster=${ETCD_INITIAL_CLUSTER} \
            --initial-cluster-token=${ETCD_INITIAL_CLUSTER_TOKEN} \
            --initial-cluster-state=new \
            --cert-file=/opt/etcd/ssl/server.pem \
            --key-file=/opt/etcd/ssl/server-key.pem \
            --peer-cert-file=/opt/etcd/ssl/server.pem \
            --peer-key-file=/opt/etcd/ssl/server-key.pem \
            --trusted-ca-file=/opt/etcd/ssl/ca.pem \
            --peer-trusted-ca-file=/opt/etcd/ssl/ca.pem
    Restart=on-failure
    LimitNOFILE=65536

    [Install]
    WantedBy=multi-user.target
    ```
    - 把所有节点的 etcd 都启动后 systemctl 才能执行成功
    - 如果因为配置文件写错了导致 etcd 启动有问题，除了修改 etcd.confg 之外还要把 /var/lib/etcd/ 路径下的内容删除掉

__配置 etcd 配置文件__
- 编写 `etcd.conf` 文件放入 /opt/etcd/cfg/ 下
    ```
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
    - 注意修改 URLS 的地址为本机的地址， ETCD_INITIAL_CLUSTER 参数为 etcd 群集的所有 ip 地址

__检查群集状态__

- 等到 master 和 node 都正确部署完 etcd 可检查群集健康状态
- 执行以下命令
    ```
    /opt/etcd/bin/etcdctl \
    --ca-file=/opt/etcd/ssl/ca.pem --cert-file=/opt/etcd/ssl/server.pem --key-file=/opt/etcd/ssl/server-key.pem \
    --endpoints="https://192.168.1.11:2379,https://192.168.1.12:2379,https://192.168.1.13:2379" \
    cluster-health
    ```