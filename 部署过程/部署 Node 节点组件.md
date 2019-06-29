## 部署 Node 节点组件

__准备工作__
- 在 Master 上将 kubelet-bootstrap 用户绑定到系统群集角色
    >node 节点上的 kubelet-bootstrap 并没有权限创建证书。所以要创建这个用户的权限并绑定到这个角色上 
    ```
    kubectl create clusterrolebinding kubelet-bootstrap --clusterrole=system:nodebootstrapper --user=kubelet-bootstrap
    ```
- 在 Master 上使用 [kubeconfig.sh](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/config-files/kubeconfig.sh) 脚本生成 bootstrap.kubeconfig 和 kube-proxy.kubeconfig
    ```
    ./kubeconfig.sh 192.168.10.110 /opt/kubernetes/ssl/
    ```
    - 将 kubelet 和 kube-proxy 放入 Node1,Node2 的 /opt/kubernetes/bin 下

__配置 [kubelet.sh](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/config-files/kubelet.sh) 文件__
```
./kubelet.sh 192.168.10.111
```

__配置 [proxy.sh](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/config-files/proxy.sh) 文件并执行执行__
```
./proxy.sh 192.168.10.111
```

- /opt/kubernetes/bin/kubectl get csr #查看请求证书的节点
    - CONDITION 为 Pending（不允许）
    - /opt/kubernetes/bin/kubectl certificate approve NAME 同意自签证书
- /opt/kubernetes/bin/kubectl get node #查看节点