---
title: RMI原理浅析
tags:
  - RMI
categories:
  - - 漏洞原理
abbrlink: 1298d583
date: 2025-04-14 10:33:52
---
@[TOC](RMI原理浅析)
前段时间不是爆了个log4j的远程代码执行漏洞吗！趁机我就了解了一下什么事jndi，然后就接触到了ldap与rmi，所有准备好好学习一番......

以上内容纯属瞎编，如有雷同，绝对是巧合。

其实很久以前就了解过jndi，但那时候感觉积累不够深，所有一直对他的原理没有搞清楚，看的各种文章也是云里雾里的，直到最近在反复研磨了网络上的文章之后，终于有了一点点心得，特此在这里记录一下。
<!--more-->
参考文章：
[Java安全之RMI协议分析](https://www.cnblogs.com/nice0e3/p/14280278.html)
[【入坑JAVA安全】RMI基础看这一篇就足够了](https://blog.csdn.net/he_and/article/details/105532007?spm=1001.2014.3001.5501)

RMI，顾名思义，远程方法调用。就是通过网络调用远程的对象方法实现特定功能的一种协议，java中RMI协议的实现依赖于java的反序列化机制以及JRMP协议或者IIOP协议，至于这两种协议是什么，暂时还没有研究，以后有机会了再研究研究。
这里先甩出来RMI的通信模型：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/8b70ec8c0be1edfe10c5c3e2c928721c.png)
首先我们需要一个注册中心、一个客户端、一个服务器。注册中心注册了服务器上的方法，客户端通过访问注册中心获得对应方法的代理对象，我们称之为stub，然后通过这个代理对象去访问目标服务器的代理，我们称之为skeleton,，目标服务器通过客户端传过来的方法名以及参数执行对应的方法，让后将结果返回个客户端代理对象，客户端代理对象再将结果返回给客户端。
这里需要明确的一点就是，客户端的代理对象，也就是存根并不是客户端自己生成的，而是由注册中心生成并返回的，因为服务器生成的代理，即骨架是随机导出到某一个端口的，这个端口只有注册了该方法的注册中兴知道，而客户端并不知道，而客户端要获取这个ip以及端口的话只能向注册中心查询。

代码层面的理解：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/23f14a6c729231de63bb294151a6234b.png)
上图是向注册中心注册对象的简单的操作步骤，11行首先获取了一个超市对象实例，12行创建了一个注册中心，13行将对象实例绑定到了注册中心里，当rebind被执行的时候会对第二个参数调用getClass方法获得一个类名，然后加上后缀_stub，加载到内存中，让后获取一个remoteRef对象，该对象就存放着服务器的信息，然后将该对象传递到注册中兴进行绑定就获得获得了一个stub对象。客户端通过访问注册中心的1099端口，来获得某一个对象的stub代理。注册中心实际上维护了一个hash表，表示了名称到对象的映射关系，当客户端携带对应的market来查找时，注册中心就会返回对应的stub代理。
为了验证我们的理论，我花了一点时间住了一下RMI协议通行过程中的数据包。

【兄弟们，这张图我画错了，这所有的请求都是在执行lookup方法时才会发送的，欲知详情请参考我的下一篇文章：[从代码层面看RMI规范的实现与攻击原理（一）](https://blog.csdn.net/qq_32731075/article/details/122280860?spm=1001.2014.3001.5501)】
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/c8351e449a79ae9ec586828d3097b1f4.png)
感兴趣的同学可以自己抓一下看看。

我们需要注意到的是，客户端与注册中心，客户端与服务器之间的对象传递是通过java的序列化与反序列化来实现的，那么就衍生出了java的反序列化攻击。需要注意的是调用方法的执行是在服务器上面，但因为服务器往往与注册中兴是在同一个JVM上，所以反序列化攻击的对象往往是注册中心所在的设备，而不是客户端。

而 在攻击的时候通常有三种方式

第一种方式：

客户端在向注册中心进行lookup前首先需要获取一个注册中心，既然有了注册中心，那么我们就可以进行bind与rebind操作
这样我们就可以手动注册一个恶意对象到注册中心，当该恶意对象再被注册的时候前面提到会调用getClass方法获取类名，这个过程中如果我没有记错是会调用静态代码块中的内容，这样我们的恶意代码就被执行了。getClass方法其实就是获取了一个类的Class对象实例，然后其对应的所有类实例都是通过这个Class对象实例生成的，而在获取Class对象实例的过程中就会调用静态代码块中的内容。听起来好像逻辑自洽了，但是不知道对不对，仅供参考。

第二种方式：

第二种方式就是直接调用服务器端有问题的方法来实现我们攻击的目的。

第三种方式：

通过RMI的动态类加载机制来加载恶意类，感觉这种方式是被利用的最多的，最近的log4j2漏洞也是通过这种方式来利用的。
正是因为这个机制，所以你应该知道了你在网络上找的JNDI搭建工具如marshalsec这种为甚么需要你启动一个web服务器，然后把恶意类的字节码文件扔到里面就可以了。
这个万一的原理我还没读，明天再读读。


今晚有点烦躁，或者说最近都有点烦躁，所以写这篇文章时感觉就想是觉得必须要写了一样，自己都感觉写的很差劲，没有进行合理的编排布局，感觉就是胡乱得在堆砌知识点。
