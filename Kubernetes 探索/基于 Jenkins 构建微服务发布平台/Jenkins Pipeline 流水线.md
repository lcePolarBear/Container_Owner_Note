# Jenkins Pipeline 流水线
### Jenkins Pipeline 是一套运行工作流框架，将原本独立运行单个或者多个节点的任务链接起来，实现单个任务难以完成的复杂流程编排和可视化。
- Jenkins Pipeline 是一套插件，支持在 Jenkins 中实现持续集成和持续交付
- Pipeline 通过特定语法对简单到复杂的传输管道进行建模
- Jenkins Pipeline 的定义被写入一个文本文件，称为 Jenkinsfile
### Jenkins Pipeline 示例
```Jenkinsfile
pipeline {
    agent any
    stages {
        stage('Build') {
            steps {
                echo 'build...'
            }
        }
        stage('Test') {
            steps {
                echo 'test...'
            }
        }
        stage('Deploy') {
            steps {
                echo 'deploy...'
            }
        }
    }
}
```
- Stages ： Pipeline 中最主要的组成部分， Jenkins 将会按照 Stages 中描述的顺序
从上往下的执行。
- Stage ：一个 Pipeline 可以划分为若干个 Stage ，每个 Stage 代表一组操作，
比如： Build 、 Test 、 Deploy
- Steps ： Steps 是最基本的操作单元，可以是打印一句话，也可以是构建一
个 Docker 镜像，由各类 Jenkins 插件提供，比如命令：sh ‘mvn'，就相当于我们平时 shell 终端中执行 mvn 命令一样
### 搭建流水线步骤
1. 第一步：实现 git 拉取代码
    ```
    def git_url = "http://192.168.102.222:88/root/microservice.git"
    def git_auth = "70ba723d-32cc-4624-bcd5-c390975842f6"

    pipeline {
    agent {
        kubernetes {
            label "jenkins-slave"
            yaml """
    apiVersion: v1
    kind: Pod
    metadata:
    name: jenkins-slave
    spec:
    containers:
    - name: jnlp
        image: "${registry}/library/jenkins-slave-jdk:1.8"
    """
            }
        
        }
        parameters {
            gitParameter branch: '', branchFilter: '.*', defaultValue: 'origin/master', description: '选择发布的分支', name: 'Branch', quickFilterEnabled: false, selectedValue: 'NONE', sortMode: 'NONE', tagFilter: '*', type: 'PT_BRANCH'        
            extendedChoice defaultValue: 'none', description: '选择发布的微服务', multiSelectDelimiter: ',', name: 'Service', type: 'PT_CHECKBOX', value: 'gateway-service:9999,portal-service:8080,product-service:8010,order-service:8020,stock-service:8030'
            choice (choices: ['ms', 'demo'], description: '部署模板', name: 'Template')
            choice (choices: ['1', '3', '5', '7'], description: '副本数', name: 'ReplicaCount')
            choice (choices: ['ms'], description: '命名空间', name: 'Namespace')
        }
        stages {
            stage('拉取代码'){
                steps {
                    checkout([$class: 'GitSCM', 
                    branches: [[name: "${params.Branch}"]], 
                    doGenerateSubmoduleConfigurations: false, 
                    extensions: [], submoduleCfg: [], 
                    userRemoteConfigs: [[credentialsId: "${git_auth}", url: "${git_url}"]]
                    ])
                }
            }
        }
    }
    ```
