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

__管理 k8s 日志__
- 管理组件日志
    - systemd 守护进程管理的组件
        ```
        journalctl -u kubelet > out.log
        ```
    - Pod 部署的组件
        ```
        kubectl logs kube-proxy-btz4p -n kube-system
        ```
    - 系统日志
        ```
        /var/log/messages
        ```
- 管理应用程序日志
    - 查看应用程序日志
        ```
        kubectl logs -f nginx
        ```
    - 使用 emptyDir 数据卷将日志文件持久化到宿主机
        ```
        /var/lib/kubelet/pods/<pod-id>/volumes/kubernetes.io~empty-dir/logs/access.log
        ```
    - 在部署容器时同时部署一个 busybox 容器（边车容器）来映射日志
        ```yaml
        spec:
          containers:
          - name: web         # 业务容器
            image: lizhenliang/nginx-php
            volumeMounts:
            - name: logs
              mountPath: /usr/lcoal/nginx/logs
          - name: web-logs    # 日志采集容器
            image: busybox
            args: [/bin/sh, -c, 'tail -f /opt/access.log']
            volumeMount:
            - name: logs
              mountPath: /opt
          volumes:
          - name: logs
            emptyDir: {}
        ```