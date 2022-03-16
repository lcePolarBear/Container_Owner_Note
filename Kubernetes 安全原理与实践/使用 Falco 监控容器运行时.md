# 使用 Falco 监控容器运行时

<aside>
💡 Falco 是一个 Linux 安全工具，它使用系统调用来保护和监控系统。

</aside>

**Falco提供了一组默认规则，可以监控内核态的异常行为，例如：**

- 对于系统目录 /etc, /usr/bin, /usr/sbin 的读写行为
- 文件所有权、访问权限的变更
- 从容器打开 shell 会话
- 容器生成新进程
- 特权容器启动

项目地址： https://github.com/falcosecurity/falco

![Falco.jfif](https://docimg7.docs.qq.com/image/P_TmEQu5NOQCAgt191HAzA.jpeg?w=961&h=422)

## 安装 Falco

### 二进制部署

```bash
rpm --import https://falco.org/repo/falcosecurity-3672BA8F.asc 
curl -s -o /etc/yum.repos.d/falcosecurity.repo https://falco.org/repo/falcosecurity-rpm.repo 
yum install epel-release -y 
yum update 
yum install falco -y 
systemctl start falco 
systemctl enable falco
```

### falco配置文件目录：/etc/falco

1. falco.yaml falco配置与输出告警通知方式
2. falco_rules.yaml 规则文件，默认已经定义很多威胁场景
3. falco_rules.local.yaml 自定义扩展规则文件
4. k8s_audit_rules.yaml K8s审计日志规则

安装文档：[https://falco.org/zh/docs/installation/](https://falco.org/zh/docs/installation/)

## 告警规则示例（falco_rules.local.yaml）

```bash

```

## 威胁场景测试

验证方式：tail -f /var/log/messages（告警通知默认输出到标准输出和系统日志）

### 监控系统二进制文件目录读写

### 监控根目录或者 /root 目录写入文件

### 监控运行交互式 Shell 的容器

### 监控容器创建的不可信任进程

监控容器创建的不可信任进程规则，在falco_rules.local.yaml文件添加

```yaml
- rule: Unauthorized process on nginx containers
	condition: spawned_process and container and container.image startswith nginx and not proc.name in (nginx) 
	desc: test 
	output: "Unauthorized process on nginx containers (user=%user.name container_name=%container.name container_id=%container.id image=%container.image.repository shell=%proc.name parent=%proc.pname cmdline=%proc.cmdline terminal=%proc.tty)" 
	priority: WARNIN
```

**condition 表达式解读**

1. spawned_process 运行新进程
2. container 容器
3. container.image startswith nginx 以nginx开头的容器镜像
4. not proc.name in (nginx) 不属于nginx的进程名称（允许进程名称列表）

**重启 falco 应用新配置文件**

```bash
systemctl restart falco 
```

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