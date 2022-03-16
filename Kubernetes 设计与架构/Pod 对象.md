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
### Secret [官方文档](https://kubernetes.io/zh/docs/concepts/configuration/secret/)
1. 将数据使用 Base64 转码
    ```bash
    [root@jump ~]# echo -n 'admin' | base64
    YWRtaW4=
    [root@jump ~]# echo -n '1f2d1e2e67df' | base64
    MWYyZDFlMmU2N2Rm
    ```
2. 创建 Secret 对象
    ```yaml
    apiVersion: v1
    kind: Secret
    metadata:
      name: mysecret
    type: Opaque
    data:
      username: YWRtaW4=
      password: MWYyZDFlMmU2N2Rm
    ```
3. 将 Secret 对象以 Volume 方式挂载到 Pod 对象中
    ```yaml
    apiVersion: v1
    kind: Pod
    metadata:
      name: mypod
    spec:
      containers:
      - name: mypod
        image: redis
        volumeMounts:
        - name: foo
          mountPath: "/etc/foo"
          readOnly: true
      volumes:
      - name: foo
        secret:
          secretName: mysecret
    ```
4. 也可以通过变量的方式挂载，但是在 secret 对象内容修改后生成的变量不会修改
    ```yaml
    apiVersion: v1
    kind: Pod
    metadata:
      name: secret-demo-pod
    spec:
      containers:
        - name: demo
          image: nginx
          env:
            - name: USER
              valueFrom:
                secretKeyRef:
                  name: mysecret
                  key: username
            - name: PASS
              valueFrom:
                secretKeyRef:
                  name: mysecret
                  key: password
          volumeMounts:
          - name: config
            mountPath: "/config"
            readOnly: true
      volumes:
        - name: config
          secret:
            secretName: mysecret
    ```
### ConfigMap [官方文档](https://kubernetes.io/zh/docs/concepts/configuration/configmap/)
1. 创建 ConfigMap 对象资源
    ```yaml
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: game-demo
    data:
      # 类属性键；每一个键都映射到一个简单的值
      player_initial_lives: "3"
      ui_properties_file_name: "user-interface.properties"

      # 类文件键
      game.properties: |
        enemy.types=aliens,monsters
        player.maximum-lives=5    
      user-interface.properties: |
        color.good=purple
        color.bad=yellow
        allow.textmode=true
    ```
2. 将 ConfigMap 对象以变量方式挂载到 Pod 对象中
    ```yaml
    apiVersion: v1
    kind: Pod
    metadata:
      name: configmap-demo-pod
    spec:
      containers:
        - name: demo
          image: alpine
          command: ["sleep", "3600"]
          env:
            # 定义环境变量
            - name: PLAYER_INITIAL_LIVES # 请注意这里和 ConfigMap 中的键名是不一样的
              valueFrom:
                configMapKeyRef:
                  name: game-demo           # 这个值来自 ConfigMap
                  key: player_initial_lives # 需要取值的键
            - name: UI_PROPERTIES_FILE_NAME
              valueFrom:
                configMapKeyRef:
                  name: game-demo
                  key: ui_properties_file_name
          volumeMounts:
          - name: config
            mountPath: "/config"
            readOnly: true
      volumes:
        # 你可以在 Pod 级别设置卷，然后将其挂载到 Pod 内的容器中
        - name: config
          configMap:
            # 提供你想要挂载的 ConfigMap 的名字
            name: game-demo
            # 来自 ConfigMap 的一组键，将被创建为文件
            items:
            - key: "game.properties"
              path: "game.properties"
            - key: "user-interface.properties"
              path: "user-interface.properties"
### Downward API [官方文档](https://kubernetes.io/zh/docs/tasks/inject-data-application/downward-api-volume-expose-pod-information/)
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: kubernetes-downwardapi-volume-example
  labels:
    zone: us-est-coast
    cluster: test-cluster1
    rack: rack-22
  annotations:
    build: two
    builder: john-doe
spec:
  containers:
    - name: client-container
      image: k8s.gcr.io/busybox
      command: ["sh", "-c"]
      args:
      - while true; do
          if [[ -e /etc/podinfo/labels ]]; then
            echo -en '\n\n'; cat /etc/podinfo/labels; fi;
          if [[ -e /etc/podinfo/annotations ]]; then
            echo -en '\n\n'; cat /etc/podinfo/annotations; fi;
          sleep 5;
        done;
      volumeMounts:
        - name: podinfo
          mountPath: /etc/podinfo
  volumes:
    - name: podinfo
      downwardAPI:
        items:
          - path: "labels"
            fieldRef:
              fieldPath: metadata.labels
          - path: "annotations"
            fieldRef:
              fieldPath: metadata.annotations
```
- 通过这样的声明方式，当前 Pod 的 Lables 字段的值就会被 Kubernetes 自动挂载成为容器里的 /etc/podinfo/labels 文件
- 目前， Downward API 支持的字段已经非常丰富了，详细请参考官方文档：[Downward API 的能力](https://kubernetes.io/zh/docs/tasks/inject-data-application/downward-api-volume-expose-pod-information/#downward-api-%E7%9A%84%E8%83%BD%E5%8A%9B)
- Downward API 获得的一定是用户容器启动前就确定下来的信息

__Projected Volume 对象可以通过设置环境变量来获取，但是会失去自动更新的能力，一般情况下建议使用 Volume 文件挂载获取__

### ServiceAccountToken 
- Service Account 对象是 kubernetes 进行权限分配的对象，其授权信息和文件被绑定在特殊的 Secret 对象：ServiceAccountToken 中。
- 如果任意查看一个在 kubernetes 集群中运行的 Pod，就会发现每一个 Pod 都已经自动声明了一个类型是 Secret 、名为 default-token-xxxxxx 的 Volume 自动挂载在每个容器的固定目录上。这是 kubernetes 在每个 pod 创建的时候自动在 sepc.volumes 部分添加了 ServiceAccountToken 的定义，然后自动给每个容器加上了对应的 volumeMounts 字段。
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

只要 Pod 的 restartPolicy 指定的策略允许重启异常的容器，那么这个 Pod 就会保持 Running 状态并重启容器而不会进入 Faild 状态。而对于包含多个容器的 Pod 来说，只有所有的容器均进入异常状态 Pod 才会显示 Faild 状态，在此之前由 READY 字段显示正常容器个数。

### Pod 字段预设
使用 PodPreset 对象预先定义好 Pod 对象中追加的字段
```yaml
apiVersion: settings.k8s.io/v1alpha1
kind: PodPreset
metadata:
  name: allow-database
spec:
  selector: # 使用 selector 定义作用于指定标签 role: frontend 的 Pod 对象
    matchLabels:
      role: frontend
  env:
    - name: DB_PORT
      value: "6379"
  volumeMounts:
    - mountPath: /cache
      name: cache-volume
  volumes:
    - name: cache-volume
      emptyDir: {}
```
定义一个带有标签 role: frontend 的 Pod 对象
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: website
  labels:
    app: website
    role: frontend
spec:
  containers:
    - name: website
      image: nginx
      ports:
        - containerPort: 80
```
查看被准入控制器更改过的 Pod 规约，以了解 PodPreset 在 Pod 上执行过的操作
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: website
  labels:
    app: website
    role: frontend
  annotations:
    podpreset.admission.kubernetes.io/podpreset-allow-database: "resource version"
spec:
  containers:
    - name: website
      image: nginx
      volumeMounts:
        - mountPath: /cache
          name: cache-volume
      ports:
        - containerPort: 80
      env:
        - name: DB_PORT
          value: "6379"
  volumes:
    - name: cache-volume
      emptyDir: {}
```