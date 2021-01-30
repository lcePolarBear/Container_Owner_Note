## Pod 对象及其管理

__Pod 的基本概念__
- Pod 是 kubernetes 创建和管理的最小单元，一个 pod 由一个或多个容器组成，容器间共享存储、网络
- 特性
    - 一个 Pod 可以理解为是一个应用实例，提供服务
    - Pod 中容器始终部署在一个 Node 上
    - Pod 中容器共享网络、存储资源
    - Kubernetes 直接管理 Pod ，而不是容器
- 存在的意义
    - 运行单个容器，在此环境下 pod = 容器
    - 运行多个容器，在此环境下就体现了 pod 的价值
        - 两个应用之间发生文件交互
        - 两个应用需要通过 127.0.0.1 或者 socket 通信
        - 两个应用需要发生频繁的调用
- 容器分类
  - `Infrastructure Container` : 基础容器，维护整个 Pod 网络空间
  - `InitContainers` : 初始化容器，先于业务容器开始执行
  - `Containers` : 业务容器，并行启动

__Pod 常用管理命令__
- 创建 Pod
    ```
    kubectl apply -f pod.yaml
    ```
    - 或者使用命令
      ```
      kubectl run nginx --image=nginx
      ```
- 查看Pod
    ```
    kubectl get pods
    kubectl describe pod <Pod名称>
    ```
- 查看日志
    ```
    kubectl logs <Pod名称> [-c CONTAINER]
    kubectl logs <Pod名称> [-c CONTAINER] -f
    ```
- 进入容器终端
    ```
    kubectl exec <Pod名称> [-c CONTAINER] -- bash
    ```
- 删除 Pod
  ```
  kubectl delete <Pod名称>
  ```

__实现 Pod 自重启和健康检查__
- Pod 重启策略
    - `Always` : 当容器终止退出后，总是重启容器（默认策略）
    - `OnFailure` : 当容器异常退出（退出状态码非 0 ）时才重启容器
    - `Never` : 当容器终止退出，从不重启容器
- Pod 健康检查
    - `livenessProbe` : 存活检查，如果检查失败，将杀死容器，根据 Pod 的 restartPolicy 来操作
    - `readinessProbe` : 就绪检查，如果检查失败， Kubernetes 会把 Pod 从 service 中剔除
    - `startupProbe` : 启动检查，不常用
- Pod 检查方式
    - `httpGet` : 发送 HTTP 请求，返回 200-400 范围状态码为成功
    - `exec` : 执行 Shell 命令返回状态码是 0 为成功
    - `tcpSocket` : 发起 TCP Socket 建立成功
- 重启与健康检查示例
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
        readinessProbe:
          exec:
            command:
            - cat
            - /tmp/healthy
          initialDelaySeconds: 5
          periodSeconds: 5
    ```
    - 使用 `livenessProbe` 通过 exec 来检查 /tmp/healthy 文件是否存在
        - exec 执行成功（找到 /tmp/healthy 文件）则会返回 0 ，如果返回非零则会触发默认的 Always 重启策略
        - `initialDelaySeconds` : 启动容器开始健康检查的等待秒数
        - `periodSeconds` : 健康检查的间隔秒数
    - 使用 `readinessProbe` 通过 exec 来检查 /tmp/healthy 文件是否存在
        - exec 执行成功则会返回 0 ，如果返回非零，Kubernetes 从 service 将此 Pod 剔除

__Init container__
- 特性
    - 基本支持所有普通容器特征
    - 优先普通容器执行
- 应用场景
    - 控制普通容器启动，初始容器完成后才会启动业务容器
    - 初始化配置，例如下载应用配置文件、注册信息等
- 示例：在 nginx 启动之前把百度的页面下载下来发布到 nginx
    ```yaml
    apiVersion: v1
    kind: Pod
    metadata:
      name: init-demo
    spec:
      initContainers:
      - name: download
        image: busybox
        command:
        - wget
        - "-O"
        - "/opt/index.html"
        - http://www.baidu.com
        volumeMounts:
        - name: wwwroot
          mountPath: "/opt"
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
        volumeMounts:
        - name: wwwroot
          mountPath: /usr/share/nginx/html
      volumes:
      - name: wwwroot
        emptyDir: {}
    ```

__静态 Pod__
> 以 kubeadm 方式安装的 k8s 组件除了 kubelet 以外都是静态 Pod
- 特性
    - Pod 由特定节点上的 kubelet 管理
    - 不能使用控制器
    - Pod 名称标识当前节点名称
- 在 kubelet 配置文件启用静态 Pod
    - vi /var/lib/kubelet/config.yaml
        ```yaml
        staticPodPath: /etc/kubernetes/manifests
        ```
- 将部署的 pod yaml 放到该目录会由 kubelet 自动创建

__Pod 资源共享机制__
- 共享网络的实现：将业务容器网络加入到负责网络的容器实现网络共享
- 创建共享网络 pod 的 yaml 文件示例
    ```yaml
    apiVersion: v1
    kind: Pod
    metadata:
      labels:
        app: test
      name: pod-net-test 
      namespace: default
    spec:
      containers:
      - image: busybox 
        name: test
        command: ["/bin/sh","-c","sleep 360000"]
      - image: nginx
        name: web
    ```
- 共享存储的实现：容器通过数据卷共享数据
- 创建共享存储 Pod 的 yaml 文件示例
    ```yaml
    apiVersion: v1
    kind: Pod
    metadata:
      labels:
        app: test
      name: pod-volume-test 
      namespace: default
    spec:
      containers:
      - image: busybox 
        name: test
        command: ["/bin/sh","-c","sleep 360000"]
        volumeMounts:
        - name: log
          mountPath: /data
      - image: nginx
        name: web
        volumeMounts:
        - name: log
          mountPath: /data
      volumes:
      - name: log
        emptyDir: {}
    ```

__在 Pod 中注入环境变量__
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-envars
spec:
  containers:
    - name: test
      image: busybox
      command: [ "sh", "-c", "sleep 36000"]
      env:
        - name: MY_NODE_NAME
          valueFrom:
            fieldRef:
              fieldPath: spec.nodeName
        - name: MY_POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: MY_POD_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        - name: MY_POD_IP
          valueFrom:
            fieldRef:
              fieldPath: status.podIP
        - name: ABC
          value: "123456"
        - name: HELLO
          value: "hello k8s"
```