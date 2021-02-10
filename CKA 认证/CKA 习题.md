### [使用 kubeadm 搭建群集](https://kubernetes.io/zh/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/)
1. [安装 kubeadm kubelet 和 kubectl 并启动](https://v1-19.docs.kubernetes.io/zh/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#%E5%AE%89%E8%A3%85-kubeadm-kubelet-%E5%92%8C-kubectl)
2. [导出 kubeadm.config 使用 kubeadm init --config 部署 master](https://kubernetes.io/zh/docs/reference/setup-tools/kubeadm/kubeadm-config/#cmd-config-print-init-defaults)
3. [master 导入 admin.config 变量](https://kubernetes.io/zh/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/#%E6%9B%B4%E5%A4%9A%E4%BF%A1%E6%81%AF)
4. kubeadm join 添加 worker 节点
5. [部署 calico](https://docs.projectcalico.org/manifests/calico.yaml)

### 新建命名空间，在该命名空间中创建一个pod
1. 创建命名空间
    ```bash
    kubectl create namespace chen
    ```
2. 导出 Pod.yaml
    ```bash
    kubectl run nginx --image=nginx --dry-run=client -o yaml > pod.yaml   # 导出 pod.yaml 模板
    ```
    ```yaml
    # vi pod.yaml
    metadata.namespace: chen    # 修改命名空间
    ```
3. 创建 Pod
    ```
    kubectl apply -f nginx.yaml
    kubectl get pod -n chen
    ```

### 创建一个 deployment 并暴露 Service
1. 导出 deployment.yaml
    ```bash
    kubectl create deployment my-dep --image=nginx --dry-run=client -o yaml > deployment.yaml
    ```
2. 参考官方文档创建 service _[官方文档](https://kubernetes.io/zh/docs/concepts/services-networking/service/#%E5%AE%9A%E4%B9%89-service)_
3. 创建 deployment 和 service

###  列出命名空间下指定标签 pod
- 以查看 coreDNS 为例
    ```bash
    kubectl get pods -n kube-system -l k8s-app=kube-dns
    # -n 表示指定命名空间
    # -l 表示指定标签
    ```

### 查看 pod 日志，并将日志中 Error 的行记录到指定文件
- 使用 kubectl logs 导出 pod 的日志后 使用 |grep error 过滤并导出内容

### 查看指定标签使用 cpu 最高的 pod 并记录到到指定文件
1. 考试环境的 K8S 应该部署了 Metrics
2. 使用 kubectl top 来查看
    ```bash
    kubectl top pods -l app=web --sort-by="cpu" > /opt/cpu
    # --sort-by="cpu" 按 cpu 占用率来排序
    ```
### 在节点上配置 kubelet 托管启动一个 pod
> 题意就是部署静态 pod
- 查看静态 pod 部署地址
    ```yaml
    # cat /var/lib/kubelet/config.yaml
    staticPodPath: /etc/kubernetes/manifests
    ```
- 进入静态 pod 部署地址
- 导出一个 pod.yaml 放入此路径下并查看是否能自启动

### 向 pod 中添加一个 init 容器， init 容器创建一个空文件，如果该空文件没有被检测到， pod 就退出
1. 创建一个包含 Init 容器的 Pod [官方链接](https://kubernetes.io/zh/docs/tasks/configure-pod-container/configure-pod-initialization/#creating-a-pod-that-has-an-init-container)
2. 查看存活检查 livenessProbe 示例 _[官方链接](https://kubernetes.io/zh/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#define-a-liveness-command)_

### 创建一个 deployment 副本数 3 ，然后滚动更新镜像版本，并记录这个更新记录，最后再回滚到上一个版本
1. 导出 deployment.yaml 并部署
2. 修改 yaml 文件镜像版本号并使用 --record=xxx 参数重新部署
3. 回滚到之前的修订版本 _[官方链接](https://kubernetes.io/zh/docs/concepts/workloads/controllers/deployment/#rolling-back-to-a-previous-revision)_

### 给 web deployment 扩容副本数为 3
- 使用 kubectl scale 命令进行扩容

### 创建一个 pod ，其中运行着 nginx , redis , memcached , consul 4 个容器
1. 导出一个 pod.yaml 模板
2. 向 pod.yaml 添加镜像信息并启动

### 生成一个 deployment yaml 文件保存到 /opt/deploy.yaml
 - 使用 kubectl create 导出 deployment.yaml 模板时指定路径即可

### 创建一个 pod ，分配到指定标签 node 上
1. 导出一个 pod.yaml
2. 以指定标签添加到 `nodeSelector` _[官方链接](https://kubernetes.io/zh/docs/concepts/scheduling-eviction/assign-pod-node/#%E6%AD%A5%E9%AA%A4%E4%BA%8C-%E6%B7%BB%E5%8A%A0-nodeselector-%E5%AD%97%E6%AE%B5%E5%88%B0-pod-%E9%85%8D%E7%BD%AE%E4%B8%AD)_

### 确保在每个节点上运行一个 pod
- 使用 DaemonSet 部署镜像 _[官方链接](https://kubernetes.io/zh/docs/concepts/workloads/controllers/daemonset/#%E5%88%9B%E5%BB%BA-daemonset)_

### 查看集群中状态为 ready 的 node 数量，不包含被打了 NodeSchedule 污点的节点，并将结果写到 /opt/node.txt
1. 列出所有状态为 Ready 的节点名称
    ```bash
    kubectl get node | grep Ready | awk '{print $1}'
    ```
2. 查看 k8s-node1 节点的污点信息
    ```bash
    kubectl describe node k8s-node1 | grep Taint
    ```
3. 查看所有节点的污点信息
    ```bash
    kubectl describe node $(kubectl get node | grep Ready | awk '{print $1}') | grep Taint
    ```
4. 将污点信息不包含 NoSchedule 字符串的行进行计数
    ```bash
    kubectl describe node $(kubectl get node | grep Ready | awk '{print $1}') | grep Taint | grep -vc NoSchedule
    # -v 选择不包含 NoSchedule 字符串的行
    # -c 将选择出来的行进行计数
    ```
### 设置成 node 不能调度，并使已被调度的 pod 重新调度
1. 设置节点为不可调度 : kubectl cordon
2. 驱除节点上的 pod : kubectl drain

### 给一个 pod 创建 service ，并可以通过 ClusterIP 访问
1. 导出一个 pod.yaml
2. 参考官方文档创建 service

### 任意名称创建 deployment 和 service ，然后使用 busybox 容器 nslookup 解析 service
 1. 导出 deployment.yaml 和创建 service.yaml 并部署
 2. 导出 busybox.yaml 并部署
 3. 进入 busybox pod 使用 nslookup 解析 service-name

 ### 列出命名空间下某个 service 关联的所有 pod ，并将 pod 名称写到 /opt/pod.txt 文件中（使用标签筛选）
 1. 查看 service 对应的标签
    ```
    kubectl get svc -o wide 
    ```
 2. 查看并导出对应标签的 pod
    ```
    kubectl get pod -l [label-name] > /opt/pod.txt
    ```