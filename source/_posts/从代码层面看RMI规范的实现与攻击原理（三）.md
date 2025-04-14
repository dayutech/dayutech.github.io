---
title: 从代码层面看RMI规范的实现与攻击原理（三）
date: 2025-04-14 10:33:52
tags:
- RMI
- 代码审计
categories:
  - [漏洞分析]
  - [代码审计]
description: 本文介绍了 从代码层面看RMI规范的实现与攻击原理
---

@[TOC](从代码层面看RMI规范的实现与攻击原理（三）)

书接上文，JRMP协议的的握手过程已经结束了，下面就是正式的携带key去注册中心查询是否存在对象了
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/f491fd63defa7f9645b0bcf86b96af5c.png)
昨天的所有分析都是在1处的代码里面，今天进入到2处
首先狐疑到的是118，119行有一个序列化的过程，首先还是获取了一个输出流，然后向里面写了一个对象`$param_String_1`，当时讲道理这个参数是个字符串，也不是一个对象啊？这是我最开始疑惑的点，但我们要知道在java中`String`类型就是一个对象并不是一种元类型，其是一种包装类。。
然后我们进入到`invoke`方法里面去：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/aabcd8f6377850df6273f5685c1385bb.png)
毫无疑问，try代码块里面的语句是重点，后面都是些异常捕获的语句，我们继续跟进：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/660c3aea8f9ee02f426fa40f9b0ae3b4.png)
看到进入了`StreamRemoteCall#executeCall`
首先对`out`进行判空，这里很明显是不为空的，我们刚刚才往out里写了对象，然后获取了一个`DGCAckHandler`对象，嗯，我看了里面的代码，这样直接获取的处理器为空，应该会只是想要这么个对象后面调用其中的方法。
然后调用`releaseOutputStream`方法这玩意儿打眼一看就知道是释放输出流的意思，至于具体功能我们还要看看：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/c498017c916e88b689e44015854513e2.png)
首先进行了判空，一样的道理坑定不为空，然后执行`out.flush`，有了昨天的理论支撑我们很容易知道，只一步执行完之后输出缓冲区的内容讲被发送到注册中心，wireshark抓包查看：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/8461be7ed4b0e86f3249fc21f3388120.png)
果然，有发送，然后注册中心也有回包。观察到发送的报文以`aced0005`打头，是序列化没跑了，看到market也包含在里面。
然后应该就是处理返回包的过程了。
在`out.flush`执行完毕后，看到又执行了`out.done`，跟进去看看：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/a91e3d69bc923f3b36ca5561e8c744bc.png)
首先对`dgcAckHandler`进行判空，很明显我们刚才获取过，这玩意就是空的，所以里面的代码不会执行，不过看这意思是要开始一个计时器。
回到上一层，执行到`conn.releaseOutputStream()`，跟进去看看：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/8c65541c45e15e2bd2e16a53f1d4060d.png)
这里又flush一次几个意思，不妨执行一下然后看看还有没有数据发送了。
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/3cb76b3bd1a6e7840fc51714fcca6bbb.png)
发现没有新的数据被发送，所以这里估计是为了确保缓冲区的所有数据都被清空。。
然后将`out`设置为`null`
单步向下回到`StreamRemoteCall#executeCall`第239行：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/c77d25df5f97087bbcfcdedc39074e1d.png)
创建输入流咯。。。
不过之前我们还是看一下输入长什么样吧：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/fa936111a545337626fa373d8f5a931d.png)
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/81515327f8a1b7cf48c4ae15c37aaf52.png)

也是序列化字符串。
然后代码读取一个字节赋值给`op`，也就是`0x51`，十进制就是81，然后判断等不等于`TransportConstants.Return`
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/d9b5450c22355093c7599c7b4a4f05d1.png)
很明显等于。
然后又调用了一次本类的获取输入流方法
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/db1b686461ad7e0fb2e9e19585254ee4.png)
看样子主要还是判断是否存在过滤器，如果存在就调用过滤器进行过滤，上网搜了搜这个过滤器就是为了反序列化过程中的安全性考虑，规定了哪些类可以被反序列化，哪些类不可以。这里没啥用的感觉，反正没有定义过过滤器，所以也就不会被执行。嘴周放回一个空的流，但是在函数执行完毕后也没有变量接收，所以对我们的逻辑没啥影响，不过从这儿也可以看到可以在这儿设置过滤器来避免危险的反序列化操作。
回到上一层，再读一个字节的数据。按照调试的结果读出来的数据是1。
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/182e6bef6f9f7bc2de4d079086301303.png)
我不李姐
。。。
原来这个`readByte`是`in`的方法，这个in也就是刚才`getInputStream`赋值的，讲道理这时候获取的输入流连应该啥也没有才对。。。
我更不理解了。
然后是`readID`不知道读了个什么神奇的东西。
然后进入到`switch`结构中，根据`returnType`判断进入哪一个逻辑，我看了一下是进入这一个
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/143624325c6d29e5d53fdb6f55cfb667.png)
别问我怎么知道的，问就是调试出来的，
这直接break了啊。。。
到了这里一直往下单步执行，发现退出了invoke方法，那么接下来应该就是反序列化注册中心发送过来的stub对象了吧。
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/36f47cd82c6de1c8ad06791a21335421.png)
果然，首先获取了输入流，然后执行了`readObject`方法进行发序列化，然后执行`ref.done`，如果我们猜错现在这一步肯定是要发送挥手包了，然后我一层一层的向里面跟进到了：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/9a3a63e3011ba0be67c80407a5b15e59.png)
然后一个一个进去看。
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/4cf7c9fa99a559f157c80e829b58c7af.png)
这个函数里面有了一些新的数据，看到重点信息是有端口和ip信息。证明源端口或者目标端口要发生变化了，至于到底是源端口还是目标端口我更倾向于源端口，也就是客户端的请求端口未58221，因为此时还没有对注册中心发送回来的数据进行解析调用，那么也就还不知道对象服务器所在的主机以及端口，这里讲道理只能是客户端的端口。

真是草了个大率，，上面一段的反洗完全是在扯犊子。。。。千万不能当真，这个58221端口就是服务器的端口，我裂开了。也就是说在`registerRefs`方法里面，存根已经被解析了，我草。说来也对，这个方法后面就改返回了，loogup函数就结束了，客户端还没有向服务器发送请求，想想也没有这么简单，这才对嘛。今天就到这里，其他明日在来，也就是客户端向服务器请求远程方法的过程。




