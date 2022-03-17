## 部署 kubernetes 内部 DNS 服务
> DNS 为 service 提供域名解析

__部署 CoreDNS__
- 使用 `kubectl get svc` 可以获取到 service name 和对应的内部 ip 地址
    > DNS 的作用就是讲这两者对应起来
- 获取 [coredns.yaml](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/%E6%89%80%E9%9C%80%E8%A6%81%E7%9A%84%E6%96%87%E4%BB%B6/coredns.yaml) 文件
- 部署 DNS 容器
    ```
    kubectl apply -f coredns.yaml
    ```

__测试 DNS 能否正常解析__
- 获取 [bs.yaml](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/%E6%89%80%E9%9C%80%E8%A6%81%E7%9A%84%E6%96%87%E4%BB%B6/bs.yaml) 文件
- 部署 busybox 容器
    ```
    kubectl apply -f bs.yaml
    ```
    - 使用 `kubectl get pods` 查看 busybox 是否成功运行起来（处于 Running 状态）
- 进入容器
    ```
    kubectl exec -it busybox sh
    ```
- 使用 nslookup 的命令查看 service name能否被解析
    ```
    nslookup web
    ```
    ```
    nslookup kubernetes
    ```