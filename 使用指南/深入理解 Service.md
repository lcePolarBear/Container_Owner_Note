## 深入理解 Service

__Pod 与 Service 的关系__
- Service通过标签关联一组Pod
- Service使用iptables或者ipvs为一组Pod提供负载均衡能力

__Service 定义与创建__
- 使用 yaml 文件创建 service
    ```
    apiVersion: v1
    kind: Service
    metadata:
      name: web
      namespace: default
    spec:
      type: ClusterIP  # 服务类型
      ports:
      - port: 80       # service端口
        protocol: TCP  # 协议
        targetPort: 80 # 容器端口
      selector:        # 标签选择器
        app: nginx     # 指定关联Pod的标签
    ```

__Service 的服务类型__
- ClusterIP : 集群内部使用
- NodePort : 对外暴露应用（集群外）
    - 在每个节点上启用一个端口来暴露服务，可以在集群
外部访问。也会分配一个稳定内部集群 IP 地址
- LoadBalancer : 对外暴露应用，适用公有云
    - 与NodePort类似，在每个节点上启用一个端口来暴
露服务。除此之外， Kubernetes 会请求底层云平台（例如阿里云、腾
讯云、 AWS 等）上的负载均衡器，将每个 Node 作为后端添加进去

__Service 代理模式__
- Iptables VS IPVS
    - Iptables：
        - 灵活，功能强大
        - 规则遍历匹配和更新，呈线性时延
    - IPVS：
        - 工作在内核态，有更好的性能
        - 调度算法丰富：rr , wrr , lc , wlc , ip hash...
- 二进制方式修改 ipvs 模式
    - `kube-proxy-config.yml`
        ```
        mode: ipvs
        ipvs:
          scheduler: "rr"
        ```
    - ```
      systemctl restart kube-proxy
      ```
- 流程包流程
    - 客户端 -> NodePort/ClusterIP （ iptables/Ipvs负载均衡规则 ） -> 分布在各节点 Pod
- 查看负载均衡规则
    - iptables模式
        - ```
          iptables-save | grep <SERVICE-NAME>
          ```
    - ipvs模式
        - ```
          ipvsadm -L -n
          ```