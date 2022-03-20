# Kubernetes 运行时安全

<aside>
💡 聚焦于 Kubernetes 集群中的运行时安全，看看如何动态地感知到 Kubernetes 集群中的攻击或者异常行为。

</aside>

## 为什么要保障 Kubenetes 运行时安全

Kubernetes 的运行时安全，是指 Kubernetes 集群**在运行状态中的实时安全性**，并不是指 Kubernetes 集群的**容器运行时的安全。**

通过 Kubernetes 的运行时安全，我们可以知道 Kubernetes 集群中，甚至是每个 Pod 内具体发生的一系列事件或行为，从中发现一些危险的操作之类的，进而及时进行阻止或者规避，最终达到保护运行中 Kubernetes 集群免受入侵相关的目的。

## 获取那些事件

### kubernetes 集群内

- "基于 Kubernetes API 的操作行为"，这类行为通过调用 Kubernetes 的 API ，来完成资源的增删改查等行为。
- "在工作负载内执行操作"，比如说进入 Pod 来实施攻击手段，比如网段、端口扫描等。

如果是基于 Kubernetes API 的，那么通常情况下我们可以利用 Kubernetes 的审计日志来获得相关的事件记录。

### kubernetes 集群外

在集群外的操作就和我们正常在服务上的手段是类似的。比如：登陆机器，修改文件，启停服务等。

所以综合来看，我们所关注的事情，大多数都是 Kubernetes 集群外的。那么我们来看看如何保护这些操作或者行为。

## Falco

[Falco](https://github.com/falcosecurity/falco) 几乎已经成为了当前 Kubernetes 运行时安全的事实标准。

![Falco.jfif](https://docimg7.docs.qq.com/image/P_TmEQu5NOQCAgt191HAzA.jpeg?w=961&h=422)

**它主要具备如下特点：**

- 灵活的规则引擎，允许用户使用 YAML 的方式进行自定义；
- 细粒度规则，在 Falco 中包含了超过 150 个事件过滤器，允许定义细粒度的规则；
- 资源消耗很少；
- 事件转发，可以与众多系统集成，将异常事件进行转发；
- 可支持基于系统调用和 Kubernetes 审计日志等方式进行异常检测。

**Falco提供了一组默认规则，可以监控内核态的异常行为，例如：**

- 对于系统目录 /etc, /usr/bin, /usr/sbin 的读写行为
- 文件所有权、访问权限的变更
- 从容器打开 shell 会话
- 容器生成新进程
- 特权容器启动

### 安装 Falco

如果是小规模集群，可以直接以二进制方式将 Falco 部署到 Node 上；

如果集群规模较大，则可以通过 Kubernetes DaemonSet 进行部署和管理

**二进制部署**

```bash
rpm --import https://falco.org/repo/falcosecurity-3672BA8F.asc 
curl -s -o /etc/yum.repos.d/falcosecurity.repo https://falco.org/repo/falcosecurity-rpm.repo 
yum install epel-release -y 
yum update 
yum install falco -y 
systemctl start falco 
systemctl enable falco
```

**falco配置文件目录：/etc/falco**

| falco.yaml | falco配置与输出告警通知方式 |
| --- | --- |
| falco_rules.yaml | 规则文件，默认已经定义很多威胁场景 |
| falco_rules.local.yaml | 自定义扩展规则文件 |
| k8s_audit_rules.yaml | K8s审计日志规则 |

安装文档：[https://falco.org/zh/docs/installation/](https://falco.org/zh/docs/installation/)

### 验证 Falco

直接执行 falco 命令，将它启动到前台，方便我们查看日志。

Falco 默认加载了 /etc/falco 下的配置文件，这些规则涵盖了大多数的使用场景。

尝试在 Kubernetes 中创建一个 Pod，并观察 Falco 的日志输出

```bash
kubectl run --rm -it  alpine --image=alpine -- sh、

If you don't see a command prompt, try pressing enter.
/ # whoami
root
```

我们创建了一个 Pod 并且获取了它的 Shell，所以 Falco 捕获了这个事件。

查看 /etc/falco/falco_rules.yaml 文件可以看到这个日志的原始定义规则：

```yaml
- rule: Terminal shell in container
  desc: A shell was used as the entrypoint/exec point into a container with an attached terminal.
  condition: >
    spawned_process and container
    and shell_procs and proc.tty != 0
    and container_entrypoint
    and not user_expected_terminal_shell_in_container_conditions
  output: >
    A shell was spawned in a container with an attached terminal (user=%user.name user_loginuid=%user.loginuid %container.info
    shell=%proc.name parent=%proc.pname cmdline=%proc.cmdline terminal=%proc.tty container_id=%container.id image=%container.image.repository)
  priority: NOTICE
  tags: [container, shell, mitre_execution]
```

```yaml
- rule: Unauthorized process on nginx containers
	condition: spawned_process and container and container.image startswith nginx and not proc.name in (nginx) 
	desc: test 
	output: "Unauthorized process on nginx containers (user=%user.name container_name=%container.name container_id=%container.id image=%container.image.repository shell=%proc.name parent=%proc.pname cmdline=%proc.cmdline terminal=%proc.tty)" 
	priority: WARNIN
```

condition 表达式解读，条件很简单，其中:

- `spawned_process` 这个预定义的宏在系统调用 execve 时触发（比如，启动一个新进程）;
- `container` 这个过滤器确定只有在容器内发生事件时才会触发。
- `container.image startswith nginx` 以nginx开头的容器镜像
- `not proc.name in (nginx)` 不属于nginx的进程名称（允许进程名称列表）

在这个文件内还有很多其他的规则，比如在主机上去操作 `/etc` 等关键目录时，也会触发对应的规则，后续增加规则时候可以进行参考。

### 威胁场景测试

验证方式：tail -f /var/log/messages（告警通知默认输出到标准输出和系统日志）

**监控系统二进制文件目录读写**

**监控根目录或者 /root 目录写入文件**

**监控运行交互式 Shell 的容器**

**监控容器创建的不可信任进程**

**监控容器创建的不可信任进程规则，在falco_rules.local.yaml文件添加**

## FalcoSideKick 集中化展示 Falco 告警

<aside>
💡 FalcoSideKick：一个集中收集并指定输出，支持大量方式输出，例如Influxdb、Elasticsearch等

</aside>

项目地址 https://github.com/falcosecurity/falcosidekick

<aside>
💡 FalcoSideKick-UI：告警通知集中图形展示系统

</aside>

项目地址: https://github.com/falcosecurity/falcosidekick-ui

### 部署 Falco UI

```bash
docker run -d \
-p 2801:2801 \
--name falcosidekick \ 
-e WEBUI_URL=http://192.168.31.71:2802 \ 
falcosecurity/falcosidekick

docker run -d \ 
-p 2802:2802 \ 
--name falcosidekick-ui \ 
falcosecurity/falcosidekick-ui
```

### 修改 falco 配置文件指定 http 方式输出

```yaml
json_output: true 
json_include_output_property: true 
http_output: 
	enabled: true 
	url: "http://192.168.31.71:2801/"
```

## Falco 支持五种输出告警通知的方式

1. 输出到标准输出（默认启用）
2. 输出到文件
3. 输出到 Syslog （默认启用）
4. 输出到 HTTP 服务
5. 输出到其他程序（命令行管道方式）

### 告警配置文件：/etc/falco/falco.yaml

例如输出到指定文件

```yaml
file_output: 
	enabled: true 
	keep_alive: false 
	filename: /var/log/falco_events.log
```