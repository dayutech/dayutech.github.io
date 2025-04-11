---
title: 解决hexo图片访问遇到图床防盗链无法访问的问题
tags:
  - hexo
  - hexo-renderer-marked
  - 图床
  - 防盗链
categories:
  - [bug修复]
  - [tips]
abbrlink: '53e2963'
date: 2025-04-11 10:47:48
---
我的`hexo`使用的时`hexo-renderer-marked`渲染引擎，在该引擎的`lib/renderer.js`文件中搜索`img`关键字  添加标签属性`referrerpolicy="no-referrer"`即可
```js
image({ href, title, text }) {
    const { options } = this;
    const { hexo } = options;
    const { relative_link } = hexo.config;
    const { lazyload, figcaption, prependRoot, postPath } = options;

    if (!/^(#|\/\/|http(s)?:)/.test(href) && !relative_link && prependRoot) {
      if (!href.startsWith('/') && !href.startsWith('\\') && postPath) {
        const PostAsset = hexo.model('PostAsset');
        // findById requires forward slash
        const asset = PostAsset.findById(join(postPath, href.replace(/\\/g, '/')));
        // asset.path is backward slash in Windows
        if (asset) href = asset.path.replace(/\\/g, '/');
      }
      href = url_for.call(hexo, href);
    }

    let out = `<img src="${encodeURL(href)}" referrerpolicy="no-referrer"`;
    if (text) out += ` alt="${escape(text)}"`;
    if (title) out += ` title="${escape(title)}"`;
    if (lazyload) out += ' loading="lazy"';

    out += '>';
    if (figcaption && text) {
      return `<figure>${out}<figcaption aria-hidden="true">${text}</figcaption></figure>`;
    }
    return out;
  }
```
