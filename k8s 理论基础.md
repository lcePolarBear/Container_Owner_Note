## 理论基础

__功能列表__
* 数据卷 pod（最小k8s单元）
* 应用健康检查
* 复制应用程序实例
* 弹性伸缩 cpu
* 服务发现 环境变量 dns-》访问地址
* 负载均衡
* 滚等更新
* 服务器编排 yaml？
* 资源监控
* 认证 rbac

__组成部分__
* Pod -   k8s最基本的操作单元 代表群集中一个进程 内部封装单、多个容器
* Service -   可以看作一组提供相同服务的Pod对外访问接口
* volume 
* namespace 
* label
* ReplicaSet
* Deployment  管理ReplicaSet
* StatefulSet 持久性应用程序
* DeaminSet   确保节点运行同一pod
* Job 定时执行、一次执行任务

__master 组件__
* kube-appserver    -    对外接口供客户端调用
* kube-controller-manager   -    管理控制器
* kube-scheduler    -    对集群内部的资源进行调度

__node 组件__
* Pod
* kubelet   -   负责监视指派到node上的pod 增删查改啥的
* kube-proxy    -   负责为pod对象提供代理
* docker
* flannel 容器间通信
* etcd  为群集提供存储服务