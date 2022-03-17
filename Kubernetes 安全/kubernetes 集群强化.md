# kubernetes 集群强化
## kubernetes 安全框架
### Authentication
- HTTPS 证书认证：基于CA证书签名的数字证书认证（kubeconfig）
- HTTP Token认证：通过一个Token来识别用户（serviceaccount）
### Authorization
- RBAC（Role-Based Access Control，基于角色的访问控制）：负责完成授权（Authorization）工作
- 是K8s默认授权策略，并且是动态配置策略（修改即时生效）。
- 主体
- 角色
- 角色绑定
- k8s 预定好了四个集群角色供用户使用，使用 `kubectl get clusterrole` 查看（其中 systemd: 开头的为系统内部使用）。
## RBAC 认证授权案例
### 1. 对用户授权访问 K8s（TLS证书）
1. 用 k8s ca 签发客户端证书
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
        "O": "",
        "OU": "System"
        }
    ]
    }
    EOF

    cfssl gencert -ca=/etc/kubernetes/pki/ca.crt -ca-key=/etc/kubernetes/pki/ca.key -config=ca-config.json -profile=kubernetes chen-csr.json | cfssljson -bare chen
    ```
2. 生成 kubeconfig 授权文件
    ```bash
    kubectl config set-cluster kubernetes \
    --certificate-authority=/etc/kubernetes/pki/ca.crt \
    --embed-certs=true \
    --server=https://192.168.102.249:16443 \
    --kubeconfig=chen.kubeconfig
    
    # 设置客户端认证
    kubectl config set-credentials chen \
    --client-key=chen-key.pem \
    --client-certificate=chen.pem \
    --embed-certs=true \
    --kubeconfig=chen.kubeconfig

    # 设置默认上下文
    kubectl config set-context kubernetes \
    --cluster=kubernetes \
    --user=chen \
    --kubeconfig=chen.kubeconfig

    # 设置当前使用配置
    kubectl config use-context kubernetes --kubeconfig=chen.kubeconfig
    ```
3. 创建 rbac 策略权限
    ```
    kind: Role
    apiVersion: rbac.authorization.k8s.io/v1
    metadata:
    namespace: default
    name: pod-reader
    rules:
    - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "watch", "list"]

    ---

    kind: RoleBinding
    apiVersion: rbac.authorization.k8s.io/v1
    metadata:
    name: read-pods
    namespace: default
    subjects:
    - kind: User
    name: chen
    apiGroup: rbac.authorization.k8s.io
    roleRef:
    kind: Role
    name: pod-reader
    apiGroup: rbac.authorization.k8s.io
    ```
4. 指定 kubeconfig 文件测试权限
    ```bash
    kubectl get pods --kubeconfig=./chen.kubeconfig
    ```
### 2. 对应用程序授权访问 K8s（ServiceAccount）
```yaml
apiVersion: v1
kind: ServiceAccount 
metadata:
name: py-k8s 
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
namespace: default
name: py-role 
rules:
- apiGroups: [""]
resources: ["pods"]
verbs: ["get", "watch", "list"]
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
name: py-role 
namespace: default
subjects:
- kind: ServiceAccount 
name: py-k8s 
roleRef:
kind: Role
name: py-role 
apiGroup: rbac.authorization.k8s.io
---
apiVersion: v1
kind: Pod
metadata:
name: py-k8s 
spec:
serviceAccountName: py-k8s 
containers:
- image: python:3
    name: python
    command:
    - sleep 
    - 24h
```
## 资源配额 ResourceQuota
1. 计算资源配额
2. 存储资源配额
3. 对象数量配额
## 资源限制 LimitRange
1. 计算资源最大、最小限制
2. 计算资源默认值限制
3. 存储资源最大、最小限制
## Admission Control
- Adminssion Control实际上是一个准入控制器插件列表，发送到API Server的请求都需要经过这个列表中的每个准入控制器插件的检查，检查不通过，则拒绝请求。
    - 启用一个准入控制器
    - 关闭一个准入控制器
    - 查看默认启用
