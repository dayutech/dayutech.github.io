---
title: .Net Remoting 导致的反序列化漏洞
tags:
  - .Net Remoting
  - 反序列化漏洞
categories:
  - - 漏洞原理
description:
  - .....
top: 250
abbrlink: 6e27d7b9
date: 2025-09-05 09:46:13
---

`.NET Remoting` 反序列化漏洞是一个**严重且历史悠久的安全问题**，它允许攻击者在目标系统上执行任意代码（RCE），尤其是在未加防护的 .NET Remoting 服务暴露在公网或不受信任网络中时。

---

## 一、什么是 .NET Remoting？

`.NET Remoting` 是微软在 .NET Framework 1.0 ~ 4.x 时代提供的一种**远程过程调用（RPC）技术**，用于跨应用程序域（AppDomain）、进程甚至网络进行对象通信。

- 它允许一个应用程序调用另一个应用程序域中的对象方法。
- 使用 **二进制序列化（BinaryFormatter）** 作为默认的序列化机制。
- 已被 **WCF（Windows Communication Foundation）** 和现代 API（如 gRPC、ASP.NET Web API）取代。
- **自 .NET 5 起已完全弃用**，不推荐在新项目中使用。

---

## 二、反序列化漏洞原理

### 核心问题：`BinaryFormatter` 的不安全性

`.NET Remoting` 默认使用 `System.Runtime.Serialization.Formatters.Binary.BinaryFormatter` 进行序列化和反序列化。

> ⚠️ **`BinaryFormatter` 的致命缺陷**：
> - 它可以序列化和反序列化**任意类型的对象**，包括 `Delegate`、`Type`、`Assembly` 等。
> - 在反序列化时，会**自动调用对象的构造函数、setter、事件处理器等**。
> - 攻击者可以构造一个恶意的序列化 payload，利用某些类型（如 `TypeConfuseDelegate`、`ObjectDataProvider`）在反序列化过程中触发**任意代码执行**。
> - TypeLevel 为 Full的时候才会导致漏洞

---

### 漏洞触发流程

1. 攻击者构造一个恶意的序列化对象（payload），其中包含：
   - 指向危险类型（如 `System.Windows.Data.ObjectDataProvider`）的引用。
   - 设置 `MethodName` 为 `Process.Start`，`MethodParameters` 为 `cmd.exe /c calc`。
2. 将该 payload 发送给使用 `.NET Remoting` 的服务端。
3. 服务端调用 `BinaryFormatter.Deserialize()` 时，自动执行恶意代码。
4. 攻击者获得远程代码执行（RCE）权限。

---

## 三、经典利用方式（PoC 示例）

```csharp
// 攻击者构造的恶意对象（示意）
var dataProvider = new ObjectDataProvider();
dataProvider.ObjectType = typeof(System.Diagnostics.Process);
dataProvider.MethodName = "Start";
dataProvider.MethodParameters.Add("cmd.exe");
dataProvider.MethodParameters.Add("/c calc.exe");

// 序列化这个对象
IFormatter formatter = new BinaryFormatter();
using (var stream = new MemoryStream())
{
    formatter.Serialize(stream, dataProvider); // 这个 stream 就是恶意 payload
    // 发送给 Remoting 服务
}
```

当服务端反序列化这个流时，`calc.exe` 会被执行。

---

## 四、受影响的组件

| 组件 | 是否受影响 |
|------|-----------|
| `.NET Remoting` | ✅ 高危（默认使用 `BinaryFormatter`） |
| `BinaryFormatter` | ✅ 所有使用它的场景都可能受影响 |
| `LosFormatter` | ⚠️ 部分场景可能受影响 |
| `NetDataContractSerializer` | ⚠️ 如果类型不受控，也可能有问题 |
| `JSON.NET` (Newtonsoft.Json) | ⚠️ 如果设置 `TypeNameHandling = Auto/All`，也可能反序列化攻击 |
| `XmlSerializer` | ❌ 相对安全（不支持任意对象图） |

---

## 五、漏洞影响

- **远程代码执行（RCE）**：攻击者可在服务器上以运行 .NET 服务的权限执行任意命令。
- **权限提升**：如果服务以高权限运行（如 LocalSystem），可完全控制服务器。
- **横向移动**：作为内网渗透的跳板。
- **数据泄露**：读取服务器上的敏感文件、数据库凭据等。

---

## 六、修复与缓解措施

### ✅ 1. **禁用 BinaryFormatter（最根本）**

从 .NET 4.0 开始，微软提供了开关来禁用 `BinaryFormatter`：

```xml
<configuration>
  <runtime>
    <NetFx40_LegacySecurityPolicy enabled="false" />
    <allowBinaryFormatter remoting="false" />
  </runtime>
</configuration>
```

或在代码中：

```csharp
AppContext.SetSwitch("System.Runtime.Serialization.EnableUnsafeBinaryFormatterSerialization", false);
```

> 设置后，`BinaryFormatter.Serialize/Deserialize` 会抛出异常。

---

### ✅ 2. **迁移到现代通信技术**

- **WCF**（更安全，支持多种绑定和安全策略）
- **ASP.NET Core Web API**（RESTful + JSON）
- **gRPC**（高性能，支持强类型契约）
- **SignalR**（实时通信）

避免使用已过时的 `.NET Remoting`。

---

### ✅ 3. **最小权限原则**

- Remoting 服务不要以 `LocalSystem` 或管理员权限运行。
- 使用低权限账户运行服务。

---

### ✅ 4. **网络隔离与防火墙**

- 不要将 Remoting 服务暴露在公网。
- 使用防火墙限制访问 IP。
- 使用 TLS 加密通信（虽然加密不能防止反序列化攻击，但可防中间人）。

---

### ✅ 5. **输入验证与反序列化控制**

如果必须使用 `BinaryFormatter`：

- 实现自定义 `SerializationBinder`，限制可反序列化的类型：

```csharp
public class SafeSerializationBinder : SerializationBinder
{
    public override Type BindToType(string assemblyName, string typeName)
    {
        // 只允许特定程序集和类型
        if (assemblyName.Contains("TrustedAssembly") && 
            (typeName == "TrustedType1" || typeName == "TrustedType2"))
        {
            return Type.GetType($"{typeName}, {assemblyName}");
        }
        return null; // 拒绝其他类型
    }
}

// 使用
formatter.Binder = new SafeSerializationBinder();
```

---

### ✅ 6. **启用日志与监控**

- 记录反序列化异常。
- 监控异常进程启动（如 `cmd.exe`, `powershell.exe` 从 .NET 服务启动）。

---

## 七、检测工具

- **Microsoft BinaryFormatter Scanner**：官方工具，扫描程序集是否使用 `BinaryFormatter`。
- **Burp Suite / ysoserial.net**：用于生成和测试反序列化 payload。
- **Code Analysis Tools**：如 SonarQube、ReSharper 可检测不安全的序列化用法。

---

## 八、总结

| 项目 | 建议 |
|------|------|
| 是否使用 `.NET Remoting`？ | ❌ 弃用，不要在新项目中使用 |
| 是否使用 `BinaryFormatter`？ | ❌ 禁用或严格限制 |
| 如何修复？ | 迁移到 WCF/WebAPI/gRPC + 禁用 BinaryFormatter + 网络隔离 |
| 是否影响现代 .NET？ | ❌ .NET 5+ 已移除 Remoting，但 `BinaryFormatter` 仍存在（需手动禁用） |

> 🔐 **安全建议**：  
> **永远不要反序列化来自不受信任源的数据**，尤其是在使用 `BinaryFormatter` 时。

如果你仍在维护使用 `.NET Remoting` 的旧系统，**强烈建议尽快迁移或至少禁用 `BinaryFormatter`**，否则系统将长期处于高风险之中。
