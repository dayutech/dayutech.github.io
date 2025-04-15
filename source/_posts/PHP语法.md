---
title: PHP语法
tags:
  - PHP语法
categories:
  - - 安全技术
  - - 编程语言
description: 本文介绍了PHP的基本语法
abbrlink: '187503e5'
date: 2025-04-10 20:56:11
---
# php

# 流程结构

`break 2`：后可接数字，表示跳出循环的级数；

# 运算符

`a and b`: 将可能为false的值放在a的位置，以提高程序的运行速度；

`a or b` 将可能为true的值放在a的位置

例：`a or ++a` 自增的运算符优先级高于`or`,一般考虑当a初始值为10 `a`为`true`的情况下，则运算后的结果a为11。实际上应为`a`为`true,`系统不对a进行自增，而是以结果为导向，`a`并不会参加运算，实际上运算结束后其值为10。

# HEREDOC

![](Untitled.png)

# 数据类型

# 变量

## 局部变量

定义在函数内部的变量为局部变量，局部变量不能在函数外部被访问，随着函数的结束而销毁

```php
function test(){
	$a=4;
	echo $a; //正常
}
echo $a; //报错
```

## 静态变量

`static $a=1;`

```php
function test(){
	static $a=1;
	$a+=1;
	return $a;
}
test();//$a==2
test();//$a==3
```

静态变量再函数结束执行后从不会立即销毁，再下次调用该函数时静态变量中存储的值仍然有效，且静态变量只再第一次执行时声明。

## 全局变量

php所有得全局变量都存在与一个叫做$GLOBALS的数组总通过变量名可以访问该全局变量,要在函数中访问全局变量需要使用global关键字声明。

```php
<?php
$x=1;
$y=2;
function test(){
	$GLOBALS['x']=$GLOBALS['x']+$GLOBALS['y'];
}
test();
echo $x $y;
#输出结果x=3,y=2

?>
```

# 常量

```php
define("SRATIC","aramndhe") //常量大写
```

## 预定义常量

[预定义常量](%E9%A2%84%E5%AE%9A%E4%B9%89%E5%B8%B8%E9%87%8F%20b5c740a209d14e979cad2094d1486ade.csv)

# 函数

## 传参-应用传递与值传递

```php
$a=10;
$b=10;
function test($a,&$b){
	$a+=1;
	$b+=1;
}
test($a,$b);
echo $a,$b;
```

运算结束后`$a`的值仍然为10，`$b`的值为11。这就是php参数传递的两种不同模式，`$a`为值传递，再函数执行时，将`$a`的值复制一份到内存中生成一个新得值，此时函数中得`$a`相当于一个局部变量，参与函数的运算，故函数中的运算并不会对`$a`的原始值产生影响。而`&$b`则指引用传递，再运算过程中`$b`的相当于将其内存地址传到了函数中，此时`$a`相当于全局变量，函数中对`$b`的改变相当于对其本身值得改变。

## 不定长传参

```php
function test(){
	var_dump(func_get_vars());
}
test(12,45,565);
```

`func_get_vars,`运算结束后将答应输入的所有实参的值，用以实现函数的不定长参数。

```php
function test(){
	var_dump(func_get_var(0));
}
test(12,45,565);
```

`func_get_var`函数中传入形参的索引编号，获取对应索引的值。上例将会打印12。

```php
function test(){
	var_dump(func_num_args());
}
test(12,45,565);
```

`func_num_args` ，获取自定义函数传入参数的数量。

## 可变函数

```php
function test(){
	var_dump(func_num_args());
}
$a = "test";
$a(132,56,64);
```

可变函数，将函数作为一个对象赋值给一个变量。

## 递归函数

函数内部自己调用自己的函数被称为递归函数。

```php
<?php
function avc($n){
    echo $n.'&nbsp';
    if ($n>0){
        avc($n-1);
    }else{
        echo '<--->';
    }
    echo $n.'&nbsp';
}
avc(3);    ////////这个函数写错了，我在这儿写蒙了....................
```

# 类型比较

![](1791863413-572055b100304_articlex.png)

![](xxxxphp.png)

# 数组函数

[数组函数](%E6%95%B0%E7%BB%84%E5%87%BD%E6%95%B0%20c36bc961c2234b2f9955d25ff9d1f75a.csv)

# 字符串函数

[字符串函数](%E5%AD%97%E7%AC%A6%E4%B8%B2%E5%87%BD%E6%95%B0%209e0dd38fb42c476fa07841c726018d3b.csv)

# 正则表达式

[正则表达式](%E6%AD%A3%E5%88%99%E8%A1%A8%E8%BE%BE%E5%BC%8F%203ac58c6683e840f8b798762884e03849.csv)

# 日期与时间

[日期与时间](%E6%97%A5%E6%9C%9F%E4%B8%8E%E6%97%B6%E9%97%B4%20009dab6678b843d795c58fd0d31ab451.csv)

# 图像处理

[图像处理](%E5%9B%BE%E5%83%8F%E5%A4%84%E7%90%86%204a40796073364bba815921092123718f.csv)

# 文件操作

[文件操作](%E6%96%87%E4%BB%B6%E6%93%8D%E4%BD%9C%206c84a88d190340f7a6d6b7376b749978.csv)

# 上传文件

[上传文件](%E4%B8%8A%E4%BC%A0%E6%96%87%E4%BB%B6%20ae156639101b4f0da055f9cd7d43d828.csv)

# 下载文件

[下载文件](%E4%B8%8B%E8%BD%BD%E6%96%87%E4%BB%B6%20f402da2166bc4961bc505e65204939d5.csv)