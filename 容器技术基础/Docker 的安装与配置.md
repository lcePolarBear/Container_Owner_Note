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
### 配置 docker 镜像仓库地址
- 添加中国区官方镜像仓库地址用于加速镜像拉取
    ```json
    # vi /etc/docker/daemon.json

    {
        "registry-mirrors":["https://registry.docker-cn.com","http://hub-mirror.c.163.com","https://docker.mirrors.ustc.edu.cn"]
    }
    ```