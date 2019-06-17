## 部署 Etcd 集群（每个节点都要完成此操作）

__首先关闭防火墙和 SELINUX__

__创建群集的集中配置路径__
```
mkdir /opt/kubernetes/{bin,cfg,ssl}
```

__部署 etcd__
* [获取 etcd](https://github.com/etcd-io/etcd/releases/tag/v3.2.12)
* 解压后将 etcd 和 etcdctl 放入 /opt/kubernetes/bin 路径 注意赋予执行权限
* 创建 [etch](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/config-files/etcd) 配置文件并放入 /opt/kubernetes/cfg/ 下
* 在/usr/lib/systemd/system/ 下创建 [etcd.service](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/config-files/etcd.service) 可执行程序
* 将 etcd.service 所需要的私钥放入 /opt/kubernetes/ssl/ 下

__文件组成路径如下__
```
/opt/kubernetes/bin
    etcd(执行文件) etcdctl
/opt/kubernetes/cfg
    etcd(配置文件)
/opt/kubernetes/ssl
    ca-key.pem ca.pem server-key.pem server.pem
/usr/lib/systemd/system
    etcd.service
```

__启动 etcd__
```
systemctl start etcd
```
* 重定向 systemd 配置文件
    ```
    systemctl daemon-reload
    ```

__检查群集状态__

等到 master 和 node 都正确部署完 etcd 可检查群集健康状态
* 进入 /opt/kubernetes/ssl/ 执行以下命令
    ```
    /opt/kubernetes/bin/etcdctl \
    --ca-file=ca.pem --cert-file=server.pem --key-file=server-key.pem \
    --endpoints="https://192.168.10.110:2379,https://192.168.10.141:2379,https://192.168.10.145:2379" \
    cluster-health
    ```