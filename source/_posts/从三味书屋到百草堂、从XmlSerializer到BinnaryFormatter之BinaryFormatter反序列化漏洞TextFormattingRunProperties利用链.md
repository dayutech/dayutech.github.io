---
title: >-
  从三味书屋到百草堂、从XmlSerializer到BinnaryFormatter之BinaryFormatter反序列化漏洞TextFormattingRunProperties利用链
tags:
  - C# - 反序列化
  - XmlSerializer
  - BinaryFormatter
  - TextFormattingRunProperties
categories:
  - - 漏洞原理
top: 222
abbrlink: 323962a4
date: 2025-05-27 09:31:53
---
# 利用链分析
`TextFormattingRunProperties`实现了`System.Runtime.Serialization.ISerializable`接口，故其在序列化以及反序列化过程中会自动执行`GetObjectData`以及特定的构造方法`internal TextFormattingRunProperties(SerializationInfo info, StreamingContext context)`
![img1](0880c08b011096a4b93d.png)
我们直接从反序列化时执行的特殊构造方法创建对象的过程开始。  
在调用构造方法创建对象期间会调用`GetObjectFromSerializationInfo`方法从`serializationInfo`中获取属性值。  
<!--more-->
```c#
internal TextFormattingRunProperties(SerializationInfo info, StreamingContext context)
{
	this._foregroundBrush = (Brush)this.GetObjectFromSerializationInfo("ForegroundBrush", info);
	this._backgroundBrush = (Brush)this.GetObjectFromSerializationInfo("BackgroundBrush", info);
	this._size = (double?)this.GetObjectFromSerializationInfo("FontRenderingSize", info);
	this._hintingSize = (double?)this.GetObjectFromSerializationInfo("FontHintingSize", info);
	this._foregroundOpacity = (double?)this.GetObjectFromSerializationInfo("ForegroundOpacity", info);
	this._backgroundOpacity = (double?)this.GetObjectFromSerializationInfo("BackgroundOpacity", info);
	this._italic = (bool?)this.GetObjectFromSerializationInfo("Italic", info);
	this._bold = (bool?)this.GetObjectFromSerializationInfo("Bold", info);
	this._textDecorations = (TextDecorationCollection)this.GetObjectFromSerializationInfo("TextDecorations", info);
	this._textEffects = (TextEffectCollection)this.GetObjectFromSerializationInfo("TextEffects", info);
	string text = (string)this.GetObjectFromSerializationInfo("CultureInfoName", info);
	this._cultureInfo = ((text == null) ? null : new CultureInfo(text));
	FontFamily fontFamily = this.GetObjectFromSerializationInfo("FontFamily", info) as FontFamily;
	bool flag = fontFamily != null;
	...
}
```
在`GetObjectFromSerializationInfo`方法中会调用`XamlReader.Parse`方法对从`serializationInfo`获取的字符串进行解析，通过上一篇文章[从三味书屋到百草堂，从XmlSerializer到BinnaryFormatter之XmlSerializer反序列化漏洞ObjectDataProvider利用链](archives/ff457959.html)我们知道  
`XamlReader`的`Parse`方法可以解析`XAML`字符串并导致命令执行。所以我们只需要将`TextFormattingRunProperties`某一个字段的值设置为符合`XamlReader`解析条件的`Payload`即可进行反序列化漏洞攻击。  
```c#
private object GetObjectFromSerializationInfo(string name, SerializationInfo info)
		{
			string @string = info.GetString(name);
			bool flag = @string == "null";
			object result;
			if (flag)
			{
				result = null;
			}
			else
			{
				result = XamlReader.Parse(@string);
			}
		
```
`serializationInfo`中的值由`GetObjectData`方法在序列化的时候设置  
```c#
public void GetObjectData(SerializationInfo info, StreamingContext context)
{
	bool flag = info == null;
	if (flag)
	{
		throw new ArgumentNullException("info");
	}
	info.AddValue("BackgroundBrush", this.BackgroundBrushEmpty ? "null" : XamlWriter.Save(this.BackgroundBrush));
	info.AddValue("ForegroundBrush", this.ForegroundBrushEmpty ? "null" : XamlWriter.Save(this.ForegroundBrush));
	info.AddValue("FontHintingSize", this.FontHintingEmSizeEmpty ? "null" : XamlWriter.Save(this.FontHintingEmSize));
	info.AddValue("FontRenderingSize", this.FontRenderingEmSizeEmpty ? "null" : XamlWriter.Save(this.FontRenderingEmSize));
	info.AddValue("TextDecorations", this.TextDecorationsEmpty ? "null" : XamlWriter.Save(this.TextDecorations));
	info.AddValue("TextEffects", this.TextEffectsEmpty ? "null" : XamlWriter.Save(this.TextEffects));
	info.AddValue("CultureInfoName", this.CultureInfoEmpty ? "null" : XamlWriter.Save(this.CultureInfo.Name));
	info.AddValue("FontFamily", this.TypefaceEmpty ? "null" : XamlWriter.Save(this.Typeface.FontFamily));
	info.AddValue("Italic", this.ItalicEmpty ? "null" : XamlWriter.Save(this.Italic));
	info.AddValue("Bold", this.BoldEmpty ? "null" : XamlWriter.Save(this.Bold));
	info.AddValue("ForegroundOpacity", this.ForegroundOpacityEmpty ? "null" : XamlWriter.Save(this.ForegroundOpacity));
	info.AddValue("BackgroundOpacity", this.BackgroundOpacityEmpty ? "null" : XamlWriter.Save(this.BackgroundOpacity));
	bool flag2 = !this.TypefaceEmpty;
	if (flag2)
	{
		info.AddValue("Typeface.Style", XamlWriter.Save(this.Typeface.Style));
		info.AddValue("Typeface.Weight", XamlWriter.Save(this.Typeface.Weight));
		info.AddValue("Typeface.Stretch", XamlWriter.Save(this.Typeface.Stretch));
	}
}
```

因为在`TextFormattingRunProperties`对象创建时第一个被获取的属性是`ForegroundBrush`，所以我们在创建`TextFormattingRunProperties`对象时可以将`ForegroundBrush`设置为我们的`Payload`  
`

