## Pod 对象及其管理

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