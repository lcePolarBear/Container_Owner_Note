## 通过工作负载控制器实现 Pod 的管理

__什么是工作负载控制器__    
- 工作负载控制器 （Workload Controllers) 是 K8s 的一个抽象概念，用于部署和管理 Pod 的更高级层次对象
    - `Deployment` : 无状态应用部署（实例之间无独立数据，所以可以实现负载均衡）
    - `StatefulSet` : 有状态应用部署（实例之间有独立数据，所以无法负载均衡）
    - `DaemonSet` : 确保所有 Node 运行同一个 Pod
    - `Job` : 一次性任务
    - `Cronjob` : 定时任务

__控制器的作用__
- 管理 Pod 对象
- 使用标签与 Pod 关联
- 控制器实现了 Pod 的运维，例如滚动更新、伸缩、副本管理、维护 Pod 状态等

__Deployment 控制器__
- 功能
    - 管理 Pod 和 ReplicaSet
    - 具有上线部署、副本设定、滚动升级、回滚等功能
    - 提供声明式更新，例如只更新一个新的镜像
- 部署
    - 使用 YAML 文件部署镜像
        ```yaml
        apiVersion: apps/v1
        kind: Deployment
        metadata:
          name: web
          namespace: default
        spec:
          replicas: 3
          selector:
            matchLabels:
              app: nginx
          template:
            metadata:
              labels:
                app: nginx
            spec:
              containers:
              - name: web
                image: nginx:1.15
        ```
     - 使用命令行创建镜像
        ```
        kubectl create deployment web --image=nginx:1.15
        ```
- 滚动升级
    > 通过使用新版本 Pod 逐步更新旧版本 Pod ，实现零停机发布，用户无感知
    - 更新镜像的方式
        ```
        kubectl apply -f xxx.yaml
        ```
        ```
        kubectl set image deployment/web nginx=nginx:1.19 --recode
        ```
    - 限制进行滚动更新的 Pod 数量
        ```yaml
        apiVersion: apps/v1
        kind: Deployment
        metadata:
          name: web
          namespace: default
        spec:
          replicas: 3
          revisionHistoryLimit: 10  # RS历史版本保存数量
          selector:
            matchLabels:
              app: nginx
          strategy:
            rollingUpdate:
              maxSurge: 25%         # 滚动更新过程中最大 Pod 副本数
              maxUnavailable: 25%   # 滚动更新过程中最大不可用 Pod 副本数
            type: RollingUpdate
          template:
            metadata:
              labels:
                app: nginx
            spec:
              containers:
              - name: web
                image: nginx:1.16
        ```
    - 查看升级状态
        ```
        kubectl rollout status deployment/web
        ```
- 弹性伸缩
    - 手动扩容
        ```
        kubectl scale deployment web --replicas=10
        ```
    - 自动水平扩容（注意 Pod 必须配置 `resource.requests` ）
        ```
        kubectl autoscale deployment web --min=3 --max=10 --cpu-percent=80
        ```
    - 查看伸缩的状况
        ```
        kubectl get hpa
        ```
    - 尝试使用 `httpd-tools` 工具进行压测
        ```
        ab -n 100000 -c 1000 http://{cluster-ip}/index.html
        ```
- 回滚
    > 回滚是重新部署某一次部署时的状态，即当时版本所有配置
    - 查看历史发布版本
        ```
        kubectl rollout history deployment/web
        ```
    - 回滚上一个版本
        ```
        kubectl rollout undo deployment/web
        ```
    - 回滚历史指定版本
        ```
        kubectl rollout undo deployment/web --to-revision=2
        ```
- 下线
    ```
    kubectl delete deploy/web
    kubectl delete svc/web
    ```
- 滚动升级与回滚机制
    - ReplicaSet : 副本集
        - 管理 Pod 副本数量，不断对比当前 Pod 数量与期望 Pod 数量
        - Deployment 每次发布都会创建一个 RS 作为记录，用于实现回滚
        ```
        kubectl get rs  # 查看 RS 记录 
        kubectl rollout history deployment web  # 版本对应 RS 记录
        ```
