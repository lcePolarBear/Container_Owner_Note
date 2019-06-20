## 部署 Master 节点组件

__部署所需要的执行文件和 token__
- 下载并解压 [kubernetes-server](https://github.com/kubernetes/kubernetes/releases)

- 将 kube-apiserver kube-controller-manager kube-scheduler 放入 /opt/kubernetes/bin/ 下

- 将token.csv 放入 /opt/kubernetes/cfg/

__通过 shell 脚本创建服务与配置文件__
- kubernetes 自带脚本路径 ~/kubernetes/cluster/centos/master/scripts/

- 配置 [apiserver.sh](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/config-files/apiserver.sh) 脚本并执行    
    ```
    ./apiserver.sh 192.168.10.110 https://192.168.10.110:2379,https://192.168.10.141:2379,https://192.168.10.145:2379
    ```

    - 启动 kube-apiserver

        ```
        systemctl start kube-apiserver
        ```
- 配置 [controller-manager.sh](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/config-files/controller-manager.sh) 脚本并执行
    ```
    ./controller-manager
    ```
    - 启动 kube-controller-manager

        ```
        systemctl start kube-controller-manager
        ```
- 配置 [scheduler.sh](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/config-files/scheduler.sh) 脚本并执行
    ```
    ./scheduler.sh
    ```
    - 启动 kube-scheduler

        ```
        systemctl start kube-scheduler
        ```
- 以上会在 /opt/kubernetes/cfg/ 下生成对应各服务的配置文件

__确保 etcd 正常的情况下可以检查群集是否正常__
```
/opt/kubernetes/bin/kubectl get cs
```