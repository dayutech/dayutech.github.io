---
title: 读书笔记-WEB前端黑客技术揭秘
tags:
  - Web
  - 前端
categories:
  - - 安全技术
  - - 读书笔记
description: 《WEB前端黑客技术揭秘》 读书笔记
abbrlink: 6eecc4bb
date: 2025-04-10 20:56:11
---
# 读书笔记-WEB前端黑客技术揭秘

资源：同源策略里面的资源指的是web客户端的资源，包括http消息头，dom树，浏览器存储（cookie\localStorage）

DOM：文档对象模型，就是将html/xml这样的文档抽象成一个树形结构，树上的每一个节点都是html/xml的标签、标签内容、标签属性

> 安全问题很大程度上其实是信任关系
iframe中嵌套的网页不能读写父页中的数据，但是可以对父页的`location` 进行操作，不过只有写权限却没有读权限

javascript 脚本可以外来引入，也可以在`<script>` 标签中，也可以在src、href的伪协议中。

通过设置set-cookie的path不能限制cookie被盗用，可以在页面中嵌入一个iframe来获取当前页面的cookie.

```jsx
xc = function(src){
	var o=document.createElement("iframe");
	o.src=src;
	document.getElementByTagName("body")[0].appendChild(o);
	o.onload=function{
	d=o.contentDocument || o.contentWindow.document();
	alert(d.cookie);
};

}("http://a.foo.com/admin/index.php");
```

cookie设置了httponly之后，客户端的脚本就不能对其进行读写，但是也是可以绕过的，如果服务器的响应洁面含有cookie调试信息，则可能导致cookie泄露，如phpinfo()，Django调式信息

Apache HTTP Server 400 错误会返回http only cookie 。apache http sever 2.2.x多个版本没有严格限制http请求头的内容，当请求头的长度超过`limitRequestFieldSize`长度时，服务器将会返回400-bad request错误，并在返回的信息中将出错的请求头的内容输出。我们可以利用这一点构造超长的请求头，主动触发400错误获取cookie.

设置了secure的cookie只能通过https协议传输，但却是可读写的。这就意味着，该类型的cookie可被篡改。

修改cookie的时候字段名、path、dmain必须与目标cookie,，不然会被认为是新的cookie，起不到改写的作用

cookie分为本地cookie与内存cookie

1. 本地cookie设置了过期时间的cookie被浏览器存储在本地，可被获取与篡改。
2. 内存cookie未设置过期时间的cookie,被浏览器存储咋内存中，可以被加上过期时间，从而存储在本地被读取篡改

cookie的p3p性质

该标准规定了是否允许目标网站的cookie是否可以被另一个域通过加载目标网站而被设置与发送，仅ie浏览器执行了该策略。

**设置cookie**

默认情况写ie时不会允许第三方的域设置cookie的，但如果容器域在响应的时候带上了p3p字段，此时第三方域就可以成功设置cookie。设置后的cookie在id下会自动带上p3p属性，依次生效，即使之后没有p3p头，也有效。

**发送cookie**

发送的cookie如果是内存cookie，那么无论是否带有p3p属性，都可以正常发送，如果是本地cookie则这个本地cookie必须要有p3p属性，否则即使3目标域响应了p3p头也没用。

大多数浏览器限制每个窗口最多能有50个cookie,最大值约4k

js函数劫持

在目标函数执行前，重写这个函数即可。

下面是eval函数的劫持语句

```jsx
var_eval=eval;
eval = function(x){
	if (typeof(x)=="undifined"){
		alert(x);
		_eval(x);

};
};
```

上述脚本的执行结果就是，会先弹窗再正常执行

同样的document.write 与document.writeln可以通过同样的方式劫持

```jsx
var_write=document.write.bind(document);
document.write=function(x){
	if (typeof(x)=="undifined"){return;}
	_write(x)

};
```

`操作界面劫持`，通过再可见的操作界面元素上伪装一层不可见的iframe以达到劫持的目的。

可分为三种：

1. **点击劫持:**
    
    ```html
    **file:1**
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport"
              content="width=device-width, user-scalable=no, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0">
        <meta http-equiv="X-UA-Compatible" content="ie=edge">
        <title>Document</title>
        <style>
            #click{
                width: 100px;
                top: 20px;
                left: 20px;
                position: absolute;
                z-index: 1;
            }
            #hidden{
                height: 50px;
                width: 120px;
                position: absolute;
                filter: alpha(opacity=50);
                opacity: 0.5;
                z-index: 2;
            }
    
        </style>
    </head>
    <body>
    <input type="button" id="click" value="click me">
    <iframe src="inneriframe.html" id="hidden" scrolling="no"></iframe>
    </body>
    </html>
    
    **file2:**
    <!doctype html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport"
              content="width=device-width, user-scalable=no, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0">
        <meta http-equiv="X-UA-Compatible" content="ie=edge">
        <title>Document</title>
    </head>
    <body>
    <input type="button" style="width: 100px;" onclick="alert('hello world')"/>
    </body>
    </html>
    ```
    
