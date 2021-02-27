## 部署 Jenkins 的流程

__部署 nfs__
1. 首先在 nfs 服务器上分配出供 Jenkins 使用的文件夹
2. 创建 StorageClass 提供动态的 pv 分配
    - 部署 [rbac.yaml](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/%E9%A1%B9%E7%9B%AE%E6%A1%88%E4%BE%8B/%E9%83%A8%E7%BD%B2%20Jenkins/nfs-deploymnet/RBAC.yaml)
    - 部署 [StorageClass.yaml](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/%E9%A1%B9%E7%9B%AE%E6%A1%88%E4%BE%8B/%E9%83%A8%E7%BD%B2%20Jenkins/nfs-deploymnet/StorageClass.yaml)
    - 部署自动分配 pv 的 [NFS-Deployment.yaml](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/%E9%A1%B9%E7%9B%AE%E6%A1%88%E4%BE%8B/%E9%83%A8%E7%BD%B2%20Jenkins/nfs-deploymnet/NFS-Deployment.yaml)

__部署 jenkins rbac__
- 部署 [service-account.yaml](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/%E9%A1%B9%E7%9B%AE%E6%A1%88%E4%BE%8B/%E9%83%A8%E7%BD%B2%20Jenkins/service-account.yml)

__部署 Jenkins__
- 部署 [jenkins-StatefulSet.yml](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/%E9%A1%B9%E7%9B%AE%E6%A1%88%E4%BE%8B/%E9%83%A8%E7%BD%B2%20Jenkins/jenkins-StatefulSet.yml)