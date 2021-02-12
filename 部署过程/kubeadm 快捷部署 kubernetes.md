## kubeadm 快捷部署 kubernetes

__在所有节点的准备工作__
- 添加阿里云 YUM 软件源
    ```bash
    cat > /etc/yum.repos.d/kubernetes.repo << EOF
    [kubernetes]
    name=Kubernetes
    baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
    enabled=1
    gpgcheck=0
    repo_gpgcheck=0
    gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
    EOF
    ```

- 安装 kubeadm,kubelet 和 kubectl
    ```
    yum install -y kubelet-1.19.0 kubeadm-1.19.0 kubectl-1.19.0
    systemctl enable kubelet
    ```

__部署Kubernetes Master__
> 结合一份配置文件来使用 kubeadm init _[官方链接](https://kubernetes.io/zh/docs/reference/setup-tools/kubeadm/kubeadm-init/#config-file)_
> 
> 初始化控制平面节点 [官方链接](https://kubernetes.io/zh/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/#%E5%88%9D%E5%A7%8B%E5%8C%96%E6%8E%A7%E5%88%B6%E5%B9%B3%E9%9D%A2%E8%8A%82%E7%82%B9)
- 创建 Master 节点
    ```bash
    kubeadm init \
      --apiserver-advertise-address=192.168.1.202 \
      --image-repository registry.aliyuncs.com/google_containers \
      --kubernetes-version v1.19.0 \
      --service-cidr=10.96.0.0/12 \
      --pod-network-cidr=10.244.0.0/16 \
      --ignore-preflight-errors=all
    ```
    - --apiserver-advertise-address 集群通告地址
    - --image-repository  由于默认拉取镜像地址 k8s.gcr.io 国内无法访问，这里指定阿里云镜像仓库地址
    - --kubernetes-version K8s 版本，与上面安装的一致
    - --service-cidr 集群内部虚拟网络， Pod 统一访问入口
    - --pod-network-cidr Pod 网络，与下面部署的CNI网络组件 yaml 中保持一致
    - 或者使用配置文件引导
        ```yaml
        # vi kubeadm.conf
        apiVersion: kubeadm.k8s.io/v1beta2
        kind: ClusterConfiguration
        kubernetesVersion: v1.18.0
        imageRepository: registry.aliyuncs.com/google_containers 
        networking:
          podSubnet: 10.244.0.0/16 
          serviceSubnet: 10.96.0.0/12 
        ```
        ```bash
        kubeadm init --config kubeadm.conf --ignore-preflight-errors=all
        ```
- 保存好输出的 kubeadm join 记录，用于添加群集节点
- 拷贝 kubectl 使用的连接 k8s 认证文件到默认路径：
    ```bash
    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config
    ```
    ```bash
    # kubectl get nodes
    NAME         STATUS   ROLES    AGE   VERSION
    k8s-node1   Ready    master   2m   v1.18.0
    ```

__加入Kubernetes Node__
> kubeadm join 命令 [官方指令](https://kubernetes.io/zh/docs/reference/setup-tools/kubeadm/kubeadm-join/)
- 向集群添加新节点，执行在 kubeadm init 输出的 kubeadm join 命令
    ```bash
    kubeadm join 192.168.1.202:6443 --token esce21.q6hetwm8si29qxwn \
        --discovery-token-ca-cert-hash sha256:00603a05805807501d7181c3d60b478788408cfe6cedefedb1f97569708be9c5
    ```
    - 默认 token 有效期为 24 小时，当过期之后，该 token 就不可用了。这时就需要重新创建 token
    - 如果没记下来，可以在 master 成功新生成
        ```bash
        kubeadm token create --print-join-command
        ```


部署容器网络 (CNI)
> 安装 Pod 网络附加组件 _[官方链接](https://kubernetes.io/zh/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/#pod-network)_

Calico 是一个纯三层的数据中心网络方案， Calico 支持广泛的平台，包括 Kubernetes、OpenStack 等

Calico 在每一个计算节点利用 Linux Kernel 实现了一个高效的虚拟路由器（ vRouter） 来负责数据转发，而每个 vRouter 通过 BGP 协议负责把自己上运行的 workload 的路由信息向整个 Calico 网络内传播

此外， Calico  项目还实现了 Kubernetes 网络策略，提供 ACL 功能

- 在 kubernetes 部署 Calico
    ```bash
    wget https://docs.projectcalico.org/manifests/calico.yaml
    ```
    - 修改里面定义 Pod 网络(CALICO_IPV4POOL_CIDR) ，与前面 kubeadm init 指定的一样
    - 修改完后应用清单
        ```bash
        kubectl apply -f calico.yaml
        kubectl get pods -n kube-system
        ```

__测试kubernetes集群__
- 在 Kubernetes 集群中创建一个 pod 验证是否正常运行
    ```bash
    kubectl create deployment nginx --image=nginx
    kubectl expose deployment nginx --port=80 --type=NodePort
    kubectl get pod,svc
    ```
- 访问地址：http://NodeIP:Port  

__部署 Dashboard__
- 获取部署 yaml 文件
    ```bash
    wget https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.3/aio/deploy/recommended.yaml
    ```
- 默认 Dashboard 只能集群内部访问，修改 Service 为 NodePort 类型，暴露到外部
    ```yaml
    kind: Service
    apiVersion: v1
    metadata:
      labels:
        k8s-app: kubernetes-dashboard
      name: kubernetes-dashboard
      namespace: kubernetes-dashboard
    spec:
      type: NodePort
      ports:
        - port: 443
          targetPort: 8443
          nodePort: 30001
      selector:
        k8s-app: kubernetes-dashboard
    ```
- 部署和查看 Dashboard
    ```bash
    kubectl apply -f recommended.yaml
    kubectl get pods -n kubernetes-dashboard
    ```
    ```
    NAME                                         READY   STATUS    RESTARTS   AGE
    dashboard-metrics-scraper-6b4884c9d5-gl8nr   1/1     Running   0          13m
    kubernetes-dashboard-7f99b75bf4-89cds        1/1     Running   0          13m
    ```
- 访问地址：https://NodeIP:30001
- 创建 service account 并绑定默认 cluster-admin 管理员集群角色
    - 创建用户
        ```
        kubectl create serviceaccount dashboard-admin -n kube-system
        ```
    - 用户授权
        ```
        kubectl create clusterrolebinding dashboard-admin --clusterrole=cluster-admin --serviceaccount=kube-system:dashboard-admin
        ```
    - 获取用户Token
        ```
        kubectl describe secrets -n kube-system $(kubectl -n kube-system get secret | awk '/dashboard-admin/{print $1}')
        ```
- 使用输出的 token 登录 Dashboard
