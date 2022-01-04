# Containerd 容器引擎
## 部署 Containerd
1. 准备配置
```bash
cat > /etc/sysctl.d/99-kubernetes-cri.conf << EOF
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
sysctl -system
```
2. 安装
```bash
cd /etc/yum.repos.d
wget http://mirrors.aliyun.com/dockerce/linux/centos/docker-ce.repo
yum install -y containerd.io
```
3. 修改配置文件
```bash
mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml
vi /etc/containerd/config.toml
    ```
[plugins."io.containerd.grpc.v1.cri"]
  sandbox_image = "registry.aliyuncs.com/google_containers/pause:3.2" 
    ...
    [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
      SystemdCgroup = true
      ...
    [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runsc]
      runtime_type = "io.containerd.runsc.v1"
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."docker.io"]
    endpoint = ["https://b9pmyelo.mirror.aliyuncs.com"]
    ```
systemctl restart containerd
```
4. 配置 kubelet 使用 containerd
```bash
# vi /etc/sysconfig/kubelet
KUBELET_EXTRA_ARGS=--container-runtime=remote --container-runtime-endpoint=unix:///run/containerd/containerd.sock --cgroup-driver=systemd
systemctl restart kubelet
```
5. 验证
```bash
kubectl get node -o wide
```
### Containerd 管理工具 crictl
[项目地址](https://github.com/kubernetes-sigs/cri-tools/)

准备 crictl 连接 containerd 配置文件
```bash
cat > /etc/crictl.yaml << EOF
runtime-endpoint: unix:///run/containerd/containerd.sock
EOF
```
![](https://docimg10.docs.qq.com/image/tASeFLWuLE4lqwyfJeEaFw.png?w=1280&h=269.1029168959824)