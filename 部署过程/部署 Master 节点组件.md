## 部署 Master 节点组件

__部署所需要的执行文件和 token__

- 将 /root/kubernetes/server/bin 路径下的 kube-apiserver | kube-controller-manager | kube-scheduler 放入 /opt/kubernetes/bin/ 下

- 将token.csv 放入 /opt/kubernetes/cfg/

__通过 shell 脚本创建服务与配置文件__

- 配置 [apiserver.sh](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/config-files/apiserver.sh) 脚本并执行    
    ```
    ./apiserver.sh 192.168.10.110 https://192.168.10.110:2379,https://192.168.10.111:2379,https://192.168.10.112:2379
    ```
- 配置 [controller-manager.sh](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/config-files/controller-manager.sh) 脚本并执行
    ```
    ./controller-manager 127.0.0.1
    ```
- 配置 [scheduler.sh](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/config-files/scheduler.sh) 脚本并执行
    ```
    ./scheduler.sh 127.0.0.1
    ```
- 用 journalctl -u 命令可以查看启动失败的错误提示

- 以上会在 /opt/kubernetes/cfg/ 下生成对应各服务的配置文件

__确保 etcd 正常的情况下可以检查群集是否正常__
```
kubectl get cs
<<<<<<< HEAD
```

__将 kubelet-bootstrap 用户绑定到系统群集角色__
>node 节点上的 kubelet-bootstrap 并没有权限创建证书。所以要创建这个用户的权限并绑定到这个角色上 
```
kubectl create clusterrolebinding kubelet-bootstrap --clusterrole=system:nodebootstrapper --user=kubelet-bootstrap
=======
>>>>>>> aedb5fc649cf7b84a37c94e4b1d12406bc910606
```