## 准备 Token 和 kubernetes 证书

__生成 kubernetes 证书__
- 自动化脚本[k8s-cert.sh](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/config-files/k8s-cert.sh
) 生成所需证书
    - 注意 server-csr.json 下的 hosts 不包含 node 节点的 ip

__生成 Token__
```
# export BOOTSTRAP_TOKEN=$(head -c 16 /dev/urandom | od -An -t x | tr -d ' ')
cat > token.csv <<EOF （用来随机生成 token 在这里我们不随机生成而是使用静态 token ）

BOOTSTRAP_TOKEN=0fb61c46f8991b718eb38d27b605b008
${BOOTSTRAP_TOKEN},kubelet-bootstrap,10001,"system:kubelet-bootstrap"
EOF
```
- 分析 token.csv 的内容
    ```
    0fb61c46f8991b718eb38d27b605b008,kubelet-bootstrap,10001,"system:kubelet-bootstrap"
    ```
    > token 是一个访问权限的认证 kubelet-bootstrap 为用户名 system:kubelet-bootstrap 是分组 
    
- token.csv 作用是让 node 节点能利用 token 中的用户信息去访问群集
    > Token 用来配置 APIserver ， 同时 Token 用来生成配置 kubelet 的 bootstrap ， 通过这层关系完成的身份认证