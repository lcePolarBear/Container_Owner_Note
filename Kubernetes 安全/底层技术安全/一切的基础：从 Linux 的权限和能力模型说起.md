# 一切的基础：从 Linux 的权限和能力模型说起
<aside>
💡 安全防护的重中之重是操作系统，因为不论是虚拟化还是容器化，都会因宿主机的操作系统受到的攻击而受影响

</aside>

## Linux 进程权限控制

Linux 的权限模型在早期只分为两类：特权进程和非特权进程

- 特权进程：有权限执行任何操作，即有效 UID 为 0 的进程，通常是系统的超级用户或者 root 用户。
- 非特权进程：只能执行部分受限操作，需要经过内核的一些权限校验，即有效 UID 是非 0 的进程，通常是系统中的普通用户。

如果普通用户想要提升权限执行某些操作可有两种方式：sudo 和 SUID

简单的权限模型很容易导致普通用户具有一些特权或者执行不具备执行权限的命令等等的**权限失控**问题

## capabilities 模型

capabilities 模型的主要特点就是将一些特权划分成不同的单元，并且灵活控制其独立或者组合进行启用或禁用

capabilities 如果用作线程属性存在，我们称之为 Thread capability sets；如果用作可执行文件的扩展属性上，则称之为 File capability sets。

### Thread capability sets

Thread capability sets 主要包含以下 5 种，每种都可以包含零个或多个上面提到的 capabilities 能力。通过了解 Theread capability sets 可以方便我们在后续进行 Linux 系统安全防护时，**更容易判断出对应的线程所具备的权限， 从而及时进行权限收敛**。

1. **Permitted**
2. **Inheritable**
3. **Effective**
4. **Bounding**
5. **Ambient**

### File capability sets

它与上文中提到的 Thread capability sets 类似，包含了 3 个集合

1. **Permitted**
2. **Inheritable**
3. **Effective**

## 容器下的 capabilities 模型

以 Docker 为例来理解 capability 在容器环境中的影响

### 容器内的特殊情况

默认情况下，如果不指定特别的运行用户，容器中会使用 root 用户执行操作。当如果我们使用非 root 用户在容器内监听 80 端口时居然成功了，要知道在 Linux 上去监听一个 1024 以下的端口是需要 root 权限的。

我们通过 libcap 工具包可以查看当前容器环境下有一个 cap_net_bind_service 的 capability，允许了 socket 绑定到特权端口上

如果我们移除 cap_net_bind_service 这个 capability 并且确保 net.ipv4.ip_unprivileged_port_start 这个 Linux 内核参数为默认值 1024 那么容器内将无法由非 root 用户创建