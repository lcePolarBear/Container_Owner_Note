# Kubernetes 应用包管理器 Helm
由于Kubernetes缺少对发布的应用版本管理和控制，使得部署的应用维护和更新等面临诸多的挑战，主要面临以下问题。
1. 如何将这些服务作为一个整体管理？
2. 这些资源文件如何高效复用？
3. 不支持应用级别的版本管理
## 什么是 Helm
- Helm 是一个 Kubernetes 的包管理工具，就像 Linux 下的包管理器，如 yum/apt 等，可以很方便的将之前打包好的 yaml 文件部署到 kubernetes 上。
- Helm 有 3 个重要概念
    1. helm：一个命令行客户端工具，主要用于 Kubernetes 应用 chart 的创建、打包、发布和管理。
    2. Chart：应用描述，一系列用于描述 k8s 资源相关文件的集合。
    3. Release：基于 Chart 的部署实体，一个 chart 被 Helm 运行后将会生成对应的一个 release ；将在 k8s 中创建出真实运行的资源对象。
### Helm 部署
```bash
wget https://get.helm.sh/helm-v3.4.2-linux-amd64.tar.gz
tar zxvf helm-v3.4.2-linux-amd64.tar.gz 
mv linux-amd64/helm /usr/bin/
```
### Helm 官方文档：[官方链接](https://helm.sh/zh/docs/)
## Helm 管理应用生命周期
### 创建 Chart 示例
- 创建 chart
```
helm create mychart # 默认示例中部署的是一个nginx服务
```
- 打包 chart
```
helm package mychart
```