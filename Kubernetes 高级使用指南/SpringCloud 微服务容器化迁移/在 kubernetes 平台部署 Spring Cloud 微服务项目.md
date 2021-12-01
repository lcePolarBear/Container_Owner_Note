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

```dockerfile
# eureka-service
FROM java:8-jdk-alpine
LABEL maintainer chen
RUN  sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories && \
     apk add -U tzdata && \
     ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
COPY ./target/eureka-service.jar ./
EXPOSE 8888
CMD java -jar -Deureka.instance.hostname=${MY_POD_NAME}.eureka.ms /eureka-service.jar

# portal-service
FROM java:8-jdk-alpine
LABEL maintainer chen
RUN  sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories && \
     apk add -U tzdata && \
     ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
COPY ./target/portal-service.jar ./
EXPOSE 8080
CMD java -jar /portal-service.jar
```
```bash
docker_registry=192.168.102.211
# 存储登录Harbor认证信息
kubectl create secret docker-registry registry-pull-secret --docker-server=$docker_registry --docker-username=admin --docker-password=Harbor12345 --docker-email=admin@ctnrs.com -n ms

service_list="eureka-service gateway-service order-service product-service stock-service portal-service"
service_list=${1:-${service_list}}
work_dir=$(dirname $PWD)
current_dir=$PWD

cd $work_dir
mvn clean package -Dmaven.test.skip=true

for service in $service_list; do
   cd $work_dir/$service
   # 业务程序需进入biz目录里构建
   if ls |grep biz &>/dev/null; then
      cd ${service}-biz
   fi
   service=${service%-*}
   image_name=$docker_registry/microservice/${service}:$(date +%F-%H-%M-%S)
   docker build -t ${image_name} .
   docker push ${image_name}
   # 修改yaml中镜像地址为新推送的，并apply
   sed -i -r "s#(image: )(.*)#\1$image_name#" ${current_dir}/${service}.yaml
   # 在 kubernetes 中部署 yaml 资源
   kubectl apply -f ${current_dir}/${service}.yaml
done
```
### 第四步：Kubernetes 服务编排
1. pod 使用 MySQL 存储数据
2. pod 将副本动态地址注册到注册中心
3. 网关通过 ingress 暴露到公网，通过注册中心查询业务微服务组件
4. 前端通过 ingress 暴露到公网，通过网关获取数据
### 第五步：在 kubernetes 部署 Eureka 集群
- 确保 kubernetes 群集已部署 Ingress
- 部署 Eureka 资源
    ```yaml
    apiVersion: extensions/v1beta1
    kind: Ingress
    metadata:
    name: eureka
    namespace: ms
    spec:
    rules:
        - host: eureka.ctnrs.com
        http:
            paths:
            - path: /
            backend:
                serviceName: eureka
                servicePort: 8888
    ---
    apiVersion: v1
    kind: Service
    metadata:
    name: eureka
    namespace: ms
    spec:
    clusterIP: None
    ports:
    - port: 8888
        name: eureka
    selector:
        project: ms
        app: eureka
    ---
    apiVersion: apps/v1
    kind: StatefulSet
    metadata:
    name: eureka
    namespace: ms
    spec:
    replicas: 3
    selector:
        matchLabels:
        project: ms
        app: eureka
    serviceName: "eureka"
    template:
        metadata:
        labels:
            project: ms
            app: eureka
        spec:
        imagePullSecrets:
        - name: registry-pull-secret
        containers:
        - name: eureka
            image: 192.168.102.211/microservice/eureka:2021-11-30-19-52-22
            ports:
            - protocol: TCP
                containerPort: 8888
            env:
            - name: MY_POD_NAME
                valueFrom:
                fieldRef:
                    fieldPath: metadata.name
            resources:
            requests:
                cpu: 0.5
                memory: 256Mi
            limits:
                cpu: 1
                memory: 1Gi
            readinessProbe:
            tcpSocket:
                port: 8888
            initialDelaySeconds: 60
            periodSeconds: 10
            livenessProbe:
            tcpSocket:
                port: 8888
            initialDelaySeconds: 60
            periodSeconds: 10
    ```
- 修改微服务 jdbc 地址到 MySQL 服务器
    ```yaml
    # order-service/order-service-biz/src/main/resources/application-fat.yml
    spring:
    datasource:
        url: jdbc:mysql://192.168.102.113:3306/tb_order?characterEncoding=utf-8
        username: root
        password: root
        driver-class-name: com.mysql.jdbc.Driver

    eureka:
    instance:
        prefer-ip-address: true
    client:
        register-with-eureka: true
        fetch-registry: true
        service-url:
        defaultZone: http://eureka-0.eureka.ms:8888/eureka,http://eureka-1.eureka.ms:8888/eureka,http://eureka-2.eureka.ms:8888/eureka
    ```
