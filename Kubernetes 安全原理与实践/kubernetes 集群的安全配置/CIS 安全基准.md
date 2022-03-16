# CIS 安全基准
## CIS安全基准介绍
- Center for Internet Security （互联网安全中心）是一个个非盈利组织，致力为互联网提供免费的安全防御解决方案。
- CIS 提供 pdf 文件可供用户根据其中的基准检查 kubernetes 群集是否安全部署和配置
- 主要是查找不安全的配置参数、敏感的文件权限、不安全的账户或公开端口等等
## kubernetes 安全基准工具 kube-bench
### kube-bench 部署
- 下载二进制包 Github 链接(https://github.com/aquasecurity/kube-bench/releases)
- 解压使用
    ```sh
    tar zxvf kube-bench_0.6.3_linux_amd64.tar.gz 
    mkdir /etc/kube-bench # 创建默认配置文件路径
    mv cfg /etc/kube-bench/cfg
    ```
### kube-bench 使用
- 检查 master 组件安全配置
kube-bench run --targets=master
执行后会逐个检查安全配置并输出修复方案及汇总信息输出
- 测试项目配置文件 /etc/kube-bench/cfg/cis-1.6/
    - id: 1.1.2
    text: "Ensure that the API server pod specification file ownership is set to root:root (Automated)"
    audit: "/bin/sh -c 'if test -e $apiserverconf; then stat -c %U:%G $apiserverconf; fi'"
    tests:
        test_items:
        - flag: "root:root"
    remediation: |
        Run the below command (based on the file location on your system) on the master node.
        For example,
        chown root:root $apiserverconf
    scored: true
    type: "skip" # 跳过检查
