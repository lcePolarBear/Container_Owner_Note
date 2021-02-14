### [使用 kubeadm 搭建群集](https://kubernetes.io/zh/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/)
1. [安装 kubeadm kubelet 和 kubectl 并启动](https://v1-19.docs.kubernetes.io/zh/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#%E5%AE%89%E8%A3%85-kubeadm-kubelet-%E5%92%8C-kubectl)
2. [导出 kubeadm.config 使用 kubeadm init --config 部署 master](https://kubernetes.io/zh/docs/reference/setup-tools/kubeadm/kubeadm-config/#cmd-config-print-init-defaults)
3. [master 导入 admin.config 变量](https://kubernetes.io/zh/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/#%E6%9B%B4%E5%A4%9A%E4%BF%A1%E6%81%AF)
4. kubeadm join 添加 worker 节点
5. 部署 calico _[官方链接](https://docs.projectcalico.org/getting-started/kubernetes/minikube)_

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

### 重新配置已存在的 deployment front-end ，对其已存在的 nginx 容器添加名为 http 的暴露端口 80/tcp 。创建名为 front-end-svc 的 Service 用于暴露名为 http 的容器端口。通过调度节点上的 NodePort 暴露各个 Pod
1. 根据 deployment 示例使用 kubectl edit 命令添加名为 http 的暴露端口 _[官方文档](https://kubernetes.io/zh/docs/concepts/workloads/controllers/deployment/#creating-a-deployment)_
2. 参考官方文档创建 service 并添加服务发现 NodePort _[官方文档](https://kubernetes.io/zh/docs/concepts/services-networking/service/#%E5%AE%9A%E4%B9%89-service)_
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
### 将 node 设置为不可用并且驱逐已部署在此节点上所有的 pod
1. 设置节点为不可调度 : kubectl cordon
2. 驱除节点上的 pod : kubectl drain
    - drain 在执行之前默认执行 cordon

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

### 创建一个 secret ，并创建 2 个 pod ， pod1 挂载该 secret ，路径为 /etc/foo ， pod2 使用环境变量引用该 secret ，该变量的环境变量名为 ABC
1. 创建一个 Secret _[官方链接](https://kubernetes.io/zh/docs/concepts/configuration/secret/#%E6%A1%88%E4%BE%8B-%E4%BB%A5%E7%8E%AF%E5%A2%83%E5%8F%98%E9%87%8F%E7%9A%84%E5%BD%A2%E5%BC%8F%E4%BD%BF%E7%94%A8-secret)_
2. pod1 使用卷挂载 Secrets _[官方链接](https://kubernetes.io/zh/docs/concepts/configuration/secret/#using-secrets-as-files-from-a-pod)_
3. pod2 使用环境变量引用 Secrets _[官方链接](https://kubernetes.io/zh/docs/concepts/configuration/secret/#using-secrets-as-environment-variables)_

### 创建一个 Pod 使用 PV 自动供给
1. 创建 PVC _[官方链接](https://kubernetes.io/zh/docs/tasks/configure-pod-container/configure-persistent-volume-storage/#%E5%88%9B%E5%BB%BA-persistentvolumeclaim)_
2. 创建使用 PVC 分配存储的 Pod _[官方链接](https://kubernetes.io/zh/docs/tasks/configure-pod-container/configure-persistent-volume-storage/#%E5%88%9B%E5%BB%BA-pod)_

### 创建一个 pod 并挂载数据卷，不可以用持久卷
- 使用官方示例部署 pod _[官方链接](https://kubernetes.io/zh/docs/concepts/storage/volumes/#emptydir-%E9%85%8D%E7%BD%AE%E7%A4%BA%E4%BE%8B)_

### 将 pv 按照名称、容量排序，并保存到 /opt/pv 文件
1. 查看 PV 的 yaml 结构 _[官方链接](https://kubernetes.io/zh/docs/tasks/configure-pod-container/configure-persistent-volume-storage/#%E5%88%9B%E5%BB%BA-persistentvolume)_
2. 使用 --sort-by 排序
    ```
    kubectl get pv --sort-by=.metadata.name >> /opt/pv kubectl get pv --sort-by=.spec.capacity.storage >> /opt/pv
    ```

### etcd 数据库备份与恢复 (kubeadm)
1. etcdctl 备份的官方示例 _[官方链接](https://kubernetes.io/zh/docs/tasks/administer-cluster/configure-upgrade-etcd/)_
    - 必须加入密钥的参数才能执行，可以使用 `-h` 查看
2. 先暂停 kube-apiserver 和 etcd 容器
    - kube-apiserver 所在路径 : /etc/kubernetes/manifests/
    - etcd 所在路径 : /var/lib/etcd/
3. 用 -h 查看恢复命令以及指定 etcd 路径

### 给定一个 Kubernetes 集群，排查管理节点组件存在问题
1. 查看组件状态
    ```
    kubectl get cs
    ```
2. 使用 `systemctl` 管理组件

### 解决工作节点 NotReady 状态
1. 查看 CNI 网络是否正常
2. 查看工作节点的 kubelet 是否正常工作

### 升级 master 节点的 kubeadm , kubelet , kubectl 组件。由1.20 升级为 1.20.1 。不要升级 work 节点
- 升级控制平面节点 _[官方链接](https://kubernetes.io/zh/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/#%E5%8D%87%E7%BA%A7%E6%8E%A7%E5%88%B6%E5%B9%B3%E9%9D%A2%E8%8A%82%E7%82%B9)_

### 创建一个 ingress
- 创建 ingress 资源 _[官方链接](https://kubernetes.io/zh/docs/concepts/services-networking/ingress/#the-ingress-resource)_

### Pod 创建一个边车容器读取业务容器日志
- 参考官方示例 _[官方链接](https://kubernetes.io/zh/docs/concepts/cluster-administration/logging/#%E4%BD%BF%E7%94%A8-sidecar-%E5%AE%B9%E5%99%A8%E5%92%8C%E6%97%A5%E5%BF%97%E4%BB%A3%E7%90%86)_

### 在指定命名空间下创建一个 ClusterRole ，关联到一个 ServiceAccount
1. 创建指定命名空间
2. 创建 `ServiceAccount` _[官方链接](https://kubernetes.io/zh/docs/tasks/configure-pod-container/configure-service-account/#%E4%BD%BF%E7%94%A8%E9%BB%98%E8%AE%A4%E7%9A%84%E6%9C%8D%E5%8A%A1%E8%B4%A6%E6%88%B7%E8%AE%BF%E9%97%AE-api-%E6%9C%8D%E5%8A%A1%E5%99%A8)_
3. 创建 `ClusterRole` _[官方链接](https://kubernetes.io/zh/docs/reference/access-authn-authz/rbac/#clusterrole-%E7%A4%BA%E4%BE%8B)_
4. 因为题目指定在特定命名空间下进行绑定，所以创建 `RoleBinding` 而不是 `ClusterRoleBinding` _[官方链接](https://kubernetes.io/zh/docs/reference/access-authn-authz/rbac/#clusterrolebinding-example)_

### 在 internal 命名空间下创建一个 NetworkPolicy ，此命名空间下所有的 pod 只能通过 9000 端口相互访问
- 参考官方 NetworkPolicy 模板 _[官方链接](https://kubernetes.io/zh/docs/concepts/services-networking/network-policies/#networkpolicy-resource)_
- 题例分析
    1. 为 NetworkPolicy 指定 internal 命名空间
    2. 题目没有对出站流量做限制所以不需要设置 egress
    3. 因为要阻止其他命名空间 pod 对 default 命名空间 pod 的访问所以需要设置 ingress
    4. 如果不对 ingress 做白名单设置那么同为 internal 命名空间的 pod 也无法实现相互访问，所以要对 ingress 增加 from.podSelector
    5. 因为只能通过 9000 端口访问所以添加 ingress.port

### Bootstrap Token 方式增加一台 Node （二进制）
- [参考文档](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/%E9%83%A8%E7%BD%B2%E8%BF%87%E7%A8%8B/Bootstrap%20Token%20%E6%96%B9%E5%BC%8F%E5%A2%9E%E5%8A%A0%20Node.md)