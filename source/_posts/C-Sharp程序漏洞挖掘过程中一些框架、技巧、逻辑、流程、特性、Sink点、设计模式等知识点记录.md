---
title: C Sharp程序漏洞挖掘过程中一些框架、技巧、逻辑、流程、特性、Sink点、设计模式等知识点记录
tags:
  - C#
  - tips
  - 漏洞挖掘
categories:
  - - 漏洞挖掘
top: 260
abbrlink: 324e0c68
date: 2025-09-11 11:00:14
description: 本文收集C# 漏洞挖掘过程中使用的一些知识点
---

# C# 顶级语句
## ✅ 基本用法

**传统写法（C# 8 及以前）：**

```csharp
using System;

namespace MyApp
{
    class Program
    {
        static void Main(string[] args)
        {
            Console.WriteLine("Hello, World!");
        }
    }
}
```

**C# 9+ 顶级语句写法：**

```csharp
Console.WriteLine("Hello, World!");
```

编译器自动生成：

- 命名空间（隐式）
- `Program` 类
- `static void Main(string[] args)` 方法
- 方法名为 `<Main>$`（可通过反射看到）

# ASP .net MVC 结构识别
找路由 搜索  APIControllerAttribute   ControllerAccribute  RouteAttribute 三个属性
判断路由是否需要认证查看是否被 Authorize 修饰  若被修饰则需要认证 若没有修饰 则不需要认证 该属性可被用户类与方法上，方法上的优先级更高 
AllowAnonymous 可以覆盖掉 Authorize的效果让方法绕过认证 比如类上使用了 Authorize 方法上使用了 AllowAnonymous 那么 该方法可以被匿名访问

# 授权逻辑
如果需要自定义授权处理器一般在 Main 方法中被定义  结构类似 
```c#
builder.AddScheme<AuthenticationSchemeOptions, TestAuthenticationHandler>("TestAuth", null, null);
``` 
TestAuthenticationHandler 就是认证处理器  负责从请求中提取认证信息用于验证用户是否经过认证以及进行权限检查等。  


# MeditorR
一种中介者模式 用一个中介对象包装一组对象  是的各个对象之间不需要显式地相互引用，从而降低耦合性
请求对象实现 IRequest 接口
处理器对象实现  IRequestHandler  接口
通过请求对象 搜索对应地处理器对象查找对应地处理器类
除了请求与响应模型 也就是 IRequest/IRequestHandler 之外
还有 通知与事件  Notification/Event
行为管道  Pipeline/Behavior

# 强制类型转换的绕过？
如下面这样的代码
```c#
MethodInfo methodInfo = callMethod.GetMethodInfoSafe();
object[] paramValues = callMethod.GetParamValues();
MarshalByRefObjectBase obj = (MarshalByRefObjectBase)callMethod.Object;
RenewObjectOnCall(obj);
object obj2 = methodInfo.Invoke(obj, paramValues);
```
可以让 Invoke 方法实现任意类的方法调用吗？
一种思路是使用代理类创建一个 MarshalByRefObjectBase 子类对象的代理对象，这个代理对象使用了一个特殊的 Interpretor
这个 Interpretor 可以使用自己持有的对象调用特定的方法
所以问题回到了是不是存在这样一个特殊的 Interpretor。
# NTLM认证过程
首先协商协议版本
服务端选择对应的协议版本并生成一个chanllenge
客户端收到challenge后 使用提供的用户密码生成NTLM HASH 然后对使用NTLM HASH 该challenge进行hash运算得到 Response 然后将用户名 Response等发送给服务端
服务端通过用户名查找得到正确的NTLM HASH 然后 对自己持有的Challenge进行hash运算与客户端传入的进行比较，如果一致则认证成功。  

在实践中，可能还会存在更多的步骤，这个步骤是开发这自定义的过程，可以加入一些自定义的流程。
# Web程序调试
使用dnspy调试  attach的进程名为w3wp.exe 这是一个32位的程序 ，所以需要使用32位的dnspy调试。
# 反编译
有些情况下ilspy要比dnspy反编译效果更好，如果遇到dnspy反编译不出来请尝试使用ilspy

