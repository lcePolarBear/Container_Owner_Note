# Kubernetes 编排原理
## 正确认识 Pod
kubernetes 项目的原子调度单位是 Pod 而不是容器。  
为了以对等关系而不是拓扑关系描述容器之间的“超亲密关系”
1. Pod 会先用 Infra 容器 "hold" Network Namespace ，后让用户容器加入其中。这样， Pod 内部容器就可以共享网络设备，共用 localhost
2. kubernetes 项目将所有 Volume 的定义都设计在 Pod 层面以保证 Pod 内部容器共享宿主机目录

通过 Pod 这种“超亲密关系”容器的设计思想可以方便的解决 Web 服务器和 WAR 包的解耦问题，也诞生了通过 sidecar 容器对工作容器进行日志收集、网络配置的管理方式，比如 Istio 。

Pod 其实可以理解为一个虚拟机，而容器镜像可以理解为在虚拟机中运行的进程，把有顺序关系的容器定义为 Init Container 。
## 深入解析 Pod 对象
