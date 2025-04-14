---
title: 解决hexo内嵌js无法加载问题
date: 2025-04-14 10:33:52
tags:
- hexo
- pjax
categories:
  - [bug修复]
  - [tips]
---
检查网站是否开启了`pjax`  
查看主题配置文件，搜索关键字`pjax`   
如果`pjax`的值为true，则证明开启了，此时若要使得内嵌`js`在每次访问时都能够执行在`js`标签上添加`data-pjax` 属性即可  
```js
<script data-pjax type="text/javascript">
xxxx
</script>

```
