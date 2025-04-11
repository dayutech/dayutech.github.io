---
title: Java语法
tags:
  - Java语法
categories:
  - [安全技术]
  - [编程语言]
date: 2025-04-10 20:56:11
description: 本文介绍了JAVA的基本语法
---
# JAVA

```java
public class Hello{
	public static void main(String[] args){
		System.out.print("armandhe")
}
} //类名与文件名必须相同，必须有main方法
```

# 数据类型

## 基本数据类型

```java
String st="armandhe"; //必须使用双引号，定义字符串，不是基本数据类型，而是一个类
byte by=1;
short sh=127;
int in=65535;
long lo=2111111L;
char ch='a'; //必须使用单引号
float fl=0.4f;
double dou=45.35;
boolean bo=true;
str1=new String("armanghe"); //str的类型是一个对象
str1=new String("armanghe"); 
str1 === str2 //false
String str3="armandhe";
String str4="armandhe"
str3===str4 //true
```

## 数据类型转换

只能转换能转换的类型

### 转换优先级

```java
//由低到高
byte short char --> int --> long --> float --> double
```

`低到高会发生自动类型转换，高到低需要进行强制转换` 

### 强制类型转换

```java
int in=43;
byte by=(int)in; //强制转换为byte型
int in1=2343444;
int in2=22222222;
long in3=in1*(long)in2; //在进行数值运算的时候一定要注意数值类型的范围，否则可能导致溢出，此方法在运算前将int转换为long类型，避免了溢出问题。

```

# 变量

值可以变化的量。变量是内存中的一段空间，不存储值，只存储值得地址。java是强类型得语言，每个变量都必须指定类型，变量声明或者定义后必须以分号结尾。

## 变量作用域

### 类变量

```java
public class Hello{
		static int i;
		static int j=10; //类变量
		public static void main(String[] args){
		System.out.print(i);
		System.out.print(j)l
}
		public void test(){
			//方法
}

```

### 实例变量

定义在类里面的变量，必须通过类引用

```java
public class Hello{
		int i;
		int j=10; //实例变量
		public static void main(String[] args){
			Hello hel = new Hello;
			System.out.print(hel.i); //j==0 //未被初始化的变量会输出其初始值，基本数据类型基本为0，其他均为null
			System.out.print(hel.j); //j==10
	
}
		public void test(){
			//类方法
}
}
```

### 局部变量

定义在方法中的变量

```java
public class Hello{
		public static void main(String[] args){
			Hello hel = new Hello;
			System.out.print(hel.i); //j==0 //未被初始化的变量会输出其初始值，基本数据类型基本为0，其他均为null
			System.out.print(hel.j); //j==10
			test.i	
}
		public void test(){
			//类方法
			int i; //局部变量
			System.out.print(i);
			
}
}
```

# 常量

值固定的量

```java
public class Hello{
	static final double PI=3.1415926; //惯例变量名大写，final是修饰符，其所处位置是任意的。
		public static void main(String[] args){
			System.out.print(PI)
}
}
```

# 算数运算符

```java
+ - * / % ++ -- //算数运算符
= //赋值运算符
< > == <= >= != //关系运算符
&& || ! //逻辑运算符
& | ^ ~ >> << >>> //位运算符
? : //条件运算符，三目运算符
+= -+ *= /= //扩展赋值运算符
```

算数运算时，若运算数种不含有long类型，那么结果类型必是int类型，如果long类型存在，那么结果必为long。

# 流程控制

## Scanner对象

### next方式

```java
import java.util.scanner;
Scanner s = new Scanner(System.in);
if (s.hasNext()){ //判断用户还有没有输入,按下回车后输入结束
	String str = s.next(); //获取用户的输入
	System.out.println(str); //打印用户输入
}
s.close(); //关闭扫描器对象，方式io流的都需要手动关闭，否则将会占用大量的资源。
//输入hello world 
//输出hello
//即不能输出带有空白字符的字符串，以空白字符为结束符，对于遇到有效字符前的空白，将会被忽略

```

### nextline方式

```java
import java.util.scanner;
Scanner s = new Scanner(System.in);
if (s.hasNextLine()){ //判断用户还有没有输入,按下回车后输入结束
	String str = s.nextline(); //获取用户的输入
	System.out.println(str); //打印用户输入
}
s.close(); //关闭扫描器对象，方式io流的都需要手动关闭，否则将会占用大量的资源。
//以回车作为结束符，可以带有空白字符，可以不需要中间的判断语句。
```

### 其他用法

