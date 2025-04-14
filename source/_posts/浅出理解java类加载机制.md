---
title: 浅出理解java类加载机制
date: 2025-04-14 10:33:52
tags:
- java
- 类加载
categories:
  - [漏洞分析]
---
> 预防针先打着，这篇文章我准备搬大部分，不要骂我

参考链接：
[深入理解Java类加载器(ClassLoader)](https://blog.csdn.net/javazejian/article/details/73413292)
[Java类加载机制](https://zhuanlan.zhihu.com/p/25228545)
[深入理解Java类加载](https://www.cnblogs.com/czwbig/p/11127222.html)

# Class类
>没有条理，只做记录 

Java程序运行时，系统一直对所有的对象进行这所谓的运行时类型标识。这项信息记录了每个对象所属的类。虚拟机通常使用该信息去选择正确的对象与方法执行，而用来保存这些类型信息的类就是Class类。Class封装一个对象和接口运行时的状态，当加载一个类的时候，Class类的对象就被创建了，也就是说，一个Class类的对象封装了一个类的类型信息，可以通过该对该对象的操作来实现对类的操作，这就是反射的原理。
既然Class类的对象封装了一个类的信息，这些信息一般包括类名、实现的接口、父类、成员方法、成员变量、注解等信息，也就是说，我们可以操作这些信息。
Class类的每一个实例都代表着一个运行中的类
Class类没有公有的构造方法，这也就意味着其不能通过new的方式来创建一个实例，Class类的对象是由jvm来创建的。
同时需要知道在JVM中，每个类只有唯一的一个Class对象，而标识一个唯一的类是通过他的完全限定名以及加载他的类加载器。在运行程序的时候，JVM首先会在缓存中判断当前类是不是已经被加载了，也就是findLoadedClass方法。如果没有加载，然后会将加载的权限交给当前类加载器的父类加载器加载，父类加载器会继续向上递交加载权限，知道某一级加载器的父类为null之后，该类的加载权限会被交给启动类加载器，启动类加载器如果不能加载该类，则向下一次按相反的顺序移交加载权限，直到某一级成功加载该类，这就是java的双亲委派机制，下面我们会从代码层面观察该机制。类加载器加载类是通过loadClass方法实现的。在loadClass方法中类加载最下层调用了一个称为findClass的方法，该方法实现了将class文件加载到内存，然后再通过defineClass方法将字节码转换为一个java Class对象。
我们可以通过下面演示的集中方式获得一个Class对象
<!--more-->
```java
package com.armandhe.javabase;

public class ClassLoaderTest1 {
    public static void main(String[] args)  throws Exception{
        ClassLoaderTest1 classLoaderTest1 = new ClassLoaderTest1();
        Class<? extends ClassLoaderTest1> aClass = classLoaderTest1.getClass();
        Class<ClassLoaderTest1> classLoaderTest1Class = ClassLoaderTest1.class;
        Class<?> aClass1 = Class.forName("com.armandhe.javabase.ClassLoaderTest1");
        System.out.println(aClass1 == classLoaderTest1Class);
        System.out.println(aClass1 == aClass1);
    }
}
```
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/2d78d0aedc7a41aa3edf16fb93accf19.png)
我们看到通过三者获得同一个类的Class对象是一样的，这就验证了同一个类只有一个Class对象的结论，我们可以在看看他们的类加载器其实也是一样的：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/7080f57b69b4ce44df7b01d962c299df.png)
后面我们将会演示类加载器不一样的效果。
我们再看一下下面的效果：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/228af10ce4994de5f98b481360103e02.png)
这里我们加载了两个名字不一样的类，当然他们的Class实例是不相等的，不过他们的类加载器是一样的，根据上面的理论，只要类加载器和完全限定名有一个不一样则两个类的Class实例就是不相等的。
可以用下面的图来描述：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/341916fed5b2790dc1eeff41a74a758c.png)

# Java反射机制
上面提到JVM在加载类的时候会先创建该类的Class类实例，该实例存储了与该类所有的字段、方法等信息，通过该实例就可以生成对应的类对象。在Java中Class实例是可以人工生成的，这一特性打通了人工生成类对象的桎梏，通过这一特性Java实现了反射机制。
所谓反射就是在运行状态中，对于任意一个类，都能够知道这个类的所有属性和方法；对于任意一个对象，都能调用它的任意方法和属性；并且能改变他的属性。
关于java反射的详情就不说了，使用的话主要就是几个获取属性、方法、构造方法的方法。
# Java类加载
Java的类加载一般都要经过加载->验证->准备->解析->初始化五个阶段，当然一个类的完整声明周期应该还要包括使用域卸载。
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/4f036e073b0688a19eef09f7195bd5db.png)

