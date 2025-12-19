---
title: 机器学习-没有免费的午餐（NFL）
abbrlink: 10efd2fb
date: 2025-12-18 15:28:16
tags:
- NFL
categories:
- - 机器学习
mathjax: true
top: 1005
description: 没有免费的午餐定理告诉我们，任何事都要放到具体的环境中取讨论，脱离了实际去讨论问题是没有意义的。实践是检验一切真理的标准。
---
假设样本空间$\chi $和假设空间$H$都是离散的。令 $P(h\|X,\mathfrak{L}_a)$ 代表算法$\mathfrak{L}_a$经过训练样本$X$产生假设$h$的概率，在令$f$表示我们希望学习到的真实目标函数。  
$\mathfrak{L}_a$的训练集外误差为： 

$$
E_ote(\mathfrak{L}_a \mid X, f) = \sum_h \underset{x \in \mathcal{X} - X}{\sum} P(x)\mathbb{I}(h(x) \neq f(x))P(h \mid X, \mathfrak{L}_a)
$$

| 符号 | 含义 |
|------|------|
| $ E_{\text{ote}} $ | **期望总误差（Expected Total Error）**，衡量分类器在未见样本上的平均错误率 |
| $ \mathfrak{L}_a $ | 某个特定的**学习算法**或**学习策略**（如决策树、SVM 等） |
| $ X $ | **训练集**（已观测数据） |
| $ f $ | **真实标签函数**（ground truth），即 $ f(x) $ 是输入 $ x $ 的真实类别 |
| $ \mathcal{X} $ | **整个输入空间**（所有可能的输入样本集合） |
| $ \mathcal{X} - X $ | **未见样本集**，即不在训练集中的输入点（测试/泛化样本） |
| $ h $ | 一个**假设**（hypothsis），即由学习算法生成的一个分类器（如某个决策规则） |
| $ P(x) $ | 输入 $ x $ 的**先验概率分布**（即 $ x $ 出现的概率） |
| $ \mathbb{I}(h(x) \neq f(x)) $ | **指示函数（Indicator Function）**：<br>当 $ h(x) \neq f(x) $ 时取值为 1（分类错误）；否则为 0（正确） |
| $ P(h \mid X, \mathfrak{L}_a) $ | 在给定训练集 $ X $ 和学习算法 $ \mathfrak{L}_a $ 下，**产生假设 $ h $ 的概率**<br>→ 表示该学习算法输出 $ h $ 的可能性 |

对于二分类问题，且真实目标函数可以是任何函数$f$,函数空间为$2^{|\mathcal{x}|}$。对所有可能的$f$按照均匀分布对误差求和
$$
\begin{align}
\sum_f E_ote(\mathfrak{L}_a \mid X, f) &= \sum_f \sum_h \underset{x \in \mathcal{X} - X}{\sum} P(x)\mathbb{I}(h(x) \neq f(x))P(h \mid X, \mathfrak{L}_a)\\\\
&=\underset{x \in \mathcal{X} - X}{\sum}P(x) \sum_h P(h \mid X, \mathfrak{L}_a)  \sum_f P(x)\mathbb{I}(h(x) \neq f(x)) \\\\
&=\underset{x \in \mathcal{X} - X}{\sum}P(x) \sum_h P(h \mid X, \mathfrak{L}_a)\frac{1}{2}2^{|x|}\\\\
&=\frac{1}{2}2^{|x|}\underset{x \in \mathcal{X} - X}{\sum}P(x) \sum_h P(h \mid X, \mathfrak{L}_a)\\\\
&=\frac{1}{2}2^{|x|}\underset{x \in \mathcal{X} - X}{\sum}P(x) . 1
\end{align}
$$
即总误差与学习算法无关，也就是说对于任意两个算法都有
$$
\sum_f E_ote(\mathfrak{L}_a \mid X, f)=\sum_f E_ote(\mathfrak{L}_b \mid X, f)
$$
这就是“没有免费的午餐”定理。这个定理基于均匀分布，然而显式中的问题并不总是均匀分布的。这提示我们脱离了实际问题的理论是毫无意义的，任何高谈阔论都要以实践为基础。