```java
import java.util.scanner;
int i=0;
Scanner s = new Scanner(System.in);
System.out.println("请输入整数：") 
if (s.hasNextInt()){ //hasNextInt hasNextFloat  hasNextDouble hasNextSting
	i=s.**nextInt()**;
	System.out.println("整数数据：" + i);
}else{
	System.out.println("输入的不是整数")
}
s.close(); 
```

## 例：求和

```java
import java.util.scanner;
double sum;
int m=1;
Scanner s = new Scanner(System.in);
while (s.hasNextDouble()){
	double x = s.nextDouble();
	x.equals("hello") //判断字符串是否相等，少使用==去判断字符串是否相等
	System.out.println("你输入了第"+m+"个数据");
	sum += x;
	m += 1;
}
System.out.println("这些数字的总和为："+sum+";");
System.out.println("这些数字的平均值为："+sum/m+";");

```

## 顺序结构

```java
//从上到下一次执行
```

## 选择结构

### 单选择结构与普通多选择结构

```java
if (condition){
	//语句
} else if (condition){
	//语句
} else {
	//语句
}
```

### switch多选择结构

```java
switch(expression){
	case value:
		//语句
	case value:
		//语句
			.
			.
			.
	default: //可选
		//语句

}
//value的值可一世数字与字符串(java SE 7之后支持)，不过字符串只能是**字面量**或者**常量**不能为变量
//如果没有设置defaule选项，如果输入未知的数据，则会发生case穿透，将输出每一种情况的计算结果
//为了避免case穿透，需要加上break；如果没有break，那么将在匹配到第一项后，继续输出后面的case语句中的计算结果，直到遇到一个break或者结束
switch(expression){
	case value:
		//语句
		break;
	case value:
		//语句
		break;
			.
			.
			.
	default: //可选
		//语句

}
```

## 循环结构

### while

```java
while (condition){
	//语句
	//break 跳出整个循环，退出循环
	//continue 跳出当前循环，进入下一轮循环
}
```

### do while

```java
do {
	//语句
}while(condition);
```

### for

```java
//初始化//条件判断//迭代
for (int i=1; i<100;i++){
	//语句
	//break
	//bontinue
}

//初始化可为空，条件判断可为空,迭代可为空，当三者均为空使为死循环。

```

### 例：九九乘法表

```java
public class test{
	public static void main(String[] args){
		for (int i=1;i<=9;i++){ //行
			for (int j=1;j<=i;i++){ //列
				System.out.print(i+"x"+j+"="+(i*j)+"\t");
			}
				System.out.println();
		}
	}
}
```

### 例：打印等腰三角形

```java
public class test{
	public static void main(String[] args){
		for int i = 1;i<=5; i++{
			for (int j=5;j>=i;j--){
				System.out.print(" ");
			}
			for (int j=1;j<=i;j++){
				System.out.print("*");
			}
			for (int j=1;j<i;j++){
				System.out.print(" ");
			}
			System.out.println();
		}
	}
}
```

### 增强型for

主要用于遍历数组与集合

```java
public class test{
	public static void main(String[] args){
		int[] num={10,20,30};
		for (int x:num){
				System.out.println(x);
		}
	}
}
```

# 方法

```java
System.out.println();
//类 对象 方法
```

```java
public class Test{
	public static void main(String[] args){
		//主方法
		int sum=add(1333,3222);
		System.out.print(sum); //输出4555

		Test su = new Test;
		int sum2=su.sub(5,6);
		System.out.print(sum2);//输出-1
	}
	public static int add(int a,int b){  //add方法，加static声明类方法，可以在类中被直接调用
		return a+b;
	}
	public int substraction(int a,int b){  //sub法，不加static声明实例方法，
	}

}
```

## 重载

1. 方法名称必须相同
2. 参数列表必须不相同（个数不相同，类型不相同，排列顺序不相同）

## 可变传参

```java
public class Test{
	public static void main(String[] args){
		//语句
		int a=1;
		int b = 3;
		int c = 4
		int d = 5;
		arg(a,b,c,d);
	}
	public static int arg(int a;int b;int... c){ //不定项参数必须是最后一个参数
		//语句
	}
}
```

## 递归

方法自己调用自己，递归必须要有基例，即程序的出口，不然会发生栈溢出。

以阶乘为例

```java
public class Test{
	public static void main(String[] args){
	}
	public static int test(int n){
		if (n==1){
			return 1;
		}else{
			return n*test(n-1);
		}
	}
}
```

# 数组

## 基本使用

