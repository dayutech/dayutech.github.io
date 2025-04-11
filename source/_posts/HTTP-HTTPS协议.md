---
title: HTTP-HTTPS协议
tags:
  - HTTP
  - HTTPS
categories:
  - [安全技术]
  - [协议规范]
date: 2025-04-10 20:56:11
description: 本文介绍了HTTP/HTTPS的基本格式
---
# HTTP/HTTPS协议

# HTTP

## HTTP概述

http-超文本标记语言，属于七层应用层协议，默认端口号80，基于tcp的协议。

http协议是无连接，无状态的一种协议

无连接：每次连接只处理一个请求

无状态：对事务处理没有记忆能力

HTTP使用统一资源标识符（Uniform Resource Identifiers, URI）来传输数据和建立连接。URL是一种特殊类型的URI，包含了用于查找某个资源的足够的信息

URI:一种抽象的标识资源的方法，并不能定位资源

URL:即可标识资源，也可定位资源

URN：仅是资源的一种命名标准

URL包括以下部分：

协议部分://用户名:密码@域名部分/虚拟目录部分/文件名部分?参数部分#锚部分

## HTTP版本区别

http1.1对比http1.0：使用了管道化技术，加入了长连接功能。此时一个http连接可以同时发送多个http请求，但是对于回包来说，无法分别出是属于哪个请求的，还是必须要去按照请求的顺序返回，这就导致了一个兼做`线头阻塞`  的问题，同时http1.1也不支持服务端推送功能

http2.0：增加了服务端推送，通过帧、流等手法解决了线头阻塞的问题，再一个连接中，可以发送多个请求，一个请求时一个流，一个流被分成很多帧。使用了标志位来区分不同的请求

## HTTP头

### HTTP请求头

**请求行 ：**请求方法 请求资源 协议类型 版本号

**请求头：**包括请求主机、用户代理、referer、cookie、accept、accept-encoding、accept-language、cache-control、connection、if-none-match等lastmodified

**空行：**分割请求头与请求体

**请求体**：请求参数

请求方法包括get、post、put、delete、connection等

### HTTP响应头

**状态行：**协议类型 版本号 响应码 响应消息

**响应头：**日期、set-cookie、access-control-allow-origain、connection、content-encoding、content-Type、etag、vary、 x-xss-protection、x-frame-options

空行：

**响应体：**

**GET与PSOT的区别**

1. get提交的数据会放在url中，post提交的数据存放在请求体中
2. GET方法提交的数据有大小限制，浏览器对url长度有限制4k,post方法无
3. GET方式提交的数据直接存放在url中，不安全。

# HTTPS

以下笔记参考

