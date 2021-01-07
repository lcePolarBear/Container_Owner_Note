## 准备 Token 和 kubernetes 证书

__Master 所需的证书__
- ca.pem
- ca-key.pem
- server.pem
- server-key.pem

__Node 所需的证书__
- ca.pem
- kube-proxy.pem
- kube-proxy-key.pem

__手动生成 kubernetes 证书__
- k8s 证书的生成与 etcd 是非常类似的，先创建文件 `ca-csr.json`
    ```
    {
        "CN": "kubernetes",
        "key": {
            "algo": "rsa",
            "size": 2048
        },
        "names": [
            {
                "C": "CN",
                "L": "Beijing",
                "ST": "Beijing",
                "O": "k8s",
                "OU": "System"
            }
        ]
    }
    ```
- 使用 cfssl 命令创建证书： ca.csr , ca-key.pem , ca.pem
    ```
    cfssl gencert -initca ca-csr.json | cfssljson -bare ca -
    ```
- 创建 `ca-config.json` 文件
    ```
    {
      "signing": {
        "default": {
          "expiry": "87600h"
        },
        "profiles": {
          "kubernetes": {
            "expiry": "87600h",
            "usages": [
                "signing",
                "key encipherment",
                "server auth",
                "client auth"
            ]
          }
        }
      }
    }
    ```
- 创建 `server-csr.json` 文件
    ```
    {
        "CN": "kubernetes",
        "hosts": [
          "10.0.0.1",
          "127.0.0.1",
          "kubernetes",
          "kubernetes.default",
          "kubernetes.default.svc",
          "kubernetes.default.svc.cluster",
          "kubernetes.default.svc.cluster.local",
          "192.168.1.11",
          "192.168.1.20",
          "192.168.1.21",
          "192.168.1.22"
        ],
        "key": {
            "algo": "rsa",
            "size": 2048
        },
        "names": [
            {
                "C": "CN",
                "L": "BeiJing",
                "ST": "BeiJing",
                "O": "k8s",
                "OU": "System"
            }
        ]
    }
    ```
    - 注意 hosts 下的地址只需要添加 master , Load Balancer 的地址，不需要添加 node 节点的地址
- 执行命令创建证书： server.csr , server-key.pem , server.pem
    ```
    cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes server-csr.json | cfssljson -bare server
    ```
- 创建 `kube-proxy-csr.json` 文件
    ```
    {
      "CN": "system:kube-proxy",
      "hosts": [],
      "key": {
        "algo": "rsa",
        "size": 2048
      },
      "names": [
        {
          "C": "CN",
          "L": "BeiJing",
          "ST": "BeiJing",
          "O": "k8s",
          "OU": "System"
        }
      ]
    }
    ```
- 执行命令创建证书: kube-proxy.csr , kube-proxy-key.pem , kube-proxy.pem
    ```
    cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes kube-proxy-csr.json | cfssljson -bare kube-proxy
    ```

__Token__
- 我们可以使用预先编写的 `token.csv` 文件
    ```
    c47ffb939f5ca36231d9e3121a252940,kubelet-bootstrap,10001,"system:node-bootstrapper"
    ```
- 分析 token.csv 的内容
    - __token__ 是一个访问权限的认证 __kubelet-bootstrap__ 为用户名 __system:kubelet-bootstrap__ 是分组 
    - token.csv 作用是让 node 节点能利用 token 中的用户信息去访问群集
    - Token 用来配置 APIserver ， 同时 Token 用来生成配置 kubelet 的 bootstrap ， 通过这层关系完成的身份认证
- token 也可以自行生成替换
    ```
    head -c 16 /dev/urandom | od -An -t x | tr -d ' '
    ```