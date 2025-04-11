---
title: PHP代码执行
tags:
  - PHP
  - 代码执行
  - 漏洞原理
categories:
  - - 漏洞原理
description: 本文列举了以下常见的PHP代码执行函数
abbrlink: d5b96b72
date: 2025-04-11 10:47:48
---

# PHP CODE INJECTION

可以注入PHP代码直接执行的漏洞

一般都是后台使用了eval 函数，将我们的输入直接作为eval函数的参数，从而是的恶意的命令被执行

## create_function

create会创建一个匿名函数，第一个参数是传入的参数，第二个参数是函数体

`create_function(args,code)` 返回回个函数名字符串

如

```php
$newfunc = create_function('$a,$b', 'return "ln($a) + ln($b) = " . log($a * $b);
```

函数的执行过程

```php
function newfunc(){    
	return "ln($a) + ln($b) = " . log($a * $b);
}
```

**案例一：**漏洞代码

```php
<?php
	error_reporting(0);
	$sort_by = $_GET['sort_by'];
	$sorter = 'strnatcasecmp';
	$databases=array('1234','4321');
	$sort_function = ' return 1 * ' . $sorter . '($a["' . $sort_by . '"], $b["' . $sort_by . '"]);';
	usort($databases, create_function('$a, $b', $sort_function));
?>
```

payload

```php
http://localhost/test1.php?sort_by=%27%22]);}phpinfo();/*
```

还原执行过程

```php
$sort_function = ' return 1 * ' . $sorter . '($a["' . $sort_by '"]);}phpinfo();/*
```

匿名函数执行

```php
function niming($a,$b){
	return 1 * ' . $sorter . '($a["' . $sort_by '"]);}phpinfo();/*	
}
```

## call_user_func

`call_user_func(yourfunc,yourargs)` //将参数传入函数，可传多个

## call_user_func_array

`call_user_func_array(yourfunc,yourargsarray)` //将索引数组的元素作为函数的参数

## assert

## eval

## system

array_map

array_filter

array_walk