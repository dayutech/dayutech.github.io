---
title: xerces XML解析特性使用不当导致XXE漏洞
tags:
  - xerces
  - xxe
top: 997
description: xerces 特定版本设置XML解析特性时报错导致特性设置失败
categories:
  - - 漏洞分析
abbrlink: 88c5bdc8
date: 2025-11-17 15:02:28
---
核心思想就是说在 在`xerces 2.2.1` 及以下版本时 若首先设置的`feature`为 禁用 `Doctype ` 将会抛出异常 导致后续设置其他的安全特性失败，从而绕过防护产生漏洞。

[参考链接](https://www.modb.pro/db/220916)