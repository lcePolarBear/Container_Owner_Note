# Ingress 配置证书
## Ingress 是什么：[详细请看 Ingress 内容]()
## HTTPS 重要性
- HTTPS是安全的HTTP，HTTP 协议中的内容都是明文传输，HTTPS 的目的是将这
些内容加密，确保信息传输安全。
## 将一个项目对外暴露 HTTPS 访问
### 准备 https 步骤
- 准备域名证书
- 将证书保存至 Secret
- Ingress 规则配置 tls
- 测试，本地电脑绑定 hosts 记录对应 ingress 里面的域名