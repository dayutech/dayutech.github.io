---
title: 机器学习-支持向量机（SVM）
tags:
  - 机器学习
  - 支持向量机
  - SVM
categories:
  - - 机器学习
top: 1003
description: 无
mathjax: true
abbrlink: e2189dc7
date: 2025-12-17 09:11:20
---
# 多元函数的极值
**定义**
设函数$f:D\subseteq \mathbb{R}^n \to \mathbb{R}$，点$\mathbf{x}=(x_01,x_02,x_03...x_0n) \in  D$  
如果存在某个$\delta >0$,使得对所有满足$\parallel \mathbf{x}-\mathbf{x_0}\parallel < \delta$ 且$x\in D$的点$\mathbf{x}$都有：
$$
f(\mathbf{x}) < f(\mathbf{x_0})
$$
那么点$\mathbf{x_0}$就是在$D$内的极大值点，反之则是极小值点。
## 二元函数的极值
为了方便说明这里用二元函数而作为例子，我们对二元函数的极值做单独的定义如下。  
设函数$z=f(x,y)$在点$(x_0,y_0)$的某一个邻域内有定义，对于该邻域内异于点$(x_0,y_0)$的零一点$(x,y)$，如果恒有：
$$
f(x,y) < f(x_0,y_0)
$$
则点$(x_0,y_0)$为该邻域内的极大值点，反之则为极小值点。
**定理1**
若函数$z=f(x,y)$在点$(x_0,y_0)$具有偏导数，且在点$(x_0,y_0)$具有极值，则它在该点的偏导数必为0，即：
$$
f_x(x_0,y_0)=0, f_y(x_0,y_0)=0
$$
这个点是函数的驻点，根据定理1，具有偏导数的函数的极值点必为驻点，但是驻点不一定是极值点。
## 条件极值与拉格朗日乘数法
函数的自变量落在定义域内，并无其他限制条件，这一内函数求极值被称为无条件极值，如果有其他的附加限制条件则被称为有条件极值。求条件极值的一种方法就是拉格朗日乘数法。
设二元函数$f(x,y)$和$\varphi(x,y)$在区域$D$内有连续偏导数，则求$z=f(x,y)$在$D$内满足$\varphi(x,y)=0$的极值，可以转化为拉格朗日函数  
$$
L(x,y,\lambda )=f(x,y)+\lambda \varphi(x,y)
$$
设点$P_0(x_0,y_0)$是函数$z=f(x,y)$在$\varphi(x,y)=0$条件下的极值点，即$P_0$是函数$z=f(x,y)$的极值点且$\varphi(x_0,y_0)=0$  
设函数$f(x,y)$和$\varphi(x,y)$ 在点$P_0$处有连续的偏导数且$\varphi_{y}(x_0,y_0)\ne 0$（这个是将隐函数改写成$y=g(x)$的必要条件），此时就可以设$y=g(x)$，即$y$是关于$x$的函数，将其带入到$f(x,y)$中则有
$z=f(x,g(x))$，如此便将二元函数转换成了一元函数，将二元函数求极值的问题转换成了一元函数求极值，一元函数求极值的必要条件是其一阶导数等于零，故这里将$z=f(x,g(x))$对$x$求导
$$
\frac{\mathrm{d} z}{\mathrm{d} x}=f_x(x,y)+f_y(x,y)g'(x) 
$$
这里因为$y=g(x)$那么就涉及到了复合函数的求导，利用复合函数的求导法则即链式法则对$g(x)$进行处理，即先对$y$求导再乘以$g(x)$对$x$的导数
因为点$P_0$是$z=f(x,y)$的极值点，所有
$$
f_x(x_0,y_0)+f_y(x_0,y_0)g'(x_0) =0\tag{1}
$$
隐函数求导的时候对等式两边分别求导
这里对$\varphi(x,y)=0$进行求导
$$
\frac{\mathrm{d} \varphi}{\mathrm{d} x}+\frac{\mathrm{d} \varphi}{\mathrm{d} y}.\frac{\mathrm{d} y}{\mathrm{d} x}=0
$$
$\frac{\mathrm{d} y}{\mathrm{d} x}$即$g'(x)$所以有
$$
g'(x)=-\frac{\frac{\mathrm{d} \varphi}{\mathrm{d} x}}{\frac{\mathrm{d} \varphi}{\mathrm{d} y}}
$$
即
$$
g'(x)=-\frac{\varphi_{x}(x,y)}{\varphi_{y}(x,y)}
$$
带入（1）有
$$
f_x(x_0,y_0)-f_y(x_0,y_0)\frac{\varphi_{x}(x_0,y_0)}{\varphi_{y}(x_0,y_0)}=0\tag{3}
$$
即此时$z=f(x,y)$在$\varphi(x,y)=0$条件下的极值存在需要满足的必要条件为
$$
\begin{cases}
 f_x(x_0,y_0)-f_y(x_0,y_0)\frac{\varphi_{x}(x_0,y_0)}{\varphi_{y}(x_0,y_0)}=0\\\\
