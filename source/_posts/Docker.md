---
title: Docker
tags:
  - Docker
  - 容器
categories:
  - - 安全技术
  - - 容器
description: 本文介绍了 Docker 容器的相关知识点
abbrlink: f5f9fa9b
date: 2025-04-10 20:56:11
---
# Docker

docker 配置文件地址：/etc/docker    daemon.json 其中定义镜像仓库等关键信息

docker info //查看docker信息

docker version //查看docker 版本

docker run 镜像 //运行镜像

—name //为容器命名

-i //交互式运行

-t //打开一个终端

-d //后台运行

-rm //推出后销毁容器

-p ip:真机端口：容器端口 | 只写容器端口| 不写-p ,直接写端口

docker stats //查看docker状态

docker image ls //列出本地所有镜像

docker image pull //拉取一个hub镜像

docker image inspect //查看镜像的具体信息

docker image push //推送镜像

docker image load //从包中加载一个镜像

docker image  save //打包一个镜像

docker image search httpd //搜索镜像

docker image  rmi 镜像名 //删除一个镜像

docker ps -a //查看正在运行的以及曾今运行过的容器

-n=1 //显示最近运行的容器，数字表示个数

-q   //只显示容器的编号

exit //停止并退出容器

^+P+Q //容器不停止退出

docker rm -f $(docker  ps -qa) //删除所有容器

docker rm  容器id //删除一个容器

docker inspect  容器id //查容器信息

docker stop 容器id

docker restart 容器id

docker stop 容器id

docker kill  容器id

docker run 

-d(后台运行，脱离真机终端) 

-p 80:80 (真机端口：容器端口)  使外部可以访问

-i (交互式运行) 

-t (终端) 

—rm(当容器处于退出状态时自动删除容器)

—name 为容器指定名称

docker exec  -it 容器 id /bin/bash  //登录容器

-c  "count=0;while true;do echo "111";sleep 2;let count++if [ $count -gt 100;then return;fi];done" //输入命令

一个容器中只有一个主进程，并一直占据容器的终端

docker kill|stop  容器id //停止容器

docker rm -f 容器id //删除容器

docker top 容器id //显示资源占用信息

docker exec -it 容器id shell //进入正在运行的容器，并开启一个新的终端，退出后不会杀死容器

docker attch b2851800b493  //进入容器，不开启一个新的终端，推出后会杀死容器

 docker cp 容器id:容器内路径 目的主机路径 //从容器内向主机拷贝数据

docker pause 容器id //暂停容器

docker unpause 容器id //停止暂停

 

自定义镜像

method 1:

Dockerfile

method 2 :

打包现有文件

docker commit -m="描述信息" -a="作者" 容器ID 目标镜像名:tag

镜像是一种轻量级的、可执行的独立软件包，用来打包软件和软件的运行环境等，他包含了软件运行所需要的所有的代码、库、环境变量、配置文件等

# docker镜像加载原理

## 联合文件系统-UFS

将文件分层管理，与图层有异曲同工之妙，可将文件的修改一层一层的叠加，可共享一些层，从而节约的内存与空间，比如安装mysql与php都需要用到centos，则centos只会被下载一次，不需要重复下载

我们可以运行一个docker容器，然后在该容器中修改自己需要的单元，修改后的内容可以通过docker commit 来保存一个新的镜像，我们修改的部分成为新的一层。

docker commit -a author -m describtion_info  容器id 镜像名:标签 -p 在执行改命令时暂停容器 -c 使用dockerfile创建容器

# 容器数据卷

容器被删除后，其中保存的数据就消失了，这样风险太高，这是后需要将数据保存在别的地方，我们通过卷技术来实现，

原理就是将容器内的数据关联到真机上面。不仅如此，容器间也可以实现数据共享

方式一：

docker  run -it -v 主机目录地址: 容器目录地址 -v 主机目录地址: 容器目录地址

可同时挂载多个目录

双向绑定，修改任一方的文件，另一方将同时变化，文件数据实际存储在真机上，删除容器后，数据不会丢失

 具名挂载：指定挂载卷的名称

匿名挂载：不指定挂载卷的名称  

默认挂载路径：/var/lib/docker/volumes/卷名/_data/

docker volume ls   //查看所有卷

-v 卷名:容器内路径:ro|rw //只读，可读可写          针对容器而言