- 加载：类加载过程的一个阶段：通过一个类的完全限定查找此类字节码文件，并利用字节码文件创建一个Class对象

- 验证：目的在于确保Class文件的字节流中包含信息符合当前虚拟机要求，不会危害虚拟机自身安全。主要包括四种验证，文件格式验证，元数据验证，字节码验证，符号引用验证。

- 准备：为类变量(即static修饰的字段变量)分配内存并且设置该类变量的初始值即0(如static int i=5;这里只将i初始化为0，至于5的值将在初始化时赋值)，这里不包含用final修饰的static，因为final在编译的时候就会分配了，注意这里不会为实例变量分配初始化，类变量会分配在方法区中，而实例变量是会随着对象一起分配到Java堆中。

- 解析：主要将常量池中的符号引用替换为直接引用的过程。符号引用就是一组符号来描述目标，可以是任何字面量，而直接引用就是直接指向目标的指针、相对偏移量或一个间接定位到目标的句柄。有类或接口的解析，字段解析，类方法解析，接口方法解析(这里涉及到字节码变量的引用，如需更详细了解，可参考《深入Java虚拟机》)。

- 初始化：类加载最后阶段，若该类具有超类，则对其进行初始化，执行静态初始化器和静态初始化成员变量(如前面只初始化了默认值的static变量将会在这个阶段赋值，成员变量也将被初始化)。

加载后面的三个截断又被统称为连接阶段。
对验证阶段的说明如下：

- 文件格式验证：如是否以幻数 0xCAFEBABE 开头、主、次版本号是否在当前虚拟机处理范围之内、常量合理性验证等。
此阶段保证输入的字节流能正确地解析并存储于方法区之内，格式上符合描述一个 Java类型信息的要求。
- 元数据验证：是否存在父类，父类的继承链是否正确，抽象类是否实现了其父类或接口之中要求实现的所有方法，字段、方法是否与父类产生矛盾等。
第二阶段，保证不存在不符合 Java 语言规范的元数据信息。
- 字节码验证：通过数据流和控制流分析，确定程序语义是合法的、符合逻辑的。例如保证跳转指令不会跳转到方法体以外的字节码指令上。
- 符号引用验证：在解析阶段中发生，保证可以将符号引用转化为直接引用。