```java
//默认初始化，包含在动态初始化中，没有被赋值的元素位将被赋元素类型的默认。

//静态初始化
int[] num = {1,2,3,4,5,5,6}; //建议书写方式
int num[] = {55,1,3,4,5,6,}; //定义并赋值 c c++ 风格

//动态初始化 
int[] nums; //声明数组
nums = new int[100]; //创建一个容量为100的数组
nums[0]=1;
nums[1]=34; //为数组赋值

//取值
System.out.print(nums[1]); //从数组取值
System.out.print(nums.length); //获取数组长度。

//遍历数组
for (int i:nums){
	System.out.print(nums[i-1]); //**注意此处**
}
//或者
for (int i=0;i<nums.lenth;i++){
	System.out.print(nums[i]);
}

//反转数组
public static int[] reverse(int[] arrays){
	int[] result = new int[arrays.length];
	for (int i=0,j=result.length-1;i<arrays.length;i++,j--){
		result[i]=arrays[j];
	}
	return result;

}

//数组的长度是固定的，定义之后不可改变
//未被赋值的位置的值为该位置预定义类型的默认值。
//数组中必须是相同的数据类型

```

## 多维数组

```java
public class Test{
	public static void main(String[] args){
		int[][] nums={{1,2},{1,4},{45,56}};
		System.out.pringln(nums[1][0]);
	}
}

//这种数组里面只能存一种类型的数据，真的是好憋得慌。
```

## Arrays对象

```java
import java.utils.Arrays;
public class Test{
	public static void main(String[] args){
		int[] a={1,434,5,63,4223,56,8};
		System.out.print(a); //输出hashcode
		System.out.print(Arrays.toString(a))//将数组转换为字符串并打印
		Arrays.sort(a)
		System.out.print(a) //排序
	}
}
```

## 冒泡排序

```java
import java.utils.Arrays;
public class Test{
	public static void main(String[] args){
	}

	public static int[] sor(int[] arrays){
		int k=0;
		for (i=0;i<arrays.length-1;i++){
			int flag=0;
			for (j=0;j < arrays.length-1-i;j++){
				if (arrays[j]>arrays[j+1]){
						k = arrays[j+1];
						arrays[j+1]=arrays[j];
						arrays[j]=k;
						flag +=1;
				}
			}
			if (flag=0){
				break;   //优化算法
			}
		}
		return arrays;
	}
}
```

## 稀疏数组

```java
//当数组中大部分元素都为0，或者报错着相同的值的时候，可使用稀疏数组要锁数组尺寸
//第一行记录数组的行和列以及有效值的数量，后面的行记录记录每一个有效值的行列以及值

```

![](Untitled.png)

```java

public class Test{
	public static void main(String[] args){
	}
	//将二维数组转换为稀疏数组
	public static int[] sparseArray(int[] arr){
		//获取有效值的数量
		int sum=0;
		int max=0;
		for (int i=0;i<arr.length){
			for (int j=0;j<arr[i].length;j++)
				//获取有效值的行数
				if (arr[i][j] !=0){
					sum++; 
				}
				//获取最大的列数
				if ((arr[i].length>arr[i+1].length) && i<(arr.length-2)){
					max=arr[i].length;
				}
			}
		}
		//创建稀疏数组
		int[][] arrSpar = new int[sum+1][3];
		arrSpar[0][0]=arr.length;
		arrSpar[0][1]=max;
		arrSpar[0][2]=sum;
		int count=0;
		for (int k=0;k<arr.length;k++){
			for (int l=0;l<arr[k].length;l++){
				if (arr[k][l] !=0){
					count++;
					arrSpar[count][0]=k;
					arrSpar[count][1]=l;
					arrSpar[count][2]=arr[k][l];
				}
			}
		}
		return arr2;
	}
	//还原稀疏数组
	public static int[] restoreSparseArray(int[][] arrspar){
			//语句，明天再写	
			int[][] arr = new int[arrspar[0][0]][arrspar[0][1]];
			for (int h=1;h<arrspar.length;h++){
				arr[arrspar[h][0]][arrspar[h][1]]=arrspar[h][2];
			}
			return arr;
	}
	
}
	
```

## 内存分析

```java
//堆内存：存放new出来的对象或数组，可以被所有的线程共享，不会存放别的对象的引用
//栈内存：存放基本变量类型（存放变量的具体数值）引用对象的变量（存放这个引用在堆里面的具体地址）
//方法区：可以被所有线程共享，包含了所有的class和static变量
//声明数组时，压栈放入一个数组 此时，数组其实并不存在
//创建数组时，在堆种创建一片空间用以存放数组的值
//赋值数组，将数据放入堆之中

```

# 面向对象编程

**静态方法**-有static关键字，不需要通过对象调用

**动态方法**-无static关键字，需要通过对象调用

**形参**-函数定义的时候指定的参数，作为占位符使用

**实参**-函数调用的时候，实际传入的参数

