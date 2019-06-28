## 部署 Etcd 集群（每个节点都要完成此操作）

__前期准备__
- 首先[关闭防火墙和 SELINUX](https://github.com/lcePolarBear/Linux_Basic_Note/blob/master/Linux%20系统和常用指令/禁用防火墙和%20selinux.md)
- 创建群集的集中配置路径
    ```
    mkdir -p /opt/etcd/{bin,cfg,ssl}
    ```

__手动部署 etcd__
* [获取 etcd](https://github.com/etcd-io/etcd/releases/tag/v3.2.12)
* 解压后将 etcd 和 etcdctl 放入 /opt/etcd/bin 路径 注意赋予执行权限
* 创建 etch 配置文件并放入 /opt/etcd/cfg/ 下
    ```
    #[Member]
    ETCD_NAME="etcd01"
    ETCD_DATA_DIR="/var/lib/etcd/default.etcd"
    ETCD_LISTEN_PEER_URLS="https://192.168.10.110:2380"
    ETCD_LISTEN_CLIENT_URLS="https://192.168.10.110:2379"

    #[Clustering]
    ETCD_INITIAL_ADVERTISE_PEER_URLS="https://192.168.10.110:2380"
    ETCD_ADVERTISE_CLIENT_URLS="https://192.168.10.110:2379"
    ETCD_INITIAL_CLUSTER="etcd01=https://192.168.10.110:2380,etcd02=https://192.168.10.111:2380,etcd03=https://192.168.10.112:2380"
    ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
    ETCD_INITIAL_CLUSTER_STATE="new"
    ```
* 创建可执行程序 /usr/lib/systemd/system/etcd.service
    ```
    [Unit]
    Description=Etcd Server
    After=network.target
    After=network-online.target
    Wants=network-online.target

    [Service]
    Type=notify
    EnvironmentFile=/opt/etcd/cfg/etcd \
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
* 将在上一步中为 etcd 生成的私钥放在 /opt/kubernetes/ssl/

- 启动 etcd
    - 启动前先新建好 /var/lib/etcd/ 路径 
    - 使用 systemd 启动
        ```
        systemctl start etcd
        ```
    - 注意第一次启动会卡壳，强制退出就可以
    - 在所有节点均启动之前用 systemctl status 查看启动状态是不成功的，但只要用 ps -ef | grep etcd 有进程启动就可以
* 启动出现失败情况的查错方式
    ```
    journalctl -u etcd
    ```
    ```
    systemctl status etcd
    ```
    ```
    tail /var/log/messages -f
    ```

__自动化脚本 [etcd.sh](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/config-files/etcd.sh) 创建 etcd 配置文件和 systemd 启动项并启动__
- 传入参数启动
    ```
    ./etcd.sh etcd01 192.168.10.110 etcd02=https://192.168.10.111:2380,etcd03=https://192.168.10.112:2380
    ```

__检查群集状态__

等到 master 和 node 都正确部署完 etcd 可检查群集健康状态
* 进入 /opt/etcd/ssl/ 执行以下命令
    ```
    /opt/etcd/bin/etcdctl \
    --ca-file=/opt/etcd/ssl/ca.pem --cert-file=/opt/etcd/ssl/server.pem --key-file=/opt/etcd/ssl/server-key.pem \
    --endpoints="https://192.168.10.110:2379,https://192.168.10.111:2379,https://192.168.10.112:2379" \
    cluster-health
    ```