\varphi(x_0,y_0)=0
\end{cases}
$$
令$\lambda=-\frac{f_{y}(x_0,y_0)}{\varphi_{y}(x_0,y_0)}$有
$$
\begin{cases}
f_x(x_0,y_0)+\lambda \varphi_{x}(x_0,y_0)=0\tag{2}\\\\
\varphi(x_0,y_0)=0
\end{cases}
$$
等式（2）前面就是拉格朗日函数了，$\lambda$被称为拉格朗日乘子，
在上面的方程组中，存在三个未知数$x_0,y_0,\lambda$需要求解，只有两个方程很明显是解不出来的，所以还需要想办法寻找第三个方程解方程组。
对（3）两边同时乘以$\varphi_{y}(x_0,y_0)$得到  
$$
f_x(x_0,y_0)\varphi_{y}(x_0,y_0)-f_y(x_0,y_0)\varphi_{x}(x_0,y_0)=0
$$
即
$$
f_x(x_0,y_0)\varphi_{y}(x_0,y_0)=f_y(x_0,y_0)\varphi_{x}(x_0,y_0)
$$
因有（2）所以有$\lambda=-\frac{f_x(x_0,y_0)}{\varphi_{x}(x_0,y_0)}$
故有
$$
\begin{align}
f_y(x_0,y_0)+\lambda \varphi_{y}(x_0,y_0)&=f_y(x_0,y_0)-\frac{f_x(x_0,y_0)}{\varphi_{x}(x_0,y_0)} \varphi_{y}(x_0,y_0)\\\\
&=f_y(x_0,y_0)-\frac{f_y(x_0,y_0)\varphi_{x}(x_0,y_0)}{\varphi_{x}(x_0,y_0)}\\\\
&=f_y(x_0,y_0)-f_y(x_0,y_0)=0
\end{align}
$$
即
$$
f_y(x_0,y_0)+\lambda \varphi_{y}(x_0,y_0)=0
$$
成立，故有方程组
$$
\begin{cases}
f_x(x_0,y_0)+\lambda \varphi_{x}(x_0,y_0)=0\\\\
f_y(x_0,y_0)+\lambda \varphi_{y}(x_0,y_0)=0\\\\
\varphi(x_0,y_0)=0
\end{cases}
$$
这里看似是三个方程其实还是两个方程，因为第二个方程是通过第一个方程推出来的，那么为什么需要这两个方程呢，还记得之前的假设么$\varphi_{y}(x_0,y_0)\ne 0$，  
因为有这个假设才能定义$\lambda=-\frac{f_{y}(x_0,y_0)}{\varphi_{y}(x_0,y_0)}$，不然分母就为$0$了，那么当$\varphi_{y}(x,y)$真的为$0$的时候呢，这时候就需要第二个方程了。
前面的推导中我们有$\lambda=-\frac{f_x(x_0,y_0)}{\varphi_{x}(x_0,y_0)}$ 此时要求$\varphi_{x}(x_0,y_0)$不为$0$。那么这个方程组就不依赖于$\varphi_{y}(x_0,y_0) \ne 0$ 或 $\varphi_{y}(x_0,y_0) \ne 0$了

