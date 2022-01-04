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
- 是一个开源的、通用策略引擎，可以将策略编写为代码。提供一个种高级声明性语言 Rego 来编写策略，并把决策这一步骤从复杂的业务逻辑中解耦出来。
- Gatekeeper 是基于 OPA的一个 Kubernetes 策略解决方案，可替代PSP或者部分RBAC功能。
- 当在集群中部署了Gatekeeper组件，APIServer所有的创建、更新或者删除操作都会触发Gatekeeper来处理，如果不满足策略则拒绝。
### 部署Gatekeeper
[官方链接地址](https://open-policy-agent.github.io/gatekeeper/website/docs/install/#deploying-a-release-using-prebuilt-image)
```
kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/release-3.7/deploy/gatekeeper.yaml
```
Gatekeeper的策略由两个资源对象组成
- Template：策略逻辑实现的地方，使用rego语言
- Contsraint：负责Kubernetes资源对象的过滤或者为Template提供输入参数
### 案例1：禁止容器启用特权
```yaml
apiVersion: templates.gatekeeper.sh/v1beta1
kind: ConstraintTemplate
metadata:
  name: privileged 
spec:
  crd:
    spec:
      names:
        kind: privileged
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package admission
        violation[{"msg": msg}] { # 如果violation为true（表达式通过）说明违反约束
          containers = input.review.object.spec.template.spec.containers
          c_name := containers[0].name
          containers[0].securityContext.privileged # 如果返回true，说明违反约束
          msg := sprintf("提示：'%v'容器禁止启用特权！",[c_name])
        }

# kubectl get ConstraintTemplate
```
```yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: privileged  # 指定为 ConstraintTemplate 的 metadata.name
metadata:
  name: privileged
spec:
  match: # 匹配的资源
    kinds:
      - apiGroups: ["apps"]
        kinds:
        - "Deployment"
        - "DaemonSet"
        - "StatefulSet"
# kubectl get constraints
```
### 案例2：只允许使用特定的镜像仓库
```yaml
apiVersion: templates.gatekeeper.sh/v1beta1
kind: ConstraintTemplate
metadata:
  name: image-check
spec:
  crd:
    spec:
      names:
        kind: image-check
      validation:
        openAPIV3Schema: 
          properties: # 需要满足条件的参数
            prefix:
              type: string
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package image
        violation[{"msg": msg}] { 
          containers = input.review.object.spec.template.spec.containers
          image := containers[0].image
          not startswith(image, input.parameters.prefix) # 镜像地址开头不匹配并取反则为true，说明违反约束
          msg := sprintf("提示：'%v'镜像地址不在可信任仓库！", [image])
        }
```
```yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: image-check
metadata:
  name: image-check
spec:
  match:
    kinds:
      - apiGroups: ["apps"] 
        kinds:
        - "Deployment"
        - "DaemonSet"
        - "StatefulSet"
  parameters: # 传递给opa的参数
    prefix: "lizhenliang/"

```
## Secret 存储敏感数据
Secret 是一个用于存储敏感数据的资源，所有的数据要经过 base64 编码，数据实际会存储在 K8s Etcd 中，然后通过创建 Pod 时引用该数据。  
Pod 使用 secret 数据有变量注入、数据卷挂载两种方式。  
kubectl create secret 支持三种数据类型
- docker-registry：存储镜像仓库认证信息
- generic：从文件、目录或者字符串创建，例如存储用户名密码
- tls：存储证书，例如HTTPS证书
### 示例：将Mysql用户密码保存到Secret中存储
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: mysql
type: Opaque
data:
  mysql-root-password: "MTIzNDU2"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mysql
spec:
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
      - name: db
        image: mysql:5.7.30
        env:
        - name: MYSQL_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysql
              key: mysql-root-password
```
## 安全沙箱运行容器
- 所知，容器的应用程序可以直接访问 Linux 内核的系统调用，容器在安全隔离上还是比较弱，虽然内核在不断地增强自身的安全特性，但由于内核自身代码极端复杂，CVE 漏洞层出不穷。  
- 所以要想减少这方面安全风险，就是做好安全隔离，阻断容器内程序对物理机内核的依赖。  
- Google 开源的一种 gVisor 容器沙箱技术就是采用这种思路，gVisor 隔离容器内应用和内核之间访问，提供了大部分 Linux 内核的系统调用，巧妙的将容器内进程的系统调用转化为对 gVisor 的访问。

gVisor 兼容 OCI ，与 Docker 和 K8s 无缝集成，很方面使用。 [项目地址](https://github.com/google/gvisor
)
![](https://docimg3.docs.qq.com/image/FP0hIp5AM2RtGRYuR5AcpA.png?w=1253&h=504)
gVisor 由 3 个组件构成
- Runsc 是一种 Runtime 引擎，负责容器的创建与销毁
- Sentry 负责容器内程序的系统调用处理
- Gofer 负责文件系统的操作代理，IO 请求都会由它转接到 Host 上
![](https://docimg3.docs.qq.com/image/eKeQNU8Th7ge3sw5SWGvZw.png?w=490&h=253)
### gVisor 与 Docker 集成
[官方参考文档](https://gvisor.dev/docs/user_guide/install/)  
gVisor 内核要求：Linux 3.17+
如果用的是 CentOS7 则需要升级内核，Ubuntu 内核一般都比较新
```bash
rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-2.el7.elrepo.noarch.rpm
yum --enablerepo=elrepo-kernel install kernel-ml-devel kernel-ml –y
grub2-set-default 0
reboot
uname -r
```
1. 准备 gVisor 二进制文件
    ```bash
    sha512sum -c runsc.sha512
    rm -f *.sha512
    chmod a+x runsc
    mv runsc /usr/local/bin
    ```
2. Docker 配置使用 gVisor
```
runsc install
# 查看加的配置  /etc/docker/daemon.json
systemctl restart docker
```
3. 使用 runsc 运行容器
```bash
docker run -d --runtime=runsc nginx
# 使用dmesg验证
docker run --runtime=runsc -it nginx dmesg
```
[已经测试过的应用和工具](https://gvisor.dev/docs/user_guide/compatibility/)
### gVisor 与 Containerd 集成
[切换 Containerd 容器引擎]()

RuntimeClass 是一个用于选择容器运行时配置的对象，容器运行时配置用
于运行 Pod 中的容器。

创建 RuntimeClass
```yaml
apiVersion: node.k8s.io/v1 # RuntimeClass 定义于 node.k8s.io API 组
kind: RuntimeClass
metadata:
  name: gvisor # 用来引用 RuntimeClass 的名字
handler: runsc # 对应的 CRI 配置的名称
```

创建 Pod 测试 gVisor
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-gvisor
spec:
  runtimeClassName: gvisor
  containers:
  - name: nginx
    image: nginx
```
```bash
kubectl get pod nginx-gvisor -o wide
kubectl exec nginx-gvisor -- dmesg
```

### 案例 1
创建一个 PSP 策略，防止创建特权 Pod，再创建一个ServiceAccount，使用 kubectl –as 验证 PSP 策略效果

### 案例 2
使用 containerd 作为容器运行时，准备好 gVisor ，创建一个 RuntimeClass ，创建一个 Pod 在 gVisor 上运行