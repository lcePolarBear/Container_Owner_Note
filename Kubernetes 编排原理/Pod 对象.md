# Pod 对象
Pod 是 kubernetes 创建和管理的原子调度单位（而不是容器），一个 pod 由一个或多个容器组成，容器间共享存储、网络。  
### 容器分类
- `Infrastructure Container` : 基础容器，维护整个 Pod 网络空间
- `InitContainers` : 初始化容器，先于业务容器开始执行
- `Containers` : 业务容器，并行启动
### 为了以对等关系而不是拓扑关系描述容器之间的“超亲密关系”
1. Pod 会先用 Infrastructure 容器 "hold" Network Namespace ，后让用户容器加入其中。这样， Pod 内部容器就可以共享网络设备，共用 localhost
2. kubernetes 项目将所有 Volume 的定义都设计在 Pod 层面以保证 Pod 内部容器共享宿主机目录

_通过 Pod 这种“超亲密关系”容器的设计思想可以方便的解决 Web 服务器和 WAR 包的解耦问题，也诞生了通过 sidecar 容器对工作容器进行日志收集、网络配置的管理方式，比如 Istio 。_

Pod 其实可以理解为一个虚拟机，而容器镜像可以理解为在虚拟机中运行的进程，把有顺序关系的容器定义为 Init Container 。凡是调度、存储、网络，以及相关安全的属性，基本上是属于 Pod 级别而不是 Container 级别。
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
### 容器健康检查和恢复机制
在 kubernetes 中，可以为 Pod 里的容器定义一个健康检查“探针”（ Probe ）。这样， kubelet 就会根据 Probe 的返回值决定这个容器的状态，而不是直接以容器是否运行（来自 Docker 返回的信息）作为依据。
```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    test: liveness
  name: pod-check 
spec:
  containers:
  - name: liveness
    image: busybox
    args:
    - /bin/sh
    - -c
    - touch /tmp/healthy; sleep 30; rm -rf /tmp/healthy; sleep 600
    livenessProbe:
      exec:
        command:
        - cat
        - /tmp/healthy
      initialDelaySeconds: 5
      periodSeconds: 5
```
以上创建的 Pod 资源会在 /tmp 路径下创建 healthy 文件并在 30 秒后删除。我们定义了一个 livenessProbe （健康检查）。他的类型是 exec ，这意味着它会在容器启动 5 秒钟后（ initialDelaySeconds: 5 ）执行 cat /tmp/healthy 命令，每 5 秒钟执行一次（ periodSeconds: 5 ），如文件存在则返回 0 ， Pod 会认为这个容器不但已经启动且健康。

Pod 健康检查
- `livenessProbe` : 存活检查，如果检查失败，将杀死容器，根据 Pod 的 restartPolicy 来操作
- `readinessProbe` : 就绪检查，如果检查失败， Kubernetes 会把 Pod 从 service 中剔除
- `startupProbe` : 启动检查，不常用

Pod 检查方式
- `httpGet` : 发送 HTTP 请求，返回 200-400 范围状态码为成功
- `exec` : 执行 Shell 命令返回状态码是 0 为成功
- `tcpSocket` : 发起 TCP Socket 建立成功

有意思的是，不健康的容器不会直接处于 Faild 状态，而是被重启了，这就是 kubernetes 里的 Pod 重启策略。

Pod 的 spec 中包含一个 restartPolicy 字段，其可能取值包括 Always、OnFailure 和 Never。默认值是 Always。
- `Always` : 当容器终止退出后，总是重启容器（默认策略）
- `OnFailure` : 当容器异常退出（退出状态码非 0 ）时才重启容器
- `Never` : 当容器终止退出，从不重启容器
只要