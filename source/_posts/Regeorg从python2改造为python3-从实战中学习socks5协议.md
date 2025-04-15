---
title: Regeorg 从python2改造为python3-从实战中学习socks5协议
tags:
  - socks5
  - Regeorg
categories:
  - - 协议规范
abbrlink: '97967489'
date: 2025-04-14 10:33:52
---

这两天没啥工作，一般这时候我都不会发挥自己的主观能动性去主动找活，于是乎只能上网看看博客，提升提升自己的技术。想起在这家公司呆久了把内网方面本来就不多的知识都快丢光了，于是乎趁着难得清闲准备补充补充营养。看了一些与内网穿透相关的博客，准备实操的时候遇到了麻烦。本着逢山开路遇水架桥的精神，今天势必要把这个问题拿下。
# 问题描述
Regeorg是只提供了对python2的支持，使用python3来运行爆了一大串错我，今天咱就一个问题一个问题得搞定，手把手教你怎么把Regeorg改造成python3版本。看了下这个项目8年前年就停止更新了
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/97ecb5ee4338329ab06c0b030df7da84.png)
<!--more-->
# 解决过程
## 环境准备
|平台| ip地址 |
|--|--|
| 物理机（windows11） | 192.168.1.101 |
|虚拟机1（centos7）|双网卡192.168.248.146(nat)、172.16.128.2(仅主机模式)|
|虚拟机2（windows7）|172.16.128.1(仅主机模式，搭建了web服务器)|
物理机作为我们的攻击机，可以正常与虚拟机1通信，虚拟机1安装了web服务作为受控主机，可正常与物理机与虚拟机2通信，虚拟机2模拟内网主机，仅能与虚拟机1通信不能与物理机通信
## 过程
首先我们把项目 clone下来
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/d531a71d517083d9bebe4aeb09d61e0f.png)
因为被控主机的中间件解析器为PHP所以这里选择php后缀的脚本作为代理转发服务器，可以看到有两个php文件，他两的区别在于一个使用了dl加载动态链接库一个没有
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/6302ac82d9c11e48049e198ddd612390.png)
这么看来该文件只能在windows环境下使用，且因为PHP貌似是5.2之后就溢出了dl函数，所以我们不用这个文件而用tunnel.nosocket.php来作为代理服务器。当该文件被上传到受控主机后使用浏览器访问该文件
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/58625b0f130fb888f7066a19ac678cbc.png)
如果看到这些字就证明服务器已就位，当然这个过程可能并不会那么顺利，你可能会遇到的问题为权限问题导致的文件不可用，这时候只需使用`linux`命令`chmod`给 `tunnel.nosocket.php`赋予更高的权限就ok了。
然后我么运行命令
```shell
python reGeorgSocksProxy.py -p 8754 -u http://192.168.248.145/tunnel.nosocket.php
```
在我们的攻击机上起一个客户端
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/fa058e1d062e8d304184d650d283e46a.png)
报错了，这个很见到，把代码里所有的`except`语句中的逗号改成`as`就好了。然后运行又报错了
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/98b84fedce2f56ca214ae1589a3389f6.png)
这个也很简单，`print`的写法不对，改成`print()`就好了，再运行

![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/7a6b1c432a99fd9eea79db8888ece049.png)
说是少了模块，看一下怎么引入的
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/7bbc7c72185f3c3a55a613ba4cb04af3.png)
`python3`里面`urlparse`集成到`urllib`包里面，直接删掉这一行然后重新导入
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/ecead071f4b5bbd407812026d4051afd.png)

再运行虽然没有说没有报错但是提示了，`georg`没有准备好
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/a84e9ac7cc5e22b2806783cdbc43f736.png)
在代码里搜一下这句报错在哪儿出现的
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/e9c237dc00808f555a523bbb2d759238.png)
看来是这行`askGeorg`返回了`False`，跟进去看看
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/ced66d140d30ac8e35728340dc47e33d.png)
重点画红框的地方，内层的if语句没有进去，我们直接打印一下相关的值看看
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/82e89d004969163ba8c14115fdad24ed.png)
注意到`response.dat`返回的是字节类型与`BASICCHECKSTRING`的字符串类型肯定不相等，我们将`BASICCHECKSTRING`的类型修改为字节文本就`ok`了，记得不要再使用`strip`去除两端空白字符
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/0ec6fa88abffe7b8479c6051b0212c39.png)
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/7df90243bf7ab5b29611e562a4407c2c.png)
再运行看起来ok了
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/44eccbbfe4dc6f729a1dd632b5651cc4.png)
当然事情没有那么简单，这时候我们使用`proxifier`将本地应用的流量代理到`regeorg`客户端试一下
配置代理服务器
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/76abbec7793072c7e1fde2a8a2df5250.png)
配置代理规则
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/6547dde1f41b35a9de072dfbe3fdb792.png)
这里注意第一处红框处是为了让本地环回网卡的流量都通过直连的方式访问，避免死循环，第二处红框则是将使用chrome浏览器访问`172.16.128.1`的流量都转发到我们的`regeorg`客户端。然后我们用浏览器访问一下`172.16.128.1`
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/5c8f58075f2a46b420c95e81b8f08bdc.png)
发现访问失败了，而且`regeorg`客户端屁都没有冒，这肯定是哪里出现了问题，那么我们还是来调试一下

