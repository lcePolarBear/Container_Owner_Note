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