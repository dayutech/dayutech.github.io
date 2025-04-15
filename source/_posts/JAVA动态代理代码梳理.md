---
title: JAVA动态代理代码梳理
tags:
  - 动态代理
  - Java
  - 代码审计
categories:
  - - 代码审计
  - - Java
abbrlink: d38cd4a6
date: 2025-04-14 10:33:52
---

当我们要为我们的代码附加别的功能的时候，我们往往写一个代理类来实现对当前类的封装，该代理类不实现具体的代码逻辑，只是提供了额外的功能，但如果我有很多的类需要封装一样的功能，那么我就得写很多的代理类，这种方式耗时严重且不易维护，是极为不可取的。所以JAVA为我们提供了动态代理的方式来一劳永逸，貌似大名鼎鼎的AOP就是通过动态代理的方式实现的，那我们来写一个动态代理的例子。
<!--more-->
首先我们需要一个接口，作为被代理类的接口
```java
package com.armandhe.dynamicproxy;

public interface ProxyInterface {
    public void printName();
}

```

然后定义一个实现类
```java
package com.armandhe.dynamicproxy;

public class ProxyInterfaceImpl implements ProxyInterface{
    @Override
    public void printName() {
        System.out.println("my name is armandhe");
    }
}

```

然后定义我们的InnovcationHandler实例，这里我把调用类写在一起了
```java
package com.armandhe.dynamicproxy;

import java.io.Serializable;
import java.lang.reflect.InvocationHandler;
import java.lang.reflect.Method;
import java.lang.reflect.Proxy;

public class DynamicProxyTest {
    public static void main(String[] args) {
        ProxyInterfaceImpl proxyInterface = new ProxyInterfaceImpl();
        ClassLoader classLoader = ProxyInterface.class.getClassLoader();
        ProxyInterface proxyInstance = (ProxyInterface) Proxy.newProxyInstance(classLoader, new Class[]{ProxyInterface.class}, new DynamicProxyHandler(proxyInterface));
        proxyInstance.printName();

    }
}

class DynamicProxyHandler implements InvocationHandler, Serializable {
    private final Object proxyedClass;
    public DynamicProxyHandler(Object proxyedClass) {
        this.proxyedClass =proxyedClass;
    }

    @Override
    public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
        System.out.println("添加的前置内容");
        Object invoke = method.invoke(proxyedClass, args);
        System.out.println("添加的前置内容");
        return invoke;
    }
}

```

这里注意到我们定义的处理器必须实现InvocationHandler, Serializable两个接口，一个是处理器，一个是反序列化标识，然后我们还得重写其invoke方法。

现在万事俱备只欠东风，我们直接打断点开始调试
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/1c72682141efd09ea30c0cc201201a5a.png)
在java.lang.reflect.Proxy#newProxyInstance方法中首先通过java.lang.reflect.Proxy#getProxyClass0方法获取一个Proxy 的Class实例，然后传入一个Innovacation的Class实例对象获取到对应的构造方法，最后利用反射调用获取到一个我们被代理类的Proxy类实例。
所以我们代理类的所有生成逻辑都在getProxyClass0这个方法中
该方法首先会从proxyClassCache缓存中检查被代理类的代理类实例是否已经生成了，如果生成则直接返回该实例，否则会调用subKeyFactory.apply方法获取subkey(干啥的没看懂)，然后生成一个Factory（只有一些赋值操作），然后判断supplier是否为空，如果为空则继续循环，并为其赋值为factory，这时候其就不为空了然后会调用到supplier.get()方法
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/5511f43bd8c13aadcfc270ddea84d371.png)
这里首先还是检查subkey是否有缓存，这时候很明显是有的且返回一个supplier对象，上面提到了会将Factory赋值为supplier，所以第一个判断假，直接到断点处，会调用valueFactory.apply，valueFactory为一个ProxyClassFactory对象。
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/e61a4eddece2289449391e21268b45aa.png)
这里直接获取了当前接口的Class实例
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/687766e458077b567aa3400cb1839c39.png)
这里设置了生成的代理类的包名
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/90fcd9add1996c0b47973552b627d1a4.png)
这里设置类代理类的全类名，可以观察导生成的代理类类名已$Proxy加一个数字开头，数字是递增的以我们传入的接口数为准
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/3b46db8cb6bfd2dbb37bf90036a80fcd.png)
然后会调用sun.misc.ProxyGenerator#generateProxyClass(java.lang.String, java.lang.Class<?>[], int)生成代理类的字节码文件，这里面全是直接操作字节码，实在牛皮，然后调用java.lang.reflect.Proxy#defineClass0链接类完成类加载，defineClass0是一个本地方法，熟悉java类架子应该知道，在默认的类加载器中也是使用的该方法链接类。
![在这里插入图片描述](https://img-blog.csdnimg.cn/18f2ec10dc1b4cebb1b6e4f756b015e0.png)
sun.misc.ProxyGenerator#generateProxyClass(java.lang.String, java.lang.Class<?>[], int)首先在加载过程中就完成了代理类的生成，这很明显是一个饿汉式的单例模式。调用构造方法就进行了一些赋值操作。
然后调用sun.misc.ProxyGenerator#generateClassFile方法最终实现类加载，然后会saveGeneratedFiles是否保存生成的代理类文件，这个值通过设置系统属性`sun.misc.ProxyGenerator.saveGeneratedFiles`设置

![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/86685f77e38e00e4beaa67adc6cd26a4.png)


![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/1ec4f936c87115d5652fdcaeaafc6c13.png)
从上到下一次完成将hashcode equals toString方法添加到proxyMethods中，将代理方法添加到sigmethods中
将被代理类方法加入到proxyMethods中
校验方法返回值类型
添加构造方法
然后就是一波操作字节码的逆天操作。。。








