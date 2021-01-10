## 理论基础

__功能列表__
* 数据卷 pod（最小k8s单元）
* 应用健康检查
* 复制应用程序实例
* 弹性伸缩 cpu
* 服务发现 环境变量 dns-》访问地址
* 负载均衡
* 滚等更新
* 服务器编排 yaml
* 资源监控
* 认证 rbac

__基本对象__
* Pod
    * k8s 最基本的操作单元，代表群集中一个进程，内部封装单、多个容器
    * [通过 YAML 文件实现 Pod 的基本管理](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/%E4%BD%BF%E7%94%A8%E6%8C%87%E5%8D%97/%E9%80%9A%E8%BF%87%20YAML%20%E6%96%87%E4%BB%B6%E5%AE%9E%E7%8E%B0%20Pod%20%E7%9A%84%E5%9F%BA%E6%9C%AC%E7%AE%A1%E7%90%86.md)
* Deployment
    * 最常见的工作负载控制器，用于更高级别部署和管理 Pod
* Service
    * 为一组 Pod 提供负载均衡，对外提供统一访问接口
* label
    * 标签，附加到某个资源上，用于关联对象、查询和筛选
* namespace
    * 命名空间，将对象逻辑上隔离，也利于权限控制
    * 常用来根据不同团队或者项目划分命名空间
* volume
* ReplicaSet
* StatefulSet 持久性应用程序
* DeaminSet   确保节点运行同一 pod
* Job 定时执行、一次执行任务

__master 组件__
* kube-apiserver
    * 集群的统一入口，对所有资源的操作都交给他在提交给 etcd
* kube-controller-manager
    * 集中处理集群中常规后台任务
* kube-scheduler
    * 为新创建的 pod 分配 node

__node 组件__
* kubelet
    * Master 在 Node 节点上的 Agent ，管理本机运行容器的生命周期，将每个 pod 转换成容器
* kube-proxy
    * 负责为 pod 提供网络代理
* docker
  * 运行容器

__第三方服务__
* flannel   -   容器间通信
    - K8S 网络模型要求
        - 一个 pod 一个 ip
        - pod 内所有的容器共享一个 ip
        - 所有容器都可以与所有其他容器通信
        - 所有节点都可以与所有容器通信
    - Overlay 网络：在基础网络上叠加一层虚拟网
* etcd  -   分布式存储系统
    - etcd 要求同一部署的机器数要达到三台及以上