2. **拖放劫持：**可在拖放过程中通过dataTransfer兑现的setData与getData函数实现跨域，

```jsx
event.dataTransfer.setData("text","someexample");
var text = event.dataTransfer.getData("text");
```

3. **触屏劫持**：举个例子：将网页伪装成向桌面一样，那么用户就无法分辨到底是不是再桌面上，弹出提示框提示他进行操作从而实现触屏劫持。伪装成桌面需要实现网页全屏与隐藏url地址栏操作

**CSRF**:如果我们不久前访问过某个网站，但这个网站存在csrf漏洞，那么如果攻击这构造一个虚假的网站，当我们访问该网站的时候，浏览器会认为这是一个合理的请求，那么我们就被成功地攻击了。

防御：校验referer|token ，token值是一个伪随机数，由服务器生成，发送到客户端与窗口绑定，伪造的请求应无法获取该token，故不能成功攻击。

**CSRF漏洞确认**：

1. 目标表单是否有有效的token随机串
2. 目标表单是否有验证码
3. 目标是否判断了referer来源
4. 网站根目录下crossdomain.xml的allow-access-from domain 是否是通配符
5. 目标json数据是否可以自定义callback函数

**界面操作劫持确认：**

1. 目标的http响应头是否设置好了X-Frame-Options字段
2. 目标是否有js的frame Bustin机制
3. 使用iframe签如目标网站测试，若成功，则说明漏洞存在。

**`<title><textarea><iframe><noscript><noframes><plaintext><plaintext>中插入js代码不会被解析`**

html标签之间的xss注入，可直接输入script代码

html标签内的xss注入，可通过闭合属性标签或者直接闭合标签两种方式实现。

对于隐藏的表单，一般通过闭合属性成功率更高，应为，再标签间的注入使用了<>，而这两个符号一遍会被网站的安全措施过滤掉或者编码。还有就是，如果再input标签中，type字段在我们的输入点之后，我们可以通过在payload中重新定义type为text，如type="text"，这样就得到了一个寻常的输入框。

**js伪协议：**javascript:后面的内容会被当作js代码来执行，如果存在多条语句，需要用分号分割，且最后一条语句的执行结果会被输出在页面上，如果不想起输入在页面上，则使用一句void 0；来进行屏蔽

**data协议**： data:text/javascript;base64,base64编码后的js代码

**expression:**在style属性或者样式表文件中使用expression可以执行js代码，只对`IE浏览器`生效

`1；xss:expression(if(!window.x{alert(1);window.x=1;}))`  避免ie陷入死循环

html代码中属性的值可以通过没有引号、单引号、双引号、反单引号（ie浏览器）,故在探测的时候，应注意判断属性值的闭合方式。

输入的值若被js处理，我们可以通过闭合js代码的方式来插入我们需要的代码。如

`</script><script>alert(1)</script>//`  #闭合标签

或者

`";alert(1111)//(注释掉后面的那内容)` #直接闭合代码

如果`注释符号//被过滤了`可以通过使用算数运算符或者逻辑运算符的方式绕过，因为js是一门弱类型的语言，所以字符间的运算时可以的

**`<title><textarea><iframe><noscript><noframes><xmp>标签中的内容会被html编码，但<plaintxt>标签在firefox中不会被编码，但在chrome中会被编码，这可能导致在firefox中出现安全问题`** 

使用webkit内核的浏览器，获取textarea标签的innerHTML值的时候，内容不会被编码。

在PHP中通过$_SERVER['qurey_string']方法获取的查询字符串是urlencode编码后的字符串，而通过$_GET['quret_string']方法获取的查询字符串是urlencode编码前的字符串。

不同浏览器针对特殊字符的url编码策略不一致导致可能存在安全漏洞

firefox:编码了'"<>`

chrome:编码了<>

IE：不做任何编码

这导致如果服务端针对url中用户的输入部分不做任何过滤，那么IE浏览器中将出现漏洞，chorme中会出现一些漏洞，firefox相对较安全。

