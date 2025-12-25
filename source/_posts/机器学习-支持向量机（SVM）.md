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
# 支持向量机
对一个训练集进行分类学习，其基本思想就是通过一个分类超平面将训练集分开。能将训练姐分开的超平面有很多，学习算法的逻辑就是找到最优的超平面对训练数据及性能划分，  
一般来讲要将两个训练集的中间分开最好，分类超平面导两侧训练集的距离越大越好，距离越大越有利于容忍更多的样本噪声，所以我们的任务就是找到一个距离最大的分类超平面。
我们用线性方程来对这个超平面进行描述
$$
\mathbf{w}^T\mathbf{x}+\mathbf{b}=0
$$
其中$\mathbb{w}$是超平面的法向量$b$是位移。那么两个被分开的训练样本集就可以通过下面的方程组进行描述
$$
\begin{cases}
\mathbf{w}^T\mathbf{x}+\mathbf{b} \ge +1 \space\space\space\space\space y_i=1 \\\\
\mathbf{w}^T\mathbf{x}+\mathbf{b}  \le -1 \space\space\space\space\space y_i=-1
\end{cases}
$$
当$\mathbf{w}^Tx+b \ge +1$ 时认为是某一类样本（正例），当$\mathbf{w}^Tx+b \le -1$ 认为是另一类样本（反例）。  这里的$+1 -1$表示的就是支持向量距离分类超平面的距离又被称为函数间隔，  
这个距离是未被归一化的距离，其是认为定义的，你也可以定义其为$2,3,4,$，但是为了方便计算这里就定义为$1$
那么我们要求最大距离，首先要定义距离，在多维空间中某一点导一个超平面的距离用下面的公式进行计算，这个距离被称为几何距离，是归一化的距离，其与法向量的长度是无关的。
$$
r=\frac{\left \| \mathbf{w}^T\mathbf{x}+\mathbf{b} \right \| }{\left \|\| \mathbf{w} \right \|\| }
$$
**推导**
... 待定

距离超平面最近的几个训练样本集被称为**支持向量**，两个异类支持向量导分类超平面的距离之和为
$$
\gamma = 2 \times \frac{\left \| \mathbf{w}^T\mathbf{x}+\mathbf{b} \right \| }{\left \|\| \mathbf{w} \right \|\| }
$$
根据上面的定义支持向量到分类超平面的未归一化距离被定义为$1$可以将这个式子进行转化
$$
\gamma = \frac{2}{\left \|\| \mathbf{w} \right \|\| }
$$
所以我们的目标是找到$\gamma$的最大值，即：
$$
\begin{align}
&\underset{w,b}{max}  \frac{2}{\left \|\| \mathbf{w} \right \|\| } \\\\
&s.t. \space\space\space\space\space\space y_i(\mathbf{w}^T\mathbf{x}+\mathbf{b}) \ge 1, \space\space\space i=1,2,3,4....n
\end{align}
$$
为了使得间隔最大，只需要使$\left \|\| \mathbf{w} \right \|\|$最小，为了便于计算将$\left \|\| \mathbf{w} \right \|\|$等价为$\frac{1}{2}\left \|\| \mathbf{w} \right \|\|^2$，所以将上式重写为
$$
\begin{align}
&\underset{w,b}{min}  \frac{1}{2}\left \|\| \mathbf{w} \right \|\|^2 \\\\
&s.t. \space\space\space\space\space\space y_i(\mathbf{w}^T\mathbf{x}+\mathbf{b}) \ge 1, \space\space\space i=1,2,3,4....n
\end{align}
$$
这就是支持向量机的基本型。  
这是一个二次凸优化问题，可以用拉格朗日乘子法进行求解。
首先将其转化为拉格朗日函数
$$
L(\mathbf{w},\mathbf{b},\mathbf{\lambda})=\frac{1}{2}\left \|\| \mathbf{w} \right \|\|^2+ \sum_{i=1}^{n}(\lambda_i (1-y_i(\mathbf{w}^T \mathbf{x_i}+\mathbf{b}))) \tag{6}
$$
其原始代价函数
$$
\underset{\left \|\| \mathbf{w} \right \|\|}{min} \space \underset{\mathbf{\lambda}}{max} L(\mathbf{w},\mathbf{b},\mathbf{\lambda})=\frac{1}{2}\left \|\| \mathbf{w} \right \|\|^2+ \sum_{i=1}^{n}(\lambda_i (1-y_i(\mathbf{w}^T\mathbf{x_i}+\mathbf{b}))) \tag{6}
$$
将原始问题转为对偶问题
$$
\underset{\mathbf{\lambda}}{max} \space \underset{\left \|\| \mathbf{w} \right \|\|}{min} L(\mathbf{w},\mathbf{b},\mathbf{\lambda})
$$

