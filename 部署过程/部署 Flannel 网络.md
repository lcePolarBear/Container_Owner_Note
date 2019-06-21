## 部署 Flannel 网络

__网络基础知识__

Flannel 是 覆盖网络的一种，将数据源包封装在另一种网络包里面进行转发和通信

__在 master 下__

写入分配的子网段到 etcd 供 flanneld 使用，在 /opt/kubernetes/ssl 下执行
```
/opt/kubernetes/bin/etcdctl \
--ca-file=ca.pem --cert-file=server.pem --key-file=server-key.pem \
--endpoints="https://192.168.10.110:2379,https://192.168.10.141:2379,https://192.168.10.145:2379" \
set /coreos.com/network/config '{"Network":"172.17.0.0/16","Backend":{"Type":"vxlan"}}'
```
可将 set 改为 get 来查验是否配置成功

__在 node 下__

- 下载 [flanneld](https://github.com/coreos/flannel/releases/) 并将其中的 mk-docker-opts 和 flanneld 放入到 /opt/kubernetes/bin 路径下
- 创建 flanneld 配置文件
vi /opt/kubernetes/cfg/[flanneld](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/config-files/flanneld)
- 再写一个systemd去管理 vi /usr/lib/systemd/system/[flanneld.service](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/config-files/flannel.server)
- cat /run/flannel/subnet.env 可以查看 flannel 分配的 ip 地址
- 将 DOCKER_NETWORK_OPTION 应用于docker
    - vi /usr/lib/systemd/system/docker.service
        ```
        EnvironmentFile=/run/flannel/subnet.env
        ExecStart=/usr/bin/dockerd $DOCKER_NETWORK_OPTION
        ```
>两个 node 节点的网段不一样是正常的 但 docker 必须跟 node 结点下的 flannel 同一网段
只要 node 节点之间相互能 ping 通 docker 的 ip 地址就说明正常了

- 我们可以在 /opt/kubernetes/ssl/ 路径下通过以下命令来查看 flannel 维护的路由信息
    ```
    /opt/kubernetes/bin/etcdctl \
    --ca-file=ca.pem --cert-file=server.pem --key-file=server-key.pem \
    --endpoints="https://192.168.10.110:2379,https://192.168.10.141:2379,https://192.168.10.145:2379" \
    ls /coreos.com/network/subnets
    ```
    结果正好是两个 node 节点分配的网段

    可以将ls替换成get来查看这些网段文件里的信息，其中主要可以看到节点的 ip 地址