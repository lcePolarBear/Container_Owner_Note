# Jenkins 在 Kubernetes 中动态创建代理
- Jenkins Master/Slave 架构，Master （ Jenkins 本身）提供 Web 页面让用户来管理项目和从节点（ Slave ），项目任务可以运行在 Master 本机或者分配到从节点运行，一个 Master 可以关联多个 Slave ，这样好处是可以让 Slave 分担 Master 工作压力和隔离构建环境。
- 当触发 Jenkin s任务时， Jenkins 会调用 Kubernetes API 创建 Slave Pod ， Pod 启动后会通过 jnlp 通信协议连接 Jenkins ，接受任务并处理。

### Kubernetes 插件配置
- 添加步骤：管理 Jenkins > 节点管理 > Configure Clouds > 添加 Kubernetes
- 添加内容：Kubernetes 地址： `https://kubernetes` ， Jenkins 地址： `http://jenkins.default`

### 回顾部署一个项目的大致流程：
1. 拉取代码 - git
2. 代码编译构建 - mvn
3. 构建镜像和推送镜像 - docker
4. 将镜像部署到 k8s 中 - gateway/microservice
5. 发布访问 - Ingress

### Jenkins 实现自动发布所需要的功能（文件）
- Dockerfile ：构建镜像
- jenkins-slave ： shell 脚本启动 slave.jar ，[下载地址](https://github.com/jenkinsci/docker-jnlp-slave/blob/master/jenkins-slave)
- settings.xml ：修改 maven 官方源为阿里云源
- slave.jar ：agent 程序，接受 master 下发的任务，[下载地址](http://enkinsip:port/jnlpJars/slave.jar)
- helm 和 kubectl ： kubernetes 客户端工具

### 自定义 Jenkins Slave 镜像
- 构建 Slave 镜像 Dockerfile
    ```dockerfile
    FROM centos:7
    LABEL maintainer jenkins
    RUN yum install -y java-1.8.0-openjdk maven curl git libtool-ltdl-devel && \
    yum clean all && \
    rm -rf /var/cache/yum/* && \
    mkdir -p /usr/share/jenkins
    COPY slave.jar /usr/share/jenkins/slave.jar 
    COPY jenkins-slave /usr/bin/jenkins-slave
    COPY settings.xml /etc/maven/settings.xml
    RUN chmod +x /usr/bin/jenkins-slave
    COPY helm kubectl /usr/bin/
    ENTRYPOINT ["jenkins-slave"]
    ```
- 构建镜像
```docker
docker build -t 192.168.102.211/library/jenkins-slave-jdk:1.8 .
docker push 192.168.102.211/library/jenkins-slave-jdk:1.8
```
### 新建 Pipeline 流水线项目并应用 Slave
- pipeline 语句
    ```script
    pipeline {
        agent {
            kubernetes {
                label "jenkins-slave"
                yaml '''
    apiVersion: v1
    kind: Pod
    metadata:
        name: jenkins-slave
    spec:
    containers:
    - name: jnlp
        image: 192.168.102.211/library/jenkins-slave-jdk:1.8
    '''
            }
        }
        stages {
            stage('Main') {
                steps {
                    sh 'hostname'
                }
            }
        }
    }

    ```