## 部署 Node 节点组件

__将 kubelet 和 kube-proxy 放入/bin 下 执行权限__

__配置 [kubelet.sh](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/config-files/kubelet.sh) 文件__

>kubelet-bootstrap并没有权限创建证书。所以要创建这个用户的权限并绑定到这个角色上 命令:
```
kubectl create clusterrolebinding kubelet-bootstrap --clusterrole=system:node-bootstrapper --user=kubelet-bootstrap
```
执行 ./kubelet.sh
在 /opt/kubernetes/cfg 有配置文件

__配置 [proxy.sh](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/config-files/proxy.sh) 文件并执行执行__

- /opt/kubernetes/bin/kubectl get csr #查看请求证书的节点
    - CONDITION 为 Pending（不允许）
    - /opt/kubernetes/bin/kubectl certificate approve NAME 同意自签证书
- /opt/kubernetes/bin/kubectl get node #查看节点