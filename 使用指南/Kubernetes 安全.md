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
    # 创建 ca ca.key
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
      resources: ["pods","deployments"]   # 资源
      verbs: ["get", "watch", "list"]   # 对资源的操作权限
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
      name: jane
      apiGroup: rbac.authorization.k8s.io
    roleRef:
      kind: Role
      name: pod-reader
      apiGroup: rbac.authorization.k8s.io
    ```
    ```shell
    # 指定 kubeconfig 文件测试
    kubectl get pods --kubeconfig=./aliang.kubeconfig
    ```