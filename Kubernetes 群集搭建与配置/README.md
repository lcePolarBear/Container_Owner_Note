# Kubernetes 群集搭建与配置
## 使用 kubeadm 部署 kubernetes
[官方文档：使用 kubeadm 创建集群](https://kubernetes.io/zh/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/)
### 初始化系统环境
1. [关闭防火墙和 selinux]()
2. [禁用 swap]()
3. 根据规划设置 hosts ，并在每个 kubernetes 节点添加所有节点的 hosts
4. 时间同步
5. 将桥接的 IPv4 流量传递到 iptables 的链
    ```bash
    cat > /etc/sysctl.d/k8s.conf << EOF
    net.bridge.bridge-nf-call-ip6tables = 1
    net.bridge.bridge-nf-call-iptables = 1
    EOF
    sysctl --system  # 生效
    ```
6. [安装 Docker]() 或者[安装 Containerd]() 容器引擎
7. 添加阿里云 YUM 软件源
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
8. 安装指定版本的 kubeadm,kubelet 和 kubectl
    ```bash
    yum install -y kubelet-1.21.0 kubeadm-1.21.0 kubectl-1.21.0
    systemctl enable kubelet
    ```
9. 通过 kubeadm init 指令生成 kubeadm-config.yaml 文件，创建 Master 节点组件
    ```bash
    [root@k8s-node1 ~]# kubeadm config print init-defaults > kubeadm-config.yaml
    ```
    ```yaml
    # vi kubeadm-config.yaml
    # 修改 api-server 地址、 kubernetes 组件镜像地址和 CoreDNS 相关内容

    apiVersion: kubeadm.k8s.io/v1beta2
    bootstrapTokens:
    - groups:
      - system:bootstrappers:kubeadm:default-node-token
      token: abcdef.0123456789abcdef
      ttl: 24h0m0s
      usages:
      - signing
      - authentication
    kind: InitConfiguration
    localAPIEndpoint:
      advertiseAddress: 192.168.102.211 #修改 api-server 的地址，就是 master 节点的地址
      bindPort: 6443
    nodeRegistration:
      criSocket: /var/run/dockershim.sock
      name: k8s-node1
      taints:
      - effect: NoSchedule
        key: node-role.kubernetes.io/master
    ---
    apiServer:
      timeoutForControlPlane: 4m0s
    apiVersion: kubeadm.k8s.io/v1beta2
    certificatesDir: /etc/kubernetes/pki
    clusterName: kubernetes
    controllerManager: {}
    dns:
      type: CoreDNS
    etcd:
      local:
        dataDir: /var/lib/etcd
    imageRepository: registry.aliyuncs.com/google_containers #修改集群组件镜像的地址为阿里云
    kind: ClusterConfiguration
    kubernetesVersion: v1.21.0
    networking:
      dnsDomain: cluster.local
      serviceSubnet: 10.244.0.0/16 #指定 pod 使用的网络
    scheduler: {}
    ```
    ```bash
    [root@k8s-node1 ~]# kubeadm init --config kubeadm-config.yaml
    ```
    - 保存好输出的 kubeadm join 记录，用于添加群集节点
    - 拷贝 kubectl 使用的连接 k8s 认证文件到默认路径：
        ```bash
        mkdir -p $HOME/.kube
        sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
        sudo chown $(id -u):$(id -g) $HOME/.kube/config
        ```
        ```bash
        [root@k8s-node1 ~]# kubectl get nodes
        NAME         STATUS   ROLES    AGE   VERSION
        k8s-node1   Ready    master   2m   v1.21.0
        ```
10. 通过 kubeadm join 将 Node 节点加入群集
    ```bash
    [root@k8s-node1 ~]# kubeadm join 192.168.102.211:6443 --token 9037x2.tcaqnpaqkra9vsbw \
        --discovery-token-ca-cert-hash sha256:b1e726042cdd5df3ce62e60a2f86168cd2e64bff856e061e465df10cd36295b8
    ```
11. 部署网络插件
    ```bash
    wget https://docs.projectcalico.org/manifests/calico.yaml
    ```
    - 修改里面定义 Pod 网络 (CALICO_IPV4POOL_CIDR) ，与前面 kubeadm init 指定 pod 使用的网络一致
    - 修改完后应用清单
        ```bash
        kubectl apply -f calico.yaml
        kubectl get pods -n kube-system
        ```
12. 部署 Dashboard 可视化插件
    1.  获取部署 yaml 文件 [从 github 获取最新版本](https://github.com/kubernetes/dashboard/releases)
    2. 默认 Dashboard 只能集群内部访问，修改 Service 为 NodePort 类型，暴露到外部
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
    3. 部署和查看 Dashboard
        ```bash
        [root@k8s-node1 ~]# kubectl apply -f recommended.yaml
        [root@k8s-node1 ~]# kubectl get pods -n kubernetes-dashboard
        READY   STATUS    RESTARTS   AGE
        dashboard-metrics-scraper-6b4884c9d5-gl8nr   1/1     Running   0          13m
        kubernetes-dashboard-7f99b75bf4-89cds        1/1     Running   0          13m
        ```
    4. 访问地址：https://NodeIP:30001
    5. 创建 service account 并绑定默认 cluster-admin 管理员集群角色
        ```bash
        # 创建用户
        [root@k8s-node1 ~]# kubectl create serviceaccount dashboard-admin -n kube-system
        # 用户授权
        [root@k8s-node1 ~]# kubectl create clusterrolebinding dashboard-admin --clusterrole=cluster-admin --serviceaccount=kube-system:dashboard-admin
        # 获取用户Token
        [root@k8s-node1 ~]# kubectl describe secrets -n kube-system $(kubectl -n kube-system get secret | awk '/dashboard-admin/{print $1}')
        ```
    6. 使用输出的 token 登录 Dashboard
## 透过 kubectl 操作来体验 kubernetes 的基础方法
- 导出 API 对象的 yaml 定义文件
```yaml
# kubectl run nginx --image=nginx --dry-run=client -o yaml > nginx.yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: nginx
  name: nginx
spec:
  containers:
  - image: nginx
    name: nginx
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}
```
- 部署 API 对象
    ```
    kubectl create -f nginx.yaml
    ```
- 查看 API 对象的创建情况
    ```
    kubectl get pod -l run=nginx
    ```
- 查看 API 对象的细节
    ```
    kebectl describe pod nginx
    ```
- 通过修改 yaml 文件变更 API 对象的定义
    ```
    kubectl apply -f nginx.yaml
    ```
- 删除 API 对象
    ```
    kubectl delete -f nginx.yaml
    ```
## 使用 kubeadm 对 K8s 集群进行版本升级
> 提示 : 最好落后最新版本一到两个版本
### 升级流程
1. 先备份所有组件，例如 etcd
2. 升级管理节点 -> 升级其他管理节点 -> 升级工作节点
### 升级管理节点
1. 查找最新版本号
    ```shell
    yum list --showduplicates kubeadm --disableexcludes=kubernetes # 禁用除了 kubernetes 之外的其他仓库
    ```
2. 升级 kubeadm
    ```
    yum install -y kubeadm-1.22.0-0 --disableexcludes=kubernetes
    ```
3. 驱逐 node 上的 pod 且不可调度
    ```shell
    kubectl drain k8s-node1 --ignore-daemonsets # 忽略 daemonset
    ```
4. 检查集群是否可以升级，并获取可以升级的版本
    ```
    kubeadm upgrade plan
    ```
5. 执行升级
    ```
    kubeadm upgrade apply v1.22.0
    ```
6. 取消不可调度
    ```
    kubectl uncordon k8s-node1
    ```
7. 升级 kubelet 和 kubectl
    ```
    yum install -y kubelet-1.22.0-0 kubectl-1.22.0-0 --disableexcludes=kubernetes
    ```
8. 重启 kubelet
    ```
    systemctl daemon-reload
    systemctl restart kubelet
    ```
### 升级工作节点
1. 升级 kubeadm
    ```
    yum install -y kubeadm-1.22.0-0 --disableexcludes=kubernetes
    ```
2. 驱逐 node 上 pod 且不可调度
    ```
    kubectl drain k8s-node2 --ignore-daemonsets 
    ```
3. 升级 kubelet 配置
    ```
    kubeadm upgrade node
    ```
4. 升级 kubelet 和 kubectl
    ```
    yum install -y kubelet-1.22.0-0 kubectl-1.22.0-0 --disableexcludes=kubernetes
    ```
5. 重启 kubelet
    ```
    systemctl daemon-reload
    systemctl restart kubelet
    ```
6. 取消不可调度，节点重新上线
    ```
    kubectl uncordon k8s-node2
    ```