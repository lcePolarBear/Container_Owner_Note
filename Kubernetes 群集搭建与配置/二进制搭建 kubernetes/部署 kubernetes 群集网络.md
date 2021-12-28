## 部署 kubernetes 群集网络

__在 Node 部署 CNI 网络__
- 获取 [CNI 二进制文件](https://github.com/containernetworking/plugins/releases/download/v0.8.2/cni-plugins-linux-amd64-v0.8.2.tgz)
- 创建 CNI 工作目录
    ```
    mkdir /opt/cni/bin /etc/cni/net.d -p
    ```
- 将二进制执行文件解压到工作目录下
    ```
    tar -zxf cni-plugins-linux-amd64-v0.8.2.tgz -C /opt/cni/bin
    ```
- 确保 kubelet.conf 配置文件中的 network-plugin 参数设置为 cni

__在 Master 部署 flannel 网络__
- 创建配置文件 [kube-flannel.yaml](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/%E6%89%80%E9%9C%80%E8%A6%81%E7%9A%84%E6%96%87%E4%BB%B6/kube-flannel.yaml)
- 创建 flannel 网络
    ```
    kubectl apply -f kube-flannel.yaml
    ```
    - 这里实际上是拉取了一个 lizhenliang/flannel:v0.11.0-amd64 的镜像部署在 node 的 docker 上从而实现部署 flannel 网络
    - 可以在 docker 上提前拉取进而节省部署时间
- 查看创建状态
    ```
    kubectl get pods -n kube-system -o wide
    ```
- 使 apiserver 连接到 kubelet 以获取日志
    - 创建配置文件 [apiserver-to-kubelet-rbac.yaml](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/%E6%89%80%E9%9C%80%E8%A6%81%E7%9A%84%E6%96%87%E4%BB%B6/apiserver-to-kubelet-rbac.yaml)
    - 创建链接
        ```
        kubectl apply -f apiserver-to-kubelet-rbac.yaml
        ```
    - 查看日志
        ```
        kubectl logs kube-flannel-ds-amd64-b2mbn -n kube-system
        ```

__尝试部署 nginx__
- 部署 nginx 容器
    ```
    kubectl create deployment web --image=nginx
    ```
- 查看部署状态
    ```
    kubectl get pods -o wide
    ```
- 向容器外暴露端口
    ```
    kubectl expose deployment web --port=80 --type=NodePort
    ```
- 查看暴露的端口
    ```
    kubectl get pods,svc
    ```
- 如果两个 node 的 ip 地址指定端口都可以访问到 nginx 则表示群集搭建的是没有问题的