所以得到结论，对于有条件极值函数的极值的拉格朗日乘数法基本步骤为：
构造拉格朗日函数：
$$
L(x,y,\lambda )=f(x,y)+\lambda \varphi(x,y)
$$
得到方程组
$$
\begin{cases}
f_x(x_0,y_0)+\lambda \varphi_{x}(x_0,y_0)&=0 \\\\
f_y(x_0,y_0)+\lambda \varphi_{y}(x_0,y_0)&=0 \\\\
\varphi(x_0,y_0)=0
\end{cases}
$$
这样求得的点是满足条件约束极值点求解的必要条件的但不够充分，解出的该点的充分性需要具体分析了。
# 矩阵分析中的拉格朗日乘子
## 含有等式约束的拉格朗日乘子法
### 只含一个等式
函数$f(\mathbf{w})$是参数向量$\mathbf{w}$的函数，约束条件为：
$$
\mathbf{w^T x}=\mathbf{b} \Rightarrow h(\mathbf{w})=\mathbf{w^T x}-\mathbf{b}=0
$$
求$f(\mathbf{w})$的极值可以描述为：
$$
\begin{align}
\min f({\mathbf{w} })\\\\
s.t.\space \space  h(\mathbf{w})=0
\end{align}
$$
根据上面的方法，使用拉格朗日乘子定义一个新的拉格朗日函数  
$$
L(\mathbf{w},\lambda)=f(\mathbf{w})+\lambda h(\mathbf{w})
$$
然后构造方程
$$
\begin{cases}
f_{\mathbf{w^{\*}}}(\mathbf{w})+\lambda h_{\mathbf{w^{\*}}}(\mathbf{w})=0\\\\
h(\mathbf{w})=0
\end{cases}
$$
### 含多个等式
函数$f(\mathbf{w})$是参数向量$\mathbf{w}$的二次函数，约束条件为：
$$
\mathbf{w^T x_k}=\mathbf{b_k} \Rightarrow h_k(\mathbf{w})=\mathbf{w^T x_k}-\mathbf{b_k}=0\space\space\space k=1,2,3,...n
$$
求$f(\mathbf{w})$的极值可以描述为：
$$
\begin{align}
&\min f({\mathbf{w} })\\\\
&s.t.\space \space  h_k(\mathbf{w})=0, \space\space\space\space k=1,2,3...n
\end{align}
$$
定义拉格朗日函数
$$
L(\mathbf{w},\lambda)=f(\mathbf{w})+\sum_{k=i}^{n}\lambda_{k}h_k(\mathbf{w})
$$
构造方程
$$
\begin{cases}
f_{w^\*}(\mathbf{w})+\sum_{k=i}^{n}\lambda_{k} h_{w^\*}(\mathbf{w})=0\\\\
h(\mathbf{w})=0
\end{cases}
$$
### 含不等式约束的拉格朗日乘法
含有不等式约束的的函数极值求法一般使用对偶方法进行求解，首先定义原始问题
$$
\begin{align}
&\underset{x}{\min} =f_0(x)
&s.t.\space\space\space\space f_i(x)\le 0,\space\space\space\space i=1,2,...m
&h_j(x)=0,\space\space\space\space j=1,2,3...n
\end{align}
$$
转换为拉格朗日函数
$$
L(x,\lambda, v)=f_0(x)+\sum_{i=1}^{m}\lambda_{i} f_i(x)+\sum_{j=1}^{n}v_{j}h_j(x)
$$
求原约束函数的极小值就是求这个拉格朗日函数的极小值$\min L(x,\lambda, v)$
此时定义约束条件$\lambda \ge 0$，则$\sum_{i=1}^{m}\lambda_{i} f_i(x) \le 0$，则有：
$$
L(x,\lambda, v) \le f_0(x)
$$
此时求$f_0(x)$的极小值就是求$L(x,\lambda, v)$的极大值
$$
J_1(x)=\underset{\lambda \ge 0,v}{\max}(f_0(x)+\sum_{i=1}^{m}\lambda_{i} f_i(x)+\sum_{j=1}^{n}v_{j}h_j(x))
$$
此时$\lambda$以及$v$是满足约束条件的，但是$x$的取值是任意的，我们需要分情况讨论，当$x$满足约束$f_i(x)\le0$与$h_i(x)=0$时，$J_1(x)$就等于$f_0(x)$，当$x$不满足约束$f_i(x)\le0$的时候  则$\sum_{i=1}^{m}\lambda_{i} f_i(x) \ge 0$，则$J_1(x) \ge f_0(x)$，数学表达即为
$$
J_1(x)=
\begin{cases}
x满足全部约束：f_0(x) \\\\
x不满足约束\[f_0(x),+\infty)
\end{cases}
$$

