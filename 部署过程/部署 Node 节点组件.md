## 部署 Node 节点组件

__将 kubelet 和 kube-proxy 放入 /opt/kubernetes/bin 下__

    - 

__配置 [kubelet.sh](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/config-files/kubelet.sh) 文件__

执行 ./kubelet.sh
在 /opt/kubernetes/cfg 有配置文件

__配置 [proxy.sh](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/config-files/proxy.sh) 文件并执行执行__

- /opt/kubernetes/bin/kubectl get csr #查看请求证书的节点
    - CONDITION 为 Pending（不允许）
    - /opt/kubernetes/bin/kubectl certificate approve NAME 同意自签证书
- /opt/kubernetes/bin/kubectl get node #查看节点