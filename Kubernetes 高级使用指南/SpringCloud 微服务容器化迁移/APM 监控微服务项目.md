# APM 监控微服务项目
> Application Performance Management 是一种应用性能监控工具，通过汇聚业务系统各处理环节的实时数据，分析业务系统各事务处理的交易路径和处理时间，实现对应用的全链路性能监测。
- APM 系统主要监控对应用程序内部，例如
    - 请求链路追踪：通过分析服务调用关系，绘制运行时拓扑信息，可视化展示
    - 调用情况衡量：各个调用环节的性能分析，例如吞吐量、响应时间、错误次数
    - 运行情况反馈：告警，通过调用链结合业务日志快速定位错误信息
- APM 系统的选型特点
    - 探针的性能消耗消耗少
    - 代码的侵入性低
    - 监控维度多
    - 可扩展性强
### Skywalking 是一个分布式应用程序性能监控系统，针对微服务体系结构而设计
- 多种监控手段。可以通过语言探针和 service mesh 获得监控是数据
- 多个语言自动探针。包括 Java,.NET Core 和 Node.JS
- 轻量高效。无需大数据平台，和大量的服务器资源
- 模块化。UI、存储、集群管理都有多种机制可选
- 支持告警。
- 优秀的可视化解决方案。
### Skywalking 工作模式
- 使用探针和指标评估应用程序，以 UI 展示，以时序数据库存储
### Skywalking 部署
- 部署 ES 数据库
    ```
    docker run --name elasticsearch -p 9200:9200 -e "discovery.type=single-node" -d elasticsearch:7.7.0
    ```
    - 查看 elasticsearch 数据库是否正常
        ```bash
        # curl -X GRT "localhost:9200"
        {
        "name" : "3de96d0ba640",
        "cluster_name" : "docker-cluster",
        "cluster_uuid" : "hmrJoCQGTNm-oqZJwFEBQg",
        "version" : {
            "number" : "7.7.0",
            "build_flavor" : "default",
            "build_type" : "docker",
            "build_hash" : "81a1e9eda8e6183f5237786246f6dced26a10eaf",
            "build_date" : "2020-05-12T02:01:37.602180Z",
            "build_snapshot" : false,
            "lucene_version" : "8.5.1",
            "minimum_wire_compatibility_version" : "6.8.0",
            "minimum_index_compatibility_version" : "6.0.0-beta1"
        },
        "tagline" : "You Know, for Search"
        }
        ```
    - 确保容器内时间与宿主机时间同步，否则会发生无法读写的问题。_可参考[容器内时间同步](../../Docker%20经验总结/容器内环境配置.md)调整_
- 部署 Skywalking OAP
    1. 下载软件包[软件下载地址](https://archive.apache.org/dist/skywalking/8.3.0/)
    2. 安装 jdk 环境并解压
        ```shell
        yum install java-11-openjdk –y
        tar zxvf apache-skywalking-apm-es7-8.3.0.tar.gz
        cd apache-skywalking-apm-bin-es7/
        ```
    3. 指定数据源
        ```yaml
        # vi config/application.yml
        storage:
          selector: ${SW_STORAGE:elasticsearch7} #这里使用elasticsearch7
        ...
        elasticsearch7:
          nameSpace: ${SW_NAMESPACE:""}
          clusterNodes: ${SW_STORAGE_ES_CLUSTER_NODES:192.168.102.232:9200} # 指定ES地址
        ```
    4. 启动 OAP 和 UI
        ```bash
        ./bin/startup.sh
        ```
    5. 访问 UI
        ```
        http://IP:8080
        ```
### Java 程序接入 Skywalking 监控
- 启动 Java 程序以探针方式集成 Agent ：
```dockerfile
CMD java -jar -javaagent:/skywalking/skywalking-agent.jar=agent.service_name=ms-portal,agent.instance_name=$(echo $HOSTNAME | awk -F- '{print $1"-"$NF}'),collector.backend_service=192.168.102.232:11800 /portal-service.jar
```