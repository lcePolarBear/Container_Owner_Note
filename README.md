# Kubernetes_Basic_Config_Note
容器编排引擎 k8s 的基础配置备忘录 

__[Kubernetes 理论基础](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/k8s%20理论基础.md)__

__系统初始化__
1. [关闭防火墙和 selinux](https://github.com/lcePolarBear/Linux_Basic_Note/blob/master/Linux%20%E7%B3%BB%E7%BB%9F%E5%92%8C%E5%B8%B8%E7%94%A8%E6%8C%87%E4%BB%A4/%E7%A6%81%E7%94%A8%E9%98%B2%E7%81%AB%E5%A2%99%E5%92%8C%20selinux.md)
2. 关闭 swap
    ```
    swapoff -a #临时
    vi /etc/fstab 注释 swap 那一行 #永久
    ```
3. 添加 hosts
    - `vi /etc/hosts`
        ```
        192.168.1.11 k8s-master1
        192.168.1.12 k8s-node1
        192.168.1.13 k8s-node2
        ```
4. 同步系统时间
    ```
    ntpdate time.windows.com
    ```

__部署流程分步示例__
- [部署 etcd 存储](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/部署过程/部署%20etcd%20群集.md)
- [部署 Flannel 网络](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/部署过程/部署%20Flannel%20网络.md)
- [部署 Master 节点组件：kube-apiserver | kube-controller-manager | kube-scheduler](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/部署过程/部署%20Master%20节点组件.md)
- [部署 Node 节点组件：kubelet | kube-proxy](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/部署过程/部署%20Node%20节点组件.md)

