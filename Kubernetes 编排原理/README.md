# Kubernetes 编排原理
## 正确认识 Pod
kubernetes 项目的原子调度单位是 Pod 而不是容器。  
为了以对等关系而不是拓扑关系描述容器之间的“超亲密关系”
1. Pod 会先用 Infra 容器 "hold" Network Namespace ，后让用户容器加入其中。这样， Pod 内部容器就可以共享网络设备，共用 localhost
2. kubernetes 项目将所有 Volume 的定义都设计在 Pod 层面以保证 Pod 内部容器共享宿主机目录

通过 Pod 这种“超亲密关系”容器的设计思想可以方便的解决 Web 服务器和 WAR 包的解耦问题，也诞生了通过 sidecar 容器对工作容器进行日志收集、网络配置的管理方式，比如 Istio 。

Pod 其实可以理解为一个虚拟机，而容器镜像可以理解为在虚拟机中运行的进程，把有顺序关系的容器定义为 Init Container 。
## 深入理解 Pod
首先要清晰：凡是调度、存储、网络，以及相关安全的属性，基本上是属于 Pod 级别而不是 Container 级别。
### Pod 主要字段
- nodeSelector ：用于将 Pod 与 Node 进行绑定
    ```yaml
    apiVersion: v1
    kind: Pod
    spec:
      nodeSelector:       # 限制分配的 node 标签
        disktype: ssd
    ```
    - Pod 只能在携带了 disktype: ssd 标签的节点上运行，否则调度失败
- nodeName ：让 Pod 跳过调度器直接分配到指定的 Node 上
    ```yaml
    apiVersion: v1
    kind: Pod
    spec:
      nodeName: k8s-node1   #指定分配的 Node
    ```
    - Pod 在使用 nodeName 时会跳过调度器，所以污点等影响调度器的配置都不会对此分配起作用
- hostAliases ：定义 Pod 中 hosts 文件的内容
    ```yaml
    apiVersion: v1
    kind: Pod
    spec:
      hostAliases:
      - ip: "127.0.0.1"
        hostnames:
        - "foo.local"
        - "bar.local"
    ```
- shareProcessNamespace ：Pod 中的容器共享 PID Namespace
    ```yaml
    apiVersion: v1
    kind: Pod
    metadata:
      name: nginx
    spec:
      shareProcessNamespace: true
      containers:
      - name: nginx
        image: nginx
      - name: shell
        image: busybox
        stdin: true
        tty: true
    ```
    - Pod 中任意容器使用 `ps ax` 指令就可以看到其他容器的进程
- hostNetwork, hsotIPC, hostPID ：用于共享宿主机的 Network, IPC 和 Namespace
    ```yaml
    apiVersion: v1
    kind: Pod
    metadata:
      name: nginx
    spec:
      hostNetwork: true
      hostIPC: true
      hostPID: true
      containers:
      - name: nginx
        image: nginx
      - name: shell
        image: busybox
        stdin: true
        tty: true
    ```
### Container 主要字段
- imagePullPolicy ：定义镜像拉取的策略 [官方文档](https://kubernetes.io/zh/docs/concepts/containers/images/)
    - Always：总是拉取
    - IfNotPresent：默认值,本地有则使用本地镜像,不拉取
    - Never：只使用本地镜像，从不拉取
- lifecycle ：容器状态变化时触发的事件
    ```yaml
    apiVersion: v1
    kind: Pod
    metadata:
      name: lifecycle-demo
    spec:
      containers:
      - name: lifecycle-demo-container
        image: nginx
        lifecycle:
          postStart:
            exec:
              command: ["/bin/sh", "-c", "echo Hello from the postStart handler > /usr/share/message"]
          preStop:
            exec:
              command: ["/bin/sh","-c","nginx -s quit; while killall -0 nginx; do sleep 1; done"]
    ```
    - postStart ：在容器启动后立即执行的操作
    - preStop ：在容器结束之前阻塞当前容器结束流程，直到 Hook 定义操作完成
### Pod 生命周期的变化 [官方文档](https://kubernetes.io/zh/docs/concepts/workloads/pods/pod-lifecycle/)
- Pending
- Running
- Succeeded
- Failed
- Unknown