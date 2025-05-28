---
title: BinaryFormatter反序列化漏洞之ActivitySurrogateSelector利用链
tags:
  - C#
  - 反序列化
  - BinnaryFormatter
  - ActivitySurrogateSelector
categories:
  - - 漏洞原理
top: 222
abbrlink: 6f1feaf8
date: 2025-05-28 09:59:48
---
# 利用链分析
关于序列化与反序列化过程中使用的代理选择器以及代理这里就不再介绍了，代理（Surrogate）可以使得不能被序列化的类被序列化，具体的操作需要用户自行实现一个`ISerializationSurrogate`接口并实现其`GetObjectData`以及`SetObjectData`方法。  
<!--more-->
```c#
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Runtime.Serialization;
using System.Runtime.Serialization.Formatters.Binary;
using System.Text;

namespace Test
{
    public class Personal
    {
        public string Name;
        public int Age;
        public string Address;
    }

    public class PersonalSurrogate : ISerializationSurrogate
    {
        public void GetObjectData(object obj, SerializationInfo info, StreamingContext context)
        {
            Personal personal = (Personal)obj;
            info.AddValue("Name", personal.Name);
            info.AddValue("Age", personal.Age);
            info.AddValue("Address", personal.Address);

        }

        public object SetObjectData(object obj, SerializationInfo info, StreamingContext context, ISurrogateSelector selector)
        {
            Personal personal = (Personal)obj;
            personal.Name = info.GetString("Name");
            personal.Age = info.GetInt32("Age");
            personal.Address = info.GetString("Address");
            return personal;
        }
    }
        public class SurrogateTest
        {
        static void Main(string[] args)
        {
            Personal personal = new Personal();
            BinaryFormatter binaryFormatter = new BinaryFormatter();
            PersonalSurrogate personalSurrogate = new PersonalSurrogate();
            SurrogateSelector surrogateSelector = new SurrogateSelector();
            surrogateSelector.AddSurrogate(typeof(Personal), new StreamingContext(StreamingContextStates.All), personalSurrogate);
            binaryFormatter.SurrogateSelector = surrogateSelector;
            MemoryStream memoryStream = new MemoryStream();
            binaryFormatter.Serialize(memoryStream, personal);

        }
    }
}
    


```
在上面的例子中`personal`既没有实现`ISerializable`接口也没有被`Serilizable`特性修饰，正常来说是不能被序列化以及反序列化的，不过我们通过创建`SurrogateSelector`并设置`Surrogate`来实现`Personal`对象的正确序列化与反序列化。  
通过`Surrogate`的特性我们便可以在反序列化漏洞的利用中使用哪些正常来说不可以被序列化与反序列化的类型。不过从上面的代码中我们也知道，要想实现对某个特定的不可序列化类的序列化需要我们在服务端创建对应的`Surrogate`并实现`ISerializationSurrogate`接口，  
然后在序列化过程中进行配置，而服务端的代码逻辑是我们在攻击过程中影响不了的，这样看起来`Suggogate`并没有用武之地。  
天无绝人之路，存在这样一个特殊的`SurrogateSeletor` `ActivitySurrogateSelector` 其`GetSurrogate`方法在特定条件下可以返回一个`ObjectSurrogate`类型的`Surrogate`  
```c#
public override ISerializationSurrogate GetSurrogate(Type type, StreamingContext context, out ISurrogateSelector selector)
		{
			if (type == null)
			{
				throw new ArgumentNullException("type");
			}
			selector = this;
			ISerializationSurrogate serializationSurrogate = null;
			bool flag;
			lock (ActivitySurrogateSelector.surrogateCache)
			{
				flag = ActivitySurrogateSelector.surrogateCache.TryGetValue(type, out serializationSurrogate);
			}
			if (flag)
			{
				if (serializationSurrogate != null)
				{
					return serializationSurrogate;
				}
				return base.GetSurrogate(type, context, out selector);
			}
			else
			{
				if (typeof(Activity).IsAssignableFrom(type))
				{
					serializationSurrogate = this.activitySurrogate;
				}
				else if (typeof(ActivityExecutor).IsAssignableFrom(type))
				{
					serializationSurrogate = this.activityExecutorSurrogate;
				}
				else if (typeof(IDictionary<DependencyProperty, object>).IsAssignableFrom(type))
				{
					serializationSurrogate = this.dependencyStoreSurrogate;
				}
				else if (typeof(XmlDocument).IsAssignableFrom(type))
				{
					serializationSurrogate = this.domDocSurrogate;
				}
				else if (typeof(Queue) == type)
				{
					serializationSurrogate = this.queueSurrogate;
				}
				else if (typeof(Guid) == type)
				{
					serializationSurrogate = this.simpleTypesSurrogate;
				}
				else if (typeof(ActivityBind).IsAssignableFrom(type))
				{
					serializationSurrogate = this.objectSurrogate;
				}
				else if (typeof(DependencyObject).IsAssignableFrom(type))
				{
					serializationSurrogate = this.objectSurrogate;
				}
				lock (ActivitySurrogateSelector.surrogateCache)
				{
					ActivitySurrogateSelector.surrogateCache[type] = serializationSurrogate;
				}
				if (serializationSurrogate != null)
				{
					return serializationSurrogate;
				}
				return base.GetSurrogate(type, context, out selector);
			}
		}
```
从上面的代码可知要想获取`ObjectSurrogate`类型的`Surrogate`需要满足序列化类为`DependencyObject`或者`ActivityBind`的子类，这样就限制了我们的发挥。  
不过虽然`ActivitySurrogateSelector`的`GetSurrogate`方法有这个限制，但我们可以自定义一个`SurrogateSelector`来绕开这个限制，从而完成使用`ObjectSurrogate`的`getObjectData`方法来进行序列化。  
```c#
public override ISerializationSurrogate GetSurrogate(Type type, StreamingContext context, out ISurrogateSelector selector)
        {
            selector = this;
            if (!type.IsSerializable)
            {
                Type t = Type.GetType("System.Workflow.ComponentModel.Serialization.ActivitySurrogateSelector+ObjectSurrogate, System.Workflow.ComponentModel, Version=4.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35");
                return (ISerializationSurrogate)Activator.CreateInstance(t);
            }

            return base.GetSurrogate(type, context, out selector);
        }
```
这时候就又存在问题了，这不还是在改变序列化的过程吗，如果反序列化的过程没有设置对应的`Surrogate`不还是不能成功进行漏洞利用吗？  
这里就不得不提到`ObjectSurrogate`神奇的`GetObjectData`方法了。  
在该方法中调用了`info.SetType`设置了反序列化过程中`obj`的实际类型为`ActivitySurrogateSelector.ObjectSurrogate.ObjectSerializedRef`，也就是说发序列化过程中将不会立即得到原始的obj，而是先得到`ObjectSerializedRef`类型。
```c#
public void GetObjectData(object obj, SerializationInfo info, StreamingContext context)
			{
				info.AddValue("type", obj.GetType());
				string[] array = null;
				MemberInfo[] serializableMembers = FormatterServicesNoSerializableCheck.GetSerializableMembers(obj.GetType(), out array);
				object[] objectData = FormatterServices.GetObjectData(obj, serializableMembers);
				info.AddValue("memberDatas", objectData);
				info.SetType(typeof(ActivitySurrogateSelector.ObjectSurrogate.ObjectSerializedRef));
			}
```
`ObjectSerializedRef`实现了	`IObjectReference`以及`IDeserializationCallback`接口，这两个接口分别包括方法`GetRealObject`以及`OnDeserialization`方法。  
`GetRealObject`与`OnDeserialization`方法均在对象图构造完成后执行，即`ObjectSerializedRef`对象构造完成后执行，且`GetRealObject`方法先于`OnDeserialization`方法执行，主要作用是控制反序列化后的实际对象返回，  
而`OnDeserialization`则用于在所有字段都恢复后进行初始化或验证操作。
`GetRealObject`方法调用`GetUninitializedObject`通过`this.type`构造目标对象，而`this.type`我们通过`ObjectSurrogate`的`getObjectData`方法可以知道是哪个最初序列化的不可序列化的类，在我们的例子中即`Personal`。  
```c#
object IObjectReference.GetRealObject(StreamingContext context)
				{
					if (this.returnedObject == null)
					{
						this.returnedObject = FormatterServices.GetUninitializedObject(this.type);
					}
					return this.returnedObject;
				}
```
`OnDeserialization`方法用于还原`Personal`对象的成员变量的值。
```c#
void IDeserializationCallback.OnDeserialization(object sender)
				{
					if (this.returnedObject != null)
					{
						string[] array = null;
						MemberInfo[] serializableMembers = FormatterServicesNoSerializableCheck.GetSerializableMembers(this.type, out array);
						FormatterServices.PopulateObjectMembers(this.returnedObject, serializableMembers, this.memberDatas);
						this.returnedObject = null;
					}
				}
```
由此我们知道了我们可以通过自定义`SurroGateSeletor`返回`ObjectSurrogate`实现对不可序列化对象的序列化，并且这样序列化的结果字符串即便在反序列化过程中`BinarryFormatter`没有设置对应的`SurroGateSeletor`的情况下也能被成功反序列化，  
因为其使用了`ObjectSerializedRef`这个可以序列化以及反序列化的类对那些不可序列化的类进行了包装。
