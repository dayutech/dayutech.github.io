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

