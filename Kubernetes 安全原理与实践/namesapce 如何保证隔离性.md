# namespace 如何保证隔离性
<aside>
💡 namespace 为了让该系统中的每个进程组通过拥有自己独立的 namespace 抽象，以达到这些进程组之间的文件系统彼此隔离、互不可见的目的。

</aside>

## namespace 的分类

### Mount namespace

在不同的 mount namespace 中的进程，可以**看到不同层次的目录结构。**

每个进程在 Mount namespace 中的描述可以在下面的文件中看到：

- /proc/[pid]/mounts
- /proc/[pid]/mountinfo
- /proc/[pid]/mountstats

一个新的 Mount namespace 的创建标识是 `CLONE_NEWNS` ，使用了 clone(2) 或者 unshare(2) 。

- 如果 Mount namespace 用 clone(2) 创建，子进程 namespace 的挂载列表是从父进程的 Mount namespace 拷贝的。
- 如果 Mount namespace 用 unshare(2) 创建，新 namespace 的挂载列表是从调用者之前的 Mount namespace 拷贝的。

```bash
# 使用 unshare 命令配合 chroot 命令，使用 debian 系统的 root filesystem 进入隔离环境
[root@sddk 9ea9bc7c56f222a1c5eac0feb668b60be37b44f2894c44abd13b8fd0d6593523]# sudo unshare --mount chroot ./ bash

# 可以看到当前已经是在 debian 系统的环境中了
root@sddk:/# cat /etc/os-release 
PRETTY_NAME="Debian GNU/Linux 11 (bullseye)"
NAME="Debian GNU/Linux"
VERSION_ID="11"
VERSION="11 (bullseye)"
VERSION_CODENAME=bullseye
ID=debian
HOME_URL="https://www.debian.org/"
SUPPORT_URL="https://www.debian.org/support"
BUG_REPORT_URL="https://bugs.debian.org/"

# 由于我们配合使用了 unshare --mount ，所以当执行 mount 命令的时候，会提示无法正常执行
root@sddk:/# mount
mount: failed to read mtab: No such file or directory

# 尝试挂载 proc 目录。挂载了 proc 后，再次执行 mount 命令就可以正确输出了
root@sddk:/# mount -t proc proc proc
root@sddk:/# mount
proc on /proc type proc (rw,relatime)

# 使用 findmnt 命令查看当前环境中所有的挂载信息
root@sddk:/# findmnt
TARGET SOURCE FSTYPE OPTIONS
/proc  proc   proc   rw,relatime
```

可以看到该命令仅输出了当前环境中挂载的 proc，并无其他输出。这说明我们的 Mount namespace 的效果已达成，确实达到了隔离 mount 信息的作用。

### Network namespace

**Network namespace 可以使得每个进程都有自己的网络堆栈**

```bash
# 使用 Network namespaces 需要内核支持 CONFIG_NET_NS 选项
[root@sddk ~]# grep CONFIG_NET_NS /boot/config-$(uname -r)
CONFIG_NET_NS=y
```

示例：通过 `unshare --net` 命令即可创建出包含自己独立 Network namespace 的环境。执行 `ip a` 命令的时候，可以看到仅包含其自身的 `lo` 接口。

```bash
sudo unshare --net bash
ip add
```

说明 Network namespace 的效果也已经达成，网络堆栈被隔离了

### UTS namespace

**UTS namespaces 可用来隔离主机名和 NIS 域名**

```bash
# 使用 UTS namespaces 需要内核支持 CONFIG_UTS_NS 选项
[root@sddk ~]# grep CONFIG_UTS_NS /boot/config-$(uname -r)
CONFIG_UTS_NS=y
```

在同一个 UTS namespace 中，通过 sethostname(2) 和 setdomainname(2) 系统调用进行设置和修改的话，其结果是所有进程共享查看的，但是对于不同 UTS namespaces 而言，则彼此隔离不可见。

示例：首先查看当前主机的 hostname，然后进入到隔离的 UTS namespace 中进行 hostname 的修改。

```bash
[root@sddk ~]# sudo unshare --uts bash
[root@sddk ~]# hostname chen
[root@sddk ~]# hostname
chen
[root@sddk ~]# exit
exit
[root@sddk ~]# hostname
sddk
[root@sddk ~]#
```

我们可以看到在退出隔离环境后，主机名并没有发生变化，这说明我们的 **UTS namespace 确实可以隔离 hostname 等**。

### PID namespace

我们知道在 Linux 系统中，每个进程的 PID 都是独立的，彼此不会重复，而 **PID namespace 的主要作用就是隔离进程号。也就是说，在不同的 PID namespace 中可以包含相同的进程号**。

每个 PID namespace 中进程号都是从 1 开始的，在此 PID namespace 中可通过调用 `fork(2)`、`vfork(2)` 和 `clone(2)` 等系统调用来创建其他拥有独立 PID 的进程。

要使用 PID namespace 需要内核支持 `CONFIG_PID_NS` 选项。如下：

```bash
[root@sddk ~]# grep CONFIG_PID_NS /boot/config-$(uname -r)
CONFIG_PID_NS=y
```

我们知道在 Linux 系统中有一个进程比较特殊，所谓的 **init 进程，也就是 PID 为 1 的进程**。

前面我们已经说了每个 PID namespace 中进程号都是从 1 开始的，那么它有什么特点呢？

- 首先，PID namespace 中的 1 号进程是**所有孤立进程的父进程**。
- 其次，如果这个进程被终止，内核将会发出 `SIGKILL` 信号，用于终止这个 PID namespace 中的所有进程。**这部分内容与 Kubernetes 中应用的优雅关闭/平滑升级等都有一定的联系**。
- 最后，从 Linux v3.4 内核版本开始，如果在一个 PID namespace 中发生 `reboot()` 的系统调用，则 PID namespace 中的 init 进程会立即退出。**这算是一个比较特殊的技巧，可用于处理高负载机器上容器退出的问题**。

示例：

```bash
[root@sddk ~]# sudo unshare --pid --fork bash
[root@sddk ~]# ps
  PID TTY          TIME CMD
19083 pts/0    00:00:00 bash
26554 pts/0    00:00:00 sudo
26556 pts/0    00:00:00 unshare
26557 pts/0    00:00:00 bash
26634 pts/0    00:00:00 ps
[root@sddk ~]# ls -l /proc/ |wc -l
390

```

我们使用 `unshare` 创建出了新的 PID namespace，但是在执行 `ps` 命令后，发现并不符合我们的预期，PID 并不是全新的，在 `/proc` 目录下仍然有大量的记录。
这里我们可以尝试配合上述的 Mount namespace 进行使用

```bash
[root@sddk 9ea9bc7c56f222a1c5eac0feb668b60be37b44f2894c44abd13b8fd0d6593523]# sudo unshare --pid --fork --mount chroot ./ bash
root@sddk:/# mount -t proc proc proc
root@sddk:/# ls /proc/
1       buddyinfo  consoles  diskstats    fb           iomem     kcore      kpagecount  mdstat   mounts        partitions   self      swaps          timer_list   version
3       bus        cpuinfo   dma          filesystems  ioports   key-users  kpageflags  meminfo  mtrr          sched_debug  slabinfo  sys            timer_stats  vmallocinfo
acpi    cgroups    crypto    driver       fs           irq       keys       loadavg     misc     net           schedstat    softirqs  sysrq-trigger  tty          vmstat
asound  cmdline    devices   execdomains  interrupts   kallsyms  kmsg       locks       modules  pagetypeinfo  scsi         stat      sysvipc        uptime       zoneinfo
root@sddk:/# ls /proc/ |wc -l
61
root@sddk:/# exit
exit
```

可以看到，当我们重新挂载 `proc` 后，在 `/proc` 目录下就能按我们的预期看到完全独立的进程号了。

### IPC namespace

IPC namespaces 隔离了 IPC 资源，如 System V IPC objects、POSIX message queues。每个 IPC namespace 都有着自己的一组 System V IPC 标识符，以及 POSIX 消息队列系统。在一个 IPC namespace 中创建的对象，对所有该 namespace 下的成员均可见，而对其他 namespace 下的成员均不可见。

使用 IPC namespace 需要内核支持 CONFIG_IPC_NS 选项

```bash
[root@sddk ~]# grep CONFIG_IPC_NS /boot/config-$(uname -r)
CONFIG_IPC_NS=y
```

可以在 IPC namespace 中设置以下 `/proc` 接口

- `/proc/sys/fs/mqueue` ： POSIX 消息队列接口
- `/proc/sys/kernel` ：System V IPC 接口，包括 msgmax、msgmnb、msgmni、sem、shmall、shmmax、shmmni、shm_rmid_forced 等
- `/proc/sysvipc` ：System V IPC 接口，包括 msg、sem 和 shm

当 IPC namespace 被销毁时（空间里的最后一个进程都被停止删除时），在 IPC namespace 中创建的 object 也会被销毁。

示例：

```bash

# 使用 ipcmk 创建一个队列
[root@sddk ~]# ipcmk -M 1000
共享内存 id：6

# 通过 ipcs 可获取队列中的信息
[root@sddk ~]# ipcs
--------- 消息队列 -----------
键        msqid      拥有者  权限     已用字节数 消息      

------------ 共享内存段 --------------
键        shmid      拥有者  权限     字节     nattch     状态      
0x00000000 2          gdm        777        16384      1          目标       
0x00000000 5          gdm        777        2129920    2          目标       
0x2def1754 6          root       644        1000       0                       

--------- 信号量数组 -----------
键        semid      拥有者  权限     nsems

# 但是如果为进程设置了 IPC namespace ，则会获取不到
[root@sddk ~]# sudo unshare --ipc bash
[root@sddk ~]# ipcs

--------- 消息队列 -----------
键        msqid      拥有者  权限     已用字节数 消息      

------------ 共享内存段 --------------
键        shmid      拥有者  权限     字节     nattch     状态      

--------- 信号量数组 -----------
键        semid      拥有者  权限     nsems
```

可以看到在新的 IPC namespace 下确实无法获取队列，所以也**说明 IPC namespace 可用于隔离队列。**

## namespace 在容器环境中的应用

```bash
# 以 Docker 为例子创建一个新的容器
[root@sddk ~]# docker run --rm -d alpine sleep 99999
Unable to find image 'alpine:latest' locally
latest: Pulling from library/alpine
59bf1c3509f3: Already exists 
Digest: sha256:21a3deaa0d32a8057914f36584b5288d2e5ecc984380bc0118285c70fa8c9300
Status: Downloaded newer image for alpine:latest
4071332b7aef37d00a2356acb24a8eed81bd97783bcc0524720d29c85141b2a6

# 查看它的 namespace 信息
[root@sddk ~]# sudo ls -al --time-style='+' /proc/`docker inspect $(docker ps -ql)  --format "{{.State.Pid}}"`/ns
总用量 0
dr-x--x--x. 2 root root 0  .
dr-xr-xr-x. 9 root root 0  ..
lrwxrwxrwx. 1 root root 0  ipc -> ipc:[4026533036]
lrwxrwxrwx. 1 root root 0  mnt -> mnt:[4026533034]
lrwxrwxrwx. 1 root root 0  net -> net:[4026533039]
lrwxrwxrwx. 1 root root 0  pid -> pid:[4026533037]
lrwxrwxrwx. 1 root root 0  user -> user:[4026531837]
lrwxrwxrwx. 1 root root 0  uts -> uts:[4026533035]

# 对比主机上的信息
[root@sddk ~]# sudo ls -al --time-style='+' /proc/self/ns
总用量 0
dr-x--x--x. 2 root root 0  .
dr-xr-xr-x. 9 root root 0  ..
lrwxrwxrwx. 1 root root 0  ipc -> ipc:[4026531839]
lrwxrwxrwx. 1 root root 0  mnt -> mnt:[4026531840]
lrwxrwxrwx. 1 root root 0  net -> net:[4026531968]
lrwxrwxrwx. 1 root root 0  pid -> pid:[4026531836]
lrwxrwxrwx. 1 root root 0  user -> user:[4026531837]
lrwxrwxrwx. 1 root root 0  uts -> uts:[4026531838]
```

可以看到容器与主机上进程的以上 5 种 namespace 的文件描述符都不一样，进而实现了隔离的效果。

## 总结

介绍了主流容器技术所使用到的 5 种 namespace 分别是什么、如何使用，以及其能实现的效果。还以一个实例展示了容器与主机的这几种 namespace 确实不一样，所以才能实现其隔离性，让容器具备自己的注记名、进程ID、网络堆栈等。

**namespace 是容器实现隔离性的核心技术**，掌握 namespace 可以方便你理解在什么样的场景下使用具体哪个类型的 namespace 可实现资源的互访和共享。