---
title: tomcat架构学习
date: 2025-04-14 10:33:52
tags:
- tomcat
categories:
  - [Tomcat]
description: 本文介绍了Tomcat的架构
---
tomcat重要的概念有Server Service Connector Container Engine Host Context Wrapper
|组件|说明|
|---|--|
|Server|一个Tomcat服务器中只能有一个Server|
|Service|一个Server下可以有多个Service|
|Connector|一个Service可以有多个Connector，不同的Connector实现了不同的协议，如HTTP与AJP，这两个协议是Tomcat中模式实现的协议。Connector还负责Socket的建立，使用ProtocolHandler处理字节数据，封装request与response对象，然后使用Adaptor将Request与Response封装成HTTPRequest与HTTPResponse对象。协议处理器包含了对各类IO框架的支持，常用的为Nio(异步不阻塞) Apr Bio(Jio，阻塞)|
|Contaier|一个Service可以包含多个容器，容器是Engin,Host，Context,Wrpper顶层封装，也就是说这四个是Container的子容器，在代码层面他们都继承了Container类|
|Engine|Tomcat默认实现的引擎为Catalina，当然你也可以实现自己的引擎|
|Host|Host就是字面意思，表示不同的主机，也就是在HTTP/1.1中的host头指定的内容，Tomcat根据该标头将请求发送给不同的StandardHost容器处理|
|Context|一个Context就是一个应用，在Tomcat的模式Host中也就是模式的webapps目录下，一个目录就是一个应用|
|Wrapper|Wapper是对Servlet的封装，一个Servlet就是一个Wapper|

四个子容器在调用的时候使用的是责任链模式，每个容器通过Pipline管道串联起来，每个Pipline中包含了一系列的Valve(阀门)，Tomcat模式每个容器实现了一个标准的Valve，分别为StandardEnginValve,StandardHostValve,StandardContextValve,StandardWrapperValve，这四个管道在每个容器中放在各自的顶层被最后一个调用，负责串联下一个容器的,这四个管道中的invoke方法负责调用下一个容器的的第一个Valve
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/2291dbc663b4f22e4a333b392386cc27.png)
就这样四个容器被串联起来，最后的StandardWrapperValve负责将请求与响应传递到FilterChain，执行一系列过滤器。
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/3d80cb5154af0061144ce94d257a2918.png)
我们也可以在Tomcat的server.xml文件中在各个容器下自定义一系列的Valve来回请求进行拦截过滤。请求在经过一系列过滤器后由最后一个过滤器调用servlet的service方法
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/512b8451cd7715f905b2a8465b18e0ec.png)
最终service方法根据请求的方式调用对应的doGet、doPost等方法，完成整个流程的闭环。

Tomcat整个设计使用了JMX（Java Manager Extension）来实现对整个应用的监控，于是可以使用JConsole进行监控，要实现一个JMX应用需要实现一个一个的MBean，作为被监控的对象，然后提供一个MBeanServer 来对所有的Mbean进行监控。

Tomcat在每个流程的实现中还大量使用了观察者模式来进行生命周期管理
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/a3be82bb692e8b498f9b2b311e2f9ef3.png)
观察者模式一般需要三类对象，分别是Subject OBClient  OBServer。Subject负责注册一个个观察者，与通知所有观察者，OBserver为一个个的观察者，一般需要定义一个接口，然后根据需要实现一个个观察者对象，OBclient为被观察对象，当被观察对象的状态发生变化的时候会通知Subject，由其通知所有的观察者做对应的操作。在Tomcat中LifeCycle作为接口由抽象类LifeCycleBase部分实现，凡是继承了LifeCycleBase类的子类都作为一个个观察者，其提供了addLifecycleListener方法注册一个个监听器，也就是一系列的观察者，当被观察者状态（启动过程的推进、init\load\start等）发生变化时由LifeCycleBase#fireLifecycleEvent方法调用各个监听器的lifecycleEvent方法发送通知给所有的观察者。
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/4d89df83b388792b2f8dee1374eb0e8a.png)
下回分解，Tomcat启动流程。。。。。








