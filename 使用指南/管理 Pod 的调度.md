## 管理 Pod 的调度

__创建一个 Pod 的工作流程__

__Pod 中影响调度的主要属性__

__资源限制对调度的影响__
- 容器资源占用上限
    - resources.limits.cpu
    - resources.limits.memory
- 容器资源所需下限
    - resources.requests.cpu
    - resources.requests.memory
    ```yaml
    apiVersion: v1
    kind: Pod
    metadata:
      name: pod-resource 
    spec:
      containers:
      - name: web
        image: nginx
        resources:
          requests:   # 容器最小资源配额
            memory: "64Mi"
            cpu: "250m"
          limits:     # 容器最大资源上限
            memory: "128Mi"
            cpu: "500m"
    ```
- K8s 会根据 Request 的值去查找有足够资源的 Node 来调度此 Pod
- 使用 kubectl describe node <node 名称> 查看分配的资源信息

__将 Pod 分配到具有指定标签的 Ndoe 上__

`nodeSelector` : 用于将 Pod 调度到匹配 Label 的 Node 上，如果没有匹配的标签会调度失败

- 示例：确保 Pod 分配到具有 SSD 硬盘的 node 上
    - 给 node 添加标签
      ```
      kubectl label nodes k8s-node1 disktype=ssd
      ```
    - 查看标签
        ```
        kubectl get nodes --show-labels
        ```
    - 添加 nodeSelector 字段到 Pod 配置中
        ```yaml
        apiVersion: v1
        kind: Pod
        metadata:
          name: pod-nodeselector
        spec:
          nodeSelector:       # 限制分配的 node 标签
            disktype: "ssd"
          containers:
          - name: web
            image: nginx
        ```
    - 查看 Pod 的分配信息
        ```
        kubectl get pods -o wide
        ```

__让 Pod 在分配时考虑 node 的亲和性__
- `required` : 硬策略（必须满足）
    ```yaml
    apiVersion: v1
    kind: Pod
    metadata:
      name: pod-node-affinity
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: gpu
                operator: In
                values:
                - nvidia
      containers:
      - name: web
        image: nginx
        ```
- `preferred` : 软策略（尝试满足）
    ```yaml
    apiVersion: v1
    kind: Pod
    metadata:
      name: pod-node-affinity
    spec:
      affinity:
        nodeAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 1         #表示权重
            preference:
              matchExpressions:
              - key: gpu
                operator: In
                values:
                - nvidia
      containers:
      - name: web
        image: nginx
    ```
- 策略中会使用的运算符 `operator`
    - In , NotIn , Exists , DoesNotExist , Gt , Lt

__阻止 Pod 分配到指定 node__
- 给 node 添加污点
    ```
    kubectl taint node k8s-node1 gpu=yes:[effect]
    ```
    - 其中 [effect] 可取值
        - NoSchedule : 一定不能被调度
        - PreferNoSchedule : 尽量不要调度，非必须配置容忍
        - NoExecute : 不仅不会调度，还会驱逐 Node 上已有的 Pod
- 查看污点
    ```
    kubectl describe node k8s-node1 | grep Taint
    ```
- 要想给存在污点的 node 分配 Pod 则必须要给 Pod 添加污点容忍
    ```yaml
    apiVersion: v1
    kind: Pod
    metadata:
      name: pod4
    spec:
      tolerations:
      - key: "gpu"
        operator: "Equal"
        value: "nvidia"
        effect: "NoSchedule"
      containers:
      - name: web
        image: nginx
    ```
- 去掉 node 的污点
    ```
    kubectl taint node k8s-node1 gpu=yes:[effect]-
    ```
    - 就是在添加污点的命令后面加一个减号 "-"

__让 Pod 分配到指定的 Node 上__
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod6
spec:
  nodeName: k8s-node1   #指定分配的 Node
  containers:
  - name: web
    image: nginx
```
- Pod 在使用 nodeName 时会跳过调度器，所以污点啥的都不会对此分配起作用