# 最小化微服务漏洞
## Pod 安全上下文
安全上下文（Security Context）：K8s对Pod和容器提供的安全机制，可以设置Pod特权和访问控制。  
### 安全上下文限制维度
- 自主访问控制（Discretionary Access Control）：基于用户ID（UID）和组ID（GID），来判定对对象（例如文件）的访问权限。
- 安全性增强的 Linux（SELinux）： 为对象赋予安全性标签。
- 以特权模式或者非特权模式运行。
- Linux Capabilities: 为进程赋予 root 用户的部分特权而非全部特权。
- AppArmor：定义 Pod 使用 AppArmor 限制容器对资源访问限制
- Seccomp：定义 Pod 使用 Seccomp 限制容器进程的系统调用
- AllowPrivilegeEscalation： 禁止容器中进程（通过 SetUID 或 SetGID 文件模式）获得特权提升。当容器以特权模式运行或者具有CAP_SYS_ADMIN能力时，AllowPrivilegeEscalation总为True。
- readOnlyRootFilesystem：以只读方式加载容器的根文件系统。
### 案例一：设置容器以普通用户运行
容器中的应用程序默认以root账号运行的，这个root与宿主机root账号是相同的，拥有大部分对Linux内核的系统调用权限，这样是不安全的，所以我们应该将容器以普通用户运行，减少应用程序对权限的使用。  
通过两种方法设置普通用户
- Dockerfile 里使用 USER 指定运行用户
- K8s 里指定 spec.securityContext.runAsUser，指定容器默认用户 UID
```dockerfile
spec:
  securityContext
    runAsUser: 1000 # 指定容器运行的用户
    fsGroup: 1000 # 指定数据卷挂载后的目录属组
  containers:
```
### 案例2：避免使用特权容器
容器中有些应用程序可能需要访问宿主机设备、修改内核等需求，在默认情况下，容器没有这个这个能力，因此这时会考虑给容器设置特权模式。
```dockerfile
spec:
  containers:
    - image: nginx
      name: web
      securityContext:
        privileged: true  # 启用特权模式
```
启用特权模式就意味着，你要为容器提供了访问Linux内核的所有能力，这是很危险的，为了减少系统调用的供给，可以使用Capabilities为容器赋予仅所需的能力。
### Linux Capabilities
Capabilities 是一个内核级别的权限，它允许对内核调用权限进行更细粒度的控制，而不是简单地以 root 身份能力授权。  
Capabilities 包括更改文件权限、控制网络子系统和执行系统管理等功能。在securityContext 中，可以添加或删除 Capabilities，做到容器精细化权限控制。
### 示例1：容器默认没有挂载文件系统能力，添加 SYS_ADMIN 增加这个能力
```dockerfile
spec:
  containers:
    - image: nginx
      name: web
      securityContext:
        capabilities:
          add: ["SYS_ADMIN"]
```
查看所有 Capabilities 列表
```
[root@jump ~]# capsh --print
```
### 案例2：只读挂载容器文件系统，防止恶意二进制文件创建
```dockerfile
spec:
  containers:
    - image: nginx
      name: web
      securityContext:
        readOnlyRootFilesystem: true
```
## Pod 安全策略（ PodSecurityPolicy ）（ 1.21 版本弃用 ）
Kubernetes中Pod部署时重要的安全校验手段，能够有效地约束应用运行时行为安全。  
使用PSP对象定义一组Pod在运行时必须遵循的条件及相关字段的默认值，只有Pod满足这些条件才会被K8s接受。
### Pod 安全策略限制维度
![](https://docimg7.docs.qq.com/image/x895zX9LQP2ZNdEUfbd8xg.png?w=1280&h=758.4313725490197)
Pod 安全策略实现为一个准入控制器，默认没有启用，当启用后会强制实施Pod安全策略，没有满足的Pod将无法创建。因此，建议在启用 PSP 之前先添加策略并对其授权。
### 启用 Pod 安全策略
```
# vi /etc/kubernetes/manifests/kube-apiserver.yaml
...
- --enable-admission-plugins=NodeRestriction,PodSecurityPolicy
...
# systemctl restart kubelet
```
用户使用 SA （ServiceAccount）创建了一个Pod，K8s 会先验证这个 SA 是否可以访问 PSP 资源权限，如果可以则进一步验证 Pod 配置是否满足 PSP 规则，任意一步不满足都会拒绝部署。  
因此，需要实施需要有这几点
- 创建 SA 服务账号
- 该 SA 需要具备创建对应资源权限，例如创建 Pod、Deployment
- SA 使用 PSP 资源权限：创建 Role，使用 PSP 资源权限，再将 SA 绑定 Role
### 示例1：禁止创建特权模式的 Pod
```yaml
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  name: psp-example
spec:
  privileged: false # 不允许特权Pod
  # 下面是一些必要的字段
  seLinux:
    rule: RunAsAny
  supplementalGroups:
    rule: RunAsAny
  runAsUser:
    rule: RunAsAny 
  fsGroup:
    rule: RunAsAny
  volumes:
  - '*'
```
```bash
# 创建SA
kubectl create serviceaccount aliang
# 将SA绑定到系统内置Role
kubectl create rolebinding aliang --clusterrole=edit --serviceaccount=default:aliang
# 创建使用 PSP 权限的 Role
kubectl create role psp:unprivileged --verb=use --resource=podsecuritypolicy --resource-name=psp-example
# 将 SA 绑定到 Role
```
### 示例2：禁止没指定普通用户运行的容器（runAsUser）
```yaml
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  name: psp-example
spec:
  privileged: false # 不允许特权Pod
  # 下面是一些必要的字段
  seLinux:
    rule: RunAsAny
  supplementalGroups:
    rule: RunAsAny
  runAsUser:
    rule: MustRunAsNonRoot 
  fsGroup:
    rule: RunAsAny
  volumes:
  - '*'
```
## Pod 安全策略（ Open Policy Agent ）
## Secret 存储敏感数据
## 安全沙箱运行容器