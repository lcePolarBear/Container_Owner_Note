## 部署 Web UI

__部署 Dashboard__
- 获取 [dashboard.yaml](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/%E6%89%80%E9%9C%80%E8%A6%81%E7%9A%84%E6%96%87%E4%BB%B6/dashboard.yaml) 文件
- 部署 kubernetes-dashboard 容器
    ```
    kubectl apply -f dashboard.yaml
    ```
- 查看容器信息，默认使用 30001 端口向外暴漏
    ```
    kubectl get pods,svc  -n kubernetes-dashboard
    ```
- 从浏览器访问 Dashboard 会出现禁止访问的提示，输入 thisisunsafe 可以访问
- 创建拥有管理员权限的用户
    - 获取 [dashboard-adminuser.yaml](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/%E6%89%80%E9%9C%80%E8%A6%81%E7%9A%84%E6%96%87%E4%BB%B6/dashboard-adminuser.yaml) 文件
    - 部署 dashboard-adminuser 容器以注册管理员用户
        ```
        kubectl apply -f dashboard-adminuser.yaml
        ```
    - 获取 Token
        ```
        kubectl -n kubernetes-dashboard describe secret $(kubectl -n kubernetes-dashboard get secret | grep admin-user | awk '{print $1}')
        ```
- 将获取的 Token 填入初始化 Dashboard 的 Token 验证