# cgroup 如何进行资源限制
<aside>
💡 以 Docker 和 Containerd 等为首的现代化容器运行时技术主要使用了 Linux 操作系统提供的 cgroup 和 namespace 等特性。

</aside>

## 为什么需要 cgroup

能实现“容器化”的技术有很多，包括最早的 `chroot` 等，这些技术实现容器化时存在什么问题？又为什么需要 cgroup？

### chroot 的安全问题

`chroot` 可以指定某个目录作为进程的根目录，避免其访问主机上的其他目录。但是，**对于有 root 权限的进程，却可以任意退出 chroot 所设置的“虚拟”环境**。

正常情况下我们的根文件系统（rootfs）的结构中会包含 `/etc` 、 `/bin` 等目录。chroot 可以使用我们已经提前准备好的目录作为根文件系统，这样在 chroot 的环境下看到的目录结构就跟正常在主机上看到的结构类似了

如果是以具备特权的用户来运行的时候，程序可以在 `chroot` 所使用的当前目录和系统上原本的根目录（`/`) 之间进行切换；而如果是一个普通用户，则没有权限操作。

### Linux VServer 和 LXC 的复杂度问题

在 2001 年前后出现的 Linux VServer 也是一个典型的容器化技术，它通过对 Linux 内核进行 patch 的方式，可以支持系统级的虚拟化，也可以共享系统调用。

但它的主要问题在于它是对 Linux 内核进行了 patch，所以无论是维护成本，还是更新成本都比较大。除此之外，它还不能跟上游的 Linux 内核版本同步，因此，后续逐步出现了其他技术来替代它。

在 2008 年前后出现的 LXC 则是后起之秀。它不需要给 Linux 内核打 patch，也是首个可以和上游 Linux 内核版本进行同步的容器化技术方案。但它的问题也比较明显，整体的学习和维护成本相对较高，并没有得到迅速的普及。

### 多样的资源限制需求

**对于容器化技术而言，实现资源的隔离和限制是其核心，而实现容器资源限制能力的，就是 cgroup**

通过查看 `/sys/fs/cgroup` 目录中的内容直接查看cgroup 可限制的资源，如： CPU、内存、PID 等多种资源。

```bash
[root@VM-4-16-centos cgroup]# ll /sys/fs/cgroup
total 0
drwxr-xr-x 2 root root  0 Jan  5 18:11 blkio
lrwxrwxrwx 1 root root 11 Jan  5 18:11 cpu -> cpu,cpuacct
lrwxrwxrwx 1 root root 11 Jan  5 18:11 cpuacct -> cpu,cpuacct
drwxr-xr-x 3 root root  0 Jan  5 18:11 cpu,cpuacct
drwxr-xr-x 2 root root  0 Jan  5 18:11 cpuset
drwxr-xr-x 4 root root  0 Jan  5 18:11 devices
drwxr-xr-x 2 root root  0 Jan  5 18:11 freezer
drwxr-xr-x 2 root root  0 Jan  5 18:11 hugetlb
drwxr-xr-x 3 root root  0 Jan  5 18:11 memory
lrwxrwxrwx 1 root root 16 Jan  5 18:11 net_cls -> net_cls,net_prio
drwxr-xr-x 2 root root  0 Jan  5 18:11 net_cls,net_prio
lrwxrwxrwx 1 root root 16 Jan  5 18:11 net_prio -> net_cls,net_prio
drwxr-xr-x 2 root root  0 Jan  5 18:11 perf_event
drwxr-xr-x 2 root root  0 Jan  5 18:11 pids
drwxr-xr-x 4 root root  0 Jan  5 18:11 systemd
```

## 如何使用 cgroup

**要想使用 cgroup，只需要在系统的 `/sys/fs/cgroup/` 下对应的资源目录中按照规则创建子目录即可**，内核会帮助我们自动填上该目录中其他我们所需要的内容。

### 创建 cgroup

