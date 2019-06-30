## 部署 Etcd 集群（每个节点都要完成此操作）

__前期准备__
- 首先[关闭防火墙和 SELINUX](https://github.com/lcePolarBear/Linux_Basic_Note/blob/master/Linux%20系统和常用指令/禁用防火墙和%20selinux.md)
- 创建群集的集中配置路径
    ```
    mkdir -p /opt/etcd/{bin,cfg,ssl}
    ```

__获取证书__
- etcd 的运行需要 ssl 证书的认证
    ```
    ca.pem | ca-key.pem | server.pem | server-key.pem
    ```
- [获取证书的步骤](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/部署过程/准备%20etcd%20%26%20flannel%20证书.md)
- 将证书放入 /opt/etcd/ssl 路径下

__自动化脚本 [etcd.sh](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/config-files/etcd.sh) 部署 etcd__
* [获取 etcd](https://github.com/etcd-io/etcd/releases/tag/v3.2.12)
* 解压后将 etcd 和 etcdctl 放入 /opt/etcd/bin 路径 注意赋予执行权限
* 将在上一步中为 etcd 生成的私钥放在 /opt/kubernetes/ssl/
* 传入参数启动
    ```
    ./etcd.sh etcd01 192.168.10.110 etcd02=https://192.168.10.111:2380,etcd03=https://192.168.10.112:2380
    ```
    - 注意第一次启动会卡壳，强制退出就可以
    - 在所有节点均启动之前用 systemctl status 查看启动状态是不成功的，但只要用 ```ps -ef | grep etcd``` 有进程启动就可以
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

__检查群集状态__

等到 master 和 node 都正确部署完 etcd 可检查群集健康状态
* 进入 /opt/etcd/ssl/ 执行以下命令
    ```
    /opt/etcd/bin/etcdctl \
    --ca-file=/opt/etcd/ssl/ca.pem --cert-file=/opt/etcd/ssl/server.pem --key-file=/opt/etcd/ssl/server-key.pem \
    --endpoints="https://192.168.10.110:2379,https://192.168.10.111:2379,https://192.168.10.112:2379" \
    cluster-health
    ```