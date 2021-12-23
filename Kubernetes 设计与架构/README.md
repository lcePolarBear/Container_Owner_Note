# Kubernetes 设计与架构
## 核心设计与架构
- 一组联合挂载在 /var/lib/docker/aufs/mnt 上的 rootfs 即为 container image
- 一个由 Namsespace + Cgroup 构成的隔离环境即为 container runtime
### kubernetes 项目的全局架构
![kubernetes 项目的全局架构](https://docimg6.docs.qq.com/image/pfAFdSWZb7h599Lso7J_AQ.png?w=455&h=414)
- 控制节点由三个紧密协作的独立容器组合而成
    1. kube-apiserver ：负责 API 服务，作为集群的统一入口，对所有资源的操作都由它提交给 etcd
    2. kube-controller-manager ：负责容器编排，集中处理集群中常规后台任务
    3. kube-scheduler ：负责调度，为 Pod 分配 Node
- 计算节点上最核心的部分，是一个名为 kubelet 的组件
    1. kubelet 通过 container runtime interface (CRI) 定义 container runtime 的各项核心操作。container runtime 会通过 OCI （容器运行时规范）把 CRI 翻译为 Linux 系统的调用（操作 Linux Namespace 和 Cgroup 等）。
    2. kubelet 通过 gRPC 协议与 Device Plugin 交互。用于管理宿主机 GPU ，支撑机器学习训练和高性能作业
    3. kubelet 通过调用 container networking interface (CNI) 和 container storage interface (CSI) 插件为容器提供网络网络配置和持久化存储

由此我们可以看出， Kubernetes 项目并没有像同期的各种容器云项目把 Docker 直接作为整个架构的核心来实现一个 PaaS ，而是仅仅把 Docker 作为一个底层的 container runtime
## Kubernetes 核心能力与项目定位
应用、组件和进程的运行环境从 OS 级别的“粗粒度”变为 container 级别的“细粒度”，才使得“微服务”思想得以落地。  
### kubernetes 是如何定义任务编排的各种关系的？
![kubernetes 核心功能全景图](https://docimg9.docs.qq.com/image/c3jxnnOfD22UlKyPrNkY_A.png?w=1280&h=720)
1. 容器被划分为 Pod ，Pod 中容器之间共享 Network Namespace 和 Volume ，从而实现高效的信息交换。
2. 通过 service 绑定一组 Pod 的 IP 地址提供负载均衡，对外提供统一访问接口
3. 为了更多样化的描述 Pod 工作性质，引入了 Job 、 DeaminSet 、 CronJob 等对象的概念
### kubernetes 的使用逻辑
1. 首先通过一个任务编排对象描述试图管理的应用。
2. 为应用定义拥有运维能力的对象，比如 Service 、 Ingress 、 Horizontal Pod Autoscaler 等，由这些对象来负责具体的运维能力侧功能。
3. 那么这种使用方法就是所谓的“声明式 API ”。这种 API 对应的编排对象和服务对象，都是 Kubernetes 项目中的 API 对象，__声明式 API 是 Kubernetes 最核心的设计理念__。

由此我们可以看出， kubernetes 不但能够将容器按照某种规则“调度”到某个最佳节点上运行，还能还能按照用户的意愿和整个系统的规则，完全自动化“编排”好容器之间的各种关系，更重要的是， kubernetes 是一系列具有普遍意义的、以声明式 API 驱动的容器化作业编排思想和最佳实践。