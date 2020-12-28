## 部署 Etcd 集群（每个节点都要完成此操作）

__前期准备__
- 创建群集的集中配置路径
    ```
    mkdir -p /opt/etcd/{bin,cfg,ssl}
    ```

__获取证书__
- etcd 的运行需要 ssl 证书的认证
- [获取证书的步骤](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/部署过程/准备%20etcd%20%26%20flannel%20证书.md)
- 将证书放入 /opt/etcd/ssl 路径下

__部署 etcd__
* [获取 etcd](https://github.com/etcd-io/etcd/releases/tag/v3.3.13)
* 解压后将 etcd 和 etcdctl 放入 /opt/etcd/bin 路径 注意赋予执行权限
* 编写 [etcd.server](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/%E6%89%80%E9%9C%80%E8%A6%81%E7%9A%84%E6%96%87%E4%BB%B6/etcd/etcd.service) 文件以便用 systemctl 来管理
    - 把所有节点的 etcd 都启动后 systemctl 才能执行成功
    - 如果因为配置文件写错了导致 etcd 启动有问题，除了修改 etcd.confg 之外还要把 /var/lib/etcd/ 路径下的内容删除掉

__配置 etcd 配置文件__
- 将 [etcd.conf](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/%E6%89%80%E9%9C%80%E8%A6%81%E7%9A%84%E6%96%87%E4%BB%B6/etcd/etcd.conf) 文件放入 /opt/etcd/cfg/ 下

__检查群集状态__

- 等到 master 和 node 都正确部署完 etcd 可检查群集健康状态
- 执行以下命令
    ```
    /opt/etcd/bin/etcdctl \
    --ca-file=/opt/etcd/ssl/ca.pem --cert-file=/opt/etcd/ssl/server.pem --key-file=/opt/etcd/ssl/server-key.pem \
    --endpoints="https://192.168.1.11:2379,https://192.168.1.12:2379,https://192.168.1.13:2379" \
    cluster-health
    ```