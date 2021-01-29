## kubectl 命令行管理工具
- [kubectl 命令概要](https://kubernetes.io/zh/docs/reference/kubectl/overview/)
- 自动补全 kubectl 命令
    - yum 安装 `bash-completion`
    - 重启 shell 后执行
        ```
        source <(kubectl completion bash)
        ```

__kubeconfig 配置文件__
- kubectl 能够管理群集信息是因为存在 `./kube/config` 配置文件能够让 kubectl 与 api-server 连接
- 如果要在别的节点上使用 kubectl 则必须要有 config 文件

__快速部署一个示例网站__
- 使用 deployment 控制器部署镜像
    ```
    kubectl create deployment java-demo --image=lizhenliang/java-demo
    ```
- 查看部署的进度
    ```
    kubectl describe pod java-demo-8548998c57-kjv8l
    ```
- 向外暴漏端口
    ```
    kubectl expose deployment java-demo --port=80 --target-port=8080 --type=NodePort
    ```

__[通过工作负载控制器实现 Pod 的管理](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/%E4%BD%BF%E7%94%A8%E6%8C%87%E5%8D%97/%E9%80%9A%E8%BF%87%E5%B7%A5%E4%BD%9C%E8%B4%9F%E8%BD%BD%E6%8E%A7%E5%88%B6%E5%99%A8%E5%AE%9E%E7%8E%B0%20Pod%20%E7%9A%84%E7%AE%A1%E7%90%86.md)完整步骤__