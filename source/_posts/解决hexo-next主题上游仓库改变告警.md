---
title: 解决hexo-next主题上游仓库改变告警
date: 2025-04-14 15:01:23
tags:
- hexo
- hexo-next
- The upstream repository of theme NexT has been changed
categories:
- [bug修复]
- tips
---

找到安装的`hexo-next-title hexo-next-share hexo-next-exif hexo-next-utteranc`等插件的安装目录 在其目录下找到`node_modules`目录  
观察是否存在 `next-util` 目录，若存在打开该目录中的`index.js`进行修改  
注释调添加的`before_generate`过滤器  
```js
'use strict';

const yaml = require('js-yaml');
const fs = require('fs');
const path = require('path');
const { merge } = require('lodash');

module.exports = function(hexo, pluginDir) {
  hexo.extend.filter.register('before_generate', function err() {
    //hexo.log.warn(`The upstream repository of theme NexT has been changed.`);
    //hexo.log.warn(`For more information: https://github.com/next-theme/hexo-theme-next`);
    //hexo.log.warn(`Documentation: https://theme-next.js.org`);
  });
  this.hexo = hexo;
  this.pluginDir = pluginDir;
  this.getFilePath = function(file) {
    return this.pluginDir ? path.resolve(this.pluginDir, file) : file;
  };
  this.getFileContent = function(file) {
    return fs.readFileSync(this.getFilePath(file), 'utf8');
  };
  this.defaultConfigFile = function(key, file) {
    const defaultConfig = file ? yaml.safeLoad(this.getFileContent(file)) : {};
    this.hexo.config[key] = merge(defaultConfig[key], this.hexo.theme.config[key], this.hexo.config[key]);
    return this.hexo.config[key];
  };
};

```
