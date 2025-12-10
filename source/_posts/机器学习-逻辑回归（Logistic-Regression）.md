---
title: 机器学习-逻辑回归（Logistic-Regression）
tags:
  - 机器学习
  - 逻辑回归
mathjax: true
top: 1001
categories:
  - - 机器学习
description: 本文简单介绍了机器学回归算法中的逻辑回归算法
abbrlink: aba9e754
date: 2025-12-08 10:53:40
---
# 概率密度
## 概率函数
用函数的形式表示概率：
$$
p_i=P(X=a_i)(i=1,2,3,4,5...)
$$
其中$p_i$表示某一个事件发生的概率，$P$则被称为概率函数。概率函数一次只能表示一个取值的概率，比如对于均匀分布事件来说，也就是说每一种情况发生的概率相等，比如抛硬币，扔骰子等，以扔骰子为例，1到6每一个点数朝上的概率为1/6，  
用概率函数表示就是$p_1=P(X=1)=1/6$。并且有
$$
\sum_{i=1}^{n}P(X=a_i)(i=1,2,3,4...n)=1
$$
## 概率分布
所谓概率分布就是随机变量的值与相应概率的对应关系，还是以扔骰子为例，
- 1朝上的概率为1/6，
- 2朝上的概率为1/6，
- 3朝上的概率为1/6，
- 4朝上的概率为1/6，
- 5朝上的概率为1/6，
- 6朝上的概率为1/6
无论以什么形式，只要将所有的随机变量与奇对应概率的对应关系表示出来得到的就是一个概率分布。
## 概率分布函数
同样，就是用函数的形式来表达概率分布
自创的公式   理解含义即可
$$
F(x)=\{\sum_{k=1}^{n}P(X=X_k)|n\le len(k)\}(k=\{1,2,3,4...\})
$$
其含义是 $F(x)$等于$X$取小于$X_k$的概率之和，故又称$F(x)$为累积概率函数。
## 概率密度函数
对一个随机事件来说，其每一种情况可能是有限个的，比如抛硬币、扔骰子，也有可能是无限个的，如一个人在一天种不同时刻的体重，将一个物体抛起其落到地面固定区域内某个点的坐标。
对于有限数量的事件，我们称为离散型随机事件，离散型随机事件不仅仅只能是有限个的其也有可能是无限个的，比如在一个数轴上，整数的取值便是离散的且是无限的，所以离散型随机事件被分为了有限个与无限个两种情况。
而连续型随机事件则在取值上是连续的，还是在一个数轴上，对于任意两个不想等的数，无论他们之间的差的绝对值有多小，他们之间永远都还有比小的那个数大 且比大的那个数小的数，这类事件就是连续型随机事件，比如上面提到的体重问题，扔物体到特定区域问题。  
有限个选择的离散型随机事件的概率很好算，比如扔骰子游戏，每个可能出现的概率都是1/6，而对于无限个选择的离散型随机事件以及连续型随机事件，这里讨论连续型随即事件，因为可选项的总数是无限的，而选择是单一的，那么某一个选择的概率就是$0$
$$
\lim_{n \to +\infty } \frac{1}{n}=0  
$$
以扔东西为例，也就是说扔出去的物体落在每一个点的概率都是0，这似乎是反常识的。虽然落在某一个点的概率都是0，但是落在不同的点的概率是有相对大小的。比如在一个凹凸不平的地面上扔东西，那么落在不同的点上的概率明显是不一样的，
但是每一个点的概率仍然都是0，这是由极限的性质决定的，比如：
$$
\lim_{x \to 0}\frac{x^{2}}{x}=0
$$
在这个例子中$x^{2}$趋于$0$的速度比$x$趋于$0$的速度要快，$x^{2}$是比$x$高阶的无穷小，虽然在趋于$0$的时候$X^{2}$与$x$的极限都是$0$但是$x^{2}$趋于$0$的速度要比$x$快的多，$x^{2}$是$x$的$2$阶无穷小
同样的，因为无穷小之间也有大小关系，那么无穷多个无穷小相加也就可能等于一个常数，在这里也就是1（概率总是不会超过1的）
$$
\sum_{i=1}^{\infty}p_i=1
$$
为了能够描述这种在不同点上概率的相对大小引入了概率密度函数。
如果一个函数$f(x)$满足下面的条件，那么则称它可以是一个概率密度函数。
$$
\int_{-\infty}^{+\infty} f(x)dx=1
$$
分布函数也可以使用概率密度函数来表示，其就是概率密度函数的变上限积分
$$
F(y)=P(X<y)=\int_{-\infty}^{y} f(x)dx
$$
而概率密度函数也可以表示成概率分布函数的导数
$$
{F}'(y)=f(x) 
$$
连续型随机事件在某一个点上的概率为0，但是在一个区间里概率是不为0的
$$
p(y_1<y<y_2)=\int_{y_1}^{y_2} f(x)dx=F(y_2)-F(y_1)
$$
# 极大似然法（Maximum Likelihood Estimate，MLE）
在随机事件的实验中，许多事件都有发生的概率，概率大的事件发生的可能就大。若只进行一次实验，事件A发生了，那么我们就认为概率A发生的概率比概率B,C,D..都大。
极大似然估计就是利用已知的样本结果，反推最有可能导致这种结果的参数值，这就是以点及面，一叶知秋。
极大似然法给出了一种给定观察数据来评估模型参数的方法，即："模型已定，参数未知"。通过若干次实验，观察其结果，利用实验到的数据得到某个参数值能够使得样本出现的概率最大，则称为极大似然估计。和线性回归模型参数的求解在方法论上很相似啊
例如，有一个模型包含有未知参数（$\theta_1,\theta_2,\theta_3,\theta_4...\theta_k$），还有一组含有N个样本的数据集D：
$$
D={x_1,x_2,x_3....,x_N}
$$
目标是求得一组$\hat{\theta}$使得数据集D出现的概率最大，定义似然函数（数据集D发生的概率，联合密度函数）：
$$
L(\theta_1,\theta_2,\theta_3,...,\theta_k)=p(x_1|\theta)p(x_2|\theta)p(x_3|\theta)...p(x_N|\theta)=\prod_{i=1}^{N} p(x_i|\theta)
$$
求解这个似然函数就是求一组$\hat{\theta}$使得L的值最大，此时的这一组$\hat{\theta}$就是$\theta$的最大似然估计值。
$$
\hat{\theta}=arg \underset{\theta }{\max }\prod_{i=1}^{N} p(x_i|\theta)
$$
求这个函数的最大值，那肯定需要求导来判断函数的递增递减关系，这个函数是一个累乘的函数，求导过程中需要用到链式求导法则，当参数的项数增多的时候求解的复杂度也逐渐增加，所以直接求导不是一个好方法。
对L取对数将乘法变成加法求导就简单多了，得到对数似然函数$H$
$$
H(\theta)=ln_{}{L}=ln_{}{\prod_{i=1}^{N} p(x_i|\theta)}
$$
对$\hat{\theta}$进行求解
$$
\hat{\theta}=arg \underset{\theta }{\max }H(\theta)=arg \underset{\theta }{\max }\sum_{i=1}^{N}\ln_{}{p(x_i|\theta )}   
$$
为什么能够取对数呢，因为取对数后不会影响似然函数的趋势
根据线性回归的经验，因为ln函数在数学上是一个凹函数，所以当其导数为0的时候就取得其极大值也就是最大值，所以只需要令每一个参数求偏导的值为0，求出相应的参数$\hat{\theta}$即可。
# 逻辑回归
## 对数几率函数
对于一个二分类问题来说，最终的结果只有两种可能，如果设其中一种可能的概率为$y$称为正例，那么另外一种可能的概率即为$1-y$称为反例。正例与反例的的比值称为几率（odds）
$$
odds=\frac{y}{1-y}
$$
给几率函数取自然对数得到对数几率函数
$$
\ln_{}{odds}=\ln_{}{\frac{y}{1-y}}
$$
在逻辑回归中假设对数几率函数与输入特征$x$呈线性关系
$$
\ln_{}{\frac{y}{1-y}}=\mathbf{w}^{T}\mathbf{x}+b
$$
对y进行求解得到
$$
y=\frac{1}{1+e^{-(\mathbf{w}^{T}\mathbf{x}+b  )} } 
$$
这就是`sigmoid`函数
## 逻辑回归
在逻辑回归问题中，我们假设两类数据通过一个线性函数进行分割，这个线性函数被称为决策边界
$$
\mathbf{w}^{T}\mathbf{x}+b
$$
当一个点落在决策边界上时有$\mathbf{w}^{T}\mathbf{x}+b=0$，当一个点落在决策边界的右边时有$\mathbf{w}^{T}\mathbf{x}+b>0$，当一个点落在决策边界左边时有$\mathbf{w}^{T}\mathbf{x}+b<0$，
也就是说当$\mathbf{w}^{T}\mathbf{x}+b>0$时，$\mathbf{w}^{T}\mathbf{x}+b$越大，正例发生的概率越大，如果不考虑具体的概率而是以$0$作为分界点，当$\mathbf{w}^{T}\mathbf{x}+b$大于0的时候则认为正例发生的概率为1，即100%发生
另外两种情况等同分析。整理一下即为：
$$
y=\begin{cases}
\space \text{0 },\space\space z<0 \\\\
\space \text{ 0.5 },\space\space z=\mathbf{w}^{T}\mathbf{x}+b \\\\
\space  \text{ 1 },\space\space z>0
\end{cases}
$$
那么现在需要一个函数能够将$\mathbf{w}^{T}\mathbf{x}+b$的值映射到$[0,1]$的区间上去，这就是前面提到的`sigmoid`函数了，
$$
\lim_{(\mathbf{w}^{T}\mathbf{x}+b) \to +\infty}{\frac{1}{1+e^{-(\mathbf{w}^{T}\mathbf{x}+b  )} } }=1
$$
$$
\lim_{(\mathbf{w}^{T}\mathbf{x}+b) \to -\infty}{\frac{1}{1+e^{-(\mathbf{w}^{T}\mathbf{x}+b  )} } }=0
$$
$$
\lim_{(\mathbf{w}^{T}\mathbf{x}+b) \to 0}{\frac{1}{1+e^{-(\mathbf{w}^{T}\mathbf{x}+b  )} } }=0.5
$$
因此逻辑回归的思路是，先拟合决策边界(不局限于线性，还可以是多项式)，再建立这个边界与分类的概率联系，从而得到了二分类情况下的概率。
## 求解参数
设
$$
\begin{align}
P(Y=1|x)&=p(x)\\\\
P(Y=0|x)&=1-p(x)
\end{align}
$$
那么似然函数为
$$
L(w)=\prod_{i=1}^{n}[p(x_i)]^{y_i}[1-p(x_i)]^{1-y_i} 
$$
这个式子之所以这么写是因为当某一个样本为正例的时候$y$的取值为$1$，则 $[1-p(x_i)]^{1-y_i} $的值为$1$，那么计算的概率为$p(x_i)$，当为反例的时候得到的就是$1-p(x_i)$  
取对数似然函数
$$
\begin{align}
\ln_{}{L(w)}&=\ln_{}{\prod_{i=1}^{n}[p(x_i)]^{y_i}[1-p(x_i)]^{1-y_i}} \\\\
&=\sum_{i=1}^{n}y_i\ln_{}{[p(x_i)]}+(1-y_i)\ln_{}{[1-p(x_i)]}\\\\
&=\sum_{i=1}^{n}y_i\ln_{}{[\frac{p(x_i)}{1-p(x_i)}]}+\ln_{}{[1-p(x_i)]}\\\\
&=\sum_{i=1}^{n}(y_i\ln_{}{(w.x_i+b)}+\ln_{}{(1+e^{(w.x_i+b)}}))\\\\
\end{align}
$$
根据前面对最大似然法的描述我们的目标就是求使得这个对数似然函数取最大值的$w$与$b$的值
不过我们这里的损失函数定义并不等于似然函数，而是对似然函数取平均数
$$
J(w)=\frac{1}{N}\ln_{}{L(w)}
$$
### 梯度下降法
由线性回归的经验，梯度变化的方向就是上升最快的方向，与梯度变化的方向相反就是下降最快的方向，这里因为损失函数$J(w)$在数学上式一个凹函数，那么我们要求得就是梯度上升最快的方向。
而梯度则是$J(w)$对$w$求偏导数。
$$
g_i=\frac{\partial J(w)}{\partial w_i} =(p(x_i)-y_i)x_i\space\space\space\text{这个式子怎么推出来的 这是个问题 需要研究}
$$

