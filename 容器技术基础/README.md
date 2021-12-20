# 容器技术基础
## 1. 从进程开始说起
> 容器本身价值是有限的，真正有价值的是“容器编排”
所谓的容器，不过就是系统中一种特殊的进程，此进程由 Namespace 限定了资源、文件、设备或者配置，由 Linux 中的 Namespace 机制所实现。
## 2. 限制与隔离
- 与虚拟化技术比较，容器技术通过 Namespace 技术实现的隔离程度是相当弱的，因为容器技术其本质就是共享系统内核而相互隔离的进程。
- Cgroups 技术对资源的限制能力也有很不完善的情况，比如在容器中执行 top ， top 指令会调用宿主机的 /proc 目录生成宿主机的执行结果。
## 3. 深入理解容器镜像
1. 基于 chroot 出现的 Mount Namespace 技术可以将指定目录作为容器进程的根目录。挂载在容器根目录上用来为容器进程提供隔离后执行环境的文件系统，就是所谓的“容器镜像” - rootfs
2. rootfs 只包含操作系统的文件、配置和目录，并不包括系统内核。rootfs 带来了容器打包操作系统的能力，保证了运行环境的一致性。
3. 通过 UnionFS 技术引入了 layer 概念来实现 rootfs 的复用，即：用户制作镜像的每一步操作都会生成一个层，也就是一个增量 rootfs。
4. 容器技术的强一致性打通了“开发-测试-部署”的每一个环节，成为未来主流的软件发布方式。
## 4. 重新认识容器（基于 Linux ）
1. 容器进程的 Namespace 信息在宿主机上以文件的形式存在，可在 /proc 路径下查看
    ```bash
    [root@jump ~]# docker inspect --format '{{ .State.Pid }}' 8b6f9e9f4e0b
    11226
    [root@jump ~]# ls -l /proc/11226/ns
    总用量 0
    lrwxrwxrwx. 1 root root 0 12月 20 16:57 ipc -> ipc:[4026532490]
    lrwxrwxrwx. 1 root root 0 12月 20 16:57 mnt -> mnt:[4026532488]
    lrwxrwxrwx. 1 root root 0 12月 20 16:55 net -> net:[4026532493]
    lrwxrwxrwx. 1 root root 0 12月 20 16:57 pid -> pid:[4026532491]
    lrwxrwxrwx. 1 root root 0 12月 20 16:57 user -> user:[4026531837]
    lrwxrwxrwx. 1 root root 0 12月 20 16:57 uts -> uts:[4026532489]
    ```
2. 通过 setns() 系统调用，可以将一个进程加入到某一个 Namespace 中，即实现了 `docker exec` 的指令
3. Docker 还提供了一个可以实现容器间互通网络的参数： -net ，其本质就是容器间共享了 Network Namespace 文件
4. 通过 bind mount 的机制，实现将一个文件或者目录挂载到指定目录上而隐藏原挂载点，即实现了 Docker Volume 功能