![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/aba99a4b53948789d732d47502454885.png)
最终的请求是由这条语句进行的那么我们跟进去看看，这里调用了`start`方法，应该是多线程的写法，所以我们直接去找`run`方法
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/742086ad66da9674eadc46708c9c167d.png)
注意到刚才控制台没有打印日志，也就是没有报错也没有进入if分支，也就是说，if的判断条件返回了`false`，那么跟进去看
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/2ba215498dff04709a1e3487da1be6d6.png)
这里就是在对`socks`协议进行解析了，首先读取了一个字节，这里的第一个字节也就是使用的协议版本号，这里为`socks5`协议，我们打印一下看看
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/a8b92d967f4a49d2092512c8eba00d50.png)
很明显这里又是数据类型有问题，在`python2`中字节文本与文本字符串是不分开的所以无所谓，但`python`里做了严格的区分，所以这里我们将连个`if`判断条件改为字节文本。
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/416ea62c6df5f7ee88081d90139d4f9c.png)
再运行
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/76cfa7252d15c299dd537ddf8bab7ca5.png)
又报错了，这里说的是在141行需要一个字节对象，但给了一个字符串，那就到141行
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/37e3efc518bf7d2004c79c68f6b722dc.png)
这里的`VER`与`METHOD`为定义的两个字符串常量，我们知道`sockets`的`sendall`是不能发送字符串的需要对其进行编码，这里可以使用`encode`方法同一修改或者在其定义的地方修改
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/ceeac2b3ba3c44fe58b54d3f0606667a.png)
再运行，又报错
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/0703ef906c9884e66280559026b329f5.png)
说的是166行`None`类型不能进行切片，也就是说`targetPort`返回了`None`，去看看
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/e942c6c511496d40a72f12f185203247.png)
那么再看看`targetPort`哪里来的
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/8e607021b4b8f987b760e045b0c62569.png)
大意就是通过`atyp`的值，来判断`targetPort`的取值方式，这里很明显还是数据类型导致的，老规矩直接改成字节文本，同时注意到这里会继续对`proxifier`发过来的握手包进行解析，先解析两个字节，一个字节是`nmethods`，一个为`methods``，nmethods`表示可以使用的方法，`methods`表示方法的值。然后`regeorg`会选择可用的方法给`proxifier`回包告诉向客户端确认协议版本号以及使用的方法。这里看一下这几个参数的值

![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/5ad30111475af280ed290ec3dae3ae3a.png)
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/1a1b501ffb0d39e593fdd3779a6ea606.png)
然后`proxifier`会再回一个包，这里进行解析
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/304db3550a2ae2b4a9b29c291d0996b9.png)
首先第一个字节任然是版本号，然后根据版本号的不同会有不同的解析方式，这里直接看`socks5`的格式
后面字节分别为命令，保留位以及目标类型，这里看一下值
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/fcf7266a7587289ac9b3ab14fed79f80.png)
命令为01，也就是连接请求，保留位不管，然后是目标类型01也就是ipv4地址。
这些都了解了我们继续看报错的内容
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/3a0ae96d858aac3a66887b752deea43a.png)
说ord函数拿到了一个整数，但需要的是1个字符，这里直接改
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/002db315455703ef5072157e3d276ec3.png)
再运行
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/462d7582eb007c1a3b95ecc2327c0772.png)
还是这儿不过报错内容变了，还是数据类型的问题，直接改就完了
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/176be127ed8938f9f8efc3a0e05fb0f4.png)
运行，看报错
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/ab9f3cf728b02c6ca63667e371686f5f.png)

这里说的是连接目标失败，然后我搜了这一句报错在代码里面没有，那么只有可能来自服务端的响应，去服务端搜
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/b6f114b7d3786ad8062e0c88bcfe2db4.png)
这一看就是socket连接失败了，然后我一看我虚拟机自动挂起了，重新开起来再运行
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/834676e13418f033c9f5b1d41572ea24.png)
又是数据类型问题，直接改
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/1676c712ac01528957e13c058c8c6104.png)
再运行
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/9d0b4e6115dab04a5e526c3f903181d1.png)
搞定了，不过浏览器的渲染结果是这样的
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/e93be96c679b771f49e124bb63fc58fd.png)
响应无效，说明是响应的问题，然后我使用`proxifier`代理了`burp`的流量看了下响应
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/bc9496b44d736bf6b0cc1459df0d5f08.png)
协议前头多了个`P`啊，这浏览器解析不了很正常，秉持着打破砂锅问到底的精神，我们还是要装样子看看这个`P`怎么来的，所以这里打印一下客户端从服务端获取的响应
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/caf0cbb99f1dfb5b61d66f8e36d0f54f.png)
这也没有`P`啊，证明应该不是`regeorg`的问题，那么就是`proxifier`的问题了，这个就有点难搞了。。。





















