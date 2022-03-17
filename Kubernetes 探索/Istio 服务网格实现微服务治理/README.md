# Istio 服务网格实现微服务治理
## Service Mesh
### 什么是 Service Mesh
- 通过 Sidecar Proxy 接管容器的网络，并搭建容器间的通信网格
### Service Mesh 特点
- Sidecar 实现治理能力独立
- 应用程序互无感知
- 服务通信的基础设施层
- 解耦应用程序的重试/超时、监控、追踪和服务发现
## Istio
### Istio 概述
- Isito 是 Service Mesh 的产品化落地，是目前最受欢迎的服务网格，功能丰富、成熟度高
### Istio 架构与组件
- 控制平面
    1. istiod 组件：负责处理 Sidecar 注入、证书分发、配置管理等功能
    2. Pilot 策略配置组件：为 Proxy 提供服务发现、智能路由、错误处理等
    3. Citadel 安全组件：提供证书生成下发、加密通信、访问控制
    4. Galley ：配置管理、验证、分发
- 数据平面
    - 由一组 Proxy 组成，这些Proxy负责所有微服务网络通信，实现高效转发和策略，是Istio在数据平面唯一的组件。使用 envoy 实现。
    - envoy 是一个基于 C++ 实现的 L4/L7 Proxy 转发器
### 部署 Istio
1. 安装
```shell
[root@jump istio-1.8.2]# cp bin/istioctl /usr/bin/
[root@jump istio-1.8.2]# istioctl profile list
Istio configuration profiles:
    default
    demo
    empty
    minimal
    openshift
    preview
    remote
[root@jump istio-1.8.2]# istioctl install 
This will install the Istio default profile with ["Istio core" "Istiod" "Ingress gateways"] components into the cluster. Proceed? (y/N) y
✔ Istio core installed                                                      
✔ Istiod installed
✔ Ingress gateways installed
✔ Installation complete
[root@jump istio-1.8.2]# kubectl get pods -n istio-system -o wide
NAME                                    READY   STATUS    RESTARTS   AGE   IP               NODE        NOMINATED NODE   READINESS GATES
istio-ingressgateway-66cc996697-vzg77   1/1     Running   0          12m   10.244.107.204   k8s-node3   <none>           <none>
istiod-54dc5777bc-qvqw4                 1/1     Running   0          12m   10.244.195.230   k8s-node5   <none>           <none>
[root@jump istio-1.8.2]# kubectl get svc -n istio-system -o wide
NAME                   TYPE           CLUSTER-IP       EXTERNAL-IP   PORT(S)                                                                      AGE   SELECTOR
istio-ingressgateway   LoadBalancer   10.98.87.195     <pending>     15021:32437/TCP,80:31364/TCP,443:30083/TCP,15012:31795/TCP,15443:31120/TCP   12m   app=istio-ingressgateway,istio=ingressgateway
istiod                 ClusterIP      10.100.230.154   <none>        15010/TCP,15012/TCP,443/TCP,15014/TCP                                        13m   app=istiod,istio=pilot
[root@jump istio-1.8.2]# istioctl profile dump default
```
2. 卸载
```
istioctl manifest generate | kubectl delete -f -
```
### Sidercar 注入
```
[root@jump httpbin]# pwd
/root/istio-1.8.2/samples/httpbin
```
- 手动注入的两种办法
    1. kubectl apply -f <(istioctl kube-inject -f httpbin-nodeport.yaml)
    2. istioctl kube-inject -f httpbin-nodeport.yaml |kubectl apply -f -
- 自动注入
```
kubectl label namespace default istio-injection=enabled
kubectl apply -f httpbin-gateway.yaml
```
- 访问 IngressGateway NodePort 地址
```
[root@jump httpbin]# kubectl get svc -n istio-system
NAME                   TYPE           CLUSTER-IP       EXTERNAL-IP   PORT(S)                                                                      AGE
istio-ingressgateway   LoadBalancer   10.98.87.195     <pending>     15021:32437/TCP,80:31364/TCP,443:30083/TCP,15012:31795/TCP,15443:31120/TCP   46m
istiod                 ClusterIP      10.100.230.154   <none>        15010/TCP,15012/TCP,443/TCP,15014/TCP                                        46m

```
- 查看创建的内容
```shell
[root@jump httpbin]# kubectl get pods -o wide
NAME                                      READY   STATUS    RESTARTS   AGE     IP               NODE        NOMINATED NODE   READINESS GATES
httpbin-db6dd7888-l85zh                   2/2     Running   0          100s    10.244.122.74    k8s-node4   <none>           <none>
[root@jump httpbin]# kubectl exec -it httpbin-db6dd7888-l85zh -c istio-proxy -- bash
istio-proxy@httpbin-db6dd7888-l85zh:/$ ps -ef      
UID          PID    PPID  C STIME TTY          TIME CMD
istio-p+       1       0  0 02:13 ?        00:00:00 /usr/local/bin/pilot-agent proxy sidecar --domain default.svc.cluster.local --serviceCluster httpbin.default --proxyLogLevel=warning --proxyComponentLogLevel=misc:error --concurrency 2
istio-p+      19       1  0 02:13 ?        00:00:00 /usr/local/bin/envoy -c etc/istio/proxy/envoy-rev0.json --restart-epoch 0 --drain-time-s 45 --parent-shutdown-time-s 60 --service-cluster httpbin.default --service-node sidecar~10.244.122.74~httpbin-db6dd7888-l85zh.
istio-p+      41       0  0 02:16 pts/0    00:00:00 bash
istio-p+      50      41  0 02:16 pts/0    00:00:00 ps -ef
istio-proxy@httpbin-db6dd7888-l85zh:/$ exit
[root@jump httpbin]# kubectl exec -it httpbin-db6dd7888-l85zh -c httpbin -- bash
groups: cannot find name for group ID 1337
root@httpbin-db6dd7888-l85zh:/# ps -ef 
UID          PID    PPID  C STIME TTY          TIME CMD
root           1       0  0 02:12 ?        00:00:00 /usr/bin/python3 /usr/local/bin/gunicorn -b 0.0.0.0:80 httpbin:app -k gevent
root           8       1  0 02:12 ?        00:00:00 /usr/bin/python3 /usr/local/bin/gunicorn -b 0.0.0.0:80 httpbin:app -k gevent
root          41       0  0 02:20 pts/0    00:00:00 bash
root          50      41  0 02:20 pts/0    00:00:00 ps -ef
[root@jump httpbin]# kubectl get gateway -o wide
NAME              AGE
httpbin-gateway   111s
```
## Istio 流量管理核心资源
### VirtualService
```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: httpbin
spec:
  hosts:
  - "*"
  gateways:
  - httpbin-gateway
  http:
  - route:
    - destination:
        host: httpbin
        port:
          number: 8000
```
1. 定义路由规则
2. 描述满足条件的请求去哪里
```
[root@jump httpbin]# kubectl get vs -o wide
NAME      GATEWAYS              HOSTS   AGE
httpbin   ["httpbin-gateway"]   ["*"]   41m
```
### DestinationRule
- 定义虚拟服务路由目标地址的真实地址，即子集（subset），支持多种负载均衡策略
    - 随机
    - 权重
    - 最小请求数

### Gateway
为网格内服务对外访问入口，管理进出网格的流量，根据流入流出方向分为
- IngressGateway:接收外部访问，并将流量转发到网格内的服务
- EgressGateway:网格内服务访问外部应用
### ServiceEntry
- 将网格外部服务添加到网格内，像网格内其他服务一样管理
## Istio 流量管理案例
### 主流发布方案介绍
- 蓝绿发布
    - 项目逻辑上分为AB组，在项目升级时，首先把A组从负载均衡中摘除，进行新版本的部署。B组仍然继续提供服。A组升级完成上线，B组从负载均衡中摘除。
    - 优点：1. 策略简单 2. 升级/回滚速度快 3. 用户无感知，平滑过渡
    - 缺点：1. 需要两倍以上服务器资源 2. 短时间内浪费一定资源成本 3. 有问题影响范围大
- 滚动发布
    - 每次只升级一个或多个服务，升级完成后加入生产环境，不断执行这个过程，直到集群中的全部旧版升级新版本。
    - 优点：1. 用户无感知，平滑过渡
    - 缺点：1. 部署周期长 2. 发布策略较复杂 3. 不易回滚 4. 有影响范围较大
- 灰度发布（金丝雀发布）
    - 只升级部分服务，即让一部分用户继续用老版本，一部分用户开始用新版本，如果用户对新版本没有什么意见，那么逐步扩大范围，把所有用户都迁移到新版本上面来。
    - 优点：1. 保证整体系统稳定性 2. 用户无感知，平滑过渡
    - 缺点：2. 自动化要求高
- A/B Test
    - 对特定用户采样后，对收集到的反馈数据做相关对比，然后根据比对结果作出决策。用来测试应用功能表现的方法，侧重应用的可用性，受欢迎程度等，最后决定是否升级。
### 灰度发布
- 部署 Bookinfo 微服务项目
    1. 创建命名空间并开启自动注入
    ```shell
    kubectl create ns bookinfo
    kubectl label namespace bookinfo istio-injection=enabled
    ```
    2. 部署应用 YAML
    ```shell
    cd istio-1.8.2/samples/bookinfo
    kubectl apply -f platform/kube/bookinfo.yaml -n bookinfo
    kubectl get pod -n bookinfo
    ```
    3. 创建 Ingress 网关
    ```shell
    kubectl apply -f networking/bookinfo-gateway.yaml -n bookinfo
    ```
    4. 确认网关和访问地址，访问应用页面
    ```shell
    kubectl get pods -n istio-system
    # 访问地址：http://192.168.31.62:31928/productpage
    # 刷新可观察到 Reviewer1 效果随之切换
    ```
- 基于权重的路由
```
kubectl apply -f networking/destination-rule-all.yaml -n bookinfo
```
    1. 流量全部发送到reviews v1版本（不带五角星）
    ```
    kubectl apply -f networking/virtual-service-all-v1.yaml -n bookinfo
    ```
    2. 将 90% 的流量发送到 reviews v1 版本，另外 10% 的流量发送到 reviews v2 版本（5个黑色五角星）
    ```
    kubectl apply -f networking/virtual-service-reviews-90-10.yaml -n bookinfo
    ```
    3. 将 50% 的流量发送到 v2 版本，另外 50% 的流量发送到 v3 版本（5个红色五角星）
    ```
    kubectl apply -f networking/virtual-service-reviews-v2-v3.yaml -n bookinfo
    ```
- 基于请求内容的路由
    - 将特定用户的请求发送到reviews v2版本（5个黑色五角星），其他用户则不受影响（v3）
    ```
    kubectl apply -f networking/virtual-service-reviews-jason-v2-v3.yaml -n bookinfo
    ```

1. 将部署应用的 deployment 里 pod 的标签增加一个 "version:v1"
2. 将 deployment 接入到 istio
3. 目标规则关联服务版本标签
4. 虚拟服务实现灰度
### 流量镜像
- 将请求复制一份，并根据策略来处理这个请求，不会影响真实请求。
    1. 线上问题排查
    2. 用真实的流量验证应用功能是否正常
    3. 对镜像环境压力测试
    4. 收集真实流量数据进行分析
```yaml
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: nginx
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "*"
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: nginx
spec:
  hosts:
  - "*"
  gateways:
  - nginx
  http:
  - route:
    - destination:
        host: nginx
        subset: v1
      weight: 100
    mirror:
      host: nginx
      subset: v2
    mirror_percent: 100
---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: nginx
spec:
  host: nginx
  subsets:
  - name: v1
    labels:
      version: v1
  - name: v2
    labels:
      version: v2
```
## 将应用暴露到互联网
- 在实际部署中， K8s 集群一般部署在内网，为了将暴露到互联网，会在前面加一层负载均衡器（公有云 LB 产品、Nginx、LVS等），用于流量入口，将用户访问的域名传递给 IngressGateway ， IngressGateway 再转发到不同应用
## 可视化监控
### 使用 Kiali 观测应用
```bash
# 部署
[root@jump ~]# kubectl apply -f istio-1.8.2/samples/addons/kiali.yaml -n istio-system
# 修改 service 的暴露服务方式为 NodePort 后访问
```
### 使用 Prometheus+Grafana 查看系统状态
```bash
# 部署
[root@jump ~]# kubectl apply -f istio-1.8.2/samples/addons/prometheus.yaml istio-1.8.2/samples/addons/grafana.yaml -n istio-system
# 修改 service 的暴露服务方式为 NodePort 后访问
```
- Istio Control Plane Dashboard：控制面板仪表盘
- Istio Mesh Dashboard：网格仪表盘，查看应用（服务）数据
- Istio Performance Dashboard：查看Istio 自身（各组件）数据
- Istio Service Dashboard：服务仪表盘
- Istio Workload Dashboard：工作负载仪表盘
- Istio Wasm Extension Dashboard
### 使用 Jaeger 进行链路追踪
- Jaeger 是 Uber 开源的分布式追踪系统，用于微服务的监控和全链路追踪
```bash
# 部署
[root@jump ~]# kubectl apply -f istio-1.8.2/samples/addons/jaeger.yaml -n istio-system
# 修改 service 的暴露服务方式为 NodePort 后访问
```
### 案例：模拟实现电商微服务灰度发布
1. 拉取镜像
2. 部署到 k8s
