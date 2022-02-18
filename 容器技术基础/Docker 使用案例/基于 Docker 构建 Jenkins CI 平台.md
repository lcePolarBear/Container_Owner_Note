## 基于 Docker 构建 Jenkins CI 平台

__目标__
- 将 git 仓库的代码拉到本地使用maven进行编译，打包成 docker 镜像推送到 Harbor ，从 Harbor 拉取镜像并运行

__准备工作__
- 首先 Node1 和 Node2 都必须[安装 docker](https://github.com/lcePolarBear/Docker_Basic_Config_Note/blob/master/Docker%20%E7%94%A8%E6%B3%95/%E9%83%A8%E7%BD%B2%E5%9C%A8%20CentOS%E4%B8%8A.md) 和 git ，且防火墙都已关闭

__部署工作__
- Node2 部署 docker-compose：
    - 部署 docker-compose 的目的是为了安装 Harbor
    - 将 [docker-compose 文件](https://github.com/docker/compose/releases/download/1.27.4/docker-compose-Linux-x86_64)赋予执行权限，放入 /usr/bin/ 路径下
        ```
        chmod +x docker-compose-Linux-x86_64
        mv docker-compose-Linux-x86_64 /usr/bin/docker-compose
        ```
- Node2 部署 Harbor
    - 将 [Harbor 离线安装包](https://github.com/goharbor/harbor/releases/download/v2.0.0/harbor-offline-installer-v2.0.0.tgz)解压
    - 进入目录修改配置文件 harbor.yml
        ```
        mv harbor.yml.tmpl harbor.yml
        vi harbor.yml
            hostname = 192.168.1.12
        ```
        - 注意默认是开启 https 的，要将这部分注释掉不然 Harbor 起不来
        - admin 用户的密码也可以找到： harbor_admin_password = Harbor12345
    - 执行 ./prepare 确认安装前的准备工作
    - 执行 ./install.sh 安装 Harbor
    - Docker 端登陆 Harbor 需要先配置 daemon.json
        ```
        { "insecure-registries":["192.168.1.12"] }
        ```
    - 测试：在 Node1 中拉下一个 tomcat 镜像提交给 Node2 的 harbor ( harbor 项目的镜像仓库会有推送命令的提示)
        ```
        docker pull tomcat:latest
        docker login 192.168.1.12 -u admin
        docker tag tomcat:latest 192.168.1.12/library/tomcat:v1
        docker push 192.168.1.12/library/tomcat:v1
        ```
        - 将此 tomcat:latest 镜像推上去后面才能利用这个镜像构建自己的 Dockerfile
- Node2 初始化 git 仓库
    - 创建系统用户 git
        ```
        useradd git
        passwd git
        ```
    - 安装 git
        ```
        yum install -y git
        ```
    - 配置 git 用户信息
        ```
        git config --global user.email "zc@mail.com"
        git config --global user.name "zc"
        ```
    - 创建项目目录并进入
        ```
        mkdir tomcat-java-demo.git
        cd tomcat-java-demo.git
        ```
    - 将此目录初始化为 git 仓库
        ```
        git --bare init
        ```
    - 切换到 root 账户的根目录，我们准备克隆一个项目做提交测试
        ```
        git clone https://github.com/lizhenliang/tomcat-java-demo
        cd tomcat-java-demo/
        ```
    - 修改配置信息，把 github 的 url 改成刚刚建立的 git 用户下的 git 仓库
        - `vi .git/config`
            ```
            url = git@49.234.28.109:/home/git/tomcat-java-demo.git
            ```
    - 提交 git
        ```
        git add .
        git commit -m 'all'
        git push origin master
        ```
        - 在这一步是需要输入 git 用户的密码
    - 在 Node1 上创建密钥对以实现免密登录 Node2 的 git 用户
        ```
        ssh-keygen
        ssh-copy-id git@192.168.1.12
        ```
        - 测试是否能实现免密登录
            ```
            ssh git@192.168.1.12
            ```
- Node1 部署 jdk
    - 查看 CentOS 自带 JDK 是否已安装
        ```
        yum list installed |grep java
        ```
    - 查看 yum 库中的 Java 安装包
        ```
        yum -y list java*
        ```
    - 以 yum 库中 java-1.8.0 为例， "*" 表示将 java-1.8.0 的所有相关 Java 程序都安装上
        ```
        yum -y install java-1.8.0-openjdk*
        ```
    - 注意一定要安装 java-devel 组件，不然 maven 在编译的时候会报错
        ```
        yum -y install java-devel
        ```
        - jdk 供给 jenkins 和 maven 使用
        - Jenkins 在安装的时候如果 jdk 是由 java 离线安装包提供的就惨了，所以要使用 yum 安装 openjdk
        - 安装 openjdk 才能给 jenkins 安装插件
- Node1 部署 Maven
    - 解压 [maven 离线安装包](http://archive.apache.org/dist/maven/maven-3/3.5.0/binaries/apache-maven-3.5.0-bin.tar.gz)并放入指定目录
        ```
        mv apache-maven-3.5.0/ /usr/local/maven/
        ```
    - 在 profile 中设定 mvn 的路径
        ```
        MAVEN_HOME=/usr/local/maven
        PATH=$PATH:$MAVEN_HOME/bin
        ```
    - 尝试执行 `mvn --version` 看看能不能获取到 mvn 的版本和 jdk 的位置
        - maven 用来编译项目

- Node1 部署 Tomcat
    - 解压 [Tomact 离线安装包](http://mirror.bit.edu.cn/apache/tomcat/tomcat-8/v8.5.43/bin/apache-tomcat-8.5.43.tar.gz)并放入指定目录
        ```
        mv apache-tomcat-8.5.43/ /usr/local/jenkins_tomcat/
        ```
        - Tomcat 用来发布 Jenkins 网页
- Node1 发布 Jenkins 网页
    - 将[离线安装包 jenkins.war](http://mirrors.jenkins.io/war-stable/2.263.1/jenkins.war) 放入 Tomcat 工作目录并重命名为 ROOT.war
        ```
        mv jenkins.war /usr/local/jenkins_tomcat/webapps/ROOT.war
        ```
    - 启动 Tomcat
        ```
        cd /usr/local/jenkins_tomcat/bin
        ./start.sh
        ```
    - 查看 Tomcat 启动状况并获取 jenkins 密钥
        ```
        tail -f /usr/local/jenkins_tomcat/logs/catalina.out
        ```
    - 打开 192.168.1.11:8080 即可访问 Jenkins
- Node1 配置 Docker 镜像源，将 harbor 设置为信任源
    - `vi /etc/docker/daemon.json` 后添加
        ```
        "insecure-registries":["192.168.1.12"]
        ```
        > 如果不配置的话 docker 是无法把镜像推送给 harbor 的
        > 如果没有 daemon.json 这个文件说明没有配置切换镜像仓库路径，详细配置情况[在这里](https://github.com/lcePolarBear/Docker_Basic_Config_Note/blob/master/Docker%20%E7%94%A8%E6%B3%95/%E9%83%A8%E7%BD%B2%E5%9C%A8%20CentOS%E4%B8%8A.md)
- 使用 Jenkins 完成 pipeline 作业
    - 创建全局凭证
        - username:git
        - 将 Node1 的 .ssh/id_rsa 私钥内容上传到 Private Key
        - 获得 id
    - 新建流水线作业
    - 填入[脚本内容](https://github.com/lcePolarBear/Docker_Basic_Config_Note/blob/master/%E6%89%80%E9%9C%80%E8%A6%81%E7%9A%84%E6%96%87%E4%BB%B6/tomcat-java-demo_Jenkinsfile)
        - 脚本依赖三个个需要手动填入的 String Parameter 变量，分别Branch,username,password
        - 脚本内容的 git_auth 要改成 ssh 私钥在 Jenkins 生成的 id
