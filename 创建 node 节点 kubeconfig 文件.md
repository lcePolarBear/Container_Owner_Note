## 创建 node 节点 kubeconfig 文件

> kuberconfig 用于 node 节点上 kube-proxy 和 kubelet 与集群进行通信做的认证

__创建 TLS Bootstrapping Token ，让 k8s 集群自动为 kubelet 颁发数字证书__
```
export BOOTSTRAP_TOKEN=$(head -c 16 /dev/urandom | od -An -t x | tr -d ' ')
cat > token.csv <<EOF
${BOOTSTRAP_TOKEN},kubelet-bootstrap,10001,"system:kubelet-bootstrap"
EOF
```
- 分析 token.csv 的内容
    ```
    d9a82c881567307c015b9ebbf1fc7067,kubelet-bootstrap,10001,"system:kubelet-bootstrap"
    ```
    > token 是一个访问权限的认证 kubelet-bootstrap为用户名 system:kubelet-bootstrap是分组 
    
- 作用是让 node 节点使用 token 值使用此用户权限和用户组权限去访问 k8s 集群

__创建一个变量 指定 k8s https 访问入口__
```
export KUBE_APISERVER="https://192.168.10.110:6443"
```

__在 /opt/kubernetes/ssl 路径下使用 [kubectl](https://github.com/kubernetes/kubernetes/releases) 工具，引用上面的变量将 kuber 证书写入 kubeconfig__
```
/opt/kubernetes/bin/kubectl config set-cluster kubernetes \
--certificate-authority=./ca.pem \
--embed-certs=true \
--server=${KUBE_APISERVER} \
--kubeconfig=bootstrap.kubeconfig
```
__设置客户端认证参数 即设置证书信息__
```
/opt/kubernetes/bin/kubectl config set-credentials kubelet-bootstrap \
--token=${BOOTSTRAP_TOKEN} \
--kubeconfig=bootstrap.kubeconfig
```
__设置上下文参数__
```
/opt/kubernetes/bin/kubectl config set-context default \
--cluster=kubernetes \
--user=kubelet-bootstrap \
--kubeconfig=bootstrap.kubeconfig
```
__设置默认上下文__
```
/opt/kubernetes/bin/kubectl config use-context default --kubeconfig=bootstrap.kubeconfig
```
> 这个 bootstrap 是 kubelet 生成证书用的

__创建 kube-proxy kubeconfig文件__
```
/opt/kubernetes/bin/kubectl config set-cluster kubernetes \
--certificate-authority=./ca.pem \
--embed-certs=true \
--server=${KUBE_APISERVER} \
--kubeconfig=proxy.kubeconfig

/opt/kubernetes/bin/kubectl config set-credentials kube-proxy \
--client-certificate=./kube-proxy.pem \
--client-key=./kube-proxy-key.pem \
--embed-certs=true \
--kubeconfig=kube-proxy.kubeconfig

/opt/kubernetes/bin/kubectl config set-context default \
--cluster=kubernetes \
--user=kube-proxy \
--kubeconfig=kube-proxy.kubeconfig

/opt/kubernetes/bin/kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig
```

__生成的 bootstrap.kubeconfig 和 kube-proxy.kubeconfig 之后会用到__