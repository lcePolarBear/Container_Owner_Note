# Kubernetes 群集搭建与配置
## 使用 kubeadm 部署 kubernetes
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
6. [安装 Docker]()
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
10. 通过 kubeadm join 将 Node 节点加入群集
    ```bash
    [root@k8s-node1 ~]# kubeadm join 192.168.31.88:16443 --token 9037x2.tcaqnpaqkra9vsbw \
        --discovery-token-ca-cert-hash sha256:b1e726042cdd5df3ce62e60a2f86168cd2e64bff856e061e465df10cd36295b8
    ```
11. 部署网络插件
