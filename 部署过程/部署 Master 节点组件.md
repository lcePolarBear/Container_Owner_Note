## 部署 Master 节点组件

__部署所需要的执行文件和 token__

- 将 /root/kubernetes/server/bin 路径下的 kube-apiserver | kube-controller-manager | kube-scheduler 放入 /opt/kubernetes/bin/ 下
- 生成 kubernetes 所需要的 [ssl 证书和 Token](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/部署过程/准备%20Token%20和%20kubernetes%20证书.md)
- 将 pem 证书放入 /opt/kubernetes/ssl/
- 将token.csv 放入 /opt/kubernetes/cfg/

__通过 shell 脚本创建服务与配置文件__

- 使用 [apiserver.sh](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/config-files/apiserver.sh) 脚本自动化生成 kube-apiserver 配置文件 kube-apiserver.service 服务
    ```
    ./apiserver.sh 192.168.10.110 https://192.168.10.110:2379,https://192.168.10.111:2379,https://192.168.10.112:2379
    ```

    - apiserver 第一次启动会卡住好长时间，判断是否启动
        - `ps -ef|grep kube-apiserver` 有进程
        - `netstat -antp | grep 8080(6443)` 有 kube-apiserver
        - apiserver 启动后状态内容为
            ```
            [restful] 2019/06/28 16:03:37 log.go:33: [restful/swagger] https://192.168.10.110:6443/swaggerui/ is mapped to folder /swagger-ui/
            ```
            这是正常现象
    - 启动 apiserver 特别容易报错，在此多说一下常用的查验手法
        - `tail /var/log/messages -f`
        - `systemctl status kube-apiserver -l`
        - 将配置文件中的日志路径 --log-dir 重定向以方便查验 INFO 日志
        - source 导入配置文件 直接让二进制程序加配置文件参数启动以显示错误

- 使用 [controller-manager.sh](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/config-files/controller-manager.sh) 脚本自动化生成 kube-controller-manager 配置文件与 kube-controller-manager.service 服务
    ```
    ./controller-manager 127.0.0.1
    ```
- 使用 [scheduler.sh](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/config-files/scheduler.sh) 自动化生成 kube-scheduler 配置文件与 kube-scheduler.service 服务
    ```
    ./scheduler.sh 127.0.0.1
    ```
- 用 `journalctl -u` 命令可以查看启动失败的错误提示


__确保 etcd 正常的情况下可以检查群集是否正常__
```
kubectl get cs
```