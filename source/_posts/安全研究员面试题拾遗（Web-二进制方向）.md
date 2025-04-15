---
title: 安全研究员面试题拾遗（Web + 二进制方向）
tags:
  - 面试题
  - 安全研究
  - Web
  - 二进制
categories:
  - - 面试题
description: 本文总结了一些常见的Java安全研究员面试题目
abbrlink: e1ac77d
date: 2025-04-14 10:33:52
---
# Web方向
|题目|回答|
|--|---|
|JAVA内存马|Servlet-api  Valve   重点是获取StandardContext对象，然后根据servlet规范调用指定的方法动态注册对应的项目               Spring Controller Interpretor|
|Weblogic反序列化| T3协议 7001端口 握手包会返回版本信息 正式的协议开头是数据长度，让后是一些其他信息，然后就是一系列的反序列化数据，aced开头的，然后我们需要替换其中一部分或者在中间插入一部分就可完成反序列化|
|JAVA反序列化| 静态代码块 实例代码块 构造方法|
|FastJSON反序列化|反序列化过程中setter会被自动调用，而在parseObject方发生getter方法也会被调用，fastjson又提供了autoType功能用以指定要发序列化的具体类，从而导致了漏洞的发生，典型的利用链为 JdbcRowImpl TemplateImpl，最新的1.2.80绕过，利用的是expactClass=Thrownable.class，找到Thrownable的子类就可以完美染过autotypeSupport判断，我们还可以通过AutoCloseable类完成绕过，该类本身在白名单中，在反序列化过程中会在getSeeAll方法是执行失败，从而继续扫描然后会将第二个@type的类作为目标类，如果这个类继承了AutoCloseable类，那么就可以绕过自动类型开启的判断，那么问题就是找到一个内置的实现了该类的子类且有危险的方法被执行|
|Log4J2漏洞原理|递归解析用来绕WAF log4j2默认开启了lookup支持，那么就会调用MessagePatternConverter去解析从配置文件、options、message中传入的参数，如果遇到了${就会去找}如果找到了就会将中间的内容通过StrSubstitutor进行解析，在解析时会通过冒号分割这部分内容，通过冒号前面的内容映射对应的处理逻辑，这部分其实是通过org.apache.logging.log4j.core.lookup.Interpolator作为代理类通过传入不同的参数调用不同的方法来实现不同的处理逻辑，而JNID恰巧就被提供了支持，也就导致了漏洞的发生|
|Spring Bean RCE漏洞原理|参数映射，主要在进行参数映射的时候会调用的对应的setter方法为进行参数绑定，而在JAVA的Objects方法中存在一个特殊的getClass方法用来获取当前类的Class实例，那么我们就可以通国传入Class=xxx的方式为Class实例赋值，而通过Class实例又可以获得类加载器ClassLoader，在类加载器中又有一个URLS属性所以就有了Class.Classloader.URLs[0]，这是老的版本的漏洞成因，最新的绕过是在JDK9中Class中提供了Module属性可以用来获取到类加载器从而导致了漏洞的发生
|JAVA assait与ASM的区别|ClassPool  ClassVisitor ClassReader ClassWriter|
|JAVA Agent| premain agentman Instrumentation ClassFileTransformer|
|JAVA动态代理|getProxyClass0---valueFactory.apply--generateClassFile---defineClass0|
|JAVA XXE漏洞|XMLReader等|
|JNDI注入原理|lookup参数可控，云云，可以详细分析过程|
|高版本JDK如何进行JNDI注入|Tomcat BeanFactory，codebase|
|JEP290了解吗|类黑名单 内置、自定义安全策略|
|讲讲Hadoop|hdfs MapReduce HBase namenode datanode client ResourceManager|
|go会吗|会，可以写一般的项目|
|Shiro反序列化|AES秘钥硬编码， CBC填充提示攻击|
|Shiro设计模式|单例模式SecurityManager 简单工厂模式|
|Shiro未授权访问|有一个未授权的拦截器，path中对;处理不当导致截断，结合spring boot的url处理缺陷导致漏洞，还有一个ant风格导致的未授权|
|有没有在原有漏洞基础上延伸|完成了fastjson最新rce漏洞的分析|
|如何防御JAVA反序列化|重写类加载器、重写readObject方法。。。JEP290|
|内网不出网|不讲工具，将原理，无非是监听、反连、正连|
|Ms068原理|忘求了，也是kerburnets协议的漏洞|
|了解哪些JAVA框架|Spring Spring Boot spring mvc shiro struts2 云云|
|讲讲Spring|IOC 与AOP，DI 构造方法注入与setter注入，AOP，动态代理，横切关注点、切面、领域等概念|
|了解哪些PHP框架|tp|
|最近跟过哪些漏洞|fastjson vmware workspace    spring security manager|
|JAVA类型机制|瞎几把问，根本就没这玩意儿，你是要问类加载机制还是强弱类型？我看自己都没搞清楚|
|如何做源码审计|工具扫、第三方依赖、过滤器、拦截器、找对应类型漏洞的关键字，跟踪调用链|
|任意文件上传漏洞怎么找|找关键字mutipart FileInputStream FIle nio类型的Writers与Readers等|
|过滤器与拦截器的区别|以前端调度器为转折点，在其前面被称为过滤器，过滤器是servlet的概念，在tomcat中依附在pipeline上，拦截器是spring中的概念，其在前端控制器之后请求正式到达servlet的前后被执行|
|挖过哪些大的开源软件的漏洞|没挖过|
|如何提高log4j2 shell漏洞的检测效率|多线程 高并发 多次请求一次验证等|
|如何提高log4j2漏洞验证PoC的准确性|你猜|
|xlst注入||
|有一个java站点的webshell，翻遍了所有配置文件都没有翻到数据库连接信息，问这些信息可能在哪里|环境变量或者内存中或者其他的数据库里|
|spring booot站点暴露了一些endpoint，如env文件泄漏，但是用户名密码是*** 如何获取明文|heepdump  利用一些其他的依赖|
|.net序列化|不会|
|反序列化攻击不成功的原因|jdk版本不允许，配置了jep290策略，内网不出网，serializationuid不匹配|
|jndi高版本如何绕过|反序列化的本质需要我们要反序列化的类在目标本地存在，若有一个类是业务系统必须使用的类，那么该类就不可能出现在黑名单中，自然就可以被用来进行反序列化利用，如tomcat中的 BeanFactory类|
|rasp如何绕过|另起一个新的进程 使用jni hook掉rasp hook sink点的函数|
|fastjson如何绕过|unicode  hex  短划线空格等|
|如何挖掘未授权漏洞|白盒与黑盒|
|有webshell 可以执行任意java代码，如何查看web项目绝对路径|直接执行命令netstat 查看pid  lsof查看关联文件  直接翻配置文件  查看classpath|

# 二进制方向【Learning】
|题目|回答|
|--|--|
|SEH是什么||
|讲讲DEP||
|Canary原理、绕过等||
|堆溢出漏洞原理||
|栈溢出漏洞原理||
|挖掘过哪些商业产品漏洞||
|用过哪些调试器||
|fast bin  small bin  large bin unsorted bin异同，chunk什么时候进入unsorted bin||
|ROP、SROP||
|calloc 与malloc的异同||
|Windows有哪些组件||
|多进程如何保护数据|锁....|
|CPU调度算法|时间片轮训、优先级、先到先服务、最短时间优先等算法|
|三种函数调用约定的异同||