# 委托
委托看着很糟心 不过将它理解为方法指针的话也就没那么糟心了
定义委托
```c#
访问修饰符  声明这是一个委托     返回值类型   委托名 局部变量总得有个名字去标识对吧   形参
public     delegate              int          Calculator                              (int x, int y);
```
一个方法要你能够被指定得委托引用  那么必须保证其 返回值以及形参个数与类型一致。
创建委托
```c#
委托类型    变量名     new一个委托  方法名
Calculator calc = new Calculator(Add); // 或直接 calc = Add;
``` 
委托的调用和方法的调用一样。
c# 中不能直接将方法作为参数传入到函数中，需要借助委托进行  这就没有Python或者Java方便了。
# 入口
Web应用指定依赖就找 Program 或者StartUp啊 
# Kestrel部署模式
Kestrel 是 ASP.NET Core 的默认跨平台、高性能、轻量级 Web 服务器，用 C# 编写，基于 .NET 的底层 Socket 实现。
在 ASP.NET Core 应用部署中，Kestrel 通常不直接面向公网，而是放在 IIS、Nginx 或 Apache 等“反向代理”服务器之后。这是微软官方推荐的生产部署架构：
有些项目使用这种部署模式  在web.conf中可以见到这样的配置
```c#
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <location path="." inheritInChildApplications="false">
    <system.webServer>
      <handlers>
        <add name="aspNetCore" path="*" verb="*" modules="AspNetCoreModuleV2" resourceType="Unspecified" />
      </handlers>
      <aspNetCore 
          processPath="dotnet" 
          arguments=".\YourApp.dll" 
          stdoutLogEnabled="false" 
          stdoutLogFile=".\logs\stdout" 
          hostingModel="inprocess" />
    </system.webServer>
  </location>
</configuration>
```
processPath 属性指定的就是启动程序 可以是默认的.net  也可以是用户自定义的一个程序  
一般在生产模式 使用第二种方式，这个程序是系统自动生成的表示独立部署模式，在发布应用时可通过配置进行选择，所有的.net RUNTIME都被打包到应用中  不需要额外安装.net Runtime 
这样部署生成的web代码位于另外的dll文件中 不在这个exe文件中一般通过存在的配置文件找到对应的主dll文件 如 配置文件名为 a.b.c.dll.config  那么就去找这个a.b.c.dll 反编译后直接找 Program 这个类

hostingModel 标识驻守模式  inprocess 表示在w3wp.exe 内部运行 拥有更高的性能

# .Net Core 启动
发布一个 .NET Core / .NET 5+ 应用为 “独立部署”（self-contained）或 “框架依赖 + 可执行文件” 时，.NET SDK 会生成一个名为 YourApp.exe 的文件，这个 .exe 实际上是微软提供的 通用启动器（apphost），其作用是：
- 初始化 .NET 运行时（CoreCLR）
- 加载你的 YourApp.dll
- 调用 Main 方法
>  所有 .NET 应用的 .exe 启动器代码都几乎一样，因为它只是个“壳”。

# 扩展方法
扩展方法在web应用启动的时候常可以看到，往往被用来做一些初始化的工作，
```c#
public static class MyExtensions
{
    public static 返回类型 extFunction(this 要扩展的类型 参数名, 其他参数...)
    {
        // 方法实现
    }
}
```
调用的时候编译器将自动将调用者作为第一个参数传入到目标方法中 如下面这样的代码：
```c#
public static class StringExtensions
{
    public static bool IsReallyEmpty(this string str)
    {
        return string.IsNullOrWhiteSpace(str);
    }
}

// 使用
string text = "   ";
// text会被传入到  IsReallyEmpty 方法中
if (text.IsReallyEmpty())
{
    Console.WriteLine("字符串为空或全是空白！");
}
```