在初始化阶段，其实就是执行`<clinit>()`方法的过程，`<clinit>()` 方法是编译器在类中收集的类变量的赋值动作与静态代码块中的语句组合的一个方法，也就是说执行`<clinit>()` 方法就会对类变量进行赋值以及执行类中静态代码块中的语句。`<clinit>()` 方法并不会显示的调用父类的`<clinit>()` 方法而是隐式得调用，也就是说我们在初始化时手工去调用父类的`<clinit>()` 方法，jvm会保证父类的`<clinit>()` 方法在子类的`<clinit>()` 方法之前执行完毕。当然接口例外，几口不需要调用父类的`<clinit>()` 方法，除非在使用到父接口中的静态标量时才需要进行调用。
当一个类中没有静态代码块以及类变量的复制操作时，`<clinit>()` 可以不存在。
JVM会保证一个类的`<clinit>()` 方法在多线程中只被执行一次，当一个线程在执行`<clinit>()` 时其他线程都需阻塞等待，直到当前线程`<clinit>()` 执行完毕。
## 类加载的时机
对于初始化阶段，虚拟机规范规定了有且只有 5 种情况必须立即对类进行“初始化”（而加载、验证、准备自然需要在此之前开始）：
- 遇到new、getstatic 和 putstatic 或 invokestatic 这4条字节码指令时，如果类没有进行过初始化，则需要先触发其初始化。对应场景是：使用 new 实例化对象、读取或设置一个类的静态字段（被 final 修饰、已在编译期把结果放入常量池的静态字段除外）、以及调用一个类的静态方法。
- 对类进行反射调用的时候，如果类没有进行过初始化，则需要先触发其初始化。
- 当初始化类的父类还没有进行过初始化，则需要先触发其父类的初始化。（而一个接口在初始化时，并不要求其父接口全部都完成了初始化）
- 虚拟机启动时，用户需要指定一个要执行的主类（包含 main() 方法的那个类），虚拟机会先初始化这个主类。
- 当使用 JDK 1.7 的动态语言支持时，如果一个 java.lang.invoke.MethodHandle 实例最后的解析结果 REF_getStatic、REF_putStatic、REF_invokeStatic 的方法句柄，并且这个方法句柄所对应的类没有进行过初始化，则需要先触发其初始化。
以上这 5 种场景中的行为称为对一个类进行主动引用。除此之外，所有引用类的方式都不会触发初始化，称为被动引用，例如：
- 通过子类引用父类的静态字段，不会导致子类初始化。
- 通过数组定义来引用类，不会触发此类的初始化。MyClass[] cs = new MyClass[10];
- 常量在编译阶段会存入调用类的常量池中，本质上并没有直接引用到定义常量的类，因此不会触发定义常量的类的初始化。
## 类加载
类加载就是加载器更具一个类的完全限定名来读取此类的二进制字节流到JVM中，然后转换为一个与目标类对应的Class实例对象。在JVM中提供了三种内置的类加载器，启动类加载器、扩展类加载器、应用类加载器。
### 启动类加载器
启动类加载器用来加载JVM自身需要的类，这个类加载器使用C++实现，没有父类，其父加载器为null，负责将%JAVAHOME%/lib下面的核心类库或者-X bootclasspath参数指定路径下的jar包加载到内存中。启动类记载器只加载java、javax、sun等开头的类。如果现在我要加载一个java.lang.String的类，但该类不在上述目录里面，因为双亲委派机制的原因，其加载权限会被发送到启动类加载器，但是因为其不在上述目录下面，所以不会被加载。这就保证了java的核心类库不被污染与篡改，这就是双亲委派机制的魅力。
### 扩展类加载器
扩展类加载器有ExtClassLoader实现，ExtClassLoader是sun.misc.Launcher的内部静态类。其负责加载%JAVA_HOME%/lib/ext目录下或者由命令-Djava.ext.jar指定的路径中的类库。
### 系统类加载器
也叫作应用类加载器，由sun.misc.Launcher$AppClassLoader实现。它负责加载系统类路径java -classpath或-D java.class.path 指定路径下的类库，也就是我们经常用到的classpath路径，开发者可以直接使用系统类加载器，一般情况下该类加载是程序中默认的类加载器，通过ClassLoader#getSystemClassLoader()方法可以获取到该类加载器。
### 双亲委派机制
双亲委派模式要求除了顶层的启动类加载器外，其余的类加载器都应当有自己的父类加载器，请注意双亲委派模式中的父子关系并非通常所说的类继承关系，而是采用组合关系来复用父类加载器的相关代码，类加载器间的关系如下：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/e9f6babf2c9e05d5b3a8d7c37ebe03e9.png)
双亲委派模式是在Java 1.2后引入的，其工作原理的是，如果一个类加载器收到了类加载请求，它并不会自己先去加载，而是把这个请求委托给父类的加载器去执行，如果父类加载器还存在其父类加载器，则进一步向上委托，依次递归，请求最终将到达顶层的启动类加载器，如果父类加载器可以完成类加载任务，就成功返回，倘若父类加载器无法完成此加载任务，子加载器才会尝试自己去加载。
采用双亲委派模式的是好处是Java类随着它的类加载器一起具备了一种带有优先级的层次关系，通过这种层级关可以避免类的重复加载，当父亲已经加载了该类时，就没有必要子ClassLoader再加载一次。其次是考虑到安全因素，java核心api中定义类型不会被随意替换，假设通过网络传递一个名为java.lang.Integer的类，通过双亲委托模式传递到启动类加载器，而启动类加载器在核心Java API发现这个名字的类，发现该类已被加载，并不会重新加载网络传递的过来的java.lang.Integer，而直接返回已加载过的Integer.class，这样便可以防止核心API库被随意篡改。可能你会想，如果我们在classpath路径下自定义一个名为java.lang.SingleInterge类(该类是胡编的)呢？该类并不存在java.lang中，经过双亲委托模式，传递到启动类加载器中，由于父类加载器路径下并没有该类，所以不会加载，将反向委托给子类加载器加载，最终会通过系统类加载器加载该类。但是这样做是不允许，因为java.lang是核心API包，需要访问权限，强制加载将会报出如下异常
> java.lang.SecurityException: Prohibited package name: java.lang

我们通过下图来认识双亲委派机制：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/6ec421d5e6bd36ebf52f4ab62f190c06.png)
从图可以看出顶层的类加载器是ClassLoader类，它是一个抽象类，其后所有的类加载器都继承自ClassLoader（不包括启动类加载器），这里我们主要介绍ClassLoader中几个比较重要的方法。

