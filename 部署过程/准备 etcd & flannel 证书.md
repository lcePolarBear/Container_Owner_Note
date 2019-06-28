## 准备 etcd & flannel 证书

__etcd & flannel 所需证书__
```
ca.pem | ca-key.pem | server.pem | server-key.pem
```

__安装证书生成工具 cfssl__

* 用 openssl 来完成 ssl 的认证非常麻烦，所以我们用 cfssl 来完成

* 获取 cfssl
    ```
    wget https://pkg.cfssl.org/R1.2/cfssl_linux-amd64
    wget https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64
    wget https://pkg.cfssl.org/R1.2/cfssl-certinfo_linux-amd64
    ```
    - cfssl 用于生成证书    
      cfssljson 用于将 json 文本导入证书  
      cfssl-certinfo 查看证书信息

* 赋予执行权限
    ```
    chmod +x cfssl_linux-amd64 cfssljson_linux-amd64 cfssl-certinfo_linux-amd64
    ```

* 加入到可直接执行命令中
    ```
    mv cfssl_linux-amd64 /usr/local/bin/cfssl
    mv cfssljson_linux-amd64 /usr/local/bin/cfssljson
    mv cfssl-certinfo_linux-amd64 /usr/local/bin/cfssl-certinfo
    ```

__手动生成 etcd 所需证书__ 
- 生成 ca 请求 ca-csr.json
    ```
    {
        "CN": "etcd CA",
        "key": {
            "algo": "rsa",
            "size": 2048
        },
        "names": [
            {
                "C": "CN",
                "L": "Beijing",
                "ST": "Beijing"
            }
        ]
    }
    ```
- 生成 ca 根证书 生成 ca.pem | ca-key.pem | ca.csr
    ```
    cfssl gencert -initca ca-csr.json | cfssljson -bare ca -
    ```
- 生成 ca 机构的属性 ca-config.json
    ```
    {
    "signing": {
        "default": {
        "expiry": "87600h"
        },
        "profiles": {
        "www": {
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
- 配置 etcd 证书的域名 server-csr.json
    ```
    {
        "CN": "etcd",
        "hosts": [
        "192.168.10.110",
        "192.168.10.111",
        "192.168.10.112"
        ],
        "key": {
            "algo": "rsa",
            "size": 2048
        },
        "names": [
            {
                "C": "CN",
                "L": "BeiJing",
                "ST": "BeiJing"
            }
        ]
    }
    ```
- 生成 etcd 证书 server.pem | server-kay.pem
    ```
    cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=www server-csr.json | cfssljson -bare server
    ```
__自动化脚本 [etcd-cert.sh](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/config-files/etcd-cert.sh) 生成以上 pem 私钥文件__
- 注意要修改其中的群集节点 ip 地址！
