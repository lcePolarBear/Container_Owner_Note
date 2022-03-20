# Kubernetes 中的组件安全

## Kubernetes 中的组件

## 扫描群集漏洞

对于一个 Kubernetes 集群而言，我们希望能快速地了解到集群当前的漏洞情况。这里介绍一个项目叫做 [kube-hunter](https://github.com/aquasecurity/kube-hunter) ，它就是由 Aqua Security 开源的一款专门用于发现 Kubernetes 集群中漏洞的工具。

我们可以直接去 kube-hunter 的官网 [kube-hunter.aquasec.com/](http://kube-hunter.aquasec.com/)

1. 在首页填写自己的邮箱，它会给我们返回一个可直接粘贴的命令。
2. 去 Kubernetes 集群的 master Node 上使用复制好的命令进行粘贴，这个命令是使用主机网络模式去运行 kube-hunter，启动后它会提示让我们进行选择，我们可以直接选择 "2"，进行 Interface scanning 。
3. 最后，它会给出一个链接，我们可以点击链接在它的网页上进行结果的查看。

## 扫描集群的配置是否符合 CIS 的规范

### CIS 安全基准介绍

- Center for Internet Security （互联网安全中心）是一个个非盈利组织，致力为互联网提供免费的安全防御解决方案。
- CIS 提供 pdf 文件可供用户根据其中的基准检查 kubernetes 群集是否安全部署和配置
- 主要是查找不安全的配置参数、敏感的文件权限、不安全的账户或公开端口等等

### Kuebrnetes 安全基准工具 kube-bench

**部署**

- 下载[二进制安装包](https://github.com/aquasecurity/kube-bench/releases)
- 解压
    
    ```bash
    tar zxvf kube-bench_0.6.3_linux_amd64.tar.gz 
    mkdir /etc/kube-bench # 创建默认配置文件路径
    mv cfg /etc/kube-bench/cfg
    ```
    

**使用**

- 检查 master 组件安全配置
    
    ```bash
    kube-bench run --targets=master
    # 执行后会逐个检查安全配置并输出修复方案及汇总信息输出
    ```
    
- 测试项目配置文件 /etc/kube-bench/cfg/cis-1.6/