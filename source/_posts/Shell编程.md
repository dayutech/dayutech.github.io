---
title: Shell编程
tags:
  - Shell编程
  - Shell
categories:
  - [安全技术]
  - [编程语言]
date: 2025-04-10 20:56:11
description: 本文介绍了Linux Shell的基本语法
---
# Shell编程

# 基本介绍

使用普通的文本编辑器即可编写,这里创建一个a.sh的shell脚本

开头第一行为 ： #! /bin/bash //目录表示shell类型

执行方法： cd到文件所在目录，./a.sh //注意不可直接写a.sh，如果这样写系统会到环境变量的path项中添加的目录中去寻找该文件执行，因为往往我们的shell脚本并没有在这些目录里面则系统无法找到该文件。

# 变量

## 定义变量

```bash
var="armandhe"
echo $var
```

等号两端不能有空格

## 使用变量

```bash
var="armandhe"
echo "I am ${var}you son of bitch!"
```

{}用于定义变量边界

## 只读变量

```bash
var="armandhe"
readonly var
echo "I am ${var}you son of bitch!
var="hejixiong"  #修改只读变量会报错
```

## 删除变量

```bash
var="armandhe"
unset var
```

不能删除只读变量

## shell变量

**局部变量：**shell脚本中定义的变量，只能在脚本中使用

**环境变量：**所有的程序，包括shell启动的程序都可以访问环境变量

**shell变量：**由shell程序设置的特殊变量，有一部分是环境变量有一部分是局部变量

# 字符串

## 简介

可以使用单引号也可以使用双引号

单引号中的内容原样输出

双引号中的内容可以包含变量，

\ 为转义标志

```bash
var="armanhe"
echo 'nihao'
echo "nihao"
echo "nihao \"${var}\""
```

## 字符串长度

```bash
var="armandhe"
echo ${#var} #输出8
```

提取子字符串

```bash
var="armanhe"
echo ${var:1:3} # 输出rma
```

# 数组

通过下标访问，下标的开始值为0，只有一维数组，且无大小限制

```bash
array1=(1 2 3 45 56 43)
array2=(
1 
2 
3 
45 
56 
43
)
declare -A array4 #声明数组
array3[0]=1
array3[1]=134
array3[2]=145
array4[234]=44
echo ${array1[0]}
echo ${array1[@]} #获取数组中所有元素

```

获取数组长度

```bash
array=(1 2 3 45 56 43)
echo ${#array[@]}
echo ${#array[*]}
echo ${#array[n]} #获取数组中某个元素的长度

```

多行注释

```bash
:<<EOF
多行注释
echo ${#array[@]}
echo ${#array[@]}
echo ${#array[@]}
EOF
```

参数传递

```bash
#! /bin/bash
# 文件名a.sh
echo "脚本名为$0"
echo "第一个参数为$1"
echo "第二个参数为$2"
echo "第三个参数为$3"
```

chmod +x a.sh

./a.sh 12 "hjx" 'red'

[Untitled](Untitled%20521b7c9be779487aaeb0ad68a1ad16fa.csv)

# 流程控制

## if else

```bash
$a=10
$b=12
if [$a -gt $b]
then
	echo [$a + $b]
elif $a -eq $b
then
	echo [$a - $b]
else
	echo [$a \* $b]
fi
```

## for

```bash
for i in `ls`
do
	echo $i
done
for (i=1;i<10;i++);do
	echo $i
done
```

## while

```bash
int=1
while(($int<=5))
do
	echo $int
	let "int++" #使用let命令，在变量计算中就不需要加上$
done
```

## until

```bash
a=0
until [! $a -lt 10]
do 
	echo $a
	a=`expr $a + 1`
done
 
```

当条件不成立的时候执行代码块

当条件成立时跳出循环，与while正好相反

## case ... esac

```bash
read num
case $num in
	1) echo '你选择了1'
	;;
	2) echo '你选择了2'
	;;
	*) echo '请正常输入'
esac
```

# 函数

```bash
function test(){
	echo '这是一个函数'
	echo $1 $2
	return $1 $2
}
test 1 2
func=function{
	#body
}
```

# 输入输出重定向

[Untitled](Untitled%20569327758ca8421ebe2a12f906547f30.csv)

# 文件包含

. filename

source filename