### 牛顿法求极值
#### 牛顿法
牛顿法的思想是设法将一个非线性方程$f(x)=0$转化为线性方程进行求解，这里就需要用到泰勒展开式。
泰勒公式
$$
\begin{align}
&p(x)=\frac{f'(x)}{1!}(x-x_0)+\frac{f''(x)}{2!}(x-x)^2+...+\frac{f^{(n)}(x_0)}{n!}(x-x_0)^n+R_n\\\\
&R_n(x)=O\[(x-x_0)^n]
\end{align}
$$
若要求方程$f(x)=0$的根，我们可以令$f(x)$的一阶泰勒展开作为$f(x)$的近似值。取$f(x)$上的一点$x_k$，在该点附近进行一阶泰勒展开。
$$
p(x)=f(x_k)+{f}'(x_k)(x-x_k)\approx f(x)
$$
得到线性方程
$$
f(x_k)+{f}'(x_k)(x-x_k)=0
$$
对该方程进行求解得到$x$
$$
x=x_k-\frac{f(x_k)}{f'{x_k}}
$$
设解出来的$x$为$x_{k+1}$,即：
$$
x_{k+1}=x_k-\frac{f(x_k)}{f'{x_k}}
$$
此时得到的$x_{k+1}$是$f(x)=0$的根的一个近似值，其并不等于$f(x)=0$的根，为了得到更加接近的值，
所以继续对$x_{k+1}$再做一阶泰勒展开直到得到的$x_{k+m}$与$k_{k+n}$的差的绝对值满足阈值要求或者达到指定的迭代次数，此时认为求得的$x_{k+n}$即为方程$f(x)=0$的近似根
**从图形的角度理解牛顿法**

<script>
function func(x) {
  return Math.exp(1/7*x) - 4;
}
function func2(x) {
  const expVal = Math.exp(20 / 7);      // e^(20/7)
  const slope = expVal / 7;             // (1/7) * e^(20/7)
  return slope * (x - 20) + (expVal - 4);
}
function func3(x) {
  const x0 = 14.609;
  const expVal = Math.exp(x0 / 7);
  const y0 = expVal - 4;
  const slope = expVal / 7;
  return slope * (x - x0) + y0;
}
function generateData2() {
  let data = [];
  for (let i = -200; i <= 200; i += 0.1) {
    data.push([i, func2(i)]);
  }
  return data;
}
function generateData3() {
  let data = [];
  for (let i = -200; i <= 200; i += 0.1) {
    data.push([i, func3(i)]);
  }
  return data;
}
function generateData() {
  let data = [];
  for (let i = -200; i <= 200; i += 0.1) {
    data.push([i, func(i)]);
  }
  return data;
}
</script>
{% echarts 600 '85%' %}
{
  
  animation: false,
  grid: {
    top: 40,
    left: 50,
    right: 40,
    bottom: 50
  },
  xAxis: {
    name: 'x',
    minorTick: {
      show: true
    },
    minorSplitLine: {
      show: true
    }
  },
  yAxis: {
    name: 'y',
    min: -100,
    max: 100,
    minorTick: {
      show: true
    },
    minorSplitLine: {
      show: true
    }
  },
  dataZoom: [
    {
      show: true,
      type: 'inside',
      filterMode: 'none',
      xAxisIndex: [0],
      startValue: 5,
      endValue: 25
    },
    {
      show: true,
      type: 'inside',
      filterMode: 'none',
      yAxisIndex: [0],
      startValue: -1,
      endValue: 15
    }
  ],
  series: [
    {
      type: 'line',
      showSymbol: false,
      clip: true,
      data: generateData()
    },
    {
      type: 'line',
      showSymbol: false,
      clip: true,
      data: generateData2(),
      markLine: {
        z:100,
        silent: true,
        lineStyle: {
          type: 'dashed',
          width: 2,
          color: '#ff0000'
        },
        data: [
          { 
            name: '', 
            xAxis: 20
          },
          {
            name: '',
            yAxis: 13.41
          }
        ],
        label: {
          show: true,
          position: 'end',
          formatter: '',
          color: '#ff0000'
        }
    }
    },
    {
      type: 'line',
      showSymbol: false,
      clip: true,
      data: generateData3(),
      markLine: {
        z:100,
        silent: true,
        lineStyle: {
          type: 'dashed',
          width: 2,
          color: '#ffff00'
        },
        data: [
          { 
            name: '', 
            xAxis: 14.609
          }
        ],
        label: {
          show: true,
          position: 'end',
          formatter: '',
          color: '#ffff00'
        }
    }
    },
    {
      type: 'scatter',
      data: [[20, 13.41]],
      symbolSize: 10, 
      label: {
        show: true,
        position: 'top',
        formatter: `切点 C`,
        fontSize: 14,
        backgroundColor: 'rgba(0,0,0,0.7)',
        color: '#fff',
        padding: [4, 8],
        borderRadius: 4
      },
      itemStyle: {
        color: 'red'
      }
      
      
    },
    {
      type: 'scatter',
      data: [[20, 0]],
      symbolSize: 10, 
      label: {
        show: true,
        position: 'right',
        formatter: `x_k`,
        fontSize: 14,
        backgroundColor: 'rgba(0,0,0,0.7)',
        color: '#fff',
        padding: [4, 8],
        borderRadius: 4
      },
      itemStyle: {
        color: 'red'
      }
    },
    {
      type: 'scatter',
      data: [[14.609, 0]],
      symbolSize: 10, 
      label: {
        show: true,
        position: 'right',
        formatter: `x_k+1`,
        fontSize: 14,
        backgroundColor: 'rgba(0,0,0,0.7)',
        color: '#fff',
        padding: [4, 8],
        borderRadius: 4
      },
      itemStyle: {
        color: 'red'
      }
    },
    {
      type: 'scatter',
      data: [[14.609, 4.0617]],
      symbolSize: 10, 
      label: {
        show: true,
        position: 'top',
        formatter: `切点`,
        fontSize: 14,
        backgroundColor: 'rgba(0,0,0,0.7)',
        color: '#fff',
        padding: [4, 8],
        borderRadius: 4
      },
      itemStyle: {
        color: 'red'
      }
    },
    {
      type: 'scatter',
      data: [[11.058, 0]],
      symbolSize: 10, 
      label: {
        show: true,
        position: 'right',
        formatter: `x_k+2`,
        fontSize: 14,
        backgroundColor: 'rgba(0,0,0,0.7)',
        color: '#fff',
        padding: [4, 8],
        borderRadius: 4
      },
      itemStyle: {
        color: 'red'
      }
    },
    
  ],

};
{% endecharts %}
首先取一点$x_k$作为$f(x)=0$的根，然后求过$(x_k,f(x_k))$的切线，该切线与$x$轴存在交点$x_{k+1}$，此时求得$x_{k+1}$的值为：
$$
x_{k+1}=x_k-\frac{f(x_k)}{f'(x_k)}
$$
这个式子就与前面的一阶泰勒展开的结果一样了。
然后再依次迭代直到满足要求即可求得$f(x)=0$的近似根。
#### 求极值
