---
title: Spring Kafka 消息头反序列化漏洞（CVE-2023-34040）
date: 2025-04-10 17:56:11
tags:
- Spring Kafka
- CVE-2023-34040
- RCE
- 反序列化
- 网络安全
- 漏洞分析
- 漏洞
categories:
- 安全技术
- 漏洞分析
---

不知道你在挖洞过程中是否碰到过这样一个问题，资源下载到了，调试环境也搞定了却迟迟找不到合适的地方下断点进行调试，这时候你会选择怎么办？是去寻找启动类一行一行代码查看直到找到URI的处理函数，还是快准狠地定位到关键点马上出洞？我想不会有人想要选择第一种方法，但按照第一种方法不断地熟悉不同的框架的过程却是一个挖洞小白向大佬进化的过程，我们往往需要在这个过程中不断地积累足够的经验来熟悉常见的技术与框架，这几乎是每一个大佬成长路上必须要走的路。毫无疑问，这种曲折的过程最能增长人们的能力，不过这个过程往往是痛苦且枯燥的，在挖洞过程中，时间紧任务重的情况下，我们往往在这个过程中浪费了大量的时间与精力，所以我给大家简单总结了一下我们应该如何去找到一些常见框架进行资源处理与存放、配置存放与解析规则的方法。

jetty
与tomcat一样，jetty也是一个jsp与servlet的容器，不过相比tomcat，其功能更加精简，整个程序的构建逻辑也与tomcat也有较大的差异，不过既然是servlet容器那么其将遵循与tomcat一样的servlet规范，如配置在web.xml中的servlet-mapping与filter-mapping等。对于漏洞挖掘来讲，其并没有太过独特的地方，我们重点关注的也就是web.xml中的配置信息，然后找到对应的请求处理方法进行审计即可。

struts2
在spring mvc火起来前，struts就是比较流行的MVC框架了，与spring mvc类似，struts也是采用类似前端控制器的方式来进行请求的分发，不过struts2是通过filter(StrutsPrepareAndExecuteFilter)的方式进行分发，而spring是通过servlet，两者没有本质的区别。

struts2的请求处理方法与spring中的controller不同，在struts中其被称为Action，每个Action负责一个请求的处理，这些Action类默认使用execute方法进行请求处理，不过也可以在配置文件中通过通过action标签属性method进行指定。

struts2的配置文件名为struts.xml，在实践中struts往往作为一个入口，具体的Action配置注册通过include的方式在其他配置文件中实现，一般相似功能的action注册在一个文件中，如与登录相关的action可以放在一个文件中再将该文件包含到struts.xml中。

struts2 action是被package管理的，每个package标签下往往有多个action标签，每个action标签可以处理一个或多个请求，具体通过对标签属性name使用通配符的方式进行，标签属性class指定action的处理类。action标签下的子标签result能够根据请求处理方法返回的字符串加载不同的资源进行视图渲染来进行响应。

如：

<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE struts PUBLIC
"-//Apache Software Foundation//DTD Struts Configuration 2.3//EN"
"http://struts.apache.org/dtds/struts-2.3.dtd">
<struts>
<package name="login" extends="struts-default" namespace="/">
<action name="*loginAction" class="com.example.www.LoginAction" method="{1}">
            <result name="success">/index.jsp</result>
</action>
</package>
</struts>
上例注册的action将会匹配所有以loginAction结尾的请求，并将请求交到LoginAction类进行处理，调用的方法是被name属性通配符匹配到的字符串同名的方法。方法调用成功后返回success将加载index.jsp渲染响应给客户端。

spring boot
spring boot可能实在没有什么值得多说的，因为大家都太熟了，一个严格遵循MVC规范开发的程序，挖洞的标准步骤可能就是先在web.xml中查看配置看看filter有哪些 servlet有哪些，然后去瞅瞅对应的servlet与filter的功能，能挖到洞就皆大欢喜，挖不倒就拉倒。可能这个流程太过标准我们往往忽视了一些其他的细节。使用spring boot单独打包的程序可能这些配置的位置很好找，但一个大型应用动辄就是几百个jar包，这些不同的功能可能被拆开打包到不同的jar包，这时候是不是就抓瞎了？难道要一个一个地去点开看？当然没必要。