所以我们只需再对$J_1(x)$求最小值就可以得到$f_0(x)$，也就是说无论$x$满不满足约束都可以通过求最小值的方法求得解，即：
$$
J_p(x)=\underset{x}{\min}J_1(x)=\underset{x}{\min}\underset{\lambda \ge 0,v}{max}L(x,\lambda,v)=f_0(x)
$$
这是原始约束极小化问题变成无约束极小化问题后的代价函数，简称原始代价函数。
定义原始约束极小化问题的最优解：
$$
p^\*=J_p(x^\*)=\underset{x}{f_0(x)}=f_0(x^\*)
$$
说人话就是约束函数$f_0(x)$的极小值就是$J_p(x)$的解。这里就将一个约束极小化问题转化为了无约束极小化问题，这个函数$J_p(x)$被称为原始代价函数。
如何对这个原始代价函数进行求解？
有一个结论$\max$函数是凸函数$\min$函数是凹函数。这里对一个无约束凸函数求极值那么求得的局部极小值就是全局极限值点。
但如果函数是非凸非凹的又该如何处理呢？这里想将非凸非凹的函数转换为凸函数或者凹函数不久可以了，这中方法就是对偶方法。
### 对偶方法
我们想求一个函数的最小值，是否可以转换为求另一个函数的最大值，且这个函数总是凹函数就好了。这样求得的局部最大值就是全局最大值并且是原始函数的最小值。
在固定$\lambda, v$的情况下我们考虑求$L(x,\lambda,v)$的下确界。
$$
g(\lambda,v)=\underset{x \in \mathbb{R}^n}{\inf}L(x,\lambda,v)
$$
这个函数有如下性质
- 对每个固定的 $(\lambda,v)$，$g(\lambda,v)$ 是拉格朗日函数关于 $x$ 的全局下确界；
- 它自动满足弱对偶性：若 $\lambda \ge 0$，则 $g(\lambda,v)\le p^\*$ 
- g总是凹函数（因是仿射函数族的逐点下确界总是凹函数，所谓仿射函数在这里就是在$(\lambda,v)$固定的情况下$\sum_{i=1}^{m}\lambda_{i} f_i(x)+\sum_{j=1}^{n}v_{j}h_j(x)$是关于$x$的仿射函数）  

所以得出原始函数的对偶函数为：
$$
\begin{align}
&\underset{\lambda,v}{\sup}g(\lambda,v)\\\\
&s.t.\space\space\space\space \lambda \ge 0
\end{align}
$$
通俗讲就是求原始问题的最小值问题变成了求$\lambda,v$固定的情况下的下确界的上确界，更一般的理解就是求最小值里的最大值。  
因为这些最小值都是小于$f_0(x)$的，所以要在这里面找一个最接近$f_0(x)$的就是求下确界关于$x$的上确界。
又因为$g(\lambda,v)$是凹函数，那么求凹函数的极大值就很美丽了。
当满足约束$\lambda \ge 0$ 且$x$满足约束的时候，有
$$
L(x,\lambda,v) \le f_0(x) \Rightarrow \underset{x}{\inf}L(x,\lambda,v) \le \underset{x \in \mathbb{R}^n}{\inf}f_0(x)=p^*
$$
即
$$
g(\lambda,v) \le p^*
$$
在取上确界
$$
d^\*=\underset{\lambda, v}{\sup}g(\lambda,v) \le p^\*
$$
即
$$
d^\* \le p^\*
$$
此时原始问题与其对偶问题的对偶性恒成立不需要任何其他的条件，被称为弱对偶成立。
倘若$d^\* = p^\*$时则被称为强对偶成立。
强对偶成立是有一定条件限制的
#### slater条件
原始问题是凸优化问题，即$f_0(x)$以及$f_i(x)$都是凸函数，$h_i(x)$是仿射函数。
slater条件即：
- $f_i(x)<0\space\space\space\space \forall i=1,2,3,...m$
- $h_i(x)=0\space\space\space\space \forall i=1,2,3,...n$
#### KKT条件
$$
\begin{align}
&f_i(x^\*) \leq 0, \quad i = 1, 2, \dots, m  \space\space\space\space (原始不等式约束)\\\\
&h_i(x^\*) = 0, \quad i = 1, 2, \dots, q  \space\space\space\space(原始等式约束)\\\\
&\lambda_i^\* \geq 0, \quad i = 1, 2, \dots, m  \space\space\space\space(对偶非负性)\\\\
&\lambda_i^\* f_i(x^\*) = 0, \quad i = 1, 2, \dots, m  \space\space\space\space(互补松弛性)\\\\
&\nabla f_0(x^\*) + \sum_{i=1}^{m} \lambda_i^\* \nabla f_i(x^\*) + \sum_{i=1}^{q} \nu_i^\* \nabla h_i(x^\*) = 0 \space\space\space\space(梯度平稳性)
&\end{align}
$$

