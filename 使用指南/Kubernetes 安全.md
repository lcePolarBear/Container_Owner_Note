## Kubernetes 安全

__Kubernetes 安全框架__
- Authentication : 鉴权
    - 三种客户端身份认证
        - HTTPS 证书认证 : 基于 CA 证书签名的数字证书认证
        - HTTP Token 认证 : 通过一个 Token 来识别用户
        - HTTP Base 认证 : 用户名 + 密码的方式认证
- Authorization : 授权
    - RBAC （ Role-Based Access Control ，基于角色的访问控制） : 负责完成授权 (Authorization) 工作
    - RBAC 根据 API 请求属性，决定允许还是拒绝，比较常见的授权维度示例 :
        - 用户名 : user
        - 用户组 : group
        - 资源 : 例如 pod , deployment
        - 资源操作方法 : get , list , create , update , patch , watch , delete
        - 命名空间
        - API
- Admission Control : 准入控制
    - Adminssion Control 实际上是一个准入控制器插件列表，发送到 API Server 的请求都需要经过这个列表中的每个准入控制器插件的检查，检查不通过则拒绝请求

__案例 : 为 chen 用户授权 default 命名空间 Pod 读取权限__
- 认证流程 : 客户端（证书内容） ----> APIServer （证书校验） ---> RBAC （分配权限）
- 用 K8S CA 签发客户端证书
    ```json
    cat > ca-config.json <<EOF
    {
      "signing": {
        "default": {
          "expiry": "87600h"
        },
        "profiles": {
          "kubernetes": {
            "usages": [
                "signing",
                "key encipherment",
                "server auth",
                "client auth"
            ],
            "expiry": "87600h"
          }
        }
      }
    }
    EOF
    ```
    ```json
    cat > chen-csr.json <<EOF
    {
      "CN": "chen",
      "hosts": [],
      "key": {
        "algo": "rsa",
        "size": 2048
      },
      "names": [
        {
          "C": "CN",
          "ST": "BeiJing",
          "L": "BeiJing",
          "O": "k8s",
          "OU": "System"
        }
      ]
    }
    EOF
    ```
    ```shell
    # 创建 ca , ca.key 证书
    cfssl gencert -ca=/etc/kubernetes/pki/ca.crt -ca-key=/etc/kubernetes/pki/ca.key -config=ca-config.json -profile=kubernetes chen-csr.json | cfssljson -bare chen
    ```
- 生成 kubeconfig 授权文件
    ```shell
    # 创建授权文件
    kubectl config set-cluster kubernetes \
      --certificate-authority=/etc/kubernetes/pki/ca.crt \
      --embed-certs=true \
      --server=https://192.168.1.202:6443 \
      --kubeconfig=chen.kubeconfig
    ```
    ```shell
    # 设置客户端认证
    kubectl config set-credentials chen \
      --client-key=chen-key.pem \
      --client-certificate=chen.pem \
      --embed-certs=true \
      --kubeconfig=chen.kubeconfig
    ```
    ```shell
    # 设置默认上下文
    kubectl config set-context kubernetes \
      --cluster=kubernetes \
      --user=chen \
      --kubeconfig=chen.kubeconfig
    ```
    ```shell
    # 设置当前使用配置 
    kubectl config use-context kubernetes --kubeconfig=chen.kubeconfig
    ```
- 创建 RBAC 权限策略
    ```yaml
    # 创建策略
    apiVersion: rbac.authorization.k8s.io/v1 
    kind: Role 
    metadata: 
      namespace: default 
      name: pod-reader 
    rules: 
    - apiGroups: [""]   # 核心组
      resources: ["pods","deployments"]   # 选择 pod deployment 资源
      verbs: ["get","watch","list"]   # 对资源的操作权限
    ```
    ```yaml
    # 创建绑定对象
    apiVersion: rbac.authorization.k8s.io/v1
    kind: RoleBinding
    metadata:
      name: read-pods
      namespace: default
    subjects:
    - kind: User
      name: chen    # 指定用户名
      apiGroup: rbac.authorization.k8s.io
    roleRef:
      kind: Role
      name: pod-reader
      apiGroup: rbac.authorization.k8s.io
    ```
    ```shell
    # 指定 kubeconfig 文件测试
    kubectl --kubeconfig=./chen.kubeconfig get pods
    ```

__网络安全框架__
> [官方指南](https://kubernetes.io/zh/docs/concepts/services-networking/network-policies/)

- 网络策略 (Network Policy) ，用于限制 Pod 出入流量，提供 Pod 级别和 Namespace 级别网络访问控制，经常用于
    - 应用程序间的访问控制。例如微服务 A 允许访问微服务 B ，微服务 C 不能访问微服务A
    - 开发环境命名空间不能访问测试环境命名空间 Pod
    - 当 Pod 暴露到外部时，需要做 Pod 白名单 
    - 多租户网络环境隔离
- Pod 网络入口方向隔离
    - 基于 Pod 级网络隔离 : 只允许特定对象访问 Pod（使用标签定义），允许白名单上的 IP 地址或者 IP 段访问 Pod
    -  基于 Namespace 级网络隔离 : 多个命名空间，A 和 B 命名空间 Pod 完全隔离
- Pod 网络出口方向隔离
    - 拒绝某个 Namespace 上所有 Pod 访问外部
    - 基于目的 IP 的网络隔离 : 只允许 Pod 访问白名单上的 IP 地址或者 IP 段
    - 基于目标端口的网络隔离 : 只允许 Pod 访问白名单上的端口

__示例：将 default 命名空间携带 run=web 标签的 Pod 隔离，只允许 default 命名空间携带 run=client1 标签的 Pod 访问 80 端口__
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: test-network-policy
  namespace: default
spec:
  podSelector:    # 目标 Pod，根据标签选择 
    matchLabels:
      run: web
  policyTypes:    # 策略类型，指定策略用于入站、出站流量
  - Ingress
  ingress:
  - from:   # from 是可以访问的白名单，可以来自于 IP 段，命名空间， Pod 标签等
    - namespaceSelector:
        matchLabels:
          project: default
    - podSelector:
        matchLabels:
          run: client1
    ports:    # ports 是可以访问的端口
    - protocol: TCP
    port: 80
```
__示例：default 命名空间下所有 pod 可以互相访问，也可以访问其他命名空间 Pod ，但其他命名空间不能访问 default 命名空间 Pod__
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-from-other-namespaces
  namespace: default
spec:
  podSelector: {}   # 如果未配置，默认所有 Pod
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector: {}   # 如果未配置，默认不允许
```