在chorme浏览器中，#后的所有内容都不会被编码，故通过该方法我们可以在chorme下触发DOMXSS攻击。（实际上会被chorme的xss filter拦截掉，我们需要突破这层拦截）

DOM的修正式渲染，浏览器会在渲染dom树的时候对html内容进行修正，也叫DOM重构，DOM重构分为静态重构与动态重构，其差别在于有没有js的参与，修正包括下面的内容：标签正确闭合、属性正确闭合。

### 字符与字符集导致的安全问题

**宽字节编码问题**

如果网页的编码方式时GBK\GB2312等宽字节编码则可能存在宽字节绕过风险

在PHP中如果开启了`magic_quotes_gpc=on`的话则可能触发宽字节注入。且该功能是默认开启的，如果没有关闭该功能则存在风险。

GBK的编码是分为高字节与低字节两个部分的，如果在一个低字节钱前面出现了一个合法的高字节的话，这两个字节则会被认为表示一个字符，从而实现绕过。这里就体现出了magic_quotes_gpc开启的关键所在了。当该功能被开启时，输入的字符'"\等默认会被转义，也就是在前面添加一个\，该斜线的十六进制表示为0x5c，刚好出现在了GBK的低字节区域，那么如果其前面出现一个合理的高字节的话，这连个字节就会被认为表示一个字符，从而绕开转义实现突破。GB2312是被GBK兼容的，但\在GB2312的编码中并没有出现在其合理的低字节区域内部，按理说是不存在问题的，但浏览器在解析的时候，是将GB2312按照GBK的方式来进行解析的，这样同样会出现问题。

**UTF7导致的问题**

当前只有IE还支持对UTF7的解析

在ie6\7时代如果http的响应头中没有指定字符集编码方式或者声明错误，同时在meta未指定charset或指定错误，那么浏览器会判断响应内容中是否出现UTF7编码的字符串，如果存在，当前页面将会按照UTF7的方式进行解码。

可以通过<link>标签来引入外域的utf7编码的css文件，在css文件中通过`expression`来执行js代码

**BOM(标记字节顺序码byte order mark),只**出现在unicode字符集中，bom出现在文件的开始文职，软件通过判断bom来判断他的unicode字符集的编码方式，如果发现了+/v8这样的字符，那么则以utf7的方式来解析网页，从而绕过过滤机制。在实践中，能够控制网页开头部分的功能为：用户自定义的css样式温江，jsoncallback类型的来连接，出现在web2.0中。防御这类的攻击最有效的方式是强制在文件的开头加上一个空格。

**绕过XSS Filter**

响应头`CRLF`注入绕过

`CRLF,即回车换行符`，在windows表示新的一行，回车，即在同一行但回到行首，换行，上移一行但水平位置不变。

如果网页存在CRLF注入，在HTTP协议中注入回车换行符（%0d%0a）就可以注入头部，因为url只有第一行是头部，换行回车后的内容会被当成响应内容响应回来。可以通过这种方式注入`X-XSS-Protection:0` 来关闭XSS Filter

同域白名单

iE浏览器通过referer判断是否来自同域，如果是则xss filter不生效。可通过嵌入`<a>`标签或者`<iframe>`标签来达到同域的目的

chrome浏览器如果是通过`<script>`嵌入的同域内的`js`文件，`XSS` Filter则完全不会工作。

场景依赖性高的绕过

如果输入内容直接出现在js代码中，这样XSSfilter就无法防御。

如果php开启了GPC功能，那么可以给通过在payload中插入%00来在IE中实现绕过。因为%00会被转换为\0

### 代码混淆

**进制常识**

html代码中可以识别`十进制与十六进制`两种，通过&#12; 表示十进制，&#x2f表示十六进制。

css中能够兼容html代码的进制表示方式，css中可以使用\6c这样的1x6进制表示方式。编码的时候注意要将css属性的：留出来不能编码，否则不能正确解析。

js中能过够直接执行带有`八进制与十六进制`的两种编码方式。这两种进制可以直接被js代码识别并执行，八进制用\23表示 十六进制用\x2e表示。这两种方式只能给单字节编码也就是ascii码，如果出现了多字节编码，则需要通过16进制来表示。\u2345。十进制虽然不能直接执行，但可以通过`String.fromCharCode(code,jinzhi)`来解码，然后再交给eval函数执行。

十进制的数字可以指定位数，不足的通过0来补齐，如&#1234; &#0024; 这种。`这种特性可以利用来绕过过滤策略` 当然，位数有时候还受到浏览器本身的限制。

**JS加解密**

js提供了三对编解码函数

1. escape|unescape
2. encodeURI|decodeURI
3. encodeURIComponent|decodeURIComponent

上述三个函数不编码的字符从上到下依次减少，所以使用第3个相对比较安全

**HTML中的代码注入技巧**

**标签中的注入**

1. HTML代码不区分大小写，可以通过大小写来实现混淆
2. HTML标签存在优先级的问题，甚至有的优先级高的标签可以截断其他的标签，从而瞒过过滤器。如`<style><title>`标签
    1. `<title><a href="<title><img src=x onerror=alert(1111)>//">` #过滤器认为是一个title标签加一个a标签，浏览器认为是一对title标签加一个img标签。
    2. 如果上述标签被过滤了可以尝试使用如下方式
        
        ```html
        1. <? foo="><script>alert(1111)</script>">
        2. <! foo="><script>alert(1111)</script>">
        3. </  foo="><script>alert(1111)</script>"># 前三种再firefox和webkit内核中有效
        4. <% foo="%><script>alert(1111)</script>> #IE中有效
        ```
        
3. 可以再HTML代码中插入xml代码、svg代码、和未知标签来瞒过过滤器
    1. `<xss style="xss:expression(alert(1111))">` #通过该方式再IE中执行插入的代码，可以瞒过过滤器
4. 使用少见的标签绕过过滤器
    
    ```html
    1. <isindex action="javascript:alert(1111)">
    2. <BGSOUND SRC="javascript:alert(111)">
    3. <meta http-wquiv="refresh" content="0;javascript:alert(111)">
    ```
    
5. 通过分析过滤器的缺陷构造可以绕过的语句
    1. 如果代码中过滤注释的语句是这样的`<!—.*—>`则可以构造这样的语句`<!—aaa <!—bbb—> ccc—>ddd` 这样ccc就被暴露出来了
    2. 如果代码中对注释没有做过滤则可以构造如下的语句 `<!—<a href="—><img src=x onerror=alert(111)//">test</a>,`对过滤器来书注释是不存在的，那么过滤器会认为上述语句为一个a正常的a标签，但对浏览器来说，上述则是一个img标签。
6. 针对IE浏览器的特殊语句
    
    ![](9bc82c060f205c9654462f96a831bb4.jpg)
    

**属性中的注入**

1. 属性值大小写不敏感、引号不敏感，IE中可以给使用`
2. 标签与属性、属性名与等号、等号与属性值之间可以用空格、换行符、回车符、过着tab等替代
3. 可以再属性的头部与尾部加上ascii中的控制字符 如&#32
4. js中一个函数可以在另一个函数中执行
    
    ```html
    1. <a href="#" onclick="do_some_func('',alert(111),'')">
    2. <a href=# onclick="do_some_func('',functiong(){alert(11);alert(22)},'')"> #执行多条语句应定义匿名函数
    ```
    
5. 资源类属性后面可以添加伪协议，当然该功能现如今已经被屏蔽了，不过IE6是支持的，不过`<iframe>`中的伪协议并没有被屏蔽
6. 可以利用url的@属性绕过
    
    如要求输入url地址如下，src=http://www.baidu.com，其中rul部分是我们需要构造payload的地方，如果该处的特殊字符被过滤掉了，我们则可以通过外部引入js代码的形式绕过，如
    
    src=http://www.baidu.com@www.hack.com/inject.js 这样@前面的内容就被当作了用户名。
    
7. 支持伪协议的不常见标签属性
    
    ```html
    <img dybsrc="javascript:alert('xss')">(IE6)
    <img lowsrc="javascript:alert('xss')">(IE6)
    <isindex action="javascript:alert('xss')">
    <input type="img" src="javascript:alert('xss');">
    ```
    

**事件**

**CSS中的代码注入技巧**

css分为选择符、属性名、属性值、规则（@charset）、声明（!import）

css代码中我们可以插入代码的部分只有资源类属性值和@import规则

css属性名的任何地方都可以插入反斜线\一家反斜线加0的各种组合

@im\po\rt "url" //引入一段css代码

@im\po\0000000rt "url"

声明总包含!import故，该针对该方法的过滤效果并不好，给了我们可乘之机

使用expression方法在IE中执行js代码，不过直接插入该方法会导致，插入的数据在页面中一致循环，我们需要用语句限制这种循环

```jsx
expression(if(window.x!=1)(alert(1);window.x=1;));
```

我们可以通过注释来混淆expression方法

```jsx
body{xss:ex/**/pressi/**/on((window.x==1)?'':eval('x=1;alert(33333)'));}
```

IE6中可以通过使用全角字符绕过

编码绕过