- ReplicaSet
    - ReplicaSet 控制器用途
        - Pod 副本数量管理，不断对比当前 Pod 数量与期望 Pod 数量
        - Deployment 每次发布都会创建一个 RS 作为记录，用于实现回滚
        - 查看 RS 记录
            ```
            kubectl get rs
            ```
        - 版本对应 RS 记录
            ```
            kubectl rollout history deployment web
            ```

__StatefulSet 控制器__
- 常用来做分布式应用和数据库集群，像 etcd 就无法使用 deployment 来部署，因为新增 Pod 的IP 无法加入群集网络。而 StatefulSet 能够提供稳定的网络和存储
    - 稳定的网络的实现 : 设置 service 的 `clusterIP: None` 实现无论怎么调度，每个 Pod 都有一个永久不变的 ID
    - 稳定的存储的实现 : 设置 volumeClaimTemplates 的 `accessModes: [ "ReadWriteOnce" ]`
- 示例 : 演示 StatefulSet 的组件
    ```yaml
    apiVersion: v1
    kind: Service
    metadata:
      name: nginx
      labels:
        app: nginx
    spec:
      ports:
      - port: 80
        name: web
      clusterIP: None   # 设置为无头服务 Headless Service
      selector:
        app: nginx
    ---
    apiVersion: apps/v1
    kind: StatefulSet
    metadata:
      name: web
    spec:
      selector:
        matchLabels:
          app: nginx
      serviceName: "nginx"  # 指定 StatefulSet 控制器要使用这个 Headless Service
      replicas: 3
      template:
        metadata:
          labels:
            app: nginx
        spec:
          terminationGracePeriodSeconds: 10
          containers:
          - name: nginx
            image: nginx:1.16
            ports:
            - containerPort: 80
              name: web
            volumeMounts:
            - name: www
              mountPath: /usr/share/nginx/html
      volumeClaimTemplates:   # StatefulSet 的存储卷使用 VolumeClaimTemplate 创建
      - metadata:
          name: www
        spec:
          accessModes: [ "ReadWriteOnce" ]    # 为创建的每一个 pod 分配一个单独的存储空间
          storageClassName: "managed-nfs-storage"
          resources:
            requests:
              storage: 1Gi
    ```
    - 创建后可以通过 kubectl get pv , kubectl get pvc 来查看 Pod 与存储之间一一对应的关系
    - Pod DNS 解析名称 : $(Pod 名称).$(服务名称).$(命名空间)svc.cluster.local ，可以通过 busybox 使用 lookup nginx 命令查看
- 相对于 Deployment , StatefulSet 的域名，主机名和 PVC 是唯一的

__DaemonSet 控制器__
- 功能
    - 在每一个 Node 上运行一个 Pod
    - 新加入的 Node 也同样会自动运行一个 Pod
- 示例：部署日志采集程序
    ```
    apiVersion: apps/v1
    kind: DaemonSet           # kind 为 DaemonSet
    metadata:
      name: filebeat
      namespace: kube-system
    spec:
      selector:
        matchLabels:
          name: filebeat
      template:
        metadata:
          labels:
            name: filebeat
        spec:
          tolerations:        # 污点容忍
          - effect: NoSchedule
            operator: Exists
          containers:
          - name: log
            image: elastic/filebeat:7.3.2
    ```

__Job__
- 功能 ： 执行一次任务
- 示例 ： 计算 pi 的值
    ```
    apiVersion: batch/v1
    kind: Job             # kind 为 Job
    metadata:
      name: pi
    spec:
      template:
        spec:
          containers:
          - name: pi
            image: perl
            command: ["perl",  "-Mbignum=bpi", "-wle", "print bpi(2000)"]
          restartPolicy: Never  # 重试策列
    ```

__CronJob__
- 功能 ： CronJob 用于实现定时任务，像 Linux 的 Crontab 一样
- 示例 ： 定时打印
    ```
    apiVersion: batch/v1beta1
    kind: CronJob
    metadata:
      name: hello
    spec:
      schedule: "*/1 * * * *"
      jobTemplate:
        spec:
          template:
            spec:
              containers:
              - name: hello
                image: busybox
                args:
                - /bin/sh
                - -c
                - date; echo Hello world
              restartPolicy: OnFailure
    ```