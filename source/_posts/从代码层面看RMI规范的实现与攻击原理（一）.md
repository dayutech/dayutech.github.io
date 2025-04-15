---
title: 从代码层面看RMI规范的实现与攻击原理（一）
tags:
  - RMI
  - 代码审计
categories:
  - - 漏洞分析
  - - 代码审计
description: 本文介绍了 从代码层面看RMI规范的实现与攻击原理
abbrlink: ca82fc3b
date: 2025-04-14 10:33:52
---
@[TOC](从代码层面看RMI规范的实现与攻击原理（一）)

上一篇文章粗糙的讲了RMI规范相关的一些内容，今天通过代码跟踪了一下具体的实现过程，发现昨天的理解有一些是错误的，首先看一段客户端的代码：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/dc2c46acd260661e09a2d95aad5d5816.png)
我们重点关注第15行与16行，这两行分别是获得一个注册器与从hash表中查询market键对应的对象的操作，我们首先打断掉跟进到`LocateRegistry#getRegistry`方法里面：

```java
public static Registry getRegistry(String host, int port,
                                       RMIClientSocketFactory csf)
        throws RemoteException
    {
        Registry registry = null;

        if (port <= 0)
            port = Registry.REGISTRY_PORT;

        if (host == null || host.length() == 0) {
            // If host is blank (as returned by "file:" URL in 1.0.2 used in
            // java.rmi.Naming), try to convert to real local host name so
            // that the RegistryImpl's checkAccess will not fail.
            try {
                host = java.net.InetAddress.getLocalHost().getHostAddress();
            } catch (Exception e) {
                // If that failed, at least try "" (localhost) anyway...
                host = "";
            }
        }

        /*
         * Create a proxy for the registry with the given host, port, and
         * client socket factory.  If the supplied client socket factory is
         * null, then the ref type is a UnicastRef, otherwise the ref type
         * is a UnicastRef2.  If the property
         * java.rmi.server.ignoreStubClasses is true, then the proxy
         * returned is an instance of a dynamic proxy class that implements
         * the Registry interface; otherwise the proxy returned is an
         * instance of the pregenerated stub class for RegistryImpl.
         **/
        LiveRef liveRef =
            new LiveRef(new ObjID(ObjID.REGISTRY_ID),
                        new TCPEndpoint(host, port, csf, null),
                        false);
        RemoteRef ref =
            (csf == null) ? new UnicastRef(liveRef) : new UnicastRef2(liveRef);

        return (Registry) Util.createProxy(RegistryImpl.class, ref, false);
    }
```
该方法是一个重载方法，我们调用的方法有三个参数分别是`host, port, csf`，比较疑惑的可能就是csf了，该参数传递的是一个`RMIClientSocketFactory`接口的对象，我们跟进去看一下：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/433a37af554e1cc218c20ac9b9ae652b.png)
根据名字很容易看到只要有一个该接口的实现类调用了`createSocket`方法就会创建一个socket，继续回到`getRegistry`方法
它首先判断了你是否为你的方法传入了`port`参数，如果没有传入，则获取系统默认的端口`1099`
然后判断你是否传入了主机名，如果你没有传入则会使用本地主机名，`loacahost`。
下一步将会创建一个LiveRef对象，至于干什么的我不清楚，简单看了看就是为一些变量赋值，后面会用到它们：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/73f8cc3eba58a21d03f3c0379b897e01.png)
可以看到`host, port,csf`都被他使用了。具体是通过`TCPEndpoint`这个方法传进去的，这些方法的作用具体不太清楚，毕竟不是专业的。
然后创建了一个`RemoteRet`对象，
`csf == null) ? new UnicastRef(liveRef) : new UnicastRef2(liveRef)`
如果csf为null，则实例化`UnicastRef`
我们跟进去看一看：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/94eca87ca47b8a9a0ee84f7a6c84ee6a.png)
我们看这个单播引用类是实现了`RemoteRef`接口的
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/f4cf160b5bfbfc4d6fbb7ba9c2ca7b1c.png)
而这个`RemoteRef`接口又是继承了`Externalizable`接口，这意味着该类可以被序列化与反序列化。
我们实例化时调用的构造方法是这一个：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/7364e60c6051154f22ac6c0babd799cd.png)
ref是一个LiveRef类型的变量。除了这个动作没有其他的动作了
心血来潮我又回去看了一下`LiveRef`类，他继承了Cloneable接口，证明它可以被克隆，至于什么事克隆暂时不清楚，写完了去看看。
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/6bdb8f78323c8e77298a6556f840e565.png)
继续回到`getRegistry`方法，
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/e2008aa62eb947f81a31d64c989d8eb7.png)
createProxy方法接受了三个参数，第一个是`RegistryImpl`类的Class实例，第二个是上面提到的ref，第三个是一个boolean值，看提示是是否强制使用Stub，我们这里传递的是`false`，也就是不使用。
我们跟进该方法：
```java
public static Remote createProxy(Class<?> implClass,
                                     RemoteRef clientRef,
                                     boolean forceStubUse)
        throws StubNotFoundException
    {
        Class<?> remoteClass;

        try {
            remoteClass = getRemoteClass(implClass);
        } catch (ClassNotFoundException ex ) {
            throw new StubNotFoundException(
                "object does not implement a remote interface: " +
                implClass.getName());
        }

        if (forceStubUse ||
            !(ignoreStubClasses || !stubClassExists(remoteClass)))
        {
            return createStub(remoteClass, clientRef);
        }

        final ClassLoader loader = implClass.getClassLoader();
        final Class<?>[] interfaces = getRemoteInterfaces(implClass);
        final InvocationHandler handler =
            new RemoteObjectInvocationHandler(clientRef);

        /* REMIND: private remote interfaces? */

        try {
            return AccessController.doPrivileged(new PrivilegedAction<Remote>() {
                public Remote run() {
                    return (Remote) Proxy.newProxyInstance(loader,
                                                           interfaces,
                                                           handler);
                }});
        } catch (IllegalArgumentException e) {
            throw new StubNotFoundException("unable to create proxy", e);
        }
    }
```
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/442dea619c0643cc0ed79dc8a48ee273.png)
注意到第13行的方法，跟一下看看：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/13ebee87d6b540073f9077c94d72b8a2.png)
`getRemoteClass`运用了java的放射原理，
194行获得了`RegistryImpl`类实现的所有接口的Class对象，然后遍历这些接口通过调用`Remote`类Class对象的`isAssignagleFrom`方法判断Remote是不是这些接口的父类、超接口、或者同一类型。
那么到底是不是呢，我们找到了`RegistryImpl`类：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/cd4bf8099daeb1ff6d8e4ae2aebf853d.png)
发现它集成了`RemoteServer`类，实现了`Register`接口
而`RemoteServer`的父类实现了`Remote`接口，`Register`接口继承了`Remote`接口，所以上面的条件是成立的，将会放回lc，也就是`Registry`类的Class对象，
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/646884aa623fa0b36879861937bcd998.png)
调试结果也证实了我们的推断。
然后进入一个if判断：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/5dd542afad768b13c489070d87531bd3.png)
我们知道`forceStubUser`是`false`的，但是调试的结果是计入了该`if`的判断中，那么后面判断条件就必须是`true`，我们先看`ignoreStubClasses`
这个值是在`Util`类被加载的时候赋值的：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/80023964b8a5ca6514d40400914faa02.png)
跟进`booleanValue`方法![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/3b9842e3cc2c528b227e430172ac8ca0.png)
发现到了`Boolean`类，这里返回的是其默认值，我们知道Boolean的默认值为False。
那么看第三个参数`stubClassExists`的返回值必须为`true`才能满足调试的结果：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/eaedc98b131b660f4c07765bb71af399.png)
影响判断的结果的语句是
`!withoutStubs.containsKey(remoteClass)`
如果为`true`则返回true，我们知道containsKey方法一般是在集合类型中，判断是否存在指定映射关系，我们看看withoutStubs是否为集合类型：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/a60773d7b77631b90800f05a34dc99a3.png)
确实是，那么有没有对应的映射呢？很明显是没有的，那么到这里条件就满足了。注意到了在if里面还通过java的反射机制将`RegisterImpl_Stub`类加载到了内存中。
`createProxy`的if条件满足后，就进入到方法`createStub`，看着方法名就知道是准备创建一个客户端存根了，不过奇怪的地方来了，昨天不是讲了，客户端存根是在注册中兴创建然后远程加载到客户端的吗？这儿怎么又在客户端创建了？这里我的理解是，在注册中心创建的存根创建后经过序列化，传输到客户端，然后客户端需要有对应类型的对象来接收他，所有这里客户端也会创建一个存根，纯属个人理解不知道对不对。
`createStub`这个方法接收了连个参数，一个是`remoteClass`，也就是`RegistryImpl`类的Class对象，一个是`clientRef`这个是什么呢？好像给跟漏了，不着急，我们找一找：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/5e2d5a6740f6a4e23b6689ff9dce7c5d.png)
原来`createProxy`方法的第二个参数就是，也就是刚刚传进来的`ref`一个单播引用对象`UnicastRef`继承乐`RemoteRef`
跟进`createStub`方法：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/e372f5b4e9b9d79eb7ea630e0631ee76.png)
首先获取了`stubname`即`RegistryImpl_Stub`
然后291到294行加载了`RegistryImpl_Stub`类到内存中,并获取了其所有的构造方法，然后调用了其中的一个有参构造方法将`ref`作为参数传递了进去。
这时候得想办法进到`RegistryImpl_Stub`类里面看看调用了怎样的方法，因为最终放回的`Registry`会调用lookup方法，我们通过该方法找到对应的实现类：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/00f415e5d43c9694fc309251e82e6534.png)
进入后找到对应的构造方法：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/ac54b1bc4245ba130b0b54b9efb0ad22.png)
使用super调用了父类的构造方法，找到`RegistryImpl_Stub`的父类：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/1dfaa82c2b8acfcfd4a00c08d88434f9.png)
这绝对是在套娃，没跑了：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/76b62e0fef1ab8ea167a0899c47e4032.png)
我草，这啥也没干啊，就赋了个值罢了。不管了，我们继续。
所以`createStub`方法最终返回的是一个`RemoteStub`对象：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/e637c33399b0c63a5b71f07d5d6d306c.png)

