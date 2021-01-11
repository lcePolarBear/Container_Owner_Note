## 通过工作负载控制器实现 Pod 的管理

__什么是工作负载控制器__    
- 工作负载控制器（ Workload Controllers ）是 K8s 的一个抽象概念，用于更高级层次对象。用于部署和管理 Pod
    - 无状态应用部署： Deployment
    - 有状态应用部署： StatefulSet
    - 确保所有 Node 运行同一个 Pod: DaemonSet
    - 一次性任务： Job
    - 定时任务： Cronjob
- 控制器的作用
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
        ```
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
        kubectl set image deployment/web nginx=nginx:1.16
        ```
        ```
        kubectl edit deployment/web
        ```
    - 限制进行滚动更新的 Pod 数量
        ```
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
- 水平扩容
    > replicas 参数控制 Pod 副本数量
    - 修改 yaml 文件里 replicas 值，再 apply
    - 使用命令行
        ```
        kubectl scale deployment web --replicas=10
        ```
- 下线
    ```
    kubectl delete deploy/web
    kubectl delete svc/web
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