### 双亲委派的过程
我们来看看AppClassLoader#loadClass的代码
```java
public Class<?> loadClass(String var1, boolean var2) throws ClassNotFoundException {
            int var3 = var1.lastIndexOf(46);
            if (var3 != -1) {
                SecurityManager var4 = System.getSecurityManager();
                if (var4 != null) {
                    var4.checkPackageAccess(var1.substring(0, var3));
                }
            }

            if (this.ucp.knownToNotExist(var1)) {
                Class var5 = this.findLoadedClass(var1);
                if (var5 != null) {
                    if (var2) {
                        this.resolveClass(var5);
                    }

                    return var5;
                } else {
                    throw new ClassNotFoundException(var1);
                }
            } else {
                return super.loadClass(var1, var2);
            }
        }
```
前面是建立了一个安全管理器啥的，具体啥意思咱也不懂，还没到那个地步。主要的代码是下面一个if判断。
首先通过findLoadedClass方法去缓存中查找当前类是否已经被家在过了，如果没有被加载过则调用super.laodClass方法去加载类，我们跟进super.loadClass方法:
```java
protected Class<?> loadClass(String name, boolean resolve)
        throws ClassNotFoundException
    {
        synchronized (getClassLoadingLock(name)) {
            // First, check if the class has already been loaded
            Class<?> c = findLoadedClass(name);
            if (c == null) {
                long t0 = System.nanoTime();
                try {
                    if (parent != null) {
                        c = parent.loadClass(name, false);
                    } else {
                        c = findBootstrapClassOrNull(name);
                    }
                } catch (ClassNotFoundException e) {
                    // ClassNotFoundException thrown if class not found
                    // from the non-null parent class loader
                }

                if (c == null) {
                    // If still not found, then invoke findClass in order
                    // to find the class.
                    long t1 = System.nanoTime();
                    c = findClass(name);

                    // this is the defining class loader; record the stats
                    sun.misc.PerfCounter.getParentDelegationTime().addTime(t1 - t0);
                    sun.misc.PerfCounter.getFindClassTime().addElapsedTimeFrom(t1);
                    sun.misc.PerfCounter.getFindClasses().increment();
                }
            }
            if (resolve) {
                resolveClass(c);
            }
            return c;
        }
    }
```
首先是获得了一把锁，具体干啥的咱也不知道。然后同样的调用了findLoadedClass方法去缓存中查找，如果没有找到则判断父类是否为空，如果不为空则调用父类的loadClass方法加载类，如果为空则调用启动类加载器加载类。如果仍然没有找到，借c==null，则调用findClass方法。
而扩展类加载器的父类我们知道为null，那么其肯定会让启动类加载器去加载类。
那么为什么为null呢，看下面的代码：
```java
public ExtClassLoader(File[] var1) throws IOException {
            super(getExtURLs(var1), (ClassLoader)null, Launcher.factory);
            SharedSecrets.getJavaNetAccess().getURLClassPath(this).initLookupCache(this);
        }
```
这里调用了父类的构造方法，注意这里第二个参数为null，我们跟进去：
```java
public URLClassLoader(URL[] urls, ClassLoader parent,
                          URLStreamHandlerFactory factory) {
        super(parent);
        // this is to make the stack depth consistent with 1.1
        SecurityManager security = System.getSecurityManager();
        if (security != null) {
            security.checkCreateClassLoader();
        }
        acc = AccessController.getContext();
        ucp = new URLClassPath(urls, factory, acc);
    }
```
这里我们看到继续调用了父类的构造方法，继续跟：
```java
protected SecureClassLoader(ClassLoader parent) {
        super(parent);
        // this is to make the stack depth consistent with 1.1
        SecurityManager security = System.getSecurityManager();
        if (security != null) {
            security.checkCreateClassLoader();
        }
        initialized = true;
    }
```
继续跟：
```java
protected ClassLoader(ClassLoader parent) {
        this(checkCreateClassLoader(), parent);
    }
```
继续：
```java
private ClassLoader(Void unused, ClassLoader parent) {
        this.parent = parent;
        if (ParallelLoaders.isRegistered(this.getClass())) {
            parallelLockMap = new ConcurrentHashMap<>();
            package2certs = new ConcurrentHashMap<>();
            assertionLock = new Object();
        } else {
            // no finer-grained lock; lock on the classloader instance
            parallelLockMap = null;
            package2certs = new Hashtable<>();
            assertionLock = this;
        }
    }
```
这里看到this.parend 被赋值为传进来的形参parent，而这个参数值为null，所以扩展类加载器的父类为null。

