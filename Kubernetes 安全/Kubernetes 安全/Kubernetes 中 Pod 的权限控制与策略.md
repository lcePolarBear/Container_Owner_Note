# Pod 权限控制与策略

## Pod 安全上下文

安全上下文（Security Context）：K8s 对 Pod 和容器提供的安全机制，可以设置 Pod 特权和访问控制。  

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

容器中的应用程序默认以 root 账号运行的，这个 root 与宿主机 root 账号是相同的，拥有大部分对 Linux 内核的系统调用权限，这样是不安全的，所以我们应该将容器以普通用户运行，减少应用程序对权限的使用。  

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

## Linux Capabilities

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