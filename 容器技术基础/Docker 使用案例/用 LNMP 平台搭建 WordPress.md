## Linux+MySQL+PHP+Nginx 配合WordPress 搭建博客

数据库文件要挂载到本地<br>
PHP网页要挂载到一个目录

拉取mysql的镜像（默认8.0） docker pull mysql

注意：要先创建lnmp的网络
```
docker network create lnmp 
```
创建启动容器
```
docker run -d \
--name lnmp_mysql \
--net lnmp \
--mount src=mysql-vol,dst=/var/lib/mysql \
-e MYSQL_ROOT_PASSWORD=123456 mysql --character-set-server=utf8
```

在 /var/lib/docker/volumes/mysql-vol/_data/ 下是初始化的数据库

docker logs lnmp_mysql+docker top lnmp_mysql //常用来进行排错工作

创建数据库 //通过exec将命令传递进docker操作mysql创建一个wp的数据库
```
docker exec lnmp_mysql sh \
-c 'exec mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e"create database wp"' 
```

yum install mysql //安装数据库客户端<br>
mysql -h[ip地址] -uroot -p //进入数据库<br>
mysql> show databases; //可以查看到数据库<br>

先获取PHP的镜像
创建PHP环境容器
```
docker run -itd \
--name lnmp_web \
--net lnmp \
-p 88:80 \
--mount type=bind,src=/app/wwwroot,dst=/var/www/html richarvey/nginx-php-fpm
```

[WordPress获取地址](https://cn.wordpress.org/download/)
解压后要放在/app/wwwroot下
这时我们已经做好端口映射了，只要访问虚拟机的88端口就可以实现间接访问docker
跟着wp的步骤完成就可以了 就可以搭建起一个简单但又功能强大的博客

**真的忘不了搭建起来的喜悦，哈哈哈哈！**

### 遇到的错误
[Authentication plugin 'caching_sha2_password' cannot be loaded](http://www.cnblogs.com/chuancheng/p/8964385.html)//注意这个小伙儿把root的密码给设置成 **root** 了<br>
[MySQL登录时出现 Access denied for user 'root'@'xxx.xxx.xxx.xxx' (using password: YES) 的原因及解决办法](https://blog.csdn.net/metheir/article/details/85238801)//我就是因为无意把密码设成上面的root导致的 但是一直在调权限，但根本不是这里的事情啊啊啊！！！ 算了看以后用不用得到~<br>
[mysql8.0授予权限报错解决方法](https://blog.csdn.net/skyejy/article/details/80645981)//在新版本8下要先创建用户然后创建权限分开来的