## etcd 数据库的备份恢复

安装 etcdctl
yum install etcd

__kubeadm 部署 etcd 的备份恢复__
- 备份命令示例
    ```
    ETCDCTL_API=3 etcdctl \
    snapshot save snap.db \
    --endpoints=https://127.0.0.1:2379 \
    --cacert=/etc/kubernetes/pki/etcd/ca.crt \
    --cert=/etc/kubernetes/pki/etcd/server.crt \
    --key=/etc/kubernetes/pki/etcd/server.key 
    ```
- 恢复步骤
    1. 先暂停 kube-apiserver 和 etcd 容器
        ```
        mv /etc/kubernetes/manifests /etc/kubernetes/manifests.bak
        mv /var/lib/etcd/ /var/lib/etcd.bak 
        ```
    2. 恢复
        ```
        ETCDCTL_API=3 etcdctl \
        snapshot restore snap.db \
        --data-dir=/var/lib/etcd 
        ```
    3. 启动 kube-apiserver 和 etcd 容器
        ```
        mv /etc/kubernetes/manifests.bak /etc/kubernetes/manifests
        ```


__二进制部署 etcd 的备份恢复__