**值传递**-将值复制一份进行传递，函数内部改变参数的值，不会应用外部变量的值。 **`JAVA中均为值传递`** 

**引用传递**-传递值得内存地址，改变函数中的值将同步改变外部该变量的值

同一个文件中可以有多个`class`，但只能有一个`public class`  

**构造器：**必须与类名同名，不能有返回值，且没有void。

**`属性封装，类继承，方法重写、多态`**  

**无参构造器**

```java
public class Test{
	public Test(){
		//构造方法
	}
	public static void main(String[] args){
	}		
}
//使用new的时候必须有构造器
```

**有参构造器**

```java
	public class Test{
		public Test(){}
		public Test(String name){
			//有参构造，**一旦定义了有参构造，无参就必须显式定义**
		}
	}
```

## 继承

```java
public class Student **extends** Persion{
	//语句
}
```

## 重写与this、super、多态

```java
//子类重写父类的方法
//重写是发生在父类与子类之间的，重载是发生在同一个类里面的。

//父类
public class Parent{
	public Parent(){
		System.out.println("父类无参构造方法");
	}
	protected String name="woshinibaba";
	public static void main(String[] args){}
	public void run(){
		System.out.print("father");
	}
}

//子类
public class Son extends Parent{
	public Son(){
		//**此处会调用父类的无参构造方法！！！父类如果定义了有参构造方法，那么子类将不能定义无参构造方法**
		System.out.println("字类无参构造方法")
	}
	private String name="armandhe";
	public static void main(String[] args){}
	@Override  //重写 方法名相同，参数列表必须相同，修饰符范围可以扩大，但不可以缩小，抛出异常的范围可以缩小但不可以扩大。
							//public > protected > default > private
	public void run(){
		System.out.print("son");
	}
	public void test(String name){
		this.run(); //输出son
		run(); //输出son，就近原则
		super.run(); //输出father
		System.out.pintln(name); //输出参数中的name
		System.out.println(this.name); //输出类变量name
		System.out.println(super.name); //输出父类的name
	}
}

//调用类
public class Application{
	public static void main(String[] args){
		Parent parent = new Parent;
		Son son = new Son;
		Parent test = new Student; **//注意这种调用方法，实际上是实例化了父类的引用，
															 //在其中可以使用父类的方法与属性，但不可以使用子
															 //类中独有的方法与属性，但可以使用子类中重写的父类的方法。
															 //只针对非静态方法
															 //静态方法不存在重写的概念，静态方法在类被加载的时候就被加载了**
		parent.run(); //输出father
		son.run(); //输出son
		son.test("hjx"); //分别输出hjx 与 armandhe 与 woshinibaba
		test.run(); //输出son
		test.
	}
}
```

## Instanceof

instanceof 判断两个类之间有没有父子关系

```java
Object => Person => Student ===object //实例对象 
Student object = new Student;
Person object = new Student;
Object object = new Student; 
object instanceof Student //上述三种请开给你均为true
```

## 类型转换

```java
Person obj new Student;
Student student = (Student)obj //强制类型转换 高转低 向下转型，可能会丢失一些方法
Person person = student; //自动类型转换 低转高 向上转型
```

## 代码块

```java
{
	//匿名代码块
}

static {
		//静态代码块
}
//执行顺序
//静态代码块在类加载的时候执行，匿名代码块在实例化类的时候执行，再执行构造方法
```

## 导入包

```java
import static java.lang.Math.random //静态导入包，导入后可以直接调用
System.out.print(random());

//被final修饰的类不能被继承，该类存在内存的方法区中
publib final void class Test{//语句}
```

## 抽象类

```java
//被abstract修饰的类，抽象类可以有抽象方法和普通方法，有抽象方法的类必须是抽象类
public abstract class Action{
	public void doSomething(); //抽象方法，只有方法名，没有方法体。只是一个约束
	public void doanotherthing(){
		//普通方法
	}
}
//抽象类不能被用来直接创建对象，即不能使用new方法创建。
//子类在继承抽象类的时候，必须要重写抽象类的方法。
public abstract run extends Action{
	@override
	public boid dosomething(){
		//重写父类方法
	}

}
```

## 接口

```java
//接口中只有规范，自己无法写方法。
public interface UserServer{
		public static void run(); //public 与static 可以省略，默认为这来给你个修饰符
	}
public interface TimeServer{
		public static void time(); //public 与static 可以省略，默认为这来给你个修饰符
	}
public class UserServerImpl implements UserServer,TimeServer{
	//接口可以实现多继承
	@Override
	public void run(){
		//重写方法
	}
	@Override
	public void time(){
		//重写方法
	}
}
```