首先，我们还是程序性得确定一下spring boot打包的jar包的结构，其与其他标准jar包略有差异，除了标准的meta-inf文件夹存放一些元信息以外，还多了一个boot-inf的文件夹，这个boot-inf文件夹下的内容才是我们真正的启动类，在meta-inf文件夹下有个MANIFEST.MF文件，我们在这个文件中找到两个属性Main-Class 与 Start-Class，其中Main-Class指定的就是spring boot的启动类，而Start-Class指定的就是我们编写的启动类。

言归正传，我们重点是在庞杂的jar包中找到真正存放请求处理类的jar包，那么如何快速定位呢？我们知道Spring Web是通过前端控制器DispatcherServlet来进行请求的分发的，在DispatcherServlet中方法doDispatch负责具体的分发逻辑，其中DispatcherServlet this对象的handlerMappings 属性存放的就是所有的注册的所有请求的处理对象，当用户请求到来时将从这个map中取得对应的handlerMapping调用对应的方法对请求进行处理，故我们只需要遍历handlerMappings就可以找到controlle所在的位置了。具体的操作可能不太方便描述，我们只需要逐级展开该对象获取器属性，然后找到带controller字样的属性然后鼠标右键选择jump to type source就可以跳转到类型的定义为止。当然我讲的这些都是在调试环境下进行的。

图片


axis2
国内可能过分追求spring生态相关的东西，而对其它的技术运用不是特别广泛。我觉得axis2就算是一个，在国外的应用中你经常就能看到他们的身影，而在国内却很少见，国内java程序员的传统艺能就是spring framework    spring mvc spring boot   spring cloud spring security 等。

axis2是apache开源的一个流行的webservice引擎，其可以方便地将java类发布为service，用户可以很容易地通过http请求调用到java类中定义的方法。

axis2通过soap协议来进行数据传输，发布一个service只需要编写一个java类，然后使用工具生成一个wsdl文件即可，一般在黑盒情况下要了解service可供使用的方法，只需要在需要访问的service路径后加上参数?wsdl即可，当然这需要你能够读懂wsdl文件并且能够根据其构造出来对应的soap请求。

嵌入式的axis2安装也是通过在web.xml中注册servlet实现的，寻找相关关键字就可以了，不过也没什么必要这里注册的内容只是告诉容器去解析axis而已，具体与服务相关的东西还是要能够精准定位到porttype类与具体的opration才行，当然我们可以以web.xml中注册的servlet为突破口，找到对应的类打断点逐步调试也能找到对应的service类，不过这需要你有足够的经验，能够根据方法名猜到其大致的功能以避免不必要的弯路。

grpc
rpc与restful一样都是一套与信息交换有关的规范，用户往往接触到的是restful风格的api，而隐藏在restful后台与微服务，过程调用等相关的规范则往往是rpc。grpc是google的一套rpc规范，其采用http/2的方式进行信息交换，众所周知相比于http/1.x http/2采用字节流的方式发送数据，融合了多路复用、头部压缩等多种新兴技术具备更快的速度与可靠性。

要实现一个grpc服务，首先我们需要按照protobuf的格式定义的IDL，即一个.proto后缀的文件，然后根据该文件使用工具编译生成与客户端请求处理相关的stub类，以及与服务端方法定义相关的ImplBase类。我们通过实现ImplBase类通过覆写其方法类实现我们自己对外暴露的方法逻辑，然后客户端通过调用stub类同名方法来实现远程方法调用。

当grpc与spring boot结合的时候对我们挖洞人来说往往是不友好的，spring通过注解进行自动装配的思想对于开发人员来说可能很方便，但对审计人员来说可真是难受，特别是分开打包+很多jar的情况。