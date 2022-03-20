# Kubernetes 审计日志

## Kubernetes 中的审计日志是什么

**Kubernetes 中的审计日志可以记录对 Kubernetes API 的请求 。**

在Kubernetes集群中，API Server的审计日志记录了哪些用户、哪些服务请求操作集群资源，并且可以编写不同规则，控制忽略、存储的操作日志。

**kube-apiserver 处理的这些请求主要包括以下内容：**

- controller-manager、kube-scheduler 等 Control Plane 的交互请求；
- Node 节点上组件的请求，包括 kubelet 和 kube-proxy 等；
- 集群中的一些系统服务的请求，包括 CoreDNS、kube-state-metrics 等；
- 用户通过 kubectl 发起的请求；
- 用户自行开发或者第三方的 controller 或 operator 之类的这些通过 client-go 等发起的请求；
- 此外 kube-apiserver 自身也会有一些请求需要处理。

审计日志通过记录哪些用户对 kube-apiserver 发起了什么请求，以及 kube-apiserver 对此请求的响应，还有授权或者拒绝的原因等。

审计日志采用 JSON 格式输出，每条日志都包含丰富的元数据，例如请求的 URL、HTTP 方法、客户端来源等，你可以使用监控服务来分析API流量，以检测趋势或可能存在的安全隐患。

## 为什么要监控 Kubernetes 中的审计日志

如果你通过 kubeadm 进行 Kubernetes 集群的部署，那么审计日志是不开启的，不过我建议你 为生产环境中的 Kubernetes 集群开启此能力。

在 Kubernetes 集群中，如果我们想要快速地了解当前集群发生了什么事情，最简单的办法是直接查看 event。

比如，我们在 Kubernetes 集群中创建一个 Deployment 资源，看看会有哪些 event 吧。

```bash
# 创建一个 Deployment
kubectl create deploy nginx --image="nginx:alpine"
deployment.apps/nginx created

# 获取 events
kubectl get events
LAST SEEN   TYPE     REASON              OBJECT                      MESSAGE
10s         Normal   Scheduled           pod/nginx-65778599-mq6nw    Successfully assigned default/nginx-65778599-mq6nw to kind-worker
10s         Normal   Pulling             pod/nginx-65778599-mq6nw    Pulling image "nginx:alpine"
4s          Normal   Pulled              pod/nginx-65778599-mq6nw    Successfully pulled image "nginx:alpine" in 5.379974736s
4s          Normal   Created             pod/nginx-65778599-mq6nw    Created container nginx
4s          Normal   Started             pod/nginx-65778599-mq6nw    Started container nginx
10s         Normal   SuccessfulCreate    replicaset/nginx-65778599   Created pod: nginx-65778599-mq6nw
10s         Normal   ScalingReplicaSet   deployment/nginx            Scaled up replica set nginx-65778599 to 1
```

如上所示，Kubernetes 集群中的 event 可以记录当前集群中发生了一些事件。

但是默认情况下 event 是存储在 etcd 中的，仅保留一小时。

而我们这里介绍了审计日志，包含的内容比 event 中的更加完整，覆盖面也更广。

通过监控 Kubernetes 集群中的审计日志，我们可以了解到当前 Kubernetes 集群中的所有变更，以及及时地定位到一些不安全的操作。

此外，通过对 Kubernetes 集群中审计日志的持久化存储，我们也可以在 Kubernetes 集群遭受攻击后，回溯到具体的原因。

## 如何配置 Kubernetes 中的审计日志

要在 Kubernetes 中启用审计日志，需要给 kube-apiserver 传递两个参数。

- `-audit-log-path`：这个参数用于设置审计日志的存储位置，如果设置为 - ，表示输出到 stdout。
- `--audit-policy-file`：这个参数用于设置审计日志的策略配置。

审计日志进行监控以及持久化存储：

- 一种就是配置上述提到了 `--audit-log-path` 参数，然后对审计日志进行采集，并进行持久化存储；
- 另一种就是，可以给 kube-apiserver 配置 `--audit-webhook-config-file` 参数，将审计日志通过 webhook 的方式发送给远端 web 服务进行持久化存储。

## 审计策略（Audit Policy）

审计策略（Audit Policy）则是用来指定要捕获的 API 请求类型。

这些 API 的调用是分阶段的，比如 `RequestReceived`（接收到请求）和 `ResponseComplete`（响应已经生成完成） 等。不过并非每个 API 都是仅这两个阶段，比如，如果是 kubectl 发起了 `watch` 请求的话，那么它的响应阶段会是 `ResponseStarted` 而非 `ResponseComplete`，因为它会持续地发送响应，而不是发送一次就结束。

在审计策略（Autdit Polciy）中，我们可以进行非常细粒度的配置，甚至包括每个请求的哪个阶段，以及对应的资源类型等。

## 示例：只记录指定资源操作日志