---
title: 从头开始挖掘Java RMI漏洞
abbrlink: b83d1f32
date: 2025-05-13 19:37:36
tags:
  - RMI
categories:
  - [漏洞原理]
description: xxxxxx
top: 210
---
# 引言
关于Java RMI 的内容反反复复也是看了很多到了，它在我的日常工作中更多的是作为一个知识点而存在，时不时就得拿出来温习一下，时间久了就会被遗忘掉具体的细节。  
但这个概念也算是Java漏洞利用中的一个明星概念以及有一定复杂度与难度的知识点了，也是面试中的常客（虽然已经很久没有参加面试了，不过我想应该是这样的，毕竟Java安全的东西说破天也就那么多）  
# RMI介绍
RMI 顾名思义即远程方法调用，用户通过一些指定查找远程服务器上的对象方法并实施调用，概念是很清楚的，但其实现的机制却不简单。  
在Java的RMI实现中涉及到三方成员，即调用客户端，远程注册中心以及远程服务提供者。调用客户端很容易理解即RMI调用的发起者，远程服务提供者也不难理解即提供RMI服务的主体，  
远程注册中心想必也并不复杂即远程服务提供者将其能够提供的服务注册到注册中心的注册表中供调用客户端进行查询。
# RMI调用实例
首先创建一个远程对象，其需要继承`UnicastRemoteObject`类并实现一个`Remote`类的子接口。  
继承`UnicastRemoteObject`类是为了在创建该远程对象实例的时候能够调用到继承`UnicastRemoteObject`的构造方法从而完成远程对象服务器的监听以及对象的导出，当然这都是后话，后面会进行详细介绍。
实现`Remote`子接口是因为该接口起到一个标志作用，表明该实现类是可以被远程调用的。    
而远程对象类为什么实现的是`Remote`的子类而不是直接实现`Remote`接口则是因为调用客户端在获得远程对象引用的存根对象时得到的是一个动态代理对象，该对象会被客户端映射为远程的对象直接调用其对应的方法，  
而`Remote`类默认是不存在这些方法的，所以我们需要一个接口先将这些方法进行生命以便调用客户端能够对获得的远程对象存根进行强制类型转换，这一点我们在客户端的创建代码中可以看到。    
```java
import java.rmi.Remote;
import java.rmi.RemoteException;
import java.rmi.server.UnicastRemoteObject;

public class BindObject extends UnicastRemoteObject implements CustomRemote {
    protected BindObject() throws RemoteException {
        super();
    }
    public String sayHello() throws RemoteException {
        return "Hello, world!";
    }
}

```
创建`Remote`接口的子接口`CustomRemote`  
该接口定义了方法`sayHello`，该方法也就是可以被客户端调用的方法。
```java
import java.rmi.Remote;
import java.rmi.RemoteException;

public interface CustomRemote extends Remote {
    public String sayHello() throws RemoteException;
}

```
创建注册中心  
```java
import java.rmi.AlreadyBoundException;
import java.rmi.RemoteException;
import java.rmi.registry.LocateRegistry;
import java.rmi.registry.Registry;

public class RMIServer {
    public static void main(String[] args) throws RemoteException, AlreadyBoundException {
        // 创建远程对象
        BindObject bindObject = new BindObject();
        // 创建注册中心
        Registry registry = LocateRegistry.createRegistry(1099);
        // 绑定远程对象
        registry.bind("test", bindObject);
    }
}
```
创建调用客户端  
```java
import java.rmi.NotBoundException;
import java.rmi.Remote;
import java.rmi.RemoteException;
import java.rmi.registry.LocateRegistry;
import java.rmi.registry.Registry;

public class RMIClient {
    public static void main(String[] args) throws RemoteException, NotBoundException {
        // 获取到注册中心的存根
        Registry registry = LocateRegistry.getRegistry(1099);
        // 通过注册中心存根据远程对象名称查询远程对象获取到远程对象的引用
        // 获取到的是一个动态代理对象  每一个方法的调用都要通过invocationHandler的invoke方法 这很重要
        CustomRemote test = (CustomRemote) registry.lookup("test");
        // 调用远程对象方法
        String s = test.sayHello();
    }
}
```
# 远程服务提供者是如何启动的
我们在 [RMI调用实例](#id_1) 中提到过远程服务提供者需要继承`UnicastRemoteObject`类，其目的是为了能够调用该类的构造方法从而完成远程对象服务器的监听以及对象导出，我们分析的起点也就是该类的构造方法。
此处调用了`UnicastRemoteObject`的有参构造方法并传入了一个参数`0`，该参数表示监听的端口，`0`即由系统自动分配一个端口。
```java
protected UnicastRemoteObject() throws RemoteException
    {
        this(0);
    }
```
接下来调用了`exportObject`方法，顾名思义这是一个与远程对象导出有关的方法，其接收两个参数，第一个参数传入我们实例化的远程对象本身，第二个参数为端口。  
```java
protected UnicastRemoteObject(int port) throws RemoteException
    {
        this.port = port;
        exportObject((Remote) this, port);
    }
```
`exportObject`方法继续调用了其重载方法，该重载方法接受两个参数，第一个参数由外层方法进行原样传递，第二个参数被封装到`UnicastServerRef`对象中。  
`UnicastServerRef`的实例对象是对远程对象服务器的启动极为重要的一个类，包括对象导出的具体逻辑、接受消息的消息分发都与该类有关。  
此处在进行实例化的时候主要作用是将`port`参数封装到`LiveRef`实例对象中，并将该LiveRef实例赋值给`UnicastServerRef`的`ref`成员变量。  
在`LiveRef`对象中则主要是通过`port`参数创建了服务器监听的`Endpoint`对象并实例化了一个`ObjID`用于唯一标识正在创建的远程对象。  
具体的代码就不放了，就是一些new以及赋值操作。  
```java
public static Remote exportObject(Remote obj, int port)
        throws RemoteException
    {
        return exportObject(obj, new UnicastServerRef(port));
    }
```
在重载的`exportObject`方法中，首先会对输入的远程对象进行类型判断，如果其继承了`UnicastRemoteObject`类则将刚才创建的单播服务引用`UnicastServerRef`  
设置到该对象的`ref`成员变量中。 然后会调用`UnicastServerRef`的`exportObject`方法。  
```java
private static Remote exportObject(Remote obj, UnicastServerRef sref)
        throws RemoteException
    {
        // if obj extends UnicastRemoteObject, set its ref.
        if (obj instanceof UnicastRemoteObject) {
            ((UnicastRemoteObject) obj).ref = sref;
        }
        return sref.exportObject(obj, null, false);
    }
```
在`UnicastServerRef`的`exportObject`方法中，会获取到正在创建的远程对象的`Class`对象，然后调用`Util.createProxy`方法创建一个当前正在创建的远程对象的动态代理对象。  
然后判断该代理对象是否是`RemoteStub`的子类，如果是则会为当前正在创建的远程对象创建一个存根。接着将获取到的代理对象封装到`Target`对象中，并继续执行导出动作。  
在进入到后面到导出操作前，这里我们需要重点关注动态代理对象的创建、存根对象的创建、Target对象的创建以及在导出后的方法hash计算的过程。  
```java
public Remote exportObject(Remote var1, Object var2, boolean var3) throws RemoteException {
        Class var4 = var1.getClass();

        Remote var5;
        try {
            var5 = Util.createProxy(var4, this.getClientRef(), this.forceStubUse);
        } catch (IllegalArgumentException var7) {
            throw new ExportException("remote object implements illegal remote interface", var7);
        }

        if (var5 instanceof RemoteStub) {
            this.setSkeleton(var1);
        }

        Target var6 = new Target(var1, this, var5, this.ref.getObjID(), var3);
        this.ref.exportObject(var6);
        this.hashToMethod_Map = (Map)hashToMethod_Maps.get(var4);
        return var5;
    }
```
首先我们关注动态代理对象的创建过程，这里会调用`Util.createProxy`方法，该方接受三个参数，第一个参数为当前正在创建的远程对象的`Class`对象，第二个参数由`getClientRef`方法获取，  
该方法将当前`UnicastServerRef`的`ref`成员变量封装到一个`UnicastRef`对象中，从名字中可以看出如果`UnicastServerRef`表示服务端的引用那么`UnicastRef`则表示客户端的引用，    
第三个参数表示是否强制使用存根，默认为`false`。  
进入到`createProxy`方法中，该方法首先调用`getRemoteClass`方法获取传入参数的所有父类中直接实现了`Remote`的子接口的类，这也是为什么我们前面不直接实现`Remote`接口而是先创建其子接口再实现的原因。  
在调用`getRemoteClass`方法时我们传入的是`BindObject`的`Class`对象，因为`BindObject`实现了`Remote`的子接口，所以这里会直接返回`BindObject`的`Class`对象。  
紧接着会遇到一个判断结构，这里重点关注`stubClassExists`方法的运行结构，因为`ignoreStubClasses`默认为`false`，根据运算符的优先级`and`会优先于`or`执行，所以这里的判断结果取决于`stubClassExists`的运算结果。  
`stubClassExists`方法会判断传入的`var3`的类名拼接`_Stub`作为新的类名的类是否存在，若存在则返回`true`，若不存在则返回`false`。  
此处我们传入的是自定义的类，很明显其存根类是不存在的，所以这里会返回`false`，代码也会进入到`else`的逻辑中。那么当`var3`为什么时会进入到`if`紧跟着的代码块中呢。  
当`var3`表示`RegistryImpl`的`Class`对象时会出现这样的情况，这将发生在注册中心的创建过程中，我们后面会介绍到的。
在`else`紧跟着的代码块中，我们创建了`UnicastRef`对象的动态代理对象，使用的`invocationHandler`为 `RemoteObjectInvocationHandler`，这一点是极为重要的，  
因为在动态代理对象执行过程中`invocationHandler`的`invoke`方法会影响原本对象方法执行的行为，请记住这一点。  
```java
public static Remote createProxy(Class<?> var0, RemoteRef var1, boolean var2) throws StubNotFoundException {
        Class var3;
        try {
            var3 = getRemoteClass(var0);
        } catch (ClassNotFoundException var9) {
            throw new StubNotFoundException("object does not implement a remote interface: " + var0.getName());
        }

        if (var2 || !ignoreStubClasses && stubClassExists(var3)) {
            return createStub(var3, var1);
        } else {
            final ClassLoader var4 = var0.getClassLoader();
            final Class[] var5 = getRemoteInterfaces(var0);
            final RemoteObjectInvocationHandler var6 = new RemoteObjectInvocationHandler(var1);

            try {
                return (Remote)AccessController.doPrivileged(new PrivilegedAction<Remote>() {
                    public Remote run() {
                        return (Remote)Proxy.newProxyInstance(var4, var5, var6);
                    }
                });
            } catch (IllegalArgumentException var8) {
                throw new StubNotFoundException("unable to create proxy", var8);
            }
        }
    }
```
对于用户创建的用户注册的远程对象来说，调用`createProxy`方法后获得的是一个`UnicastRef`的动态代理对象，该对象封装了一个`LiveRef`对象，  
而这个`LiveRef`对象中又封装了一个`ObjID`对象，这个`ObjID`正是当前创建远程对象的唯一标识符，在后面的操作中调用客户端需要以来这个`ObjID`来从导出表中查找对应的远程对象。  
`setSkeleton`方法的调用需要特殊的时机，即`createProxy`创建的存根对象实现了`RemoteStub`类，很明显我们自行创建的远程对象的存根对象是没有实现这个类的，那么也只有前面提到的`RegistryImpl_Stub`对象会实现这个类了。  
在`setSkeleton`方法中，其会创建`RegistryImpl`的骨架，即创建`RegistryImpl_Skel`对象并存储到`UnicastServerRef`的`skeleton`成员变量中。  
```java
public void setSkeleton(Remote var1) throws RemoteException {
    if (!withoutSkeletons.containsKey(var1.getClass())) {
        try {
            this.skel = Util.createSkeleton(var1);
        } catch (SkeletonNotFoundException var3) {
            withoutSkeletons.put(var1.getClass(), (Object)null);
        }
    }

}
static Skeleton createSkeleton(Remote var0) throws SkeletonNotFoundException {
        Class var1;
        try {
            var1 = getRemoteClass(var0.getClass());
        } catch (ClassNotFoundException var8) {
            throw new SkeletonNotFoundException("object does not implement a remote interface: " + var0.getClass().getName());
        }

        String var2 = var1.getName() + "_Skel";

        try {
            Class var3 = Class.forName(var2, false, var1.getClassLoader());
            return (Skeleton)var3.newInstance();
        } catch (ClassNotFoundException var4) {
            throw new SkeletonNotFoundException("Skeleton class not found: " + var2, var4);
        } catch (InstantiationException var5) {
            throw new SkeletonNotFoundException("Can't create skeleton: " + var2, var5);
        } catch (IllegalAccessException var6) {
            throw new SkeletonNotFoundException("No public constructor: " + var2, var6);
        } catch (ClassCastException var7) {
            throw new SkeletonNotFoundException("Skeleton not of correct class: " + var2, var7);
        }
    }

```
`BindObject`对象即是我们长在创建的远程对象，后面不在使用`正在创建的远程对象`这个说法而直接使用`BindObject`对象代替。  
在进行`Target`对象的封装时，首先会创建`BindObject`对象的弱引用, 创建时传入的第二个参数是一个队列，当`BindObject`对象被`GC`回收时,会将弱引用对象加入到这个队列中，  
通过对这个队列的监听可以定制某个对象被回收时的行为，这是与`DGC`有关的内容了这里不进行详述，后面会再开一篇专门介绍`RMI`中的`DGC`。  
传入的第二个参数为`UnicastServerRef`对象本身，其此时作为消息的分发器被传递，后面当服务器接受到客户端的消息时将由该对象对消息进行分发与处理。  
传入的第三个参数作为`BindObject`对象的存根，其本身是一个`UnicastRef`的动态代理对象。  
传入的第四个参数是`ObjID`对象，其表示远程对象的唯一标识符。  
传入的第五个参数表示远程对象是否是持久的，如果为`true`则表示远程对象是持久的，否则表示远程对象是临时的。我们自行创建的远程对象该参数均为`false`，即不是持久的对象。  
其作为弱引用被`Target`对象引用，当没有其他对象引用时将被`GC`回收掉，而持久存在的对象则只有系统创建的`RegistryImpl`以及`DGCImpl`对象。  
`pinImpl`方法就是用来进行对象持久化的方法，其本质就是创建了一个使用`=`号的赋值操作来对远程对象进行引用，只要`Target`对象不被回收，该远程对象将一直存在。  
```java
public Target(Remote var1, Dispatcher var2, Remote var3, ObjID var4, boolean var5) {
        this.weakImpl = new WeakRef(var1, ObjectTable.reapQueue);
        this.disp = var2;
        this.stub = var3;
        this.id = var4;
        this.acc = AccessController.getContext();
        ClassLoader var6 = Thread.currentThread().getContextClassLoader();
        ClassLoader var7 = var1.getClass().getClassLoader();
        if (checkLoaderAncestry(var6, var7)) {
            this.ccl = var6;
        } else {
            this.ccl = var7;
        }

        this.permanent = var5;
        if (var5) {
            this.pinImpl();
        }

    }

```
尾巴处理完了，我们接着看对象的导出操作是什么样的。  
`ep`以及`transport`都是再`LiveRef`实例化过程中创建的对象，需要了解的可以倒回去看看。  
```java
public void exportObject(Target var1) throws RemoteException {
        this.ep.exportObject(var1);
    }

public void exportObject(Target var1) throws RemoteException {
    this.transport.exportObject(var1);
}


```
下面就是最为核心的对象导出方法了，该方法包含重要的两个步骤，其一是完成`serverSocket`服务的建立，其二是进行真正的对象导出。  
```java
public void exportObject(Target var1) throws RemoteException {
        synchronized(this) {
            this.listen();
            ++this.exportCount;
        }

        boolean var2 = false;
        boolean var12 = false;

        try {
            var12 = true;
            super.exportObject(var1);
            var2 = true;
            var12 = false;
        } finally {
            if (var12) {
                if (!var2) {
                    synchronized(this) {
                        this.decrementExportCount();
                    }
                }

            }
        }

        if (!var2) {
            synchronized(this) {
                this.decrementExportCount();
            }
        }

    }
```
首先关注`serverSocket`的建立。  



# 注册中心是如何启动的
# 客户端获取注册中心存根
# 客户端查询远程对象
# 客户端调用远程对象方法
# DGC
# 