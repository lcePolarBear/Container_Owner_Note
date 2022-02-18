## 搭建 Harbor 并以 https 的方式访问

__确保已安装 Docker__

__安装 Dockerp-compose__

harbor 由各组件组成，通过 docker-compose 来启动
* 下载 [dockerp-compose 文件](https://github.com/docker/compose/releases/download/1.27.4/docker-compose-Linux-x86_64)
* 放入执行目录并赋予执行权限
    ```
    mv docker-compose-Linux-x86_64 /usr/local/bin/docker-compose
    ```
    ```
    chmod +x /usr/local/bin/docker-compose
    ```
* [官方文档](https://docs.docker.com/compose/install/)详细说明了这两个步骤

__安装 Harbor__
* 下载[离线安装包](https://github.com/goharbor/harbor/releases/download/v2.1.3/harbor-offline-installer-v2.1.3.tgz)
* 解压 tar 包并进入
* 创建一个 cert 文件夹进行证书操作
* 在 cert 下[生成服务器的 https 公钥私钥](https://github.com/lcePolarBear/Docker_Basic_Config_Note/blob/master/Dcoekr%20实例/使用%20openssl%20实现%20https%20证书.md)

__编辑配置文件 Harbor.yml__
```
hostname: chen.com

https:
  # https port for harbor, default is 443
  port: 443
  # The path of cert and key files for nginx
  certificate: /root/ssl/chen.com.crt
  private_key: /root/ssl/chen.com.key

harbor_admin_password: Harbor12345
```
__运行 harbor__

* 变更配置
    ```
    ./prepare
    ```
* 运行
    ```
    ./install.sh
    ```
* 查看当前 harbor 各组件运行状态
    ```
    docker-compose ps
    ```
* 在本地将 chen.com 添加入 host 后，浏览器访问 https://chen.com 即可进入Harbor

__Docker 机器的操作__
* 创建存放 Docker 证书的默认路径，放入 Harbor 生成的私钥 `chen.com.crt`
    ```
    mkdir /etc/docker/certs.d/chen.com -p
    ```
* 在 Docker 端的 /etc/hosts 中加入 chen.com
* 使用 Docker 进行登陆
    ```
    docker login chen.com
    ```
* 测试将本地已有的镜像进行推送操作
    ```
    docker tag tomcat:v1 chen.com/test/tomcat:v1
    docker push chen.com/test/tomcat:v1
    ```