[Https详解+wireshark抓包演示](https://www.jianshu.com/p/a3a25c6627ee)

我们知道http协议是无状态、无连接的一种明文传输的协议。那么在传输过程中我们的数据就可能会被不法分子所劫持、篡改等。

https的原理就是在原来http协议的基础上添加了一层安全套接层ssl对传输的数据进行加密。我们在tcp三次握手完成后，正式传输数据前还需要进行ssl握手交换彼此的密钥、证书。

## https握手过程

![](Untitled.png)

### Step1：Client Hello

报文包含：

1. TLS版本
2. 随机数：random1 包含两部分：时间戳（4字节）+随机数（28字节
3. session-id:用来表明一次会话，第一次建立没有。如果以前建立过，可以直接带过
4. 加密算法套装列表：客户端支持的加密-签名算法列
5. 压缩算法：一般不适
6. 扩展字段：密码交换算法的参数、请求主机的名字

### Step2：Server Hello

报文包括：

1. TLS版本号：和客户端上传的版本号对比，使用相应的版本
2. 确定加密套件，压缩算法
3. 产生一个随机数random2,此时客户端与服务端都拥有了两个随机数

### Step3：Server ⇒ Client

报文包括：

1. Certificat: 服务器向CA申请的证书
2. Server Key Exchange:
    
    这个消息是用来发送密钥交换算法相关参数和数据的。这里要提前提一下，就是根据密钥交换算法的不同，传递的参数也是不同的。
    常用的密钥交换算法：RSA、DH（Diffie-Hellman）、ECDH（Ellipticcurve Diffie–Hellman）。
    
3. Server Hello Done:用来表示服务端说完了。

客户端拿到证书后，通过保存在本机的根证书，验证该证书是否合法，取得证书中的公钥。

### Step4：Client => Server

报文包括

1. Client Key Exchange：交换密钥参数，此时客户端会生成一个随机数random3,然后使用从服务端哪里获取的公钥进行加密得到密文，然后发送到服务端，服务端收到这个值后，使用自己的私钥进行解密，此时服务器与客户端就都有了三个随机数了。
2. Change Cipher Spec:编码改变通知。这一步是客户端通知服务端后面再发送的消息都会使用前面协商出来的秘钥加密了，是一条事件消息。
3. Encrypted Handshake Message:这一步对应的是 Client Finish 消息，客户端将前面的握手消息生成摘要(随机数)再用协商好的秘钥加密，这是客户端发出的第一条加密消息。服务端接收后会用秘钥解密，能解出来说明前面协商出来的秘钥是一致的。

### Step5：Server ⇒ Client

报文包括

1. New Session Ticket:包含了一个加密通信所需要的信息，这些数据采用一个只有服务器知道的密钥进行加密。目标是消除服务器需要维护每个客户端的会话状态缓存的要求。这部分内容在后面的扩展部分会讲到
2. Change Cipher Spec:编码改变通知。这一步是服务端通知客户端后面再发送的消息都会使用加密，也是一条事件消息。
3. Encrypted Handshake Message:这一步对应的是 Server Finish 消息，服务端也会将握手过程的消息生成摘要再用秘钥加密，这是服务端发出的第一条加密消息。客户端接收后会用秘钥解密，能解出来说明协商的秘钥是一致的。

## 我们为什么需要https

http协议在互联网上是明文传输的，那么就可能存在数据被截获、篡改的可能。为了信息安全于是在http协议的基础上添加了一层安全套接层，也就是ssl。ssl现在已经发展到TLS了，当前主流的使用也是TLS方式加密。那么这个加密过程到底是怎样的呢。首先我们需要了解两种加密方式。对称加密于非对称加密。

对称加密也就是，通信双方公用同一个密钥进行加密与解密，那么问题来了，双方要进行对称加密通信则必须要进行交换密钥的操作，交换密钥的过程势必使明文传输的，那么密钥就存在泄露的风险，那么对称加密通信也就不再安全了。

非对称加密，通信双方使用各自的公钥私钥进行同行，私钥进行加密，公钥进行验证，私钥加密的数据只能被公钥解密，公钥加密的数据只能被私钥解密，私钥只有发信方本人知道，公钥向与之通信的人公开，那么通过公钥加密的数据就只能被拥有私钥的接收方解密，但通过私钥加密的数据却能被所有拥有公钥的人解密，且通过公钥加密的数据虽然保证了安全性，但数据完整性却没有得到保证，其仍存在被篡改的可能，为了解决数据完整性与公钥加密数据的安全性问题，我们又引入另外两个概念CA与数字摘要、数字签名。

既然数据可能在传输过程中被篡改，那么我们只需要让数据接收方能够通过一个特征验证数据的真伪就可以了，这个验证特征就是数字摘要，将源数据通过哈希算法进行散列得到一个摘要随着数据一同发送。哈希算法的特征保证了哈希值的基本唯一性，所以我们可以在接受到数据后对收到的数据使用同样的hash算法，得到一个hash值对比接收到的hash值，如果两者一致，那么就保证了数据没有被篡改过。那么为什么又需要数字签名呢，前面提到了，摘要如果明文传输的话，就可能被截获，并整个篡改。

# 其他

# 客户端

## 胖客户端

请求的资源在客户端加载运行

不安全

## 瘦客户端

请求的资源在服务器运行完返回运行结果

# 服务器

## 动态的web服务器

执行代码，返回运行结果

php-php服务器 

jsp-tomcat

asp-iis

## 静态的web服务器

直接返回原资源

apache ngix iis

# http状态码

100 提示信息

200 成功

300 重定向

301 永久重定向

302 临时重定向

400 客户端错误

403 forbiden

404 not found

500 服务端错误

501 网关错误

http协议是一种无状态的协议，每次只能请求一个资源，如果想一次请求多个资源，可以使用到长连接，长连接通过时间与连接数量来控制生存时间，从而不然该连接占据太多的带宽

cd /etc/httpd/conf.d/

touch keepalive.conf

写入以下内容

KeepAlive on

MaxKeepAliveRequests 500

KeepAliveTimeout 5

设置长连接

restful 风格，基于路径的风格,主流风格

# APACHE-HTTPD

# httpd主配置文件

## 全局配置

ServerRoot "/etc/httpd" //设置配置文件的根目录，该配置文件中后面的所有相对路径都是基于该目录开始的

Listen 80 //配置监听的端口，可复写多个

Listen ipaddr:80

User apache

Group apache //以什么身份运行

ServerAdmin root@localhost //报错信息发送目标

## 中心主机配置

DocumentRoot "/var/www/html" //中心主机根目录

<Location "url">

基于url的权限设置

</Location>

<files "本地文件路径">

针对文件的权限设置

</files>

<Directory "本地目录">

require all granted|denied

Allowoverride all|none|directive_type //与.htaccess文件相关，如果设置为允许，则如果该文件中的directory与配置文件中的directory冲突，配置文件中的内容将被覆盖。

Options Indexes|FollowSymboLinks|none|all

require ip ipaddr granted|denied //按ip配置权限

AuthType Basic //认证类型

AuthName "请输入你的用户名" //要认证的用户

AuthUserFile "/etc/httpd/.htpasswd" //合法用户列表

Require valid-user // 合法的用户均可访问该目录 

</directory>

htpasswd -c 文件 新建的用户名 //配置了认证选项之后，执行命令，创建可供登录的用户  [//window](//window) 同样有该命令

<IFModule dir_module>

DirectoryIndex index.html //如果存在dir_module模块则，设置默认页面为index.html

</IFModule>

Errorlog "本地目录"

LogLevel warn [//debug](//debug) info notice warn error crit alert emerg  记录大于或者等于warn的错误日志

<IfModule log_config_module>

LogFormat "%h %u %l %t \"%r\" \"%{Referer}i\""  combined //访问日志文件格式，最后为名称

CustomLog "访问日志路径" combined(启用的格式)

</IfModule>

<IFModule alias_module>

**`Alias /webpath 本地文件路径 //将本地文件路径映射到url路径`  //restful风格**

</IFModule>

ErrorDocument 404 filepath //自定义错误页面

ServerName [www.armandhe.com:80](http://www.armandhe.com:80)  //配置主机名-FQDN

## 虚拟主机

一台服务器上可以运行多个主机，一个中心主机，其他虚拟主机。停掉中心主机后建立虚拟主机

中心主机与虚拟主机可通过ip地址、端口号、http头部的hosts来区分

单独建立一个虚拟主机，新建一个配置文件

cd /etc/httpd/conf/conf.d

touch virtualhost.conf

在该文件中写入

<VirtualHost 172.16.11.16:80>

DocumentRoot "/a"

<Directory "/a">

Require all granted

</Directory>

</VirtualHost>

# 动态服务器工作结构

客户端的消息发送到httpd之后，如果是请求静态资源，httpd直接将数据发送到客果请求的是动态的资源，则请求被传送到php服务器，php服务器处理完之后再将结果发送到httpd，由httpd发送给客户端。

`单体架构`

前端和后端写在一起

`前后分离`

php默认监听在9000端口

php与httpd的结合方式分为模块化，与独立进程两种方式

模块化，php作为httpd的一个模块嵌入到httpd中

独立进程，php独立成为一个进程。

独立进程php安装：yum install php-fpm

**独立进程php服务器架构**

cd /etc/php-fpm.d

vim www.conf

将允许访问的客户端ip地址 listen.allowed_clients修改为你的apache客户端ip地址

在apache的配置文件中写入

ProxyPassMatch  "/(.*\.php$) " "fcgi://ipaddr:port-9000/phpfile_path/$1" //反向代理

删除php模块 保留配置文件 注释掉最后两行

# https实现

## 证书签发流程

yum install openssl 			
第一步 创建私有CA
1：(umask 066;openssl genrsa -out /etc/pki/CA/private/cakey.pem 2048)
生成CA密钥
2： openssl req -new -x509 -key /etc/pki/CA/private/cacd key.pem -days 7300 -out /etc/pki/CA/cacert.pem
自签CA证书
第二步 申请证书
1：  (umask 066;openssl genrsa -out /etc/httpd/ssl/httpd.key 2048)
生成web服务器私钥
2： openssl req -new -key /etc/httpd/ssl/httpd.key -days 365 -out /etc/httpd/ssl/httpd.csr
创建证书申请
第三步 签署证书
1：	touch /etc/pki/CA/index.txt ;echo 01 >/etc/pki/CA/serial
创建证书数据库;证书颁发列表
2： openssl ca -in /etc/httpd/ssl/httpd.csr -out /etc/pki/CA/certs/httpd.crt -days 365
签发证书
使用证书实现https
1 :安装mod_ssl
2 : /etc/httpd/conf.d/ssl.conf
1: SSLCertificateFile /etc/httpd/ssl/httpd.crt 指定证书的位置
2：SSLCertificateKeyFile /etc/httpd/ssl/httpd.key 指定私钥的位置

## 后续步骤

sz /etc/pki/CA/cacert.pem //将证书拷贝到桌面,添加到受信任的根证书签发机构

`双击证书安装`

win+r 输入MMC 添加一个管理节点 选择证书 查看安装的证书

在/etc/httpd/conf.d/ssl.conf 在虚拟主机里面添加证书的路径与私钥的路径

SSLCertificateFile /etc/httpd/ssl/httpd.crt //证书路径

SSLCertificateKeyFile /etc/httpd/ssl/httpd.key //私钥路径

添加虚拟主机的配置到ssl.conf 添加以下内容

ServerName [www.test.com:443](http://www.test.com:443/)
 DocumentRoot "/test"
<Directory "/a">
     require all granted
 </Directory>
ProxyPassMatch /(.*\.php$) "fcgi://192.168.0.107:9000/phptest/$1"  //反向代理到php服务器

apache服务器上应该卸载php模块，但保留php.conf配置文件并注释掉其最后两行内容

php服务器上应该修改以下内容

listen = 9000 //监听所有的ip地址的9000端口

listen.allowed_clients = 127.0.0.1 //注释掉这一行，表示允许所有主机访问该站点

//`注意关闭防火墙` 访问时记得修改hosts文件

# NGINX