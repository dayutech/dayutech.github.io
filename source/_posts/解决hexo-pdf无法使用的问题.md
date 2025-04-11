---
title: 解决hexo-pdf无法使用的问题
tags:
  - hexo
  - hexo-pdf
description: 本文介绍了如何解决hexo-pdf插件不生效的问题
categories:
  - - bug修复
  - - tips
abbrlink: e9ccef3c
date: 2025-04-11 10:40:10
---
下载`hexo-pdf`后，修改`index.js`中的代码将`tag`名修改为非`pdf`即可  
我这里修改为`pdfpath`
之前修改为`pdf-path`也不能正常运行，pdf应该时不能单独出现的
```js
/**
* hexo-pdf
* https://github.com/superalsrk/hexo-pdf.git
* Copyright (c) 2015, superalsrk
* Licensed under the MIT license.
* Syntax:
* {% pdf http://yourdoman.com/x.pdf %} %}
**/

var ejs = require('ejs'),
    path = require('path'),
    fs = require('fs')

hexo.extend.tag.register('pdfpath', function(args){
  var htmlTmlSrc = path.join(__dirname, 'reader.ejs');
  var htmlTml = ejs.compile(fs.readFileSync(htmlTmlSrc, 'utf-8'))

  var type = 'normal';
  var pdfLink = args[0];

  if (pdfLink.indexOf('.pdf') > 0) {
  	type = 'normal'
  }
  else if(pdfLink.indexOf('drive.google.com') > 0) {
  	type = 'googledoc'
  }
  else if(pdfLink.indexOf('www.slideshare.net') > 0) {
  	type = 'slideshare'
  }
  return htmlTml({"src": args[0], "type" : type});
 
  
});


```