2. 第二步：实现编译代码
```
def git_url = "http://192.168.102.222:88/root/microservice.git"
def git_auth = "70ba723d-32cc-4624-bcd5-c390975842f6"

pipeline {
  agent {
    kubernetes {
        label "jenkins-slave"
        yaml """
apiVersion: v1
kind: Pod
metadata:
  name: jenkins-slave
spec:
  containers:
  - name: jnlp
    image: "${registry}/library/jenkins-slave-jdk:1.8"
    imagePullPolicy: Always
    volumeMounts:
      - name: docker-cmd
        mountPath: /usr/bin/docker
      - name: docker-sock
        mountPath: /var/run/docker.sock
      - name: maven-cache
        mountPath: /root/.m2
  volumes:
    - name: docker-cmd
      hostPath:
        path: /usr/bin/docker
    - name: docker-sock
      hostPath:
        path: /var/run/docker.sock
    - name: maven-cache
      hostPath:
        path: /tmp/m2
"""
        }
      
      }
    parameters {
        gitParameter branch: '', branchFilter: '.*', defaultValue: 'origin/master', description: '选择发布的分支', name: 'Branch', quickFilterEnabled: false, selectedValue: 'NONE', sortMode: 'NONE', tagFilter: '*', type: 'PT_BRANCH'        
        extendedChoice defaultValue: 'none', description: '选择发布的微服务', multiSelectDelimiter: ',', name: 'Service', type: 'PT_CHECKBOX', value: 'gateway-service:9999,portal-service:8080,product-service:8010,order-service:8020,stock-service:8030'
        choice (choices: ['ms', 'demo'], description: '部署模板', name: 'Template')
        choice (choices: ['1', '3', '5', '7'], description: '副本数', name: 'ReplicaCount')
        choice (choices: ['ms'], description: '命名空间', name: 'Namespace')
    }
    stages {
        stage('拉取代码'){
            steps {
                checkout([$class: 'GitSCM', 
                branches: [[name: "${params.Branch}"]], 
                doGenerateSubmoduleConfigurations: false, 
                extensions: [], submoduleCfg: [], 
                userRemoteConfigs: [[credentialsId: "${git_auth}", url: "${git_url}"]]
                ])
            }
        }
        stage('代码编译') {
            // 编译指定服务
            steps {
                sh """
                  mvn clean package -Dmaven.test.skip=true
                """
            }
        }
    }
}
```
3. 第三步：实现构建并推送镜像
```
def registry = "192.168.102.211"
// 项目
def project = "microservice"
def git_url = "http://192.168.102.222:88/root/microservice.git"
// 认证
def image_pull_secret = "registry-pull-secret"
def harbor_auth = "0ea75c5a-6db7-4e4d-95fa-05abb4b00b49"
def git_auth = "70ba723d-32cc-4624-bcd5-c390975842f6"

pipeline {
  agent {
    kubernetes {
        label "jenkins-slave"
        yaml """
apiVersion: v1
kind: Pod
metadata:
  name: jenkins-slave
spec:
  containers:
  - name: jnlp
    image: "${registry}/library/jenkins-slave-jdk:1.8"
    imagePullPolicy: Always
    volumeMounts:
      - name: docker-cmd
        mountPath: /usr/bin/docker
      - name: docker-sock
        mountPath: /var/run/docker.sock
      - name: maven-cache
        mountPath: /root/.m2
  volumes:
    - name: docker-cmd
      hostPath:
        path: /usr/bin/docker
    - name: docker-sock
      hostPath:
        path: /var/run/docker.sock
    - name: maven-cache
      hostPath:
        path: /tmp/m2
"""
        }
      
      }
    parameters {
        gitParameter branch: '', branchFilter: '.*', defaultValue: 'origin/master', description: '选择发布的分支', name: 'Branch', quickFilterEnabled: false, selectedValue: 'NONE', sortMode: 'NONE', tagFilter: '*', type: 'PT_BRANCH'        
        extendedChoice defaultValue: 'none', description: '选择发布的微服务', multiSelectDelimiter: ',', name: 'Service', type: 'PT_CHECKBOX', value: 'gateway-service:9999,portal-service:8080,product-service:8010,order-service:8020,stock-service:8030'
        choice (choices: ['ms', 'demo'], description: '部署模板', name: 'Template')
        choice (choices: ['1', '3', '5', '7'], description: '副本数', name: 'ReplicaCount')
        choice (choices: ['ms'], description: '命名空间', name: 'Namespace')
    }
    stages {
        stage('拉取代码'){
            steps {
                checkout([$class: 'GitSCM', 
                branches: [[name: "${params.Branch}"]], 
                doGenerateSubmoduleConfigurations: false, 
                extensions: [], submoduleCfg: [], 
                userRemoteConfigs: [[credentialsId: "${git_auth}", url: "${git_url}"]]
                ])
            }
        }
        stage('代码编译') {
            // 编译指定服务
            steps {
                sh """
                  mvn clean package -Dmaven.test.skip=true
                """
            }
        }
        stage('构建镜像') {
          steps {
              withCredentials([usernamePassword(credentialsId: "${harbor_auth}", passwordVariable: 'password', usernameVariable: 'username')]) {
                sh """
                 docker login -u ${username} -p '${password}' ${registry}
                 echo ${Service}
                 for service in \$(echo ${Service} |sed 's/,/ /g'); do
                    service_name=\${service%:*}
                    image_name=${registry}/${project}/\${service_name}:${BUILD_NUMBER}
                    cd \${service_name}
                    if ls |grep biz &>/dev/null; then
                        cd \${service_name}-biz
                    fi
                    docker build -t \${image_name} .
                    docker push \${image_name}
                    cd ${WORKSPACE}
                  done
                """
                configFileProvider([configFile(fileId: "${k8s_auth}", targetLocation: "admin.kubeconfig")]){
                    sh """
                    # 添加镜像拉取认证
                    kubectl create secret docker-registry ${image_pull_secret} --docker-username=${username} --docker-password=${password} --docker-server=${registry} -n ${Namespace} --kubeconfig admin.kubeconfig |true
                    # 添加私有chart仓库
                    helm repo add  --username ${username} --password ${password} myrepo http://${registry}/chartrepo/${project}
                    """
                }
              }
          }
        }
    }
}
```