当我们跟到findClass方法里面发现了：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/244da1d4d3043573f856bec2aad525b0.png)
直接抛出了异常，所以如果我们需要加载任意路径的类就需要重写findClass方法。
findClass方法中实现的功能就是从文件系统加载class文件到内存，然后通过defineClass方法生成一个Class对象，defineClass方法的逻辑在ClassLoader类中实现了。看下面的一个findClass的实现：
```java
@Override
    protected Class<?> findClass(String name) throws ClassNotFoundException {
        System.out.println("正在查找类@");
        // 获取类的字节数组
        byte[] classData = new byte[0];

        classData = getClassData(name);
        if (classData == null) {
            throw new ClassNotFoundException();
        } else {
            //使用defineClass生成class对象
            return defineClass(name, classData, 0, classData.length);
        }

    }
```
getClassData方法实现的是从文件系统加载字节码数据：
```java
private byte[] getClassData(String className) {
        System.out.println("正在获取字节数据");
        try {
            byte[] bytes = new byte[4096];
            int len = -1;
            String s = classNameToPath(className);
            ByteArrayOutputStream byteArrayOutputStream = new ByteArrayOutputStream();
            InputStream inputStream = new FileInputStream(new File(s));
            //        ObjectInputStream objectInputStream = new ObjectInputStream(inputStream);
            while ((len = inputStream.read(bytes)) != -1) {
                byteArrayOutputStream.write(bytes, 0, len);
            }
            return byteArrayOutputStream.toByteArray();
        }catch (IOException e){
            e.printStackTrace();
        }
        return null;
}
```

classNameToPath则是将输入的文件名转换为对应路径的逻辑：
```java
private String classNameToPath(String classname){
        return rootDir + File.separatorChar + classname.replace('.', File.separatorChar) + ".class";
    }
```
这样一个findClass方法的简单逻辑就实现了。完整的代码如下：
```java
package com.armandhe.javabase;

import java.io.*;
import java.lang.Class;



class FileClassLoader extends ClassLoader{
    private String rootDir;

    public FileClassLoader(String rootDir) {
        this.rootDir = rootDir;
    }


    @Override
    protected Class<?> findClass(String name) throws ClassNotFoundException {
        System.out.println("正在查找类@");
        // 获取类的字节数组
        byte[] classData = new byte[0];

        classData = getClassData(name);
        if (classData == null) {
            throw new ClassNotFoundException();
        } else {
            //使用defineClass生成class对象
            return defineClass(name, classData, 0, classData.length);
        }

    }

    private String classNameToPath(String classname){
        return rootDir + File.separatorChar + classname.replace('.', File.separatorChar) + ".class";
    }

    private byte[] getClassData(String className) {
        System.out.println("正在获取字节数据");
        try {
            byte[] bytes = new byte[4096];
            int len = -1;
            String s = classNameToPath(className);
            ByteArrayOutputStream byteArrayOutputStream = new ByteArrayOutputStream();
            InputStream inputStream = new FileInputStream(new File(s));
            //        ObjectInputStream objectInputStream = new ObjectInputStream(inputStream);
            while ((len = inputStream.read(bytes)) != -1) {
                byteArrayOutputStream.write(bytes, 0, len);
            }
            return byteArrayOutputStream.toByteArray();
        }catch (IOException e){
            e.printStackTrace();
        }
        return null;
}}

public class ClassLoaderTest {
    public static void main(String[] args){
        String rootDir = "E:\\desktop\\java\\javatest\\target\\classes";
        FileClassLoader fileClassLoader = new FileClassLoader(rootDir);
//        fileClassLoader.getClassData("test");
        System.out.println("自定义类加载器的父加载器："+fileClassLoader.getParent());
        System.out.println("系统类加载器："+ClassLoader.getSystemClassLoader());
        System.out.println("系统类加载器的父加载器："+ClassLoader.getSystemClassLoader().getParent());
        System.out.println("扩展类加载器的父加载器："+ClassLoader.getSystemClassLoader().getParent().getParent());
        try {
            Class<?> aClass = fileClassLoader.findClass("com.armandhe.javabase.ClassLoaderDemo");
            System.out.println(aClass.newInstance());
            aClass.getMethod("test").invoke(null);
        } catch (Exception e) {
            System.out.println("类未发现！");
        }
    }
}
```

运行结果：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/5b05384bf5cd30d49c453edd95c5db86.png)
在上面我们我们提到了在loadClass方法中有一个参数var2，如果var2==true则掉哦用了resolveClass方法，使用该方法可以使用类的Class对象创建完成也同时被解析。前面我们说链接阶段主要是对字节码进行验证，为类变量分配内存并设置初始值同时将字节码文件中的符号引用转换为直接引用。
还有个线程上下文加载器，写不动了！！！去看原文吧
jdbc就使用的线程上线文加载器，一般来说线程上下文加载器使用的是系统类加载器，但在某些中间件中其使用的是自定义的类加载器，如tomcat。