对$\mathbf{w},\mathbf{b}$来说这是一个凸函数，所以直接对其求偏导就可以求到最小值。  
首先对$\mathbf{w}$求偏导。  
$$
\frac{\partial L(\mathbf{w},\mathbf{b},\mathbf{\lambda}) }{\partial \mathbf{w}}=\mathbf{w} - \sum_{i=1}^{n} \lambda_i y_i \mathbf{x_i} =0
$$
所以
$$
\mathbf{w}=\sum_{i=1}^{n} \lambda_i y_i \mathbf{x_i} \tag{4}
$$
对$\mathbf{b}$求偏导
$$
\frac{\partial L(\mathbf{w},\mathbf{b},\mathbf{\lambda}) }{\partial \mathbf{b}}= \sum_{i=1}^{n} \lambda_i y_i = 0
$$
得到
$$
\sum_{i=1}^{n} \lambda_i y_i = 0 \tag{5}
$$
将（5）与（4）带入到（6）可以得到
$$
\begin{align}
L(\mathbf{w},\mathbf{b},\mathbf{\lambda})&=\frac{1}{2}\left \|\| \mathbf{w} \right \|\|^2+ \sum_{i=1}^{n}(\lambda_i (1-y_i(\mathbf{w}^T \mathbf{x_i}+\mathbf{b}))) \\\\
&=\frac{1}{2}\left \|\left\| \sum_{i=1}^{n} \lambda_i y_i \mathbf{x_i} \right \|\right\|^2+ \sum_{i=1}^{n}(\lambda_i (1-y_i((\sum_{i=1}^{n} \lambda_i y_i \mathbf{x_i})^T \mathbf{x_i}+\mathbf{b}))) \\\\
&=\frac{1}{2}(\sum_{i=1}^{n} \lambda_i y_i \mathbf{x_i})^T\sum_{i=1}^{n} \lambda_i y_i \mathbf{x_i}+\sum_{i=1}^{n}\lambda_i - \sum_{i=1}^{n}(\lambda_i y_i x_i)  \\\\
&=\sum_{i=1}^{n}(\lambda_i)-\frac{1}{2}(\sum_{i=1}^{n} \lambda_i y_i \mathbf{x_i})^T\sum_{i=1}^{n} \lambda_i y_i \mathbf{x_i} \\\\
&=\sum_{i=1}^{n}\lambda_i-\frac{1}{2}\sum_{i=1}^{n}\sum_{j=1}^{n} \lambda_i \lambda_j y_i y_j \mathbf{x_i}^T\mathbf{x_j}
\end{align}
$$
考虑（5）的约束得到对偶问题。
$$
\begin{align}
&\underset{\lambda}{max} \space \sum_{i=1}^{n}\lambda_i-\frac{1}{2}\sum_{i=1}^{n}\sum_{j=1}^{n} \lambda_i \lambda_j y_i y_j \mathbf{x_i}^T\mathbf{x_j}\\\\
&s.t. \space\space\space\space\space\space \sum_{i=1}^{n} \lambda_i y_i = 0 \\\\
& \lambda_i \ge 0 \tag{8}
\end{align}
$$
同时需要满足KKT条件
- 不等式约束
- 非负性
- 互补松驰性
$$
\begin{cases}
1-y_i(\mathbf{w}^T\mathbf{x_i}+\mathbf{b}) \le 0\\\\
\lambda_i \ge 0\\\\
\lambda_i (1-y_i(\mathbf{w}^T\mathbf{x_i}+\mathbf{b})) = 0 \tag{9}
\end{cases}
$$
将（4）带入到分类超平面方程中
$$
f(x)=\mathbf{w}^T\mathbf{x_i}+\mathbf{b}=\sum_{i=1}^{n} \lambda_i y_i (\mathbf{x_i})^T\mathbf{x_i} + b \tag{7}
$$
对应任意一个样本$(x_i, y_i)$，当$\lambda_i = 0$时，样本的位置对结果没有影响，所以$\lambda_i$ 不能取$0$，  
当$\lambda_i \> 0$时有$1-y_i(\mathbf{w}^T\mathbf{x_i}+\mathbf{b})=0 \Rightarrow y_i(\mathbf{w}^T\mathbf{x_i}+\mathbf{b}) = 1$即对应的样本点位于最大间隔边界上，即一个支持向量。  
这表明了支持向量机训练结束后大部分样本都不需要保留，最终模型只与支持向量有关。
根据（7）需要求得$\mathbf{\lambda}$，通过（8）与（9）求得，使用SMO算法进行求解。
## 线性不可分样本的支持向量机
### 样本噪声导致的线性不可分
当两类样本搅合在一起不能明显地通过一条直线或者超平面分开的时候就就需要用到“软间隔支持向量机”，这种线性不可分又不是完全分不开而是因为数据采样误差等因素导致的样本失真。
所谓“软间隔”集让我们的模型能够一定程度上容忍样本的噪声。通俗的讲就是样本能够落到分类超平面与过支持向量的超平面之间的区域。  
当然这个容忍是有限度的，如果不设限那么所有的样本就都可以落在这个区间，这样也就意味着分类间隔可以任意大，于是分类就没了意义，所以我们引入了惩罚项，  
当分类间隔越大惩罚越重，这样就避免了其无限的扩大。所以优化目标可以写作
$$
\underset{\mathbf{w},b}{min} \frac{1}{2} \left \| \left \| \mathbf{w} \right\|\right\|^2 + C\sum_{i=i}^{n} \ell_{0/1}(y_i(\mathbf{w}^T\mathbf{x}+b)-1)
$$
其中$C \> 0$ ,$\ell_{0/1}$称为$0,1$损失函数，其取值只有两个
$$
\ell_{0/1}(z)=
\begin{cases}
1 \space\space\space\space\space\space if \space z < 0\\\\
0  otherwise
\end{cases}
$$
当$\ell_{0/1}(z)$取大于1的时候$C$越大对目标函数的影响也就越大，当C趋于无穷大的时候迫使目标函数极大，这样就会使得所有样本都满足要求，当C取有限值的时候将会对结果产生有限的影响，  
所以通过调节C的大小可以控制软间隔宽度。这个0/1损失函数虽然功能上满足需求但是在数学上却不是一个好的选择，其是一个阶跃函数非凸非凹不宜求解，所以往往使用其他的函数来对该函数进行替代
常见的替代函数有
hinge损失函数：
$$
\ell_{hinge}(z)=max(0,1-z)
$$
指数损失：
$$
\ell_{exp}(z)=e^{(-z)}
$$
对率损失：
$$
\ell_{log}(z)=log(1+e^{(-z)})
$$
这里以`hinge`损失函数为例带入目标函数
$$
\underset{\mathbf{w},b}{min} \frac{1}{2} \left \| \left \| \mathbf{w} \right\|\right\|^2 + C\sum_{i=i}^{n} max(0,1-y_i(\mathbf{w}^T\mathbf{x}+b))
$$
引入**松弛变量**$\xi_i$原始问题改写为
$$
\begin{align}
&\underset{\mathbf{w},b}{min} \frac{1}{2} \left \| \left \| \mathbf{w} \right\|\right\|^2 + C\sum_{i=i}^{n} \xi_i\\\\
&s.t. \space\space\space\space\space\space y_i(\mathbf{w}^T\mathbf{x}+b) \ge 1-\xi_i\\\\
\space\space\space\space\space\space \space\space\space\space&\xi_i \ge 0
\end{align}
$$
上面就是软间隔支持向量机  含有两个不等式 引入拉格朗日乘子转换为
$$
L(\mathbf{w},b,\mathbf{\lambda},\mathbf{\xi},\mathbf{\mu }) = \frac{1}{2} \left \| \left \| \mathbf{w} \right\|\right\|^2 + C\sum_{i=i}^{n} \xi_i+\sum_{i=i}^{n}\lambda_i(1-\xi_i-y_i(\mathbf{w}^T\mathbf{x_i}+b))-\sum_{i=i}^{n}\mu_i\xi_i
$$
对$\mathbf{w}$求偏导
$$
\mathbf{w} - \sum_{i=1}^{n}\lambda_i y_i \mathbf{x_i} = 0 \Rightarrow \mathbf{w}=\sum_{i=1}^{n}\lambda_i y_i \mathbf{x_i}
$$
对$\xi_i$求偏导
$$
n\times C - n \times \lambda_i - n \times \xi_i \Rightarrow C=\lambda_i + \mu_i
$$
对$b$求偏导
$$
\sum_{i=1}^{n} \lambda_i y_i = 0
$$
带入原问题后得到表达式 然后将原问题转为对偶问题如下 （和之前的操作一样）
$$
\begin{align}
&\underset{\lambda}{max} \space \sum_{i=1}^{n}\lambda_i-\frac{1}{2}\sum_{i=1}^{n}\sum_{j=1}^{n} \lambda_i \lambda_j y_i y_j \mathbf{x_i}^T\mathbf{x_j}\\\\
&s.t. \space\space\space\space\space\space \sum_{i=1}^{n} \lambda_i y_i = 0 \\\\
& 0 \le \lambda_i \le C
\end{align}
$$
满足KKT条件
$$
\begin{cases}
1-y_i(\mathbf{w}^T\mathbf{x_i}+\mathbf{b}) -\xi_i \le 0\\\\
\lambda_i \ge 0\\\\
\lambda_i (1-y_i(\mathbf{w}^T\mathbf{x_i}+\mathbf{b}) + \xi_i) = 0 \\\\
\xi_i \ge 0\\\\
\mu_i\xi_i = 0
\end{cases}
$$
经过变换处理的原始问题可以写为更一般的形式
$$
\underset{f}{min}\Omega (f) + C\sum_{i=1}^{n}\ell(f(x_i),y_i)
$$
其中$\Omega (f)$ 被称为结构化风险 $\sum_{i=1}^{n}\ell(f(x_i),y_i)$ 被称为经验风险
### 完全不可分的支持向量机
将不可分的低维数据通过函数变换升维到更高维从而变为线性可分的问题。如果升为无限维的话那么结果必然是线性可分的，但是无限维带来的问题是计算量巨大无比。  
有一种方法可以使得我们不需要结算所有维度的数据，只需要找到一个替代函数其结果与升维后的结果抑制就行，这个函数就是核函数
设将样本从低维映射到高维的函数为$\varphi (x)$ 
则分类超平面的方程变为
$$
f(x)=\mathbf{w}^T\varphi(x)+\mathbf{b}
$$
最大化分类间隔的原始问题变为
$$
\begin{align}
&\underset{w,b}{min}  \frac{1}{2}\left \|\| \mathbf{w} \right \|\|^2 \\\\
&s.t. \space\space\space\space\space\space y_i(\mathbf{w}^T\varphi(x_i)+\mathbf{b}) \ge 1, \space\space\space i=1,2,3,4....n
\end{align}
$$
对偶问题变为
$$
\begin{align}
&\underset{\lambda}{max} \space \sum_{i=1}^{n}\lambda_i-\frac{1}{2}\sum_{i=1}^{n}\sum_{j=1}^{n} \lambda_i \lambda_j y_i y_j \varphi(x_i)^T\varphi(x_j)\\\\
&s.t. \space\space\space\space\space\space \sum_{i=1}^{n} \lambda_i y_i = 0 \\\\
& \lambda_i \ge 0
\end{align}
$$
核函数就是找到一个函数使得$k(x_i,x_j)$使得
$$
k(x_i,x_j)=\varphi(x_i)^T\varphi(x_j)
$$
这样就使得无限维的向量内积计算变成了在原样本空间中的$k(x_i,x_j)$函数的计算结果，$k(x_i,x_j)$就是核函数。
常见的核函数
线性核
$$
k(x_i,x_j)=x_{i}^Tx_j
$$
多项式核
$$
k(x_i,x_j)=(x_{i}^Tx_j)^d \space\space\space\space\space d \ge 1
$$
高斯核
$$
k(x_i,x_j)= e^{(-\frac{\left \|\left\| x_i-x_j \right \|\right\|^2}{2\sigma^2})} \space\space\space\space\space \sigma > 0
$$
拉普拉斯核
$$
k(x_i,x_j)= e^{(-\frac{\left \|\left\| x_i-x_j \right \|\right\|}{\sigma})} \space\space\space\space\space \sigma > 0
$$
sigmod核
$$
k(x_i,x_j)= tanh(\beta x_i^T x_j+\theta )
$$

## 支持向量回归
...