然后`createProxy`继续将这个对象往上一层抛：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/afc6e7e0dd8154abc68be33a0de6b8cf.png)
最后在`getRegistry`方法中被强转为`Registry`类型的对象。
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/2cbb3d4be5b250b90bbc2c01a4cecfc0.png)
我们知道像下转型才是需要强转的，那么`Registry`到底是不是`RemoteStub`类型的子类呢？
貌似好像不是的，这个的原理我不太理解，是知识还有欠缺，实际上`Registry`是一个接口继承了`Remote`接口
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/effaacb1129012dcc50601b360a4bf87.png)
而`RemoteStub`继承了`RemoteObject`
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/2b2e5aa9c064976943c43abd97560713.png)
而`RemoteObject`类实现了`Remote`接口
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/2fcbd9f29e84cfb93491b602bc752f31.png)
所以这算什么？
这也不是向下转型，而是向上转型，不算一般意义上的强转，当然向上转型也是可以使用强转的。
这里的我的理解是`RemoteStub`向上转型到`Remote`，因为`Registry`是扩展了`Remote`接口的，所以也是可以的。
到了这里我们就获得了一个注册器了，到此为止我们仍然没有发现客户端向注册中心发送请求获取存根的代码，为了验证我的推导，我使用难了wireshark抓包，发现确实没有导1099端口的流量：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/ae46705e9699401864cf20c96aa27aa9.png)

那么这部分代码最有可能是存在于lookup的过程中。
欲知后事如何，请听下回分说。

