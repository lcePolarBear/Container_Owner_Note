# DaemonSet 对象
官方文档：[DaemonSet | Kubernetes](https://kubernetes.io/zh/docs/concepts/workloads/controllers/daemonset/)

### DaemnSet 对象的三个特征

1. 这个 Pod 在 Kubernetes 群集里的每一个节点上运行
2. 每一个节点上只有一个这样的 Pod
3. 每当有新节点加入 kubernetes 群集，该 Pod 会自动地在新结节点上被创建出来，而当旧节点被删除后，它上面的 Pod 也会被相应的回收

更重要的是，与其他编排对象不同， DaemonSet 开始运行的时候要比整个 kubernetes 群集出现的时机要早，比如当 kubernetes 群集未部署网络组件，所有 Worker 节点的状态都为 NotReady (NetworkReady=false) 时，基于 DaemonSet 资源的 calico 组件就可以部署在 kubernetes 上。

### 示例：部署日志采集程序

```yaml
apiVersion: apps/v1
kind: DaemonSet
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

## DaemonSet 如何保证每个节点有且只有一个被管理的 Pod

DaemonSet Controller 首先从 etcd 中获取所有节点列表然后遍历，以此检查当前这个节点是否有一个携带了 `name: filebeat` 标签的 Pod 在运行。

### nodeAffinity

删除 Pod 可以很方便的通过调用 kubernetes API 实现，新增 Pod 则可以通过 nodeAffinity 字段实现

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  affinity:
    nodeAffinity:
	      requiredDuringSchedulingIgnoredDuringExecution: # 意味着 nodeAffinity 必须在每次调度时被考虑
        nodeSelectorTerms:
        - matchExpressions: # 这个 Pod 将来只允许在 metadata.name = node-ituring 的节点上运行 
          - key: metadata.name
            operator: In
            values:
            - node-ituring
  containers:
  - name: nginx
    image: nginx
    imagePullPolicy: IfNotPresent
```

所以，我们的 DaemonSet Controller 会在创建 Pod 的时候自动在这个 Pod 的 API 对象里加上需要绑定节点的 nodeAffinity 定义。

### tolerations

此外， DaemonSet 会自动给这个 Pod 自动加上另一个与调度相关的字段：tolerations 。该字段意味着这个 Pod 会容忍某些节点的 Taint（污点）。

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  containers:
  - name: nginx
    image: nginx
    imagePullPolicy: IfNotPresent
  tolerations:
  - key: "node.kubernetes.io/unschedulable"
    operator: "Exists"
    effect: "NoSchedule"
```

在正常情况下，被加上 unschedulabel “污点”的节点是不会被允许任何 Pod 调度到上面（ effect: NoSchedule ）。可是 DaemonSet 自动地给被管理的 Pod 加上这个特殊的 toleration 使得 Pod 可以忽略限制保证每个节点被调度一个 Pod 。

假如当前 DaemonSet 管理的是一个网络插件的 Agent Pod，那么你就必须在这个 DaemonSet 的 YAML 文件里给它的 Pod 模板加上一个能够“容忍” [node.kubernetes.io/network-unavailable](http://node.kubernetes.io/network-unavailable) “污点”的 Toleration 。当 kubernetes 群集未部署网络组件，所有 Worker 节点的状态都为 NotReady (NetworkReady=false) 时，calico 能够部署就因为它实际上是一个 DaemonSet 。

## DaemonSet 如何控制版本

Deployment 对象 管理版本依靠的是 ReplicaSet ，而 DaemonSet 控制器直接操作 Pod ，如何实现版本控制？

### ControllerRevision

kubernetes 自 v1.7 版本后推出一个 API 对象：ControllerRevision ，专门记录某种 Controller 对象的版本

查看指定明明命名空间下的 ControllerRevision：

```bash
kubectl get controllerrevision -n kube-system
```

查看 calico ControllerRevision 对象

```bash
[root@jump ~]# kubectl describe controllerrevision canal -n kube-system
Name:         canal-75477f57b4
Namespace:    kube-system
Labels:       controller-revision-hash=75477f57b4
              k8s-app=canal
Annotations:  deprecated.daemonset.template.generation: 1
API Version:  apps/v1
Data:
  Spec:
    Template:
      $patch:  replace
      Metadata:
        Annotations:
          scheduler.alpha.kubernetes.io/critical-pod:  
        Creation Timestamp:                            <nil>
        Labels:
          k8s-app:  canal
      Spec:
        Containers:
          Env:
            ...
          Image:              calico/node:v3.10.4
          Image Pull Policy:  IfNotPresent
          Liveness Probe:
            Exec:
              Command:
                /bin/calico-node
                -felix-live
...
Revision:                  1
Events:                    <none>
```

ControllerRevision 对象实际上是在 Data 字段保存了该版本对应的完整  DaemonSet 的 API 对象，并且在 Annotation 字段保存了创建这个对象所使用的 kubectl 命令。

### 回滚 DaemonSet 版本

```bash
kubectl rollout undo daemonset canal —to-revision=1 -n kube-system daemonset.extensions/canal rolled back
```

这个 kubectl rollout undo 操作，实际上相当于读取了 Revision=1 的 ControllerRevision 对象保存的 Data 字段。而这个 Data 字段里保存的信息，就是 Revision=1 时这个 DaemonSet 的完整 API 对象。