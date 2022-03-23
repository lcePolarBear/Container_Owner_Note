# Kubernetes 限制容器的资源访问和系统调用

## 最小特权原则（ Principle of least privilege, POLP ）

是一种信息安全概念，即为用户提供执行其工作职责所需的最小权限等级或许可。

最小特权原则被广泛认为是网络安全的最佳实践，也是保护高价值数据和资产的特权访问的基本方式。

### POLP 重要性

1. 减少网络攻击面：当今，大多数高级攻击都依赖于利用特权凭证。通过限制超级用户和管理员权限，最小权限执行有助于减少总体网络攻击面。
2. 阻止恶意软件的传播： 通过在服务器或者在应用系统上执行最小权限，恶意软件攻击（例如SQL注入攻击）将很难
提权来增加访问权限并横向移动破坏其他软件、设备。
3. 有助于简化合规性和审核：许多内部政策和法规要求都要求组织对特权帐户实施最小权限原则，以防止对关键业务系统的恶意破坏。最小权限执行可以帮助组织证明对特权活动的完整审核跟踪的合规性。

### 在团队中实施 POLP 原则

1. 在所有服务器、业务系统中，审核整个环境以查找特权帐户（例如SSH账号、管理后台账号、跳板机账号）
2. 减少不必要的管理员权限，并确保所有用户和工具执行工作时所需的权限
3. 定期更改管理员账号密码
4. 监控管理员账号操作行为，告警通知异常活动

## AppArmor 限制容器对资源访问

Application Armor 是一个 Linux 内核安全模块，可用于限制主机操作系统上运行的进程的功能。

每个进程都可以拥有自己的安全配置文件。

安全配置文件用来允许或禁止特定功能，例如网络访问、文件读/写/执行权限等。

可以限制容器进程操作文件的权限

### Apparmor 两种工作模式

- Enforcement（强制模式） ：在这种模式下，配置文件里列出的限制条件都会得到执行，并且对于违反这些限制条件的程序会进行日志记录。
- Complain（投诉模式）：在这种模式下，配置文件里的限制条件不会得到执行，Apparmor 只是对程序的行为进行记录。一般用于调试。

### K8s 使用 AppArmor 的先决条件

- K8s 版本v1.4+ ，检查是否支持：`kubectl describe node | grep AppArmor`
- Linu x内核已启用 AppArmor，查看方式 `cat /sys/module/apparmor/parameters/enabled`
    - CentOS 对于 AppArmor 支持差，不建议在 CentOS 上启用 AppArmor
- 容器运行时需要支持 AppArmor，目前 Docker 已支持

### 常用命令

- apparmor_status：查看 AppArmor 配置文件的当前状态的
- apparmor_parser：将 AppArmor 配置文件加载到内核中
- aa-complain：将 AppArmor 配置文件设置为投诉模式，需要安装 apparmor-utils 软件包
- aa-enforce：将 AppArmor 配置文件设置为强制模式，需要安装 apparmor-utils 软件包

### AppArmor 限制容器对资源访问

## Seccomp 限制容器进程系统调用

对于 Linux 来说，用户层一切资源相关操作都需要通过系统调用来完成，系统调用实现技术层次上解耦，内核只关心系统调用 API 的实现，而不必关心谁调用的。

可以确保容器内无法使用权限黑名单中指定的权限

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: dig
  namespace: default
spec:
  securityContext:
    seccompProfile:
      type: Localhost
      localhostProfile: <profile> # Pod所在宿主机上策略文件名，默认目录：/var/lib/kubelet/seccomp
  containers:
    ....
```

### 示例：禁止容器使用 chmod

```bash
# mkdir /var/lib/kubelet/seccomp
# vi /var/lib/kubelet/seccomp/chmod.json
{
    ""defaultAction": "SCMP_ACT_ALLOW",
    "syscalls": [
        {
            "names": [
                "chmod"
            ],
            "action": "SCMP_ACT_ERRNO"
        }
    ]
}
```

- defaultAction：在syscalls部分未定义的任何系统调用默认动作为允许
- syscalls:
    - names 系统调用名称，可以换行写多个
    - SCMP_ACT_ERRNO 阻止系统调用

大多数容器运行时都提供一组允许或不允许的默认系统调用。  

通过使用 runtime/default 注释，或将 Pod 或容器的安全上下文中的 seccomp 类型设置为 RuntimeDefault，可以轻松地在 Kubernetes 中应用默认值。  

[Docker 默认配置说明](https://docs.docker.com/engine/security/seccomp/)