## Kubernetes 的监控和日志

__查看资源群集状态__
- 查看 master 组件状态
    ```
    kubectl get cs
    ```
- 查看 node 状态
    ```
    kubectl get node
    ```
- 查看资源信息
    ```
    kubectl describe pod nginx
    kubectl get pod nginx --watch
    ```

__监控群集资源利用率__
- [Metric Server](https://github.com/kubernetes-sigs/metrics-server)
    - Metrics Server 是一个集群范围的资源使用情况的数据聚合器，作为一个应用部署在集群中
    - Metric server 从每个节点上 Kubelet API 收集指标，通过 Kubernetes 聚合器注册在 Master APIServer 中
- Metric Server 的部署
    - 获取 [components.yaml 文件])()
        - 修改 image 拉取的地址
        - 忽略证书认证 `--kubelet-insecure-tls`
        - 使用节点 IP 连接 kubelet `--kubelet-preferred-address-types=InternalIP`
    - 部署
        ```
        kubectl apply -f components.yaml
        ```
    - 查看资源消耗
        ```
        kubectl top node k8s-node1
        kubectl top pod nginx
        ```