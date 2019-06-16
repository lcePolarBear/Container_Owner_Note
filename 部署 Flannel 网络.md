## 部署 Flannel 网络

__网络基础知识__
Flannel 是 覆盖网络的一种，将数据源包封装在另一种网络包里面进行转发和通信

[flanneld 下载地址](https://github.com/coreos/flannel/releases/)

写入分配的子网段到 etcd 供 flanneld 使用
```
/opt/kubernetes/bin/etcdctl \
```