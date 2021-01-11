## 使用 deployment 和 YAML 文件实现资源编排

__YAML 语法格式__
- 缩进表示层级关系
- 不支持制表符 "tab" 缩进，使用空格缩进
- 开头缩进 2 个空格
- 冒号，横杠后面缩进 1 个空格
- "---" 表示是下一个片段的开头
- "#" 标识注释

__YAML 对资源的管理__
- 使用命令行创建镜像
    ```
    kubectl create deployment web --image=lizhenliang/java-demo -n default
    ```
- 使用 YAML 文件创建镜像
    ```
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: nginx
      namespace: default
    spec:
      replicas: 3
      selector:
        matchLabels:
          app: web2
      template:
        metadata:
          labels:
            app: web2
        spec:
          containers:
          - name: web
            image: nginx:1.18
    ```
    - apiVersion : api资源版本
    - kind : 资源类型
    - metadata : 资源元数据
    - spec : 资源规格
    - replicas : 副本数量
    - selector : 标签选择器
    - template : Pod模板
    - metadata : Pod元数据
    - spec : Pod规格
    - containers : 容器配置
- 使用命令行创建 Service ，对外暴露资源
    ```
    kubectl expose deployment web --port=80 --target-port=8080 --type=NodePort -n default
    ```
- 使用 YAML 文件创建 Service
    ```
    apiVersion: v1
    kind: Service
    metadata:
      name: web
      namespace: default
    spec:
      ports:
      - port: 80
        protocol: TCP
        targetPort: 80
      selector:
        app: web2
      type: NodePort
    ```
    - ports : 端口
    - selector : 标签选择器
    - type : Service 类型
- 使用 yaml 文件的命令
    ```
    kubectl apply -f deployment.yaml

    kubectl delete -f deployment.yaml
    ```
__导出 deployment 生成的 YAML__
- 用 create 命令生成 YAML
    ```
    kubectl create deployment nginx --image=nginx:1.16 -o yaml --dry-run=client > my-deploy.yaml
    ```
- 用 get 命令生成 YAML
    ```
    kubectl get deployment nginx -o yaml > my-deploy.yaml
    ```