### 第六步：部署微服务
- 业务处理微服务
    ```yaml
    apiVersion: apps/v1
    kind: Deployment
    metadata:
    name: product
    namespace: ms
    spec:
    replicas: 1
    selector:
        matchLabels:
        project: ms
        app: product
    template:
        metadata:
        labels:
            project: ms
            app: product
        spec:
        imagePullSecrets:
        - name: registry-pull-secret
        containers:
        - name: product
            image: 192.168.102.211/microservice/product:2021-11-30-20-38-32
            imagePullPolicy: Always
            ports:
            - protocol: TCP
                containerPort: 8010
            resources:
            requests:
                cpu: 0.5
                memory: 256Mi
            limits:
                cpu: 1
                memory: 1Gi
            readinessProbe:
            tcpSocket:
                port: 8010
            initialDelaySeconds: 60
            periodSeconds: 10
            livenessProbe:
            tcpSocket:
                port: 8010
            initialDelaySeconds: 60
            periodSeconds: 10
    ```
    ```yaml
    apiVersion: apps/v1
    kind: Deployment
    metadata:
    name: order
    namespace: ms
    spec:
    replicas: 1
    selector:
        matchLabels:
        project: ms
        app: order
    template:
        metadata:
        labels:
            project: ms
            app: order
        spec:
        imagePullSecrets:
        - name: registry-pull-secret
        containers:
        - name: order
            image: 192.168.102.211/microservice/order:2021-11-30-20-38-03
            imagePullPolicy: Always
            ports:
            - protocol: TCP
                containerPort: 8020
            resources:
            requests:
                cpu: 0.5
                memory: 256Mi
            limits:
                cpu: 1
                memory: 1Gi
            readinessProbe:
            tcpSocket:
                port: 8020
            initialDelaySeconds: 60
            periodSeconds: 10
            livenessProbe:
            tcpSocket:
                port: 8020
            initialDelaySeconds: 60
            periodSeconds: 10
    ```
    ```yaml
    apiVersion: apps/v1
    kind: Deployment
    metadata:
    name: stock
    namespace: ms
    spec:
    replicas: 1
    selector:
        matchLabels:
        project: ms
        app: stock
    template:
        metadata:
        labels:
            project: ms
            app: stock
        spec:
        imagePullSecrets:
        - name: registry-pull-secret
        containers:
        - name: stock
            image: 192.168.102.211/microservice/stock:2021-11-30-20-39-04
            imagePullPolicy: Always
            ports:
            - protocol: TCP
                containerPort: 8030
            resources:
            requests:
                cpu: 0.5
                memory: 256Mi
            limits:
                cpu: 1
                memory: 1Gi
            readinessProbe:
            tcpSocket:
                port: 8030
            initialDelaySeconds: 60
            periodSeconds: 10
            livenessProbe:
            tcpSocket:
                port: 8030
            initialDelaySeconds: 60
            periodSeconds: 10
    ```
- 网关微服务
    ```yaml
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
    name: gateway
    namespace: ms
    spec:
    rules:
        - host: gateway.ctnrs.com
        http:
            paths:
            - path: /
            pathType: Prefix
            backend:
                service:
                name: gateway
                port:
                    number: 9999
    ---
    apiVersion: v1
    kind: Service
    metadata:
    name: gateway
    namespace: ms
    spec:
    ports:
    - port: 9999
        name: gateway
    selector:
        project: ms
        app: gateway
    ---
    apiVersion: apps/v1
    kind: Deployment
    metadata:
    name: gateway
    namespace: ms
    spec:
    replicas: 1
    selector:
        matchLabels:
        project: ms
        app: gateway
    template:
        metadata:
        labels:
            project: ms
            app: gateway
        spec:
        imagePullSecrets:
        - name: registry-pull-secret
        containers:
        - name: gateway
            image: 192.168.102.211/microservice/gateway:2021-12-01-19-12-33
            imagePullPolicy: Always
            ports:
            - protocol: TCP
                containerPort: 9999
            resources:
            requests:
                cpu: 0.5
                memory: 256Mi
            limits:
                cpu: 1
                memory: 1Gi
            readinessProbe:
            tcpSocket:
                port: 9999
            initialDelaySeconds: 60
            periodSeconds: 10
            livenessProbe:
            tcpSocket:
                port: 9999
            initialDelaySeconds: 60
            periodSeconds: 10
    ```
- 前端微服务
    ```yaml
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
    name: portal
    namespace: ms
    spec:
    rules:
        - host: portal.ctnrs.com
        http:
            paths:
            - path: /
            pathType: Prefix
            backend:
                service:
                name: portal
                port:
                    number: 8080
    ---
    apiVersion: v1
    kind: Service
    metadata:
    name: portal
    namespace: ms
    spec:
    ports:
    - port: 8080
        name: portal
    selector:
        project: ms
        app: portal
    ---
    apiVersion: apps/v1
    kind: Deployment
    metadata:
    name: portal
    namespace: ms
    spec:
    replicas: 2
    selector:
        matchLabels:
        project: ms
        app: portal
    template:
        metadata:
        labels:
            project: ms
            app: portal
        spec:
        imagePullSecrets:
        - name: registry-pull-secret
        containers:
        - name: portal
            image: 192.168.102.211/microservice/portal:2021-11-30-19-53-07
            imagePullPolicy: Always
            ports:
            - protocol: TCP
                containerPort: 8080
            resources:
            requests:
                cpu: 0.5
                memory: 256Mi
            limits:
                cpu: 1
                memory: 1Gi
            readinessProbe:
            tcpSocket:
                port: 8080
            initialDelaySeconds: 60
            periodSeconds: 10
            livenessProbe:
            tcpSocket:
                port: 8080
            initialDelaySeconds: 60
            periodSeconds: 10
    ```
# 第七步：微服务升级与扩容
- 使用 scale 指令扩容 deployment 资源副本
- 按照自动化脚本的流程，修改完代码后重新打包镜像并推送，kubernetes 在部署时会自动进行蓝绿发布
```
```