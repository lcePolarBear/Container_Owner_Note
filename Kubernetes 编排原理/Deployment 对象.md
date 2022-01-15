# Deployment 对象

官方文档：[Deployments | Kubernetes](https://kubernetes.io/zh/docs/concepts/workloads/controllers/deployment/)

<aside>
💡 Deployment 对象最重要的特点就是体现了 Kubernetes 项目中一个非常重要的功能：Pod 的 `horizontal scaling out/in` （水平扩展和收缩），从 PaaS 时代开始，这个功能就是平台级项目必备的编排能力

</aside>

## ReplicaSet 与 Deployment 的联系

当 Deployment 的 Pod 模板被修改时，Deployment 就会通过 `rolling update` （滚动更新）的方式去变更容器，而这个能力的实现依赖 Kubernetes 中一个非常重要的 API 对象：`ReplicaSet`

### ReplicaSet 结构

```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: frontend
  labels:
    app: guestbook
    tier: frontend
spec:
  # modify replicas according to your case
  replicas: 3
  selector:
    matchLabels:
      tier: frontend
  template:
    metadata:
      labels:
        tier: frontend
    spec:
      containers:
      - name: php-redis
        image: gcr.io/google_samples/gb-frontend:v3
```

一个 ReplicaSet 对象其实是由 `replicas` 和一个 `template` 组成，不难发现它的定义其实就是 Deployment 的子集。

更重要的是， Deployment 控制器实际操纵的就是这样的 ReplicaSet 对象。

### Deployment 结构

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
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
      - name: nginx
        image: nginx:1.14.2
        ports:
        - containerPort: 80
```

这是一个定义了 replicas=3 的 Deployment ，与它的 ReplicaSet 以及 Pod 之间实际上是一种“层层控制”的关系。

![deply.jfif](https://docimg3.docs.qq.com/image/TNmzqnrY0ew04CWL5aH1KA.jpeg?w=388&h=389)

ReplicaSet 负责通过控制器模式保证系统中 Pod 的个数永远等于指定个数。

## 实现 Deployment 的水平扩展/收缩

### 使用指令操作 ReplicaSet 的个数和属性

```bash
$ kubectl scale deplyment nginx-deployment --replicas=4
```

### 自动水平扩容

Pod 必须先配置 `resource.requests` 用以限制资源分配，才能实现自动扩容

```bash
kubectl autoscale deployment web --min=3 --max=10 --cpu-percent=80
```

### 查看伸缩的状况

```bash
kubectl get hpa
```

### 使用 httpd-tools 工具进行压测，观察扩容情况

```bash
ab -n 100000 -c 1000 http://{cluster-ip}/index.html
```

## 实现 Deployment 的滚动更新

```bash
[root@jump ~]# kubectl create -f nginx-deployment.yaml --record
deployment.apps/nginx-deployment created

# 只更新镜像版本
[root@jump ~]# kubectl set image deployment/nginx-deployment nginx=nginx:1.19 --record
deployment.apps/nginx-deployment image updated
```

```bash
[root@jump ~]# kubectl get deployments
NAME               READY   UP-TO-DATE   AVAILABLE   AGE
nginx-deployment   1/3     3            1           18s
```

**返回结果包含三个状态字段**

1. `READY` ****：当前处于 Running 状态的副本数和用户期待的 Pod 副本数
2. `UP-TO-DATE` ：当前处于最新版本的 Pod 个数
3. `AVAILABLE` ：当前已经可用的 Pod 个数

### 实时查看 Deployment 对象的状态变化

```bash
[root@jump ~]# kubectl rollout status deployment/nginx-deployment
Waiting for deployment "nginx-deployment" rollout to finish: 0 of 3 updated replicas are available...
Waiting for deployment "nginx-deployment" rollout to finish: 1 of 3 updated replicas are available...
Waiting for deployment "nginx-deployment" rollout to finish: 2 of 3 updated replicas are available...
deployment "nginx-deployment" successfully rolled out
```

### 查看 Deployment 对象控制的 ReplicaSet

```bash
[root@jump ~]# kubectl get rs
NAME                          DESIRED   CURRENT   READY   AGE
nginx-deployment-5d59d67564   3         3         3       2m26s
```

### 通过使用 kubectl edit 指令修改 Deployment 对象

```bash
[root@jump ~]# kubectl edit deployment/nginx-deployment
deployment.apps/nginx-deployment edited
```

kubectl edit 指令编辑完成后， kubernetes 就会立即触发“滚动更新”，可通过 kubectl rollout status 指令查看变化

```bash
[root@jump ~]# kubectl rollout status deployment/nginx-deployment
Waiting for deployment "nginx-deployment" rollout to finish: 1 out of 3 new replicas have been updated...
Waiting for deployment "nginx-deployment" rollout to finish: 1 out of 3 new replicas have been updated...
Waiting for deployment "nginx-deployment" rollout to finish: 1 out of 3 new replicas have been updated...
Waiting for deployment "nginx-deployment" rollout to finish: 2 out of 3 new replicas have been updated...
Waiting for deployment "nginx-deployment" rollout to finish: 2 out of 3 new replicas have been updated...
Waiting for deployment "nginx-deployment" rollout to finish: 2 out of 3 new replicas have been updated...
Waiting for deployment "nginx-deployment" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "nginx-deployment" rollout to finish: 1 old replicas are pending termination...
deployment "nginx-deployment" successfully rolled out
```

通过查看 Deployment 的 Events 可以看到这个“滚动更新”的过程

```bash
[root@jump ~]# kubectl describe deployment nginx-deployment
...
Events:
  Type    Reason             Age   From                   Message
  ----    ------             ----  ----                   -------
  Normal  ScalingReplicaSet  7m2s  deployment-controller  Scaled up replica set nginx-deployment-5d59d67564 to 3
  Normal  ScalingReplicaSet  112s  deployment-controller  Scaled up replica set nginx-deployment-69c44dfb78 to 1
  Normal  ScalingReplicaSet  86s   deployment-controller  Scaled down replica set nginx-deployment-5d59d67564 to 2
  Normal  ScalingReplicaSet  86s   deployment-controller  Scaled up replica set nginx-deployment-69c44dfb78 to 2
  Normal  ScalingReplicaSet  55s   deployment-controller  Scaled down replica set nginx-deployment-5d59d67564 to 1
  Normal  ScalingReplicaSet  55s   deployment-controller  Scaled up replica set nginx-deployment-69c44dfb78 to 3
  Normal  ScalingReplicaSet  54s   deployment-controller  Scaled down replica set nginx-deployment-5d59d67564 to 0
```

可以看到，这是一个新 ReplicaSet 替代旧 ReplicaSet ，多个 Pod 版本交替逐一升级的过程，即为滚动更新。

```bash
[root@jump ~]# kubectl get rs
NAME                          DESIRED   CURRENT   READY   AGE
nginx-deployment-5d59d67564   0         0         0       8m19s
nginx-deployment-69c44dfb78   3         3         3       3m9s
```

### 限制进行滚动更新的 Pod 数量

Deployment 对象有一个 `spec.revisionHistoryLimit` 字段，就是 kubernetes 为 Deployment 保留的历史版本个数，如果为 0 的话，就再也不能进行回滚操作了

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
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
      - name: nginx
        image: nginx:1.14.2
        ports:
        - containerPort: 80
```

## 实现 Deployment 的回滚

### 回滚上一个版本

当 deployment 出现升级失败需要回滚时，可通过 kubectl rollout undo 指令将整个 deployment 回滚到上个版本

```bash
[root@jump ~]# kubectl rollout undo deployment/nginx-deployment
deployment.apps/nginx-deployment rolled back
```

### 查看历史发布版本

如果需要回滚到更早的版本，先使用 kubectl rollout history 命令查看每次 deployment 变更对应的版本

```bash
[root@jump ~]# kubectl rollout history deployment/nginx-deployment
deployment.apps/nginx-deployment 
REVISION  CHANGE-CAUSE
2         kubectl create --filename=nginx-deployment.yaml --record=true
3         kubectl create --filename=nginx-deployment.yaml --record=true
```

通过添加 `--revision=2` 参数查看 API 对象细节

```bash
[root@jump ~]# kubectl rollout history deployment/nginx-deployment --revision=2
deployment.apps/nginx-deployment with revision #2
Pod Template:
  Labels:	app=nginx
	pod-template-hash=69c44dfb78
  Annotations:	kubernetes.io/change-cause: kubectl create --filename=nginx-deployment.yaml --record=true
  Containers:
   nginx:
    Image:	nginx:1.9.1
    Port:	80/TCP
    Host Port:	0/TCP
    Environment:	<none>
    Mounts:	<none>
  Volumes:	<none>
```

### 回滚历史指定版本

通过在 kubectl rollout undo 命令行最后加上目标版本号，来回滚到指定版本

```bash
[root@jump ~]# kubectl rollout undo deployment/nginx-deployment --to-revision=2
deployment.apps/nginx-deployment rolled back
```