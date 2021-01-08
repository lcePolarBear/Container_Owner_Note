## kubectl 命令行管理工具

__以部署 nginx 为例子展示 kubectl 管理应用程序的生命周期__
- 创建
    ```
    kubectl run nginx --replicas=3 --image=nginx:1.14 --port=80
    kubectl get deploy,pods
    ```
- 发布
    ```
    kubectl expose deployment nginx --port=80 --type=NodePort --target-port=80 --name=nginx-service
    kubectl get service
    ```
- 更新
    ```
    kubectl set image deployment/nginx nginx=1.15
    ```
- 回滚
    ```
    kubectl rollout history deploy/nginx
    kubectl rollout undo deploy/nginx
    ```
- 删除
    ```
    kubectl delete deploy/nginx
    kubectl delete svc/nginx-service
    ```

__[kubectl 命令概要](https://kubernetes.io/docs/reference/kubectl/overview/)__
- `bash-completion` 安装后能够自动补全 kubectl 命令

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