# Kubernetes_Basic_Config_Note
容器编排引擎 k8s 的基础配置备忘录 

__[kubernetes 体系概览](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/kubernetes%20%E4%BD%93%E7%B3%BB%E6%A6%82%E8%A7%88.md)__

__部署过程__
- [系统初始化](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/%E9%83%A8%E7%BD%B2%E8%BF%87%E7%A8%8B/%E7%B3%BB%E7%BB%9F%E5%88%9D%E5%A7%8B%E5%8C%96.md)
- [kubeadm 部署 Kubernetes](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/%E9%83%A8%E7%BD%B2%E8%BF%87%E7%A8%8B/kubeadm%20%E5%BF%AB%E6%8D%B7%E9%83%A8%E7%BD%B2%20kubernetes.md)
    - [kubeadm 对 K8s 集群进行版本升级](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/%E9%83%A8%E7%BD%B2%E8%BF%87%E7%A8%8B/kubeadm%20%E5%AF%B9%20K8s%20%E9%9B%86%E7%BE%A4%E8%BF%9B%E8%A1%8C%E7%89%88%E6%9C%AC%E5%8D%87%E7%BA%A7.md)
    - [Ubuntu 18.04 以 kubeadm 的方式部署 K8s](https://mp.weixin.qq.com/s?__biz=MzI1MzcxMzIwNA==&mid=2247483876&idx=1&sn=1e8781b8861820e30064ff8f5d93392b&chksm=e9d10fbfdea686a92752f06ed71818f19015c1a48d493b3be77f63876baa1ff723fe9be834c2&mpshare=1&scene=1&srcid=0111QCE9fOtmCZgzVVmPjqYo&sharer_sharetime=1613099569670&sharer_shareid=e5ca94adfe157df8104a54ba6d65c424&exportkey=ATauXlMtxwS2m427ZNsKQXY%3D&pass_ticket=CGlMkWg%2BMmtcFtixTQVMeCNStj0Dl5Zmb9817RklUHINmeFZ%2FEvDGEwMEsnMH87%2F&wx_header=0#rd)
- 二进制部署 Kubernetes
    1. [部署 etcd 存储](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/部署过程/部署%20etcd%20群集.md)
    2. [准备 Token 和 Kubernetes 证书](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/%E9%83%A8%E7%BD%B2%E8%BF%87%E7%A8%8B/%E5%87%86%E5%A4%87%20Token%20%E5%92%8C%20kubernetes%20%E8%AF%81%E4%B9%A6.md)
    3. [部署 Master 节点组件：kube-apiserver , kube-controller-manager , kube-scheduler](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/部署过程/部署%20Master%20节点组件.md)
    4. [部署 Node 节点组件：kubelet , kube-proxy](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/部署过程/部署%20Node%20节点组件.md)
    5. [部署 kubernetes 群集网络](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/%E9%83%A8%E7%BD%B2%E8%BF%87%E7%A8%8B/%E9%83%A8%E7%BD%B2%20kubernetes%20%E7%BE%A4%E9%9B%86%E7%BD%91%E7%BB%9C.md)
    6. [部署 Web UI](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/%E9%83%A8%E7%BD%B2%E8%BF%87%E7%A8%8B/%E9%83%A8%E7%BD%B2%20Web%20UI.md)
    7. [部署 kubernetes 内部 DNS 服务](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/%E9%83%A8%E7%BD%B2%E8%BF%87%E7%A8%8B/%E9%83%A8%E7%BD%B2%20kubernetes%20%E5%86%85%E9%83%A8%20DNS%20%E6%9C%8D%E5%8A%A1.md)
- Ansible 部署 Kubernetes
- [Bootstrap Token 方式增加 Node](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/%E9%83%A8%E7%BD%B2%E8%BF%87%E7%A8%8B/Bootstrap%20Token%20%E6%96%B9%E5%BC%8F%E5%A2%9E%E5%8A%A0%20Node.md)

__使用指南__
- [kubectl 命令行管理工具](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/%E4%BD%BF%E7%94%A8%E6%8C%87%E5%8D%97/kubectl%20%E5%91%BD%E4%BB%A4%E8%A1%8C%E7%AE%A1%E7%90%86%E5%B7%A5%E5%85%B7.md)
- [Kubernetes 的监控和日志](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/%E4%BD%BF%E7%94%A8%E6%8C%87%E5%8D%97/Kubernetes%20%E7%9A%84%E7%9B%91%E6%8E%A7%E5%92%8C%E6%97%A5%E5%BF%97.md)
- [应用程序生命周期管理](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/%E4%BD%BF%E7%94%A8%E6%8C%87%E5%8D%97/%E5%BA%94%E7%94%A8%E7%A8%8B%E5%BA%8F%E7%94%9F%E5%91%BD%E5%91%A8%E6%9C%9F%E7%AE%A1%E7%90%86.md)
- [Pod 对象及其管理](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/%E4%BD%BF%E7%94%A8%E6%8C%87%E5%8D%97/Pod%20%E5%AF%B9%E8%B1%A1%E5%8F%8A%E5%85%B6%E7%AE%A1%E7%90%86.md)
- [管理 Pod 的调度](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/%E4%BD%BF%E7%94%A8%E6%8C%87%E5%8D%97/%E7%AE%A1%E7%90%86%20Pod%20%E7%9A%84%E8%B0%83%E5%BA%A6.md)
- [通过工作负载控制器实现 Pod 的管理](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/%E4%BD%BF%E7%94%A8%E6%8C%87%E5%8D%97/%E9%80%9A%E8%BF%87%E5%B7%A5%E4%BD%9C%E8%B4%9F%E8%BD%BD%E6%8E%A7%E5%88%B6%E5%99%A8%E5%AE%9E%E7%8E%B0%20Pod%20%E7%9A%84%E7%AE%A1%E7%90%86.md)
- [深入理解 Service](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/%E4%BD%BF%E7%94%A8%E6%8C%87%E5%8D%97/%E6%B7%B1%E5%85%A5%E7%90%86%E8%A7%A3%20Service.md)
- [使用 Ingress 对外暴露应用](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/%E4%BD%BF%E7%94%A8%E6%8C%87%E5%8D%97/%E4%BD%BF%E7%94%A8%20Ingress%20%E5%AF%B9%E5%A4%96%E6%9A%B4%E9%9C%B2%E5%BA%94%E7%94%A8.md)
- [Kubernetes 存储](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/%E4%BD%BF%E7%94%A8%E6%8C%87%E5%8D%97/Kubernetes%20%E5%AD%98%E5%82%A8.md)
- [Kubernetes 安全](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/%E4%BD%BF%E7%94%A8%E6%8C%87%E5%8D%97/Kubernetes%20%E5%AE%89%E5%85%A8.md)
- [etcd 数据库的备份恢复](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/%E4%BD%BF%E7%94%A8%E6%8C%87%E5%8D%97/etcd%20%E6%95%B0%E6%8D%AE%E5%BA%93%E7%9A%84%E5%A4%87%E4%BB%BD%E6%81%A2%E5%A4%8D.md)

__项目部署案例__
- [部署 WordPress](http://www.showerlee.com/archives/2336)
- [部署 Jenkins](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/tree/master/%E9%A1%B9%E7%9B%AE%E6%A1%88%E4%BE%8B/%E9%83%A8%E7%BD%B2%20Jenkins)
- [已有状态方式部署 kafka](https://blog.csdn.net/miss1181248983/article/details/106720732)
- [部署单机 redis](https://blog.csdn.net/baidu_38432732/article/details/106429477)
- [部署群集 redis](https://segmentfault.com/a/1190000039196137)

__[CKA 题目](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/CKA%20%E8%AE%A4%E8%AF%81/README.md)__