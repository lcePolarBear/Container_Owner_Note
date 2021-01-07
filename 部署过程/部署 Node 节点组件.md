## 部署 Node 节点组件
__安装 Docker__
- [安装 Docker 的步骤](https://github.com/lcePolarBear/Docker_Basic_Config_Note/blob/master/Docker%20%E7%94%A8%E6%B3%95/%E9%83%A8%E7%BD%B2%E5%9C%A8%20CentOS%E4%B8%8A.md)

__创建群集的集中配置路径__
```
mkdir -p /opt/kubernetes/{bin,cfg,logs,ssl}
```

__部署所需要的执行文件、证书__
- 将 __kubelet , kube-proxy__ 放入 /opt/kubernetes/bin/ 下
- 将 Node 需要的 [ssl 证书](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/%E9%83%A8%E7%BD%B2%E8%BF%87%E7%A8%8B/%E5%87%86%E5%A4%87%20Token%20%E5%92%8C%20kubernetes%20%E8%AF%81%E4%B9%A6.md)放入 /opt/kubernetes/bin/ssl 下

__部署配置文件__
- 将 kubelet , kube-proxy 所需的配置文件放在 /opt/kubernetes/cfg/ 路径下
- `bootstrap.kubeconfig`
    ```
    apiVersion: v1
    clusters:
    - cluster:
        certificate-authority: /opt/kubernetes/ssl/ca.pem
        server: https://192.168.1.11:6443
      name: kubernetes
    contexts:
    - context:
        cluster: kubernetes
        user: kubelet-bootstrap
      name: default
    current-context: default
    kind: Config
    preferences: {}
    users:
    - name: kubelet-bootstrap
      user:
        token: c47ffb939f5ca36231d9e3121a252940
    ```
    - 这里记录了 master 所使用的 token 值
- `kubelet.conf`
    ```
    KUBELET_OPTS="--logtostderr=false \
    --v=2 \
    --log-dir=/opt/kubernetes/logs \
    --hostname-override=k8s-node1 \
    --network-plugin=cni \
    --kubeconfig=/opt/kubernetes/cfg/kubelet.kubeconfig \
    --bootstrap-kubeconfig=/opt/kubernetes/cfg/bootstrap.kubeconfig \
    --config=/opt/kubernetes/cfg/kubelet-config.yml \
    --cert-dir=/opt/kubernetes/ssl \
    --pod-infra-container-image=lizhenliang/pause-amd64:3.0"
    ```
    - hostname-override 要填写当前 node 所在机器的 hostname
- `kubelet-config.yml`
    ```
    kind: KubeletConfiguration
    apiVersion: kubelet.config.k8s.io/v1beta1
    address: 0.0.0.0
    port: 10250
    readOnlyPort: 10255
    cgroupDriver: cgroupfs
    clusterDNS:
    - 10.0.0.2
    clusterDomain: cluster.local
    failSwapOn: false
    authentication:
      anonymous:
        enabled: false
      webhook:
        cacheTTL: 2m0s
        enabled: true
      x509:
        clientCAFile: /opt/kubernetes/ssl/ca.pem
    authorization:
      mode: Webhook
      webhook:
        cacheAuthorizedTTL: 5m0s
        cacheUnauthorizedTTL: 30s
    evictionHard:
      imagefs.available: 15%
      memory.available: 100Mi
      nodefs.available: 10%
      nodefs.inodesFree: 5%
    maxOpenFiles: 1000000
    maxPods: 110
    ```
- `kube-proxy.conf`
    ```
    KUBE_PROXY_OPTS="--logtostderr=false \
    --v=2 \
    --log-dir=/opt/kubernetes/logs \
    --config=/opt/kubernetes/cfg/kube-proxy-config.yml"
    ```
- `kube-proxy-config.yml`
    ```
    kind: KubeProxyConfiguration
    apiVersion: kubeproxy.config.k8s.io/v1alpha1
    address: 0.0.0.0
    metricsBindAddress: 0.0.0.0:10249
    clientConnection:
      kubeconfig: /opt/kubernetes/cfg/kube-proxy.kubeconfig
    hostnameOverride: k8s-node1
    clusterCIDR: 10.0.0.0/24
    mode: ipvs
    ipvs:
      scheduler: "rr"
    iptables:
      masqueradeAll: true
    ```
    - hostnameOverride 要填写当前 node 所在机器的 hostname
- `kube-proxy.kubeconfig`
    ```
    apiVersion: v1
    clusters:
    - cluster:
        certificate-authority: /opt/kubernetes/ssl/ca.pem
        server: https://192.168.1.11:6443
      name: kubernetes
    contexts:
    - context:
        cluster: kubernetes
        user: kube-proxy
      name: default
    current-context: default
    kind: Config
    preferences: {}
    users:
    - name: kube-proxy
      user:
        client-certificate: /opt/kubernetes/ssl/kube-proxy.pem
        client-key: /opt/kubernetes/ssl/kube-proxy-key.pem
    ```

__在 Master 上将 kubelet-bootstrap 用户绑定到系统群集角色__
- node 节点上的 kubelet-bootstrap 并没有权限创建证书。所以要创建这个用户的权限并绑定到这个角色上 
    ```
    kubectl create clusterrolebinding kubelet-bootstrap \
    --clusterrole=system:node-bootstrapper \
    --user=kubelet-bootstrap
    ```

__将 kubelet , kube-proxy 作为 service 使用 systemctl 来管理__
- 将文件 [kubelet.service](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/%E6%89%80%E9%9C%80%E8%A6%81%E7%9A%84%E6%96%87%E4%BB%B6/kubelet.service) , [kube-proxy.service](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/%E6%89%80%E9%9C%80%E8%A6%81%E7%9A%84%E6%96%87%E4%BB%B6/kube-proxy.service) 放入 /usr/lib/systemd/system/ 路径下
- 更新 service 并启动 kubelet , kube-proxy
    ```
    systemctl daemon-reload -a
    systemctl start kubelet , kube-proxy
    ```

__在 Master 上注册两个 node__
- 在 master 上查看是否有请求的注册
    ```
    kubectl get csr
    ```
- 如果两个 node 都部署成功 kubernetes 的话会有两个 kubelet-bootstrap 请求
- 颁发证书（ name 自行替换）
    ```
    kubectl certificate approve node-csr-MYUxbmf_nmPQjmH3LkbZRL2uTO-_FCzDQUoUfTy7YjI
    ```
- 颁发完成后只需要稍等一会就可以看到 node 以 NotReady 的状态注册到 Master 上
    ```
    kubectl get node
    ```

__查看 node 因注册生成的证书和配置文件__
- 在 /opt/kubernetes/ssl/ 下生成 kubelet 证书
    - kubelet-client-current.pem
    - kubelet.crt
    - kubelet.key
- 在 /opt/kubernetes/cfg/ 下生成 kubelet.kubeconfig 配置文件
    ```
    apiVersion: v1
    clusters:
    - cluster:
        certificate-authority: /opt/kubernetes/ssl/ca.pem
        server: https://192.168.1.11:6443
      name: default-cluster
    contexts:
    - context:
        cluster: default-cluster
        namespace: default
        user: default-auth
      name: default-context
    current-context: default-context
    kind: Config
    preferences: {}
    users:
    - name: default-auth
      user:
        client-certificate: /opt/kubernetes/ssl/kubelet-client-current.pem
        client-key: /opt/kubernetes/ssl/kubelet-client-current.pem
    ```