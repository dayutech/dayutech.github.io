---
title: 一次失败的JAVA代码审计-SQL注入
tags:
  - SQL注入
  - 代码审计
categories:
  - - 漏洞分析
  - - 代码审计
description: 本文介绍了 一次失败的JAVA代码审计-SQL注入
abbrlink: b8d90c0d
date: 2025-04-14 10:33:52
---

本次审计的CMS系统为UJCMS最新版。立足于我现在的审计水平暂时是没有发现该系统的漏洞的，拉胯。本来今天晚上跟一个SQL注入的点跟的本来都要大功告成了，结果被当头棒喝，学会了什么叫人生的参差。废话不多说直接开干。
直接在整个项目中搜索关键字 `order by ${`
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/82739f44b0d9fd7572daa223c583c0be.png)
那么如果这个`queryInfo.orderBy`可控的话就皆大欢喜了，目前来看有很大机会
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/46b91c4c867dea6874e9f5b174651dd2.png)
这里注意到order by 是在一条id为`Select_ALL`的语句中，对应的`mybatis`文件名为`SeqMapper.xml`，最开始的时候我就去找对应名称的`DAO`层实现类，结果一直没有找到。最后迫不得已直接来了个全局搜索
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/254a328e59662d472abdba7abd98d13f.png)
注意到`Select_ALL`出现在其他的`mybatis`映射文件的`include` 标签里，这个标签就和php里的include或者require一个功能，用作代码复用。那么我们随便进入一个`mapper.xml`，这里以`Article.mapper`为例。
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/82b1150a5d9c2d9bc9318d3b99103b37.png)
这里的sql语句id为`selectAll`，返回值类型为`ResultMap`，然后找到对应的`DAO`层实现类
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/4ab6fbb786f6ba96f10eb785e26d3065.png)
注意到这里是个接口而不是实现类，这是因为`@Mapper  @Repository` 这两个注解的功劳@Mapper可以使接口在编译时自动生成器实现类，@Repositry注解帮助实现自动注入。然后就是取找对应的`Services`层，这里也是去找对应文件名，不出意外是`ArticleService.java`
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/8f4a52e3de92113b3c20724aa72956ae.png)
看到这里注入了`AticleMapper`，然后在在当前文件搜索哪里调用了`selectAll`方法
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/518c76667202e3f11ddd6ca906bff8e8.png)
然后就是找对应的控制器
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/e1897c2399c77c6629719e39e9d52bf5.png)
这么多，根据命名的规则，我们直接进入`ArticleController`
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/1ee837af9def4c318f55e9699ea9b466.png)
然后搜索有没有调用`AritcleService.selectAll`方法的语句，一搜，啪，没有咋整，不要换，在回去`ArticleService`里面看看有没有类本地的调用
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/718dab1f95329a3b947da5e612dda9c8.png)
`selectList`方法调用了，再回到`ArticleController`看看有没有调用`selectList`方法
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/99ef6f21f07c0a3b05bf5d4b44cbbc79.png)
这儿调用了，对应的路由为`/api/article`
然后就是看参数是否可控了，这里我么你可以控制的参数有三个，分别是`params,queryMap,customsQueryMap`
看看这三个参数怎么来的，跟到对应的query函数
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/bbf42a23df56077d010c3608e991ad8e.png)
在`query`函数中为上述三个参数赋值，`params`来自客户端传的参，`queryMap`与`customsMap`同样来自于客户端传的参，不过有要求，参数中前缀为`Q_`的参数会被添加到`queryMap`，前缀为`custom`的参数会被添加到`customsMap`中，然后调用`ArticleListDirective.assemble`对`queryMap`参数进行处理，跟进去看看
该函数前面都不重要，直到最后一条语句
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/714c1936bd2e7b019ab31c6801599133.png)
这里就有处理`orderBy`了，注意到有一个默认值，如果搞不好就得使用这个默认值，我们当然是不想的。
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/e487e7b309c50c8a857d125af9804d8f.png)
调用`getString`函数进行处理，然后把结果添加到`queryMap`中，跟进`getString`
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/4335735042134ca1845e7eadff1f535b.png)
重点来了，敲黑板，要考，注意到如果value为空则使用默认值，不为空则使用从param中获取的值，简直皆大欢喜啊。。。。
这时候我们只需要传参`orderBy=xxxx`就可以控制value的值了，简直完美，然后接着往下走。接下来queryMap会被传入到`selectList`函数
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/afb5e6d4b004c18036df1cfa52cb0846.png)
然后传入`selectAll` 然后mybatis从queryInfo中获取到orderBy的值，然后拼接到sql语句中，注入完成，于是我就试了下，然后就报错了。。。。。
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/6ed045dfdeee0302e085577626fa6481.png)

哦豁，白名单，完蛋。到这里基本上就失败了，不过我们还要去看一看怎么拦的，这里报错注意到是在`QueryParser`解析的时候限制了白名单，最后定位到这里
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/791ada2e53ee84118d82feb21c5eb9b0.png)
跟进去
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/3768c9c3ce96f2e60702fe9c3fe0c8dd.png)
继续到parse函数最后一行
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/4e6fda6669c7b46c6f08dfdf4aebf804.png)
跟进`parseOrderBy`
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/99806a2b16e0e7ea3777e19f7029ae2f.png)
他妈的，我一眼就注意到这里的`preventInjection`，进去看看
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/aa41d49a6862016da9fcd45c4a4784b8.png)
。。。。根源在这里
