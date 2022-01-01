# Docker 的安装与配置
### 安装 Docker
- 确保时间同步 
- Dcoker 的安装步骤在官方文档中已经详细的说明了 [官方链接](https://docs.docker.com/engine/install/centos/)
- 可以将 docker-ce.repo 替换为国内源以加快下载和安装的速度
    ```bash
    [root@jump ~]# wget https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo -O /etc/yum.repos.d/docker-ce.repo
    ```
- 选择指定的 Docker 版本进行安装
    ```bash
    [root@jump ~]# yum list docker-ce --showduplicates | sort -r
    [root@jump ~]# yum install docker-ce-19.03.9-3.el7 -y
    ```
- 验证 Docker 安装
    ```bash
    [root@jump ~]# docker info
    ```
- Ubuntu 安装 Dokcer
    - [官方文档地址](https://docs.docker.com/engine/install/ubuntu/)
    - [Ubuntu 18.04 通过通过阿里云源安装 docker](https://www.jianshu.com/p/2e6459475dcd)
        ```bash
        # 更新apt库
        sudo apt update
        
        # 以下安装使得允许apt通过HTTPS使用存储库
        sudo apt install apt-transport-https ca-certificates curl software-properties-common

        # 添加阿里 GPG 秘钥
        curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | sudo apt-key add -

        # 添加阿里 docker 源
        sudo add-apt-repository \
          "deb [arch=amd64] http://mirrors.aliyun.com/docker-ce/linux/ubuntu \
          $(lsb_release -cs) \
          stable"

        # 再次更新 apt 源
        sudo apt update

        # 查看 docker 有哪些版本
        apt-cache madison docker-ce

        # 安装 docker 指定版本
        sudo apt-get install -y docker-ce=5:19.03.15~3-0~ubuntu-focal
        ```
### 配置 docker 镜像仓库地址
- 添加中国区官方镜像仓库地址用于加速镜像拉取
    ```json
    # vi /etc/docker/daemon.json

    {
        "registry-mirrors":["https://registry.docker-cn.com","http://hub-mirror.c.163.com","https://docker.mirrors.ustc.edu.cn"]
    }

    # 重启 docker 后生效
    ```