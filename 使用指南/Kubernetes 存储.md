## Kubernetes 存储

__容器部署过程中一般有以下三种数据__
- 启动时需要的初始数据，例如配置文件
- 启动过程中产生的临时数据，该临时数据需要多个容器间共享
- 启动过程中产生的持久化数据，例如 MySQL 的 data

__引入数据卷以解决数据共享和持久化的问题__
- Kubernetes 中的 Volume 提供了在容器中挂载外部存储的能力
    - Pod 需要设置卷来源 (spec.volume）和挂载点 (spec.containers.volumeMounts) 两个信息后才可以使用相应的 Volume
- 常用的数据卷
    - 本地 (hostPath , emptyDir)
    - 网络 (NFS , Ceph , GlusterFS)
    - 公有云 (AWS , EBS)
    - K8S 资源 (configmap , secret)

__emptyDir : 临时存储卷__
- 是一个临时存储卷，与 Pod 生命周期绑定一起，如果 Pod 删除了卷也会被删除
- 用于 Pod 中容器之间数据共享
- 容器共享 emptyDir 示例
    ```yaml
    apiVersion: v1
    kind: Pod
    metadata:
      name: my-pod
    spec:
      containers:
      - name: write
        image: centos
        command: ["bash","-c","for i in {1..100};do echo $i >> /data/hello;sleep 1;done"]
        volumeMounts: 
          - name: data 
            mountPath: /data
      - name: read 
        image: centos 
        command: ["bash","-c","tail -f /data/hello"] 
        volumeMounts: 
          - name: data 
            mountPath: /data
      volumes: 
        - name: data 
          emptyDir: {}
    ```

__hostPath : 节点存储卷__
- 挂载 Pod 所在节点上文件或者目录到 Pod 中的容器里
- 一般用于挂载 Pod 中容器都需要访问的宿主机文件，比如 hosts 什么的
- yaml 文件示例
    ```yaml
    apiVersion: v1 
    kind: Pod 
    metadata: 
      name: my-pod 
      spec: 
        containers: 
        - name: busybox 
          image: busybox 
          args: 
          - /bin/sh 
          - -c 
          - sleep 36000 
          volumeMounts: 
          - name: data 
            mountPath: /data 
        volumes: 
        - name: data 
          hostPath: 
            path: /tmp 
            type: Director
    ```
__NFS : 网络存储卷__
- nfs 是一个主流的文件共享服务器，安装步骤如下
    ```shell
    yum install nfs-utils     # 每个 Node 上都要安装 nfs-utils
    vi /etc/exports
        /ifs/kubernetes *(rw,no_root_squash)
    mkdir -p /ifs/kubernetes
    systemctl start nfs       # 只有 server 端需要开启 nfs
    systemctl enable nfs

    mount -t nfs 192.168.1.205:/ifs/kubernetes /mnt/ # 挂载 nfs 存储命令
    umount 10.244.169.163 # 卸载 nfs 存储命令
    ```
- 提供对 NFS 挂载支持，可以自动将 NFS 共享路径挂载到 Pod 中
    ```yaml
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: web
    spec:
      selector:
        matchLabels:
          app: nginx
      replicas: 3
      template:
        metadata:
          labels:
            app: nginx
        spec:
          containers:
          - name: nginx
            image: nginx:1.16
            volumeMounts:
            - name: wwwroot
              mountPath: /usr/share/nginx/html
            ports:
            - containerPort: 80
          volumes:
          - name: wwwroot
            nfs:
              server: 192.168.1.205
              path: /ifs/kubernetes
    ```

__为了将存储抽象出来而引入持久卷，从而对开发实现屏蔽具体的存储路径的需求__
- PV 用于定义数据卷，将存储作为集群中的资源进行管理
    ```yaml
    apiVersion: v1 
    kind: PersistentVolume 
    metadata: 
      name: web-pv 
    spec: 
      capacity: 
        storage: 5Gi 
      accessModes: 
        - ReadWriteMany 
      nfs: 
        path: /ifs/kubernetes 
        server: 192.168.1.205
    ```
- PVC 在定义容器时使用，让用户不需要关心具体的 Volume 实现细节
    ```yaml
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: web
    spec:
      selector:
        matchLabels:
          app: nginx
      replicas: 3
      template:
        metadata:
          labels:
            app: nginx
        spec:
          containers:
          - name: nginx
            image: nginx:1.16
            volumeMounts:
            - name: wwwroot
              mountPath: /usr/share/nginx/html
            ports:
            - containerPort: 80
          volumes:
          - name: wwwroot
            persistentVolumeClaim:
              claimName: web-pvc
    ---
    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      name: web-pvc
    spec:
      accessModes:
        - ReadWriteMany
      resources:
        requests:
          storage: 5Gi
    ```
- 查看部署的 PV 和 PVC
    ```
    kubectl get pv
    kubectl get pvc
    ```

__PV 的生命周期__
- AccessModes - `访问模式` : 是用来对 PV 进行访问模式的设置，用于描述用户应用对存储资源的访问权限
    - ReadWriteOnce（RWO）：读写权限，但是只能被单个节点挂载 
    - ReadOnlyMany（ROX）：只读权限，可以被多个节点挂载 
    - ReadWriteMany（RWX）：读写权限，可以被多个节点挂
- RECLAIM POLICY - `回收策略`
    - Retain（保留）： 保留数据，需要管理员手工清理数据 
    - Recycle（回收）：清除 PV 中的数据，效果相当于执行 rm -rf / ifs/kuberneres/* 
    - Delete（删除）：与 PV 相连的后端存储同时删
- STATUS - `状态`
    - Available（可用）：表示可用状态，还未被任何 PVC 绑定 
    - Bound（已绑定）：表示 PV 已经被 PVC 绑定 
    - Released（已释放）：PVC 被删除，但是资源还未被集群重新声明 
    - Failed（失败）： 表示该 PV 的自动回收失败

__PV 和 PVC 的匹配机制__
- 首先 pv 和 pvc 里面标记的存储容量并不是限制实际容量的，而是作为匹配标签存在的，如果没有相对应容量的 PV 存在， PVC 会保持 pending 状态等待相对应的 PV
- 访问模式也作为匹配的依据

__使用 [StorageClass 对象](https://v1-19.docs.kubernetes.io/zh/docs/concepts/storage/storage-classes/)实现 PV 动态供给__
- 通过 StorageClass pvc 不需要由 pv 申请资源，而是由 StorageClass 去分配
- 创建存储类 : [rbac.yaml](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/%E6%89%80%E9%9C%80%E8%A6%81%E7%9A%84%E6%96%87%E4%BB%B6/nfs-client/class.yaml) ，查看存储类
    ```
    kubectl get sc
    ```
- 修改 nfs-client 的 nfs 参数并部署 : [deployment.yaml](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/%E6%89%80%E9%9C%80%E8%A6%81%E7%9A%84%E6%96%87%E4%BB%B6/nfs-client/deployment.yaml) ，用以管理并动态分配 PV
- 授权访问 apiserver : [rbac.yaml](https://github.com/lcePolarBear/Kubernetes_Basic_Config_Note/blob/master/%E6%89%80%E9%9C%80%E8%A6%81%E7%9A%84%E6%96%87%E4%BB%B6/nfs-client/rbac.yaml)
- 容器申请 PV
    ```yaml
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: web
    spec:
      selector:
        matchLabels:
          app: nginx
      replicas: 3
      template:
        metadata:
          labels:
            app: nginx
        spec:
          containers:
          - name: nginx
            image: nginx:1.16
            volumeMounts:
            - name: wwwroot
              mountPath: /usr/share/nginx/html
            ports:
            - containerPort: 80
          volumes:
          - name: wwwroot
            persistentVolumeClaim:
              claimName: web-pvc
    ---
    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      name: web-pvc
    spec:
      storageClassName: "managed-nfs-storage" # 创建 pvc 时指定存储类名称
      accessModes:
        - ReadWriteMany
      resources:
        requests:
          storage: 5Gi
    ```
- 以后容器 pvc 申请 pv 不需要先创建 pv ，只需要在 PVC 指定不同的 claimName 就可以

__ConfigMap : 应用程序配置文件存储__
- 使用 ConfigMap 来将你的配置数据和应用程序代码分开，在 ConfigMap 中保存的数据不可超过 1 MiB
- Pod 使用 configmap 数据有 `变量注入` 和 `数据卷挂载` 两种方式
- 示例 : Pod 使用 ConfigMap 导入环境变量
    ```yaml
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: configmap-demo
    data:
      abc: "123"    # 设置参数
      cde: "456"

      redis.properties: |   # 设置参数集合
        port: 6379
        host: 192.168.31.10
    ```
    ```yaml
    apiVersion: v1
    kind: Pod
    metadata:
      name: configmap-demo-pod
    spec:
      containers:
        - name: demo
          image: nginx
          env:
            - name: ABCD    # 创建一个变量以引用 ConfigMap 变量
              valueFrom:
                configMapKeyRef:    # 引用 ConfigMap
                  name: configmap-demo
                  key: abc
            - name: CDEF
              valueFrom:
                configMapKeyRef:
                name: configmap-demo
                key: cde
          volumeMounts:
          - name: config
            mountPath: "/config"
            readOnly: true
      volumes:
        - name: config
          configMap:    # 引用 ConfigMap 数据卷
            name: configmap-demo
            items:
            - key: "redis.properties"
              path: "redis.config"    # 指定挂载到 Pod volumeMounts 的文件名称
    ```
    - 进入 Pod 查看 echo $ABCD 能否显示变量，查看 /config 路径下是否有文件 redis.properties

__Secret : 加密应用程序配置文件存储__
- Secret 主要存储敏感数据，所有的数据要经过 base64 编码，常用来存储凭证，例如
    - docker-registry : 存储镜像仓库认证信息
    - generic : 存储用户名密码
    - tls : 存储证书，例如 HTTPS 证书
- 示例 : 将加密后的密码放入参数文件供 Pod 调用
    ```bash
    echo -n 'admin' | base64
    echo -n '1f2d1e2e67df' | base64
    ```
    ```yaml
    apiVersion: v1
    kind: Secret
    metadata:
      name: db-user-pass
    type: Opaque
    data:
      username: YWRtaW4=
      password: MWYyZDFlMmU2N2Rm
    ```
    ```yaml
    apiVersion: v1
    kind: Pod
    metadata:
      name: secret-demo-pod
    spec:
      containers:
        - name: demo
          image: nginx
          env:
            - name: USER
              valueFrom:
                secretKeyRef:
                  name: db-user-pass
                  key: username
            - name: PASS
              valueFrom:
                secretKeyRef:
                  name: db-user-pass
                  key: password
          volumeMounts:
          - name: config
            mountPath: "/config"
            readOnly: true
      volumes:
        - name: config
          secret:
            secretName: db-user-pass
            items:
            - key: username
              path: my-username
    ```