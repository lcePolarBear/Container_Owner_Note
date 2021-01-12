## 使用 Ingress 对外暴露应用

__Ingress__
- Ingress 公开了从集群外部到集群内服务的 HTTP 和 HTTPS 路由的规则集合，而具体实现流量路由则是由 Ingress Controller 负责
- Ingress Controller 根据Ingress生成具体的路由规则，并对Pod负载均衡器

__Ingress Contronler 的工作方式__
- Ingress Contronler通过与 Kubernetes API 交互，动态的去感知集群中 Ingress 规则变化，然后读取它
- 按照自定义的规则（规则就是写明了哪个域名对应哪个 service ），生成一段 Nginx 配置，应用到管理的 Nginx 服务，然后热加载生效，以此来达到 Nginx 负载均衡器配置及动态更新的问题
- 一般会在 Ingress Contronler 前面添加一个负载均衡配合 DaemonSet 或者 nodeSelector 实现高可用

__部署 Ingress Controller__
- 获取 [ingress-controller.yaml 文件](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/%E6%89%80%E9%9C%80%E8%A6%81%E7%9A%84%E6%96%87%E4%BB%B6/ingress-controller.yaml)
- 部署 ingress-controller
    ```
    kubectl apply -f ingress-controller.yaml
    ```
- 对外暴露应用
    - 创建 Ingress 路由 yaml 文件，将原有 service 的暴露接管
        ```
        apiVersion: networking.k8s.io/v1beta1
        kind: Ingress
        metadata:
          name: my-ingress-for-nginx
        spec:
          rules:
          - host: web1.ctnrs.com
            http:
              paths:
              - path: /
                backend:
                  serviceName: java-demo
                  servicePort: 80
        ```
    - 部署 yaml 文件

__以 HTTPS 的方式将应用向外部暴露__
- 以 `blog.ctnrs.com` 域名通过 [shell 脚本](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/%E6%89%80%E9%9C%80%E8%A6%81%E7%9A%84%E6%96%87%E4%BB%B6/blog.ctnrs.com-certs.sh)创建证书
- 将证书保存在 kubernetes 中
    ```
    kubectl create secret tls blog-ctnrs-com --cert=blog.ctnrs.com.pem --key=blog.ctnrs.com-key.pem
    ```
- 创建以 https 方式暴露应用的 yaml 文件
    ```
    apiVersion: networking.k8s.io/v1beta1
    kind: Ingress
    metadata:
      name: blog
    spec:
      tls: 
      - hosts:
        - blog.ctnrs.com
        secretName: blog-ctnrs-com
      rules:
      - host: blog.ctnrs.com
        http:
          paths:
          - path: /
            backend:
              serviceName: java-demo
              servicePort: 80
    ```
- 部署 yaml 文件