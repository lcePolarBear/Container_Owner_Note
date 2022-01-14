# StatefulSet 对象

官方文档：[StatefulSets | Kubernetes](https://kubernetes.io/zh/docs/concepts/workloads/controllers/statefulset/)

<aside>
💡 StatefulSet 对象用于编排有状态应用

</aside>

## StatefulSet 对应用状态的抽象

1. **拓扑状态**：应用的多个实例间不完全对等，这些应用实例必须按照某种顺序启动，即使删除后重建其启动顺序和网络标识不变。
2. **存储状态**：应用的多个实例分别绑定了不同的存储数据，比如数据库的多个存储实例。

所以，StatefulSet 的核心功能，就是通过某种方式记录这些状态，然后在 Pod 被重新创建时，能够为新 Pod 恢复这些状态。

## Headless Service

### Service 是怎么被访问的？

1. Service 的 VIP（ Virtual IP，虚拟 IP ）方式
2. Service 的 DNS 方式
    1. Normal Service ，解析 Service 的 VIP
    2. Headless Service ，解析 Pod IP 地址

基于 Service 的 DNS 访问方式，Headless Service 不需要分配一个 VIP ，而是可以直接以 DNS 记录的方式解析出被代理 Pod 的 IP 地址。

### Headless Service 设计的作用

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx
  labels:
    app: nginx
spec:
  ports:
  - port: 80
    name: web
  clusterIP: None
  selector:
    app: nginx
```

clusterIP 字段为 Node ，这个 service 被创建后并不会被分配一个 VIP ，而是以 DNS 记录的方式暴露以 app: nginx 为标签的 Pod

当按照这样的方式创建一个 Headless Service 之后，它所代理的所有 Pod 的 IP 地址都会被绑定一个如下格式的 DNS 记录

`<pod-name>.<svc-name>.<namespace>.svc.cluster.local`

这个 DNS 记录正是 Kubernetes 项目为 Pod 分配的唯一 resolvable identity （可解析身份）

## StatefulSet 资源使用 Headless Service

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web
spec:
  selector:
    matchLabels:
      app: nginx # has to match .spec.template.metadata.labels
  serviceName: "nginx"
  replicas: 2 # by default is 1
  template:
    metadata:
      labels:
        app: nginx # has to match .spec.selector.matchLabels
    spec:
      containers:
      - name: nginx
        image: nginx:1.9.1
        ports:
        - containerPort: 80
          name: web
```

这个 YAML 文件与 nginx-deployment 的唯一区别就是多了一个 serviceName=nginx 字段，用于指定 Headless Service 保证 Pod 可解析。

```bash
[root@jump ~]# kubectl get svc
NAME         TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP   42h
nginx        ClusterIP   None         <none>        80/TCP    29s
[root@jump ~]# kubectl get statefulset
NAME   READY   AGE
web    2/2     37s
```

查看 StatefulSet 的 Event 信息，可以看出 StatefulSet 资源是给 Pod 的名字进行了统一的编号

```bash
[root@jump ~]# kubectl describe statefulset web
...
Events:
  Type    Reason            Age    From                    Message
  ----    ------            ----   ----                    -------
  Normal  SuccessfulCreate  2m46s  statefulset-controller  create Pod web-0 in StatefulSet web successful
  Normal  SuccessfulCreate  2m44s  statefulset-controller  create Pod web-1 in StatefulSet web successful
```
并且，Pod 的 hostname 也以此命名规则被分配，我们可以尝试使用 DNS 方式访问 Headless Service

```bash
[root@jump ~]# kubectl run -i --tty --image busybox:1.28.0 dns-test --restart=Never --rm /bin/sh
/ # nslookup web-0.nginx
Server:    10.96.0.10
Address 1: 10.96.0.10 kube-dns.kube-system.svc.cluster.local

Name:      web-0.nginx
Address 1: 10.244.2.11 web-0.nginx.default.svc.cluster.local
/ # nslookup web-1.nginx
Server:    10.96.0.10
Address 1: 10.96.0.10 kube-dns.kube-system.svc.cluster.local

Name:      web-1.nginx
Address 1: 10.244.1.18 web-1.nginx.default.svc.cluster.local
```

mslookup 命令输出结果显示，访问 DNS 直接指向 Pod 的 IP 地址，即使将这两个 Pod 删除掉， StatefulSet 也会重新创建两个与原来相同“网络身份”的 Pod 。