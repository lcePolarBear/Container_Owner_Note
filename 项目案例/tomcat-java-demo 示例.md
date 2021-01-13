## tomcat-java-demo 示例

__获取并编译项目__
- 使用 git 获取项目代码
    ```
    git clone https://github.com/lizhenliang/tomcat-java-demo
    ```
- 安装编译工具 java , maven
    ```
    yum install java-1.8.0-openjdk maven git -y
    ```
- 编译项目
    ```
    mvn clean package -Dmaven.test.skip=true
    ```
- 将编译完成的 war 包解压构建为 ROOT
    ```
    unzip target/*.war -d target/ROOT
    ```

__打包为 Docker 镜像__
- 创建 Dockerfile
    ```
    FROM lizhenliang/tomcat
    LABEL maintainer www.ctnrs.com
    RUN rm -rf /usr/local/tomcat/webapps/*
    ADD target/ROOT /usr/local/tomcat/webapps/ROOT
    ```
- 