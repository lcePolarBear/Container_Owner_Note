## 部署 Master 节点组件
__创建群集的集中配置路径__
```
mkdir -p /opt/kubernetes/{bin,cfg,logs,ssl}
```

__部署所需要的执行文件、证书和 token__
- 获取 [kubernetes 组件](https://dl.k8s.io/v1.16.15/kubernetes-server-linux-amd64.tar.gz)
- 将 __kube-apiserver , kube-controller-manager , kube-scheduler__ 放入 /opt/kubernetes/bin/ 路径下
- 将 Master 所需要的证书放入 /opt/kubernetes/ssl/ 路径下， token.csv 放入 /opt/kubernetes/cfg/ 路径下

__部署配置文件__
- 将 kube-apiserver , kube-controller-manager , kube-scheduler 所需的配置文件放在 /opt/kubernetes/cfg/ 路径下
- `kube-apiserver.conf`
    ```
    KUBE_APISERVER_OPTS="--logtostderr=false \
    --v=2 \
    --log-dir=/opt/kubernetes/logs \
    --etcd-servers=https://192.168.1.11:2379,https://192.168.1.12:2379,https://192.168.1.13:2379 \
    --bind-address=192.168.1.11 \
    --secure-port=6443 \
    --advertise-address=192.168.1.11 \
    --allow-privileged=true \
    --service-cluster-ip-range=10.0.0.0/24 \
    --enable-admission-plugins=NamespaceLifecycle,LimitRanger,ServiceAccount,ResourceQuota,NodeRestriction \
    --authorization-mode=RBAC,Node \
    --enable-bootstrap-token-auth=true \
    --token-auth-file=/opt/kubernetes/cfg/token.csv \
    --service-node-port-range=30000-32767 \
    --kubelet-client-certificate=/opt/kubernetes/ssl/server.pem \
    --kubelet-client-key=/opt/kubernetes/ssl/server-key.pem \
    --tls-cert-file=/opt/kubernetes/ssl/server.pem  \
    --tls-private-key-file=/opt/kubernetes/ssl/server-key.pem \
    --client-ca-file=/opt/kubernetes/ssl/ca.pem \
    --service-account-key-file=/opt/kubernetes/ssl/ca-key.pem \
    --etcd-cafile=/opt/etcd/ssl/ca.pem \
    --etcd-certfile=/opt/etcd/ssl/server.pem \
    --etcd-keyfile=/opt/etcd/ssl/server-key.pem \
    --audit-log-maxage=30 \
    --audit-log-maxbackup=3 \
    --audit-log-maxsize=100 \
    --audit-log-path=/opt/kubernetes/logs/k8s-audit.log"
    ```
- `kube-controller-manager.conf`
    ```
    KUBE_CONTROLLER_MANAGER_OPTS="--logtostderr=false \
    --v=2 \
    --log-dir=/opt/kubernetes/logs \
    --leader-elect=true \
    --master=127.0.0.1:8080 \
    --address=127.0.0.1 \
    --allocate-node-cidrs=true \
    --cluster-cidr=10.244.0.0/16 \
    --service-cluster-ip-range=10.0.0.0/24 \
    --cluster-signing-cert-file=/opt/kubernetes/ssl/ca.pem \
    --cluster-signing-key-file=/opt/kubernetes/ssl/ca-key.pem  \
    --root-ca-file=/opt/kubernetes/ssl/ca.pem \
    --service-account-private-key-file=/opt/kubernetes/ssl/ca-key.pem \
    --experimental-cluster-signing-duration=87600h0m0s" 
    ```
- `kube-scheduler.conf`
    ```
    KUBE_SCHEDULER_OPTS="--logtostderr=false \
    --v=2 \
    --log-dir=/opt/kubernetes/logs \
    --leader-elect \
    --master=127.0.0.1:8080 \
    --address=127.0.0.1"
    ```
__将 kube-apiserver , kube-controller-manager , kube-scheduler 作为 service 使用 systemctl 来管理__
- 将文件 [kube-apiserver.service](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/%E6%89%80%E9%9C%80%E8%A6%81%E7%9A%84%E6%96%87%E4%BB%B6/kube-apiserver.service) , [kube-controller-manager.service](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/%E6%89%80%E9%9C%80%E8%A6%81%E7%9A%84%E6%96%87%E4%BB%B6/kube-controller-manager.service) , [kube-scheduler.service](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/%E6%89%80%E9%9C%80%E8%A6%81%E7%9A%84%E6%96%87%E4%BB%B6/kube-scheduler.service) 放入 /usr/lib/systemd/system/ 路径下
- 更新 service 并启动 kube-apiserver , kube-controller-manager , kube-scheduler
    ```
    systemctl daemon-reload -a
    systemctl start kube-apiserver kube-controller-manager kube-scheduler
    ```

__确保 etcd 正常的情况下可以检查群集是否正常__
```
kubectl get cs
```