方式二：dickerfile

新建一个文件，写入一下内容

FROM centos //基础镜像

VOLUME ["容器内目录地址01","容器内目录地址02"]

CMD echo " ——挂载完毕———"

CMD   /bin/bash

执行：docker build -f  dockerfile_name -t armandhe/centos(镜像名) .

## 数据卷容器-容器与容器将数据同步

创建三个容器———实现了同一功能的

```bash
docker run -it  —name "docker01" 容器id  //创建父容器
```

```bash
docker run -it —name "docker02" 容器id —volumes-from docker01 //创建子容器
```

```bash
docker run -it —name "docker03" 容器id —volumes-from docker01 //创建子容器
```

三个容器共享数据，无论在哪一个容器中新增数据，另外两个都会同步。同步的数据只是针对数据卷的。

# dockerfile

dockfile 一行命令就是一层，定义了所有的步骤

dockerinages :通过dockerfile生成的镜像

docker容器：容器就是运行起来的镜像，镜像与容器的关系就像类与实例的关系

所有指令均为大写

## dockerfile指令

```bash
FROM  //基础镜像
MAINRAINER //维护者信息
RUN //运行时的命令
ADD //步骤，添加内容
WORKDIR //镜像的工作目录
VOLUME //容器卷
EXPOSE //指定暴露的端口
RUN //
CMD //指定容器启动的时候需要运行的命令,只有最后一个会生效，可被替代
ENTRYPOINT //和cmd相似，但可追加命令
ONBULID //当构建一个被继承dockerfile 这个时候就会运行改命令
COPY //类似add，将文件拷贝到镜像中
ENV //构建的时候设置环境变量
```

发布镜像

```bash
docker login -u dockerhub_name -p
```

```bash
docker tag reposity_name/images_name:tag
```

```bash
docker push tag
```

# docker网络原理

docker安装的时候会生成张docker0网卡，充当所有容器的路由器

evth-pair //充当桥梁来连接不同的虚拟设备

生成一个容器的时候会成对得生成evth-pair网卡，使得容器与容器之间可以相互通信

![](Untitled.png)

所有的容器在不指定网络的情况下，都是由docker0进行路由的，docker会为每一个容器分配一个可用的ip

![](Untitled%201.png)

物理机网卡与docker通过NAT直连

## —link

容器重启之后，ip地址可能发生变化，那么容器之间通过ip进行通信的话，就需要重新进行配置，这不是我们需要的效果。所以通过—link将两个容器连接起来，无论ip怎么变化，只要容器的名称-服务名不变，那么两个容器之间就仍然可以正常通信。

```bash
docker run -d -P —name "tomcat01" tomcat
```

```bash
docker run -d -P —name "tomcat02" —link tomcat01 tomcat
```

```bash
docker exec-it tomcat02 ping tomcat01  //ok
```

```bash
docker exec-it tomcat01 ping tomcat02 //no
```

如果需要tomcat01能够通过服务名ping通tomcat02 需要为tomcat01也设置—link

本质是在/etc/hosts 文件中配置了映射

可以看出docker0不支持通过容器名来实现容器间的通信

新手入门级，现已不推荐使用

```bash
docker network inspect  容器id
```

```bash
docker network ls //列出所有网络
```

```bash
docker network rm //删除一个网络
```

## 自定义网络

docker网络模式

bridge //桥接

none //不配置网络

host //和宿主机共享网络

container //容器间网络联通

docker run -d —name "tomcat" —net bridge tomcat  //—net 为默认参数，不写也会自动添加、

`docker network create —driver bridge —subnet 192.168.0.0/16 —gateway 192.168.0.1 mynet(网络名)  //自定义一个网络`

使用自定义网络启动容器

```bash
docker run -d -P  —name "container_mynet_01" —net mynet tomcat
```

```bash
docker run -d -P  —name "container_mynet_02" —net mynet tomcat
```

通过该方法运行的容器，可以通过容器名会互相ping通

同时可为不同的集群创建不同的网络，从而保证了网络的健康，提升了网络的安全性

## 网络连通

连接不同的网络，不是直接打通不同的网络，而是将不同网络的容器同网络联通

```bash
docker network connect  网络名 容器名 //将容器连接到网络上，实质是将容器直接放到网络下面，相当于一个容器拥有了两个IP
```