```bash
[root@VM-4-16-centos cpu]# mkdir -p /sys/fs/cgroup/cpu/moelove
[root@VM-4-16-centos cpu]# ls -l --time-style='+' /sys/fs/cgroup/cpu/moelove
total 0
-rw-r--r-- 1 root root 0  cgroup.clone_children
--w--w--w- 1 root root 0  cgroup.event_control
-rw-r--r-- 1 root root 0  cgroup.procs
-r--r--r-- 1 root root 0  cpuacct.stat
-rw-r--r-- 1 root root 0  cpuacct.usage
-r--r--r-- 1 root root 0  cpuacct.usage_percpu
-rw-r--r-- 1 root root 0  cpu.cfs_period_us
-rw-r--r-- 1 root root 0  cpu.cfs_quota_us
-rw-r--r-- 1 root root 0  cpu.rt_period_us
-rw-r--r-- 1 root root 0  cpu.rt_runtime_us
-rw-r--r-- 1 root root 0  cpu.shares
-r--r--r-- 1 root root 0  cpu.stat
-rw-r--r-- 1 root root 0  notify_on_release
-rw-r--r-- 1 root root 0  tasks
```

验证生成的 cgroup

```bash
lscgroup  |grep moelove
```

### 设置资源限制

对比容器启动前后的 cgroup CPU 相关信息，可以看到多了一个 `cpu,cpuacct:/docker/9d1608854ce4017e4aea7ded8ac390fef8c719428c7609438cac167e9f61aaa4` 的记录。这是 Docker 为容器默认创建的。

我们查看其 cgroup 中跟 CPU 相关的配置信息

```bash
cat cpu,cpuacct/docker/9d1608854ce4017e4aea7ded8ac390fef8c719428c7609438cac167e9f61aaa4/cpu.cfs_quota_us
cat cpu,cpuacct/docker/9d1608854ce4017e4aea7ded8ac390fef8c719428c7609438cac167e9f61aaa4/cpu.cfs_period_us
```

`cpu.cfs_period_us` 是指 CPU 时钟周期长度，上面例子中是 100000

`cpu.cfs_quota_us` 是指在 CPU 时钟周期长度内能使用的 CPU 时间数，上面例子中它是 -1，表示无限制

我们可以将 `cpu.cfs_quota_us` 设置为 `cpu.cfs_period_us` 的一半，表示只允许使用 0.5 CPU。

```bash
echo 50000 > cpu,cpuacct/docker/9d1608854ce4017e4aea7ded8ac390fef8c719428c7609438cac167e9f61aaa4/cpu.cfs_quota_us
```

### 验证资源限制

在容器内执行以下命令验证

```bash
# sha256sum /dev/zero
```

通过 `top` 命令或者 `docker stats` 命令可以获取容器进程的 cpu 使用率。

## cgroup 在容器环境中的应用

除了上述示例中我们直接去写 cgroup 的配置外，容器运行时其实已经帮我们做了自动化的操作，在使用 Docker 运行容器时，我们可以直接在 `docker run` 命令之后增加参数用于资源控制，包括对于 CPU、内存、IO、PID 等的控制。

```bash
docker run --help |grep -E 'cpu|memory|pid|net|blkio|device'
```

所以我们可以使用如下命令启动容器，验证其使用 cgroup 进行 CPU 资源配额的限制

```bash
docker run --rm -it --cpus=0.3 alpine
```

## cgroup v1 和 v2

cgroup v2 主要解决了 v1 中允许任意数量的层次结构的问题，这样可以规避一些问题，比如层次结构不匹配之类的。当然 cgroup v2 也提供了更加方便的管理形式，可以简化管理成本。

## 总结

**cgroup 的出现满足了容器对于资源配额管理的需求，同时我们可以通过使用 cgroup 对进程资源进行非常方便的资源限制，以免进程之间出现资源抢占的问题。**

在容器环境中，cgroup 的使用频率非常高，对于 Kubernetes 环境，也建议你对 Pod 进行 request 和 limit 的限制（实际上底层还是 cgroup 在起作用）。学习底层原理，可以方便你对上层技术的理解。