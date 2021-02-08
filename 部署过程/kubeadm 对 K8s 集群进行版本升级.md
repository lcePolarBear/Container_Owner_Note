## kubeadm 对 K8s 集群进行版本升级
_提示 : 最好落后最新版本一到两个版本_

__升级流程__
- 先备份所有组件，例如 etcd
- 升级管理节点 -> 升级其他管理节点 -> 升级工作节点

__升级管理节点__
1. 查找最新版本号
    ```shell
    yum list --showduplicates kubeadm --disableexcludes=kubernetes # 禁用除了 kubernetes 之外的其他仓库
    ```
2. 升级 kubeadm
    ```
    yum install -y kubeadm-1.19.3-0 --disableexcludes=kubernetes
    ```
3. 驱逐 node 上的 pod 且不可调度
    ```shell
    kubectl drain k8s-node1 --ignore-daemonsets # 忽略 daemonset
    ```
4. 检查集群是否可以升级，并获取可以升级的版本
    ```
    kubeadm upgrade plan
    ```
5. 执行升级
    ```
    kubeadm upgrade apply v1.19.3
    ```
6. 取消不可调度
    ```
    kubectl uncordon k8s-node1
    ```
7. 升级 kubelet 和 kubectl
    ```
    yum install -y kubelet-1.19.3-0 kubectl-1.19.3-0 --disableexcludes=kubernetes
    ```
8. 重启 kubelet
    ```
    systemctl daemon-reload
    systemctl restart kubelet
    ```

__升级工作版本__
1. 升级 kubeadm
    ```
    yum install -y kubeadm-1.19.3-0 --disableexcludes=kubernetes
    ```
2. 驱逐 node 上 pod 且不可调度
    ```
    kubectl drain k8s-node2 --ignore-daemonsets 
    ```
3. 升级 kubelet 配置
    ```
    kubeadm upgrade node
    ```
4. 升级 kubelet 和 kubectl
    ```
    yum install -y kubelet-1.19.3-0 kubectl-1.19.3-0 --disableexcludes=kubernetes
    ```
5. 重启 kubelet
    ```
    systemctl daemon-reload
    systemctl restart kubelet
    ```
6. 取消不可调度，节点重新上线
    ```
    kubectl uncordon k8s-node2
    ```