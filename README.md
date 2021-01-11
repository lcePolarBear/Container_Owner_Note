# Kubernetes_Basic_Config_Note
容器编排引擎 k8s 的基础配置备忘录 

__[kubernetes 体系概览](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/kubernetes%20%E4%BD%93%E7%B3%BB%E6%A6%82%E8%A7%88.md)__

__二进制部署流程__
1. [系统初始化](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/%E9%83%A8%E7%BD%B2%E8%BF%87%E7%A8%8B/%E7%B3%BB%E7%BB%9F%E5%88%9D%E5%A7%8B%E5%8C%96.md)
2. [部署 etcd 存储](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/部署过程/部署%20etcd%20群集.md)
3. [准备 Token 和 Kubernetes 证书](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/%E9%83%A8%E7%BD%B2%E8%BF%87%E7%A8%8B/%E5%87%86%E5%A4%87%20Token%20%E5%92%8C%20kubernetes%20%E8%AF%81%E4%B9%A6.md)
4. [部署 Master 节点组件：kube-apiserver , kube-controller-manager , kube-scheduler](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/部署过程/部署%20Master%20节点组件.md)
5. [部署 Node 节点组件：kubelet , kube-proxy](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/部署过程/部署%20Node%20节点组件.md)
6. [部署 kubernetes 群集网络](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/%E9%83%A8%E7%BD%B2%E8%BF%87%E7%A8%8B/%E9%83%A8%E7%BD%B2%20kubernetes%20%E7%BE%A4%E9%9B%86%E7%BD%91%E7%BB%9C.md)
7. [部署 Web UI](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/%E9%83%A8%E7%BD%B2%E8%BF%87%E7%A8%8B/%E9%83%A8%E7%BD%B2%20Web%20UI.md)
8. [部署 kubernetes 内部 DNS 服务](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/%E9%83%A8%E7%BD%B2%E8%BF%87%E7%A8%8B/%E9%83%A8%E7%BD%B2%20kubernetes%20%E5%86%85%E9%83%A8%20DNS%20%E6%9C%8D%E5%8A%A1.md)

__使用指南__
- [kubectl 命令行管理工具](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/%E4%BD%BF%E7%94%A8%E6%8C%87%E5%8D%97/kubectl%20%E5%91%BD%E4%BB%A4%E8%A1%8C%E7%AE%A1%E7%90%86%E5%B7%A5%E5%85%B7.md)
- [使用 deployment 和 YAML 文件实现资源编排](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/%E4%BD%BF%E7%94%A8%E6%8C%87%E5%8D%97/%E4%BD%BF%E7%94%A8%20deployment%20%E5%92%8C%20YAML%20%E6%96%87%E4%BB%B6%E5%AE%9E%E7%8E%B0%E8%B5%84%E6%BA%90%E7%BC%96%E6%8E%92.md)
- [通过 YAML 文件实现 Pod 的基本管理](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/%E4%BD%BF%E7%94%A8%E6%8C%87%E5%8D%97/%E9%80%9A%E8%BF%87%20YAML%20%E6%96%87%E4%BB%B6%E5%AE%9E%E7%8E%B0%20Pod%20%E7%9A%84%E5%9F%BA%E6%9C%AC%E7%AE%A1%E7%90%86.md)
- [管理 Pod 的调度](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/%E4%BD%BF%E7%94%A8%E6%8C%87%E5%8D%97/%E7%AE%A1%E7%90%86%20Pod%20%E7%9A%84%E8%B0%83%E5%BA%A6.md)
- [通过工作负载控制器实现 Pod 的管理](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/%E4%BD%BF%E7%94%A8%E6%8C%87%E5%8D%97/%E9%80%9A%E8%BF%87%E5%B7%A5%E4%BD%9C%E8%B4%9F%E8%BD%BD%E6%8E%A7%E5%88%B6%E5%99%A8%E5%AE%9E%E7%8E%B0%20Pod%20%E7%9A%84%E7%AE%A1%E7%90%86.md)
- [深入理解 Service](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/%E4%BD%BF%E7%94%A8%E6%8C%87%E5%8D%97/%E6%B7%B1%E5%85%A5%E7%90%86%E8%A7%A3%20Service.md)