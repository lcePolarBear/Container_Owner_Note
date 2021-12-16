# kubernetes 安全框架
## Authentication
- HTTPS 证书认证：基于CA证书签名的数字证书认证（kubeconfig）
- HTTP Token认证：通过一个Token来识别用户（serviceaccount）
## Authorization
- RBAC（Role-Based Access Control，基于角色的访问控制）：负责完成授权（Authorization）工作
- 是K8s默认授权策略，并且是动态配置策略（修改即时生效）。
- 主体
- 角色
- 角色绑定
- k8s 预定好了四个集群角色供用户使用，使用 `kubectl get clusterrole` 查看（其中 systemd: 开头的为系统内部使用）。
1. 对用户授权访问 K8s（TLS证书）
2. 对应用程序授权访问 K8s（ServiceAccount）
3. 资源配额 ResourceQuota
## Admission Control
- Adminssion Control实际上是一个准入控制器插件列表，发送到API Server的请求都需要经过这个列表中的每个准入控制器插件的检查，检查不通过，则拒绝请求。
    - 启用一个准入控制器
    - 关闭一个准入控制器
    - 查看默认启用
