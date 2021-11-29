# 在 kubernetes 平台部署 Spring Cloud 微服务项目
### 第一步：熟悉 sping cloud 微服务项目
- 由三个微服务分别负责商品服务、订单服务、库存服务
- 由 MySQL 数据库提供存储
- 由 Eureka 提供注册中心
### 第二部：源代码编译构建
- 准备 jdk 和 mvn
```shell
yum install java-1.8.0-openjdk maven -y
```
- 使用 mvn 构建包
```shell
# mvn clean & mvn package 并跳过单元测试
mvn clean package -D maven.test.skip=true
```
### 第三步：构建项目镜像并推送到镜像仓库
1. 编写 dockerfile
2. 使用 dockerfile 构建镜像
3. 将构建出的镜像推送到 Harbor
### 第四步：Kubernetes 服务编排
1. pod 使用 MySQL 存储数据
2. pod 将副本动态地址注册到注册中心
3. 网关通过 ingress 暴露到公网，通过注册中心查询业务微服务组件
4. 前端通过 ingress 暴露到公网，通过网关获取数据