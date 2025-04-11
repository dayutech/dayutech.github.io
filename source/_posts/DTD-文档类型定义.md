---
title: DTD-文档类型定义
tags:
  - DTD
  - XML
  - XXE
categories:
  - [安全技术]
  - [协议规范]
date: 2025-04-10 20:56:11
description: 本文介绍了DTD的基本规范
---
# DTD-文档类型定义

用来定义合法的xml文档构建模块，使用一些列合法的元素来定义文档结构，可被用来检测xml文档语法是否正确。DTD可以被成行地声明于xml文档中，也可以成为一个外部引用。

## 内部文档声明

```xml
<!DOCTYPE 根元素 [元素声明]>
e.g.
<?xml version="1.0"?>
<!DOCTYPE note [
	<!ELEMENT note (to,from,heading,body)>
	<!ELEMENT to (#PCDATA)>
	<!ELEMENT from (#PCDATA)>
	<!ELEMENT heading (#PCDATA)>
	<!ELEMENT body (#PCDATA)>
]>
<note>
	<to>armandhe</to>
	<from>hjx<from>
	<heading>message</heading>
	<body>hello,world</body>

</note>
```

[test.xml](test.xml)

## 外部文档声明

**xml文档部分**

```xml
<?xml version="1.0"?>
<!DOCTYPE note SYSTEM 'note.dtd'> //定义外部文档声明
<note>
	<to>armandhe</to>
	<from>hjx<from>
	<heading>message</heading>
	<body>hello,world</body>

</note>
```

**dtd文档部分**

```xml
	<!ELEMENT note (to,from,heading,body)>
	<!ELEMENT to (#PCDATA)>
	<!ELEMENT from (#PCDATA)>
	<!ELEMENT heading (#PCDATA)>
	<!ELEMENT body (#PCDATA)>
```

## XML文档构建模块

所有地xml文档均由一下地构建模块构成：

- 元素
- 属性
- 实体
- PCDATA
- CDDATA

### 元素

元素是 XML 以及 HTML 文档的***主要构建模块***。

HTML 元素的例子是 "body" 和 "table"。XML 元素的例子是 "note" 和 "message" 。元素可包含文本、其他元素或者是空的。空的 HTML 元素的例子是 "hr"、"br" 以及 "img"。

```xml
<body id="1">
	父元素文本
	<form>子元素文本内容</form>
</body>    //body与form均为元素
```

### 属性

属性可提供有关元素的额外信息。性总是被置于某元素的开始标签中。属性总是以名称/值的形式成对出现的。

```xml
<img src="computer.gif" />
```

### 实体

实体是用来定义普通文本的变量。实体引用是对实体的引用。

```xml
类似于html实体，html实体在xml中也可以使用，已经被预定义了
```

### PCDATA

PCDATA 的意思是被解析的字符数据（parsed character data）。

可把字符数据想象为 XML 元素的开始标签与结束标签之间的文本。

**PCDATA 是会被解析器解析的文本。这些文本将被解析器检查实体以及标记。**

文本中的标签会被当作标记来处理，而实体会被展开。

不过，被解析的字符数据不应当包含任何 &、< 或者 > 字符；需要使用 &amp;、&lt; 以及 &gt; 实体来分别替换它们。

`也就是说，某一个元素被定义为PCDATA，那么他内部地文本元素中地内容如果出现其他标记，那么这些标记将被解析为元素,如果要让xml中使用地特殊字符被原样显示，则需要使用对应地实体。` 

### CDDATA

CDATA 的意思是字符数据（character data）。

***CDATA 是不会被解析器解析的文本。***在这些文本中的标签不会被当作标记来对待，其中的实体也不会被展开。

`通俗得讲就是原样输出` 

## 元素声明

```xml
<!ELEMENT note EMPTY> //<note /> 空元素
<!ELEMENT note (#PCDATA)> 
<!ELEMENT note ANY>  //可包含任意内容
<!ELEMENT note (to,from,heading,body)>  //字元素必须按章列出顺序出现在元素中且，字元素也需被声明
<!ELEMENT note (footer)> //声明只出现一次的元素
<!ELEMENT note (footer+)> //子元素至少出现一次
<!ELEMENT note (footer*)> //字元素出现一次或多次
<!ELEMENT note (footer?)> //字元素出现零次或多次
<!ELEMENT note (head,body,(message|confirm))> //括号总的元素有且只能出现一个
<!ELEMENT note (#PCDATA|to|form)*> //可以出现零次或多次的.....
```

## 属性声明

```xml
<!ARRLIST 元素名称 属性名称 属性类型 默认值>
e.g
<!AttlIST note id CDATA 1>

```

[属性类型](%E5%B1%9E%E6%80%A7%E7%B1%BB%E5%9E%8B%20aafed6de37df4ebd919995b3af4d41d4.csv)

[属性默认值](%E5%B1%9E%E6%80%A7%E9%BB%98%E8%AE%A4%E5%80%BC%2028f7fb5827924cfc84ea39b0a288be63.csv)

## 实体

实体是用于定义引用普通文本或特殊字符的快捷方式的变量。

实体引用是对实体的引用。

实体可在内部或外部进行声明。

```xml
//内部实体
<!ENTITY 实体名称 “实体值”>
<!ENTITY message "this is a part of a good book">
<des>&message;</des> 
//外部实体
<!ENTITY message SYSTEM "http://www.armandhe.com/a.dtd"> 
<des>&message;</des>
```