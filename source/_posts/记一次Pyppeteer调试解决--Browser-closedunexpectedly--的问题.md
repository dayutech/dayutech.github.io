---
title: 记一次Pyppeteer调试解决--Browser closed unexpectedly--的问题
date: 2025-04-14 10:33:52
tags:
- pyppeteer
categories:
  - [bug修复]
  - [tips]
---

事情是酱婶儿的：
我曾经是个靓仔，可后来我妈来了.......
她告诉我过年想抱孙子.....
我说，啊，这.......
我不做靓仔很多年了......
这种事去找幺娃子就好了..........
emo........
<!--more-->


我写了一个脚本监控先知、freebuf以及安全客论坛上面的文章更新，因为先知恶心的反爬虫机制所以使用了Chromium无头浏览器配合pyppeteer来进行监控，前两天运行的很丝滑，但今天运行的时候发现界面一直卡住不动，就像下面这样子：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/b9a60352e0de708de86823eac1feddae.png)
这能认吗，这不能忍。于是我：
找到了万能的小冰，小冰不知所措，呸，垃圾；
找到了度娘，度娘不知所措，呸，垃圾；
找到了谷哥，谷哥不知所措，呸，垃圾；
还有什么垃圾尽管放马过来？
在座的都是垃圾。
忍无可忍之下我只好艰难得爬起来尝试着定位问题在哪。
通过不断的print，定位到了这儿：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/d8c29df09f7bf126443dfc2902b1e9fb.png)
只打印4，2让你吃了？
30秒后。。。。。报错了：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/8eaedcd35755b6a89156748de6f54a5d.png)
浏览器不知所措：
果断打断点，进到lunch方法里面：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/69aa61a0c95bfdd6ff5fd4adfd475269.png)
Launcher类的launch方法，先对Launcher类进行初始化：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/56a46c6eb13a64c10ba32e719c249fe5.png)
没啥屌用，不过我还是看了好久，怕错过什么，我一步一步看的，还是有收获，然后调用launch方法：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/573dab837eb35425fa50c1944a4fc1ac.png)
注意Popen方法：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/b1734163dcbcf28653a960faa0fb121e.png)
此处执行系统命令，打开了chromium浏览器：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/c0669cb626fdf0f2b5859a07c21c5b3d.png)
然后当我单步到上图红框执行完之后pycharm就停住了，30s后系统crash了，所以问题就出在上图断点处，进去：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/0e378c98e7a2052e00b3432fbef52fd6.png)
这里调用urlopen方法访问了`http://127.0.0.1:64443/json/version`，然后当我再往下的时候，就进入了except里面，证明里面出错了，大概率是url请求出错，所以我在浏览器访问了一下这个资源：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/93143ec440760a0710a12020fdd9616a.png)
很丝滑，讲道理不会报错才对，不信邪的我又在其他文件用urlopen打开了一下这个资源：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/5b786080484a93e6ecdcd5cd2a227f19.png)
bingo!!报错了，但是为什么了，我又换了request请求了一次：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/79e0fc1ee4fc3bf1dc874c4d0e005db1.png)
又报错了，而且提供了我们更多的信息，ProxyError。这尼玛，急的我立马去查了下我所有的代理发现都是关着的.....
裂了，后来上网搜了搜代理可以通过命令行配置，可以在高级系统设置里面看到有没有一个http_proxy的字段。我一看，尼玛，还真有：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/a6875f0b92a546027f4d3405d8294d4a.png)
他娘的，果断删除，重启pycharm运行：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/9ab74e0be63933b527fcef27aba51d6d.png)
丝滑，打完收工！！！
不过这个代理他么哪来的呢？？
想起来了，昨晚复现GLPI的一个漏洞安装环境要安装PHP的composer，这个垃圾玩意儿当时让我设置个代理，还不能取消。最后环境也没有打起来，简直太坑了。
