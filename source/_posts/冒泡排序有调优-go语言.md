---
title: 冒泡排序调优 go语言
tags:
  - 冒泡排序
  - Golang
categories:
  - - 算法
description: 本文简要介绍了 冒泡排序 的Go语言实现方案
abbrlink: 7473afbd
date: 2025-04-14 10:33:52
---

# 常规做法
```go
package main

import "fmt"



func main()  {
	origin := [...]int{1,223,3,4,34,3545,3,4,23,56,78,89,345,2377,3457,6777}
	fmt.Println(origin)
	//冒泡排序 与调优
	//lastExchangeIndex := 0
	//sortBorder := 0
	for i := 0; i<len(origin);i++{
		fmt.Println(i)
		//isSorted := false
		for j := len(origin)-1; j>i;j--{
			if origin[j]<origin[j-1] {
				tmp := origin[j-1]
				origin[j-1] = origin[j]
				origin[j] = tmp
				//isSorted = true
				//lastExchangeIndex = j
			}
		}
		//sortBorder =lastExchangeIndex
		//if !isSorted{
		//	break
		//}
	}



	fmt.Println(origin)

}


```


# 一次优化

```go
package main

import "fmt"



func main()  {
	origin := [...]int{1,223,3,4,34,3545,3,4,23,56,78,89,345,2377,3457,6777}
	fmt.Println(origin)
	//冒泡排序 与调优
	//lastExchangeIndex := 0
	//sortBorder := 0
	for i := 0; i<len(origin);i++{
		fmt.Println(i)
		isSorted := false
		for j := len(origin)-1; j>i;j--{
			if origin[j]<origin[j-1] {
				tmp := origin[j-1]
				origin[j-1] = origin[j]
				origin[j] = tmp
				isSorted = true
				//lastExchangeIndex = j
			}
		}
		//sortBorder =lastExchangeIndex
		if !isSorted{
			break
		}
	}



	fmt.Println(origin)

}

```

当某一次排列没有发生位置交换时证明已经完成排序


# 二次调优

```go
package main

import "fmt"



func main()  {
	origin := [...]int{1,223,3,4,34,3545,3,4,23,56,78,89,345,2377,3457,6777}
	fmt.Println(origin)
	//冒泡排序 与调优
	lastExchangeIndex := 0
	sortBorder := 0
	for i := sortBorder; i<len(origin);i++{
		fmt.Println(i)
		isSorted := false
		for j := len(origin)-1; j>i;j--{
			if origin[j]<origin[j-1] {
				tmp := origin[j-1]
				origin[j-1] = origin[j]
				origin[j] = tmp
				isSorted = true
				lastExchangeIndex = j
			}
		}
		sortBorder =lastExchangeIndex
		if !isSorted{
			break
		}
	}



	fmt.Println(origin)

}


```

在一次调优的基础上记录上一次排列最后一次发生交换的位置，那么之后的位置都是没有发生交换的，所以下一轮交换从上一轮最后一次调优的位置开始

