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