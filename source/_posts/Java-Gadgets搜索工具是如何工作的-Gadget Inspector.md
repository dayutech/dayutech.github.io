---
title: Java-Gadgets搜索工具是如何工作的-Gadget Inspector
tags:
  - Java Gadgets
  - Gadget Inspector
  - 反序列化
  - 反序列化利用链
categories:
  - - 漏挖工具
abbrlink: a580d790
date: 2025-04-11 11:19:48
top: 102
---
# Java Gadgets 搜索工具是如何工作的（Gadget Inspector）
Gadget Inspector 由 Ian Haken 于 2018 年 8 月在  DEF CON 上发布，其发布开创了Gadget 自动化挖掘的先河。Gadget Inspector 依靠Java ASM    
技术，通过静态模拟 Java 程序运行过程中操作数栈以及局部变量表的动态变化来进行数据流跟踪从而实现污点分析进而进行Gadgets探测。  
### 检测原理
Gadget Inspector 的核心逻辑包含5个步骤，分别是类信息分析、数据传播分析、调用图构造、入口探测以及Gadgets串联。  
在第一步中 Gadget Inspector 利用 MethodDiscovery 类对 当前环境中所有类的方法、成员、继承结构进行解析并集中存储在特定的数据结构中以便后续进行    
数据传播分析以及调用图构造。  
在第二步中 Gadget Inspector 利用 PassthroughDiscovery 类运用 深度优先算法、逆拓扑排序等方式进行数据流分析从而确认方法入参与返回值的关系，    
即入参是否能够污染到返回值，其根本目的在于确认关键参数是否可以被攻击者控制。  
在第三步中 Gadget Inspector 通过 Java ASM 技术构造方法调用图，其目的在于确认主调方法与被调用方法参数之间的关系。  
第四步中 Gadget Inspector 通过 SourceDiscovery 针对不同的夫序列化类型进行分发，通过对比第一步中形成的methodMap中存储的方法信息与预定义  
的反序列化 Gadget Source点进行比较，从而确定当前项目中可被使用的反序列化入口方法。  
在第五步中 Gadget  Inspector 开始从Source点开始遍历调用图，直到找到一个方法与预定义的sink点相匹配则说明Gadget Inspector 找到了一条可以  
使用的反序列化调用链。  
<!--more-->
```java
public static void main(String[] args) throws Exception {
        ...
        // Perform the various discovery steps
        // 对类结构进行分析 包括类的方法信息  成员信息等
        if (!Files.exists(Paths.get("classes.dat")) || !Files.exists(Paths.get("methods.dat"))
                || !Files.exists(Paths.get("inheritanceMap.dat"))) {
            LOGGER.info("Running method discovery...");
            MethodDiscovery methodDiscovery = new MethodDiscovery();
            methodDiscovery.discover(classResourceEnumerator);
            methodDiscovery.save();
        }
        // 对方法的入参与返回值的关系进行分析
        if (!Files.exists(Paths.get("passthrough.dat"))) {
            LOGGER.info("Analyzing methods for passthrough dataflow...");
            PassthroughDiscovery passthroughDiscovery = new PassthroughDiscovery();
            passthroughDiscovery.discover(classResourceEnumerator, config);
            passthroughDiscovery.save();
        }
        // 对方法调用之间参数的关系进行分析
        if (!Files.exists(Paths.get("callgraph.dat"))) {
            LOGGER.info("Analyzing methods in order to build a call graph...");
            CallGraphDiscovery callGraphDiscovery = new CallGraphDiscovery();
            callGraphDiscovery.discover(classResourceEnumerator, config);
            callGraphDiscovery.save();
        }
        // 根据预定义规则查找所有的source点
        if (!Files.exists(Paths.get("sources.dat"))) {
            LOGGER.info("Discovering gadget chain source methods...");
            SourceDiscovery sourceDiscovery = config.getSourceDiscovery();
            sourceDiscovery.discover();
            sourceDiscovery.save();
        }

        {   
            // 查找 gadget chain
            LOGGER.info("Searching call graph for gadget chains...");
            GadgetChainDiscovery gadgetChainDiscovery = new GadgetChainDiscovery(config);
            gadgetChainDiscovery.discover();
        }

        LOGGER.info("Analysis complete!");
    }
```
#### 类结构分析
Gadget Inspector 针对项目中的类的结构分析开始于 MethodDiscovery 类的 discover 方法。  
classResourceEnumerator 类存储了当前项目中所有被指定的需要分析的类信息，包括用户指定的jar包、JDK原生的依赖库。通过获取每一个类的字节码流将其传递给  
ASM框架的ClassVisitor对每一个类进行解析。
```java
public void discover(final ClassResourceEnumerator classResourceEnumerator) throws Exception {
        for (ClassResourceEnumerator.ClassResource classResource : classResourceEnumerator.getAllClasses()) {
            try (InputStream in = classResource.getInputStream()) {
                ClassReader cr = new ClassReader(in);
                try {
                    cr.accept(new MethodDiscoveryClassVisitor(), ClassReader.EXPAND_FRAMES);
                } catch (Exception e) {
                    LOGGER.error("Exception analyzing: " + classResource.getName(), e);
                }
            }
        }
    }
```
MethodDiscoveryClassVisitor 类是 ASM 框架 ClassVisitor 类的实现类，在当前步骤中 MethodDiscoveryClassVisitor 主要通过实现 ClassVistor  
的 visit visitField visitMethod visitEnd 方法类对类的字段、方法进行分析。  
上述四个方法将按照顺序依次调用，首先是visit方法被调用，用于访问类的基本信息（如版本、访问标志、类名、父类名、接口等），它标志着类的开始。
需要特别说明的是 ClassReference.Handle 表示某一个类的处理句柄，Gadget Inspector将类名封装到该类中用以作为后续步骤中从各种数据结构中访问类信息的句柄  
不仅类名被封装通过句柄访问，后续类方法以及类成员信息同样被封装为句柄。与类不同方法句柄将不经包含方法名信息，还将包括方法签名、返回值等信息。
```java
public void visit ( int version, int access, String name, String signature, String superName, String[]interfaces)
        {
            this.name = name;
            this.superName = superName;
            this.interfaces = interfaces;
            this.isInterface = (access & Opcodes.ACC_INTERFACE) != 0;
            this.members = new ArrayList<>();
            this.classHandle = new ClassReference.Handle(name);

            super.visit(version, access, name, signature, superName, interfaces);
        }
```
当 visit 方法调用完毕后，visitField方法会被调用，用于访问类中的每个字段。如果存在多个字段，visitField会为每个字段单独调用依次。  
该重载方法中对字段的访问修饰符进行了判断，如果当前字段的访问修饰符为 ACC_STATIC 即被 static 关键词修饰则步记录该字段到 members 变量中。   
这是因为静态字段在类加载时被初始化不能被攻击者所控制修改，于反序列化漏洞无益。针对引用数据类型Object以及Array，Gadget Inspector只获取其内部类型   
而不必获取其完整的类型描述符，如：变量 String s，其类型描述符为 Ljava/lang/String;，而其内部类型为 java/lang/String。  
类成员信息最终被封装为 ClassReference.Member 类并存储在 members 变量中，该类封装了字段名、访问修饰符以及字段类型。  
```java
public FieldVisitor visitField(int access, String name, String desc,
                                       String signature, Object value) {
            if ((access & Opcodes.ACC_STATIC) == 0) {
                Type type = Type.getType(desc);
                String typeName;
                if (type.getSort() == Type.OBJECT || type.getSort() == Type.ARRAY) {
                    typeName = type.getInternalName();
                } else {
                    typeName = type.getDescriptor();
                }
                members.add(new ClassReference.Member(name, access, new ClassReference.Handle(typeName)));
            }
            return super.visitField(access, name, desc, signature, value);
        }
```
在所有字段都被访问完后，visitMethod 方法会被调用，用于访问类中的每个方法。如果有多个方法，visitMethod 会为每个方法依次调用一次。   
visitMethod方法将当前类中所有的方法封装为 MethodReference 类，并最终被存储在 discoveredMethods 变量中。    
需要特别注意的是在进行方法信息存储是存储了当前方法是否是类方法，该信息主要在后续进行数据流传播分析时对静态方法进行特殊处理。  
```java
@Override
        public MethodVisitor visitMethod(int access, String name, String desc, String signature, String[] exceptions) {
            boolean isStatic = (access & Opcodes.ACC_STATIC) != 0;
            discoveredMethods.add(new MethodReference(
                    classHandle,
                    name,
                    desc,
                    isStatic));
            return super.visitMethod(access, name, desc, signature, exceptions);
        }
```

当类的所有字段和方法都被访问完毕后，visitEnd 方法会被调用，表示类访问的结束。  
该方法将已经访问的类信息封装为ClassReference对象存储在 discoveredClasses 变量中，用于标识已经被访问过的类。  
```java
@Override
        public void visitEnd() {
            ClassReference classReference = new ClassReference(
                    name,
                    superName,
                    interfaces,
                    isInterface,
                    members.toArray(new ClassReference.Member[members.size()]));
            discoveredClasses.add(classReference);

            super.visitEnd();
        }
```
上述四个方法调用完毕后，我们便可通过 MethodDiscovery 对象的 discoveredClasses 以及 discoveredMethods 变量获取到当前类中所有字段以及方法信息。  
为了方便后续过程使用这一步生成的信息，Gadget Inspector 调用 MethodDiscovery 的 save 方法将这些信息保存到本地文件中分别为 classes.dat 以及 methods.dat  
用以存储类信息以及方法信息。   
classes.dat的数据存储结构为：  
全类名|父类名|接口列表|是否是接口|成员列表  
methods.dat的数据存储结构为：  
所属类全类名|方法名|方法描述符|是否是静态方法  
类基本信息存储完毕后 Gadget Inspector 将利用 discoveredClasses 变量中存储的类信息计算类的继承树并将其存储到 inheritanceMap.dat 文件中。  
首先从 ClassReference 对象中获取父类以及接口信息，再从classMap中获取到当前类的父类与接口的 ClassReference 对象，最后进行递归调用，获得基类的所有  
父类以及接口。  
```java
private static void getAllParents(ClassReference classReference, Map<ClassReference.Handle, ClassReference> classMap, Set<ClassReference.Handle> allParents) {
        Set<ClassReference.Handle> parents = new HashSet<>();
        if (classReference.getSuperClass() != null) {
        parents.add(new ClassReference.Handle(classReference.getSuperClass()));
        }
        for (String iface : classReference.getInterfaces()) {
        parents.add(new ClassReference.Handle(iface));
        }

        for (ClassReference.Handle immediateParent : parents) {
        ClassReference parentClassReference = classMap.get(immediateParent);
        if (parentClassReference == null) {
        LOGGER.debug("No class id for " + immediateParent.getName());
        continue;
        }
        allParents.add(parentClassReference.getHandle());
        getAllParents(parentClassReference, classMap, allParents);
        }
        }
```
最终 inheritanceMap.dat 的数据存储结构为：  
当前类全类名|父类以及接口列表  
#### 数据流分析
数据流分析是 Gadget Inspector 中最核心的模块，其目的是对数据流进行传播分析，从而确定方法入参与返回值的关系。数据流分析整体上分为3步，即构造方法调用图、  
对所有方法进行逆拓扑排序、计算数据传播流图。  
##### 分析方法调用关系
```java
public void discover(final ClassResourceEnumerator classResourceEnumerator, final GIConfig config) throws IOException {
        Map<MethodReference.Handle, MethodReference> methodMap = DataLoader.loadMethods();
        Map<ClassReference.Handle, ClassReference> classMap = DataLoader.loadClasses();
        InheritanceMap inheritanceMap = InheritanceMap.load();

        Map<String, ClassResourceEnumerator.ClassResource> classResourceByName = discoverMethodCalls(classResourceEnumerator);
        List<MethodReference.Handle> sortedMethods = topologicallySortMethodCalls();
        passthroughDataflow = calculatePassthroughDataflow(classResourceByName, classMap, inheritanceMap, sortedMethods,
                config.getSerializableDecider(methodMap, inheritanceMap));
    }
```
方法调用图的构造只是简单得使用 MethodCallDiscoveryClassVisitor 这个 ClassVisitor 通过对其重写的 visitMethod 方法进行调用时通过引入   
MethodCallDiscoveryMethodVisitor 这个  MehtodVisitor，通过其 visitMethodInsn 方法的调用从而记录当前类的每一个方法在用过程中发起了哪些其他的方法调用。  
visitMethodInsn 方法监听的方法调用类型包括 INVOKEVIRTUAL、INVOKESPECIAL、INVOKESTATIC、INVOKEINTERFACE，  
即实例方法调用、（构造函数，私有方法，父类方法）、静态方法调用、接口方法调用。   
```java
@Override
        public void visitMethodInsn(int opcode, String owner, String name, String desc, boolean itf) {
            calledMethods.add(new MethodReference.Handle(new ClassReference.Handle(owner), name, desc));
            super.visitMethodInsn(opcode, owner, name, desc, itf);
        }
```
这些方法调用最终会被记录到 methodCalls 变量中并通过对应的方法句柄进行索引。  
```java
public MethodCallDiscoveryMethodVisitor(final int api, final MethodVisitor mv,
                                           final String owner, String name, String desc) {
            super(api, mv);

            this.calledMethods = new HashSet<>();
            methodCalls.put(new MethodReference.Handle(new ClassReference.Handle(owner), name, desc), calledMethods);
        }
```
##### 拓扑排序
在了解Gadget Inspector 的逆拓扑排序方法之前，我们首先需要了解以下什么是拓扑排序，当前情境下为什么需要拓扑排序。  
###### 图相关概念
假设存在一个二元组 G = (V, E)，其中V是一系列点的集合，E是一系列边的集合，其中V = {v1, v2, v3, v4, v5}，E = {(v1, v2), (v2, v3), (v3, v4), (v4, v5), (v5, v1)}，那么G就是一个图。   
我们将V中的某一个点称为这个图的顶点，与该顶点相关联的边的条数称为该顶点的度，例如：在图G中，与顶点 v1 相关的边为(v1, v2) 和 (v5, v1)，故其度为2。   
度又分为入度与出度，一个顶点的入度指的是以该顶点为终点的边数，出度指的是以该顶点为起点的边数，故顶点 V1 的入度与出度均为1。   
在图G中，每一条边均是有方向的，被记作(u, v)，故称图G是一个有向图。在一个图中一系列相互连接的边被称为一条途径，若边两两不同则被称为一条迹，若点也两两不同，则被称为一条路径。   
对于一条迹，如果其起点与终点一致，那么该迹称为一条回路。对于一条回路，如果其起点与终点是唯一相同的点，则称该回路是一个环。  
所谓有向无环图则必须满足两个条件，其一该图是一个有向图；其二该图不存在环。  
有向无环图存在两个性质，其一能进行拓扑排序的图，一定是有向无环图；其二有向无环图一定能进行拓扑排序。  
###### 为什么需要将所有方法进行拓扑排序
拓扑排序的目标是将所有节点排序，使得排在前面的节点不能依赖于排在后面的节点。
在本项目中，我们需要求解的是方法的参数与返回值的关系，而一个方法调用中可能存在另外一个方法调用，该方法可能会接受外层方法的参数同时其返回值可能会影响外层方法的局部变量，  
而该局部变量又可能会影响外层方法的返回值， 故我们在对外层方法的入参与返回值的关系进行求解时需要先对内层被调用方法的入参与返回值的关系进行求解。  
在下面的例子中，我们如果需要判断方法a的参数arg会不会污染其返回值。因为返回值br来自于方法b的执行结果，故我们需要先判断方法b的入参arg2会不会污染其返回值。    
在方法b中因为形参arg2会污染方法b的返回值，故在方法a中arg1作为方法b的实参被传入，故br会被arg1污染，即方法a的返回值会被方法a的参数arg1污染。  
```java
class A {
    public String a(String arg1) {
        String br = b(arg1);
        return br;
    }

    public String b(String arg2) {
        return arg2 + "\n";
    }
}
```
我们可以将不同的方法看作不同的点，所有的方法构成一个点集，将方法的调用关系看作边，调用者作为起点，被调用者作为终点从而形成一个有向的边集形成一个有向图。  
因为 Java 方法调用的特殊性，其往往存在各种循环调用，典型的就是递归调用，故方法调用图并不是一个典型的有向无环图。一般来说这样的图是不能进行拓扑排序的，   
不过 Gadget Inspector 通过引入中间变量并增加逻辑判断的方式来避免了这个问题。  
###### 如何对方法调用进行拓扑排序
在前一节中通过 discoverMethodCalls 方法的调用获取了一个以 MethodReference.Handle 方法句柄为Key，Set<MethodReference.Handle> 为值的一个Map并赋值给变量methodCalls。  
在进行拓扑排序是首先将methodCalls变量的值进行拷贝到 outgoingReferences 中，然后定义了三个变量 dfsStack，visitNodes，sortedMethods    
分别用于记录搜索栈，已访问节点集合，以及最终的排序结果集合。  
```java
private List<MethodReference.Handle> topologicallySortMethodCalls() {
        Map<MethodReference.Handle, Set<MethodReference.Handle>> outgoingReferences = new HashMap<>();
        for (Map.Entry<MethodReference.Handle, Set<MethodReference.Handle>> entry : methodCalls.entrySet()) {
            MethodReference.Handle method = entry.getKey();
            outgoingReferences.put(method, new HashSet<>(entry.getValue()));
        }

        // Topological sort methods
        LOGGER.debug("Performing topological sort...");
        Set<MethodReference.Handle> dfsStack = new HashSet<>();
        Set<MethodReference.Handle> visitedNodes = new HashSet<>();
        List<MethodReference.Handle> sortedMethods = new ArrayList<>(outgoingReferences.size());
        for (MethodReference.Handle root : outgoingReferences.keySet()) {
            dfsTsort(outgoingReferences, sortedMethods, visitedNodes, dfsStack, root);
        }
        LOGGER.debug(String.format("Outgoing references %d, sortedMethods %d", outgoingReferences.size(), sortedMethods.size()));

        return sortedMethods;
    }
```
stack 变量是用来跟踪方法调用深度的栈，每当发生方法调用时便将该方法压入到栈中，当方法调用结束时将该方法从栈中弹出，当栈为空时表示一次排序结束。  
visitedNodes 变量用于表示当前节点已经被访问过了，当某个节点出现在visitedNotes中时将不必继续进行递归而是直接返回，因为该节点已经被排序存储到 sortedMethods 中。  
通过 visitedNodes 集合的引入，Gadget Inspector 有效地避免了有向图拓扑排序过程中环的问题。  
sortedMethods 存储最终的排序结果，所有的方法都将被存储在该列表中。  
在整个排序过程中 stack 变量可能为空，因为其只存储了一次方法调用排序的堆栈变化关系，当当前方法调用结束后 stack 变量为空，则表示一次排序结束。    
visitedNodes 过程中不会为空而是不断地增长，因为其存储的是所有被访问过的方法，随着排序的进行其容量会不断扩大。sortedMethods 列表会随着排序的进行增长，因为其存储的是排序的结果。  
visitedNodes 集合的引入是为了处理有向图中出现的环的问题。  
```java
private static void dfsTsort(Map<MethodReference.Handle, Set<MethodReference.Handle>> outgoingReferences,
                                    List<MethodReference.Handle> sortedMethods, Set<MethodReference.Handle> visitedNodes,
                                    Set<MethodReference.Handle> stack, MethodReference.Handle node) {

        if (stack.contains(node)) {
            return;
        }
        if (visitedNodes.contains(node)) {
            return;
        }
        Set<MethodReference.Handle> outgoingRefs = outgoingReferences.get(node);
        if (outgoingRefs == null) {
            return;
        }

        stack.add(node);
        for (MethodReference.Handle child : outgoingRefs) {
            dfsTsort(outgoingReferences, sortedMethods, visitedNodes, stack, child);
        }
        stack.remove(node);
        visitedNodes.add(node);
        sortedMethods.add(node);
    }
```
##### 构造数据传播流图
本节是 Gadget Inspector 的精华，它通过静态模拟程序运行过程中局部变量表以及操作数栈的变换来进行污点分析，从而确认方法入参与返回值之间的关系。  
在下面的方法中首先对 <clinit> 方法做了排除，因为它是类的构造方法，在类的加载过程中由JVM执行，负责类静态代码块的执行以及类成员变量的初始化等操作。    
该过程不受攻击者控制。   
然后通过方法句柄获取到其所属类并读取该类的字节码流，并使用 PassthroughDataflowClassVisitor 对字节码流进行解析。 PassthroughDataflowClassVisitor 是一个 ClassVisitor，   
其 visitMethod 会依次处理该类的所有方法，并使用 MethodVisitor 对方法进行解析。  
```java
private static Map<MethodReference.Handle, Set<Integer>> calculatePassthroughDataflow(Map<String, ClassResourceEnumerator.ClassResource> classResourceByName,
                                                                                          Map<ClassReference.Handle, ClassReference> classMap,
                                                                                          InheritanceMap inheritanceMap,
                                                                                          List<MethodReference.Handle> sortedMethods,
                                                                                          SerializableDecider serializableDecider) throws IOException {
        final Map<MethodReference.Handle, Set<Integer>> passthroughDataflow = new HashMap<>();
        for (MethodReference.Handle method : sortedMethods) {
            if (method.getName().equals("<clinit>")) { 
                continue;
            }
            ClassResourceEnumerator.ClassResource classResource = classResourceByName.get(method.getClassReference().getName());
            try (InputStream inputStream = classResource.getInputStream()) {
                ClassReader cr = new ClassReader(inputStream);
                try {
                    PassthroughDataflowClassVisitor cv = new PassthroughDataflowClassVisitor(classMap, inheritanceMap,
                            passthroughDataflow, serializableDecider, Opcodes.ASM6, method);
                    cr.accept(cv, ClassReader.EXPAND_FRAMES);
                     passthroughDataflow.put(method, cv.getReturnTaint());
                } catch (Exception e) {
                    LOGGER.error("Exception analyzing " + method.getClassReference().getName(), e);
                }
            } catch (IOException e) {
                LOGGER.error("Unable to analyze " + method.getClassReference().getName(), e);
            }
        }
        return passthroughDataflow;
    }
```
PassthroughDataflowMethodVisitor 是一个 MethodVisitor，其会访问一个方法调用的各种信息。  
```java
@Override
@Override
public MethodVisitor visitMethod(int access, String name, String desc,
        String signature, String[] exceptions) {
        // 访问指定的方法   方法名与方法描述符必须一致  避免方法重载带来的冲突
        if (!name.equals(methodToVisit.getName()) || !desc.equals(methodToVisit.getDesc())) {
        return null;
        }
        if (passthroughDataflowMethodVisitor != null) {
        throw new IllegalStateException("Constructing passthroughDataflowMethodVisitor twice!");
        }

        MethodVisitor mv = super.visitMethod(access, name, desc, signature, exceptions);
        // 访问类的某一个方法的详细信息
        passthroughDataflowMethodVisitor = new PassthroughDataflowMethodVisitor(
        classMap, inheritanceMap, this.passthroughDataflow, serializableDecider,
        api, mv, this.name, access, name, desc, signature, exceptions);

        return new JSRInlinerAdapter(passthroughDataflowMethodVisitor, access, name, desc, signature, exceptions);
        }
```
PassthroughDataflowMethodVisitor 继承自 TaintTrackingMethodVisitor 两者一同实现了操作数栈以及局部变量表的静态模拟。     
PassthroughDataflowMethodVisitor 主要负责污点传播分析， TaintTrackingMethodVisitor 主要负责在分析过程中调整操作数栈以及局部变量表。  
在 MethodVisitor 中针对字节码不同的行为均有相应的方法进行处理，如当方法中出现无操作数字节码调用时，如：RETURN, IRETURN, ATHROW，将会触发 visitInsn 方法调用，   
当出现方法调用指令时，如： INVOKEVIRTUAL, INVOKESPECIAL, INVOKESTATIC, INVOKEINTERFACE ，将触发 visitMethodInsn 方法调用。   
Gadget Inspector 将在对应的方法中同步记录这些指令调用时操作数栈以及局部变量表的变化情况。  
下面我们将通过几个方法的调用举例展示，Gadget Inspector 时如何进行模拟的。  

visitCode 方法是最先被执行的方法，其将负责局部变量表空间的开辟，并设置相应的污点。  
```java
@Override
        public void visitCode() {
            // 开辟局部变量表空间
            super.visitCode();

            int localIndex = 0;
            int argIndex = 0;
            // 设置污点  也可以理解成设置形参在局部变量表中的位置 形成的数据类似
            // 假如有这样一个实例方法
            // (String,long,int)
            // 对应的局部变量表为 long 的索引为2 占据两个槽位
            // | 0 | 1 | 2 |   | 3 |
            if ((this.access & Opcodes.ACC_STATIC) == 0) {
                // 第0个局部变量被第0个参数污染
                setLocalTaint(localIndex, argIndex);
                localIndex += 1;
                argIndex += 1;
            }
            // 依次类推 设置参数的污染 根据参数的类型调整局部变量表索引，因为 long Double 类型占据两个槽位
            for (Type argType : Type.getArgumentTypes(desc)) {
                setLocalTaint(localIndex, argIndex);
                localIndex += argType.getSize();
                argIndex += 1;
            }
        }
```
PassthroughDataflowMethodVisitor 父类 TaintTrackingMethodVisitor 的 visitCode 方法，主要作用是开辟局部变量表空间。  
```java
public void visitCode() {
        super.visitCode();
        savedVariableState.localVars.clear();
        savedVariableState.stackVars.clear();
        // 方法的访问修饰符部位 static  为局部变量表开辟一个空间 因为实例方法第一个参数为this, 占据一个槽位
        if ((this.access & Opcodes.ACC_STATIC) == 0) {
            savedVariableState.localVars.add(new HashSet<T>());
        }
        // 根据方法描述符获取到参数类型 不同的参数类型占据不同的槽位 一般的类型为1个槽位  long double 占据两个槽位
        for (Type argType : Type.getArgumentTypes(desc)) {
            // 根据参数类型开辟不同大小的空间
            for (int i = 0; i < argType.getSize(); i++) {
                savedVariableState.localVars.add(new HashSet<T>());
            }
        }
    }
```
当方法中出现字段访问时会调用 visitFieldInsn 方法  
```java
@Override
        public void visitFieldInsn(int opcode, String owner, String name, String desc) {

            switch (opcode) {
                // 静态的操作不了
                case Opcodes.GETSTATIC:
                    break;
                case Opcodes.PUTSTATIC:
                    break;
                    // 从字段取值
                case Opcodes.GETFIELD:
                    Type type = Type.getType(desc);
                    // 占据一个槽位的字段
                    if (type.getSize() == 1) {
                        Boolean isTransient = null;

                        // If a field type could not possibly be serialized, it's effectively transient
                        // 判断字段是否能实例化 经典java序列化的条件 是 实现了serialize接口且类型没有在黑名单中
                        // 如果不能被序列化 则 isTransient 标记为true
                        if (!couldBeSerialized(serializableDecider, inheritanceMap, new ClassReference.Handle(type.getInternalName()))) {
                            isTransient = Boolean.TRUE;
                        } else {
                            ClassReference clazz = classMap.get(new ClassReference.Handle(owner));
                            while (clazz != null) {
                                // 获取当前字段所属类 的所有成员变量 进行遍历
                                for (ClassReference.Member member : clazz.getMembers()) {
                                    // 如果当前字段所属类的成员变量与当前字段相等
                                    if (member.getName().equals(name)) {
                                        // 如果当前字段是被transient修饰 则被标记为   isTransient
                                        isTransient = (member.getModifiers() & Opcodes.ACC_TRANSIENT) != 0;
                                        break;
                                    }
                                }
                                if (isTransient != null) {
                                    break;
                                }
                                // 父类也要被找一遍 多态的原因
                                clazz = classMap.get(new ClassReference.Handle(clazz.getSuperClass()));
                            }
                        }

                        Set<Integer> taint;
                        // 字段如果不是瞬态的 需要从栈上去一个值
                        // getField 会先从栈顶取出对象的引用
                        if (!Boolean.TRUE.equals(isTransient)) {
                            taint = getStackTaint(0); // 只取不删
                        } else {
                            // 字段如果是瞬态的 虽然也需要从栈上取对象的引用 但并不会产生污点 只需设置一个空集合即可
                            // 或者说 污点传播链被中断了
                            taint = new HashSet<>();
                        }
                        // 模拟堆栈变化
                        super.visitFieldInsn(opcode, owner, name, desc);
                        // 取值完成后要将值重新压入到栈中 以便继续使用 即污点被压栈了
                        setStackTaint(0, taint);
                        return;
                    }
                    break;
                case Opcodes.PUTFIELD:
                    break;
                default:
                    throw new IllegalStateException("Unsupported opcode: " + opcode);
            }
            // putField 与 两个槽数据的getField 堆栈变化放到这里了
            // 只会引起堆栈变化并不影响污点的变化
            // 静态操作不受控制 不影响污点传播
            // putField 操作前污点值已经咋栈上 执行完毕后改值会被弹出，不需要额外设置
            // long 和 double 类型数据传播到sink点也没啥价值，这里直接忽略掉了
            super.visitFieldInsn(opcode, owner, name, desc);
        }
```
TaintTrackingMethodVisitor 的方法 visitFieldInsn 主要负责模拟指令执行时栈帧的变化  
```java
@Override
    public void visitFieldInsn(int opcode, String owner, String name, String desc) {
        int typeSize = Type.getType(desc).getSize();
        switch (opcode) {
            // 从class中读数据 然后将读取的数据 压入栈
            case Opcodes.GETSTATIC:
                for (int i = 0; i < typeSize; i++) {
                    push();
                }
                break;
                // 从栈上弹出数据 然后给class对象指定的变量赋值
            case Opcodes.PUTSTATIC:
                for (int i = 0; i < typeSize; i++) {
                    pop();
                }
                break;
                // 取值会 先从栈上弹出对象的引用 然后将取出的字段压入栈中
            case Opcodes.GETFIELD:
                pop();
                for (int i = 0; i < typeSize; i++) {
                    push();
                }
                break;
                // 先从栈上将数据弹出来 然后弹出要被赋值的对象的引用 最后进行赋值
            case Opcodes.PUTFIELD:
                for (int i = 0; i < typeSize; i++) {
                    pop();
                }
                pop();

                break;
            default:
                throw new IllegalStateException("Unsupported opcode: " + opcode);
        }

        super.visitFieldInsn(opcode, owner, name, desc);

        sanityCheck();
    }
```
当出现方法调用时会调用 visitMethodInsn 方法   
```java
@Override
        public void visitMethodInsn(int opcode, String owner, String name, String desc, boolean itf) {
            Type[] argTypes = Type.getArgumentTypes(desc);
            if (opcode != Opcodes.INVOKESTATIC) { // 处理实例方法调用的 this，将 this 加入到参数列表中
                Type[] extendedArgTypes = new Type[argTypes.length+1];
                System.arraycopy(argTypes, 0, extendedArgTypes, 1, argTypes.length);
                extendedArgTypes[0] = Type.getObjectType(owner);
                argTypes = extendedArgTypes;
            }
            // 返回值大小
            int retSize = Type.getReturnType(desc).getSize();

            Set<Integer> resultTaint;
            switch (opcode) {
                case Opcodes.INVOKESTATIC:
                case Opcodes.INVOKEVIRTUAL:
                case Opcodes.INVOKESPECIAL:
                case Opcodes.INVOKEINTERFACE:
                    // 初始化 参数污点列表
                    final List<Set<Integer>> argTaint = new ArrayList<Set<Integer>>(argTypes.length);
                    for (int i = 0; i < argTypes.length; i++) {
                        argTaint.add(null);
                    }

                    int stackIndex = 0;
                    // 调用方法前 方法的参数都会被先压到栈上 所以这里先从栈上将污点取出来
                    // 从这里可以看出  参数是从右往左压栈的
                    for (int i = 0; i < argTypes.length; i++) {
                        Type argType = argTypes[i];
                        if (argType.getSize() > 0) {

                            argTaint.set(argTypes.length - 1 - i, getStackTaint(stackIndex + argType.getSize() - 1));
                        }
                        stackIndex += argType.getSize();
                    }
                    // 构造方法将被第一个参数污染
                    if (name.equals("<init>")) {
                        // Pass result taint through to original taint set; the initialized object is directly tainted by
                        // parameters
                        resultTaint = argTaint.get(0);
                    } else {
                        resultTaint = new HashSet<>();
                    }
                    // 当前方法是否已经被分析过了 参数与返回值的传播关系
                    Set<Integer> passthrough = passthroughDataflow.get(new MethodReference.Handle(new ClassReference.Handle(owner), name, desc));
                    // 如果已经被分析过了 直接获取已有的结果
                    if (passthrough != null) {
                        for (Integer passthroughDataflowArg : passthrough) {
                            resultTaint.addAll(argTaint.get(passthroughDataflowArg));
                        }
                    }
                    // 如果没有分析过 那就是前面的方法调用拓扑排序存在异常，这种情况基本不可能出现
                    break;
                default:
                    throw new IllegalStateException("Unsupported opcode: " + opcode);
            }
            // 处理方法调用过程中的操作数栈变化
            super.visitMethodInsn(opcode, owner, name, desc, itf);
            // 如果存在返回值
            if (retSize > 0) {
                // 补充而不是设置 因为时集合的缘故，重复的值会被剔除掉
                getStackTaint(retSize-1).addAll(resultTaint);
            }
        }
```
处理方法调用过程中的操作数栈变化  同时进行污点跟踪 与 PassthroughDataflowMethodVisitor 的 visitMethodInsn 有重复的逻辑。  
```java
@Override
    public void visitMethodInsn(int opcode, String owner, String name, String desc, boolean itf) {
        final MethodReference.Handle methodHandle = new MethodReference.Handle(
                new ClassReference.Handle(owner), name, desc);

        Type[] argTypes = Type.getArgumentTypes(desc);
        if (opcode != Opcodes.INVOKESTATIC) {
            Type[] extendedArgTypes = new Type[argTypes.length+1];
            System.arraycopy(argTypes, 0, extendedArgTypes, 1, argTypes.length);
            extendedArgTypes[0] = Type.getObjectType(owner);
            argTypes = extendedArgTypes;
        }

        final Type returnType = Type.getReturnType(desc);
        final int retSize = returnType.getSize();

        switch (opcode) {
            case Opcodes.INVOKESTATIC:
            case Opcodes.INVOKEVIRTUAL:
            case Opcodes.INVOKESPECIAL:
            case Opcodes.INVOKEINTERFACE:
                // 定义参数列表
                final List<Set<T>> argTaint = new ArrayList<Set<T>>(argTypes.length);
                for (int i = 0; i < argTypes.length; i++) {
                    argTaint.add(null);
                }
                // 方法调用完后会恢复栈帧，将方法的参数弹出栈
                for (int i = 0; i < argTypes.length; i++) {
                    Type argType = argTypes[i];
                    if (argType.getSize() > 0) {
                        // 占两个槽的 数据需要先弹一次 因为污点数据存储在更下层的槽位中 
                        for (int j = 0; j < argType.getSize() - 1; j++) {
                            pop();
                        }
                        // 将栈上的污点压入被调用方法的参数污点列表中
                        argTaint.set(argTypes.length - 1 - i, pop());
                    }
                }

                Set<T> resultTaint;
                // 构造方法的返回值会被第一个参数污染
                if (name.equals("<init>")) {
                    // Pass result taint through to original taint set; the initialized object is directly tainted by
                    // parameters
                    resultTaint = argTaint.get(0);
                } else {
                    resultTaint = new HashSet<>();
                }

                // If calling defaultReadObject on a tainted ObjectInputStream, that taint passes to "this"
                if (owner.equals("java/io/ObjectInputStream") && name.equals("defaultReadObject") && desc.equals("()V")) {
                    savedVariableState.localVars.get(0).addAll(argTaint.get(0));
                }
                // 已知的一些预定义的污染关系
                for (Object[] passthrough : PASSTHROUGH_DATAFLOW) {
                    if (passthrough[0].equals(owner) && passthrough[1].equals(name) && passthrough[2].equals(desc)) {
                        for (int i = 3; i < passthrough.length; i++) {
                            resultTaint.addAll(argTaint.get((Integer)passthrough[i]));
                        }
                    }
                }
                // 如果存在已分析的传播流数据
                if (passthroughDataflow != null) {
                    // 尝试从其中取出当前方法的污点传播流数据
                    Set<Integer> passthroughArgs = passthroughDataflow.get(methodHandle);
                    // 如果当前方法的污点传播流已经被分析过了
                    if (passthroughArgs != null) {
                        // 遍历得到当前方法会被哪些参数污染
                        for (int arg : passthroughArgs) {
                            // 从入参中取出对应位置的污点 放到 resultTaint 中 resultTaint 表示当前方法的返回值会被哪个入参污染
                            resultTaint.addAll(argTaint.get(arg));
                        }
                    }
                }

                // Heuristic; if the object implements java.util.Collection or java.util.Map, assume any method accepting an object
                // taints the collection. Assume that any method returning an object returns the taint of the collection.
                // 如果不是静态方法调用 且第一个参数非基本数据类型
                // 针对集合以及映射做的特殊处理
                // 假设任意接受对象的方法均会污染集合 假设任意返回对象的方法都会返回集合的污点
                if (opcode != Opcodes.INVOKESTATIC && argTypes[0].getSort() == Type.OBJECT) {
                    Set<ClassReference.Handle> parents = inheritanceMap.getSuperClasses(new ClassReference.Handle(argTypes[0].getClassName().replace('.', '/')));
                    if (parents != null && (parents.contains(new ClassReference.Handle("java/util/Collection")) ||
                            parents.contains(new ClassReference.Handle("java/util/Map")))) {
                        for (int i = 1; i < argTaint.size(); i++) {
                            argTaint.get(0).addAll(argTaint.get(i));
                        }

                        if (returnType.getSort() == Type.OBJECT || returnType.getSort() == Type.ARRAY) {
                            resultTaint.addAll(argTaint.get(0));
                        }
                    }
                }
                // 方法调用完需要如果需要返回数据 则需要先将返回值压栈
                if (retSize > 0) {
                    push(resultTaint);
                    // 如果返回值占据两个槽位则还要压一次
                    for (int i = 1; i < retSize; i++) {
                        push();
                    }
                }
                break;
            default:
                throw new IllegalStateException("Unsupported opcode: " + opcode);
        }

        super.visitMethodInsn(opcode, owner, name, desc, itf);

        sanityCheck();
    }
```
当方法执行完毕需要返回时 调用  
```java
@Override
        public void visitInsn(int opcode) {
            switch(opcode) {
                // 这些指令操作的数据在操作数栈上只占据一个槽位
                case Opcodes.IRETURN:
                case Opcodes.FRETURN:
                case Opcodes.ARETURN:
                    // 从污点栈上取出最上面的一个数据 设置到 returnTaint 中
                    // 如果污点栈上的数据与形参存在关联则证明 该参数可以影响方法的返回值
                    returnTaint.addAll(getStackTaint(0));
                    break;
                    // 同样的 这些指令占据两个槽位
                case Opcodes.LRETURN:
                case Opcodes.DRETURN:
                    returnTaint.addAll(getStackTaint(1));
                    break;
                    // void
                case Opcodes.RETURN:
                    break;
                default:
                    break;
            }

            super.visitInsn(opcode);
        }
```
最终数据传播流图的的分析结果将被存储在字段 gadgetinspector.PassthroughDiscovery.passthroughDataflow，该字段的签名为 Map<MethodReference.Handle, Set<Integer>>，  
即一个通过方法名句柄索引结果的 Map 映射，Map 的值为会污染该方法返回值的形参位置集合。  
passthroughDataflow 最终会被保存在文件 passthrough.dat 中，数据的存储格式为  
方法所属类全类名|方法名|方法描述符|污染的参数位置1,污染的参数位置2,污染的参数位置3...  
如：  
javax/swing/plaf/nimbus/OptionPanePainter	decodeEllipse1	()Ljava/awt/geom/Ellipse2D;	0,  
#### 构造调用图
上一步的 passthroughDataflow生成是宏观的方法参数与返回值的关系并没有关系到方法内部的污染关系，若要形成 Gadgets 链还需确定父方法与子方法之间的参数传递关系。  
这一步主要是分析方法的参数与其调用的子方法之间的关系，即子方法的参数是否会被其父方法的参数所污染。  
因为涉及到方法内部的细节处理，所以这里仍然需要使用 MethodVisitor， 对应的方法访问器实现类为 ModelGeneratorMethodVisitor。  
ModelGeneratorMethodVisitor 也是继承自 TaintTrackingMethodVisitor，其单独重写了visitCode visitFieldInsn 以及 visitMethodInsn 方法。  
  
该方法整体流程与数据传播流图分析时的 visitCode 方法一致，区别在于局部变量表中存储的数据。数据流图分析时局部变量表中存储的是参数的索引，    
此时存储的是一个以`arg`开头并追加参数索引的字符串，如：arg0，arg1。这样做的目的在于分析父方法与被调用子方法之间的形参传递时，    
能够通过检查子方法的参数值是否以`arg` 来头来判断父方法的形参是否传递到了子方法中。  
```java
@Override
        public void visitCode() {
            super.visitCode();

            int localIndex = 0;
            int argIndex = 0;
            if ((this.access & Opcodes.ACC_STATIC) == 0) {
                setLocalTaint(localIndex, "arg" + argIndex);
                localIndex += 1;
                argIndex += 1;
            }
            for (Type argType : Type.getArgumentTypes(desc)) {
                setLocalTaint(localIndex, "arg" + argIndex);
                localIndex += argType.getSize();
                argIndex += 1;
            }
        }
```
针对字段访问相关的字节码指令进行处理。  
```java
@Override
        public void visitFieldInsn(int opcode, String owner, String name, String desc) {

            switch (opcode) {
                case Opcodes.GETSTATIC:
                    break;
                case Opcodes.PUTSTATIC:
                    break;
                case Opcodes.GETFIELD:
                    Type type = Type.getType(desc);
                    if (type.getSize() == 1) {
                        Boolean isTransient = null;

                        // If a field type could not possibly be serialized, it's effectively transient
                        if (!couldBeSerialized(serializableDecider, inheritanceMap, new ClassReference.Handle(type.getInternalName()))) {
                            isTransient = Boolean.TRUE;
                        } else {
                            ClassReference clazz = classMap.get(new ClassReference.Handle(owner));
                            while (clazz != null) {
                                for (ClassReference.Member member : clazz.getMembers()) {
                                    if (member.getName().equals(name)) {
                                        isTransient = (member.getModifiers() & Opcodes.ACC_TRANSIENT) != 0;
                                        break;
                                    }
                                }
                                if (isTransient != null) {
                                    break;
                                }
                                clazz = classMap.get(new ClassReference.Handle(clazz.getSuperClass()));
                            }
                        }

                        Set<String> newTaint = new HashSet<>();
                        if (!Boolean.TRUE.equals(isTransient)) {
                            // 栈顶放的时对象的引用 构造污点标识符
                            // 如果对象来自父方法的入参 则 s 为 arg1.fieldName
                            for (String s : getStackTaint(0)) {
                                newTaint.add(s + "." + name);
                            }
                        }
                        // 模拟操作数栈变化
                        super.visitFieldInsn(opcode, owner, name, desc);
                        // 将取字段的结果放入到栈顶 即 arg1.fieldName
                        setStackTaint(0, newTaint);
                        return;
                    }
                    break;
                case Opcodes.PUTFIELD:
                    break;
                default:
                    throw new IllegalStateException("Unsupported opcode: " + opcode);
            }
            // 模拟操作数栈变化
            super.visitFieldInsn(opcode, owner, name, desc);
        }
```
针对方法访问进行处理  
```java
@Override
        public void visitMethodInsn(int opcode, String owner, String name, String desc, boolean itf) {
            Type[] argTypes = Type.getArgumentTypes(desc);
            if (opcode != Opcodes.INVOKESTATIC) {
                Type[] extendedArgTypes = new Type[argTypes.length+1];
                System.arraycopy(argTypes, 0, extendedArgTypes, 1, argTypes.length);
                extendedArgTypes[0] = Type.getObjectType(owner);
                argTypes = extendedArgTypes;
            }

            switch (opcode) {
                case Opcodes.INVOKESTATIC:
                case Opcodes.INVOKEVIRTUAL:
                case Opcodes.INVOKESPECIAL:
                case Opcodes.INVOKEINTERFACE:
                    int stackIndex = 0;
                    for (int i = 0; i < argTypes.length; i++) {
                        int argIndex = argTypes.length-1-i;
                        Type type = argTypes[argIndex];
                        // 此时从栈顶向下的数据均为被调用方法的入参
                        // 根据栈索引从栈上取得参数
                        Set<String> taint = getStackTaint(stackIndex);
                        // 如果该参数有污点标识符 
                        if (taint.size() > 0) {
                            // 遍历污点标识符
                            for (String argSrc : taint) {
                                // 如果参数的污点标识符 不是arg开头 则直接报错退出，即调用方法的参数无法影响被调用方法的入参
                                // 这里直接抛出异常 是否存在问题
                                // 第一个参数不被受主调方法入参影响，直接退出针对该方法的分析，那么第二个参数如果受影响呢？
                                if (!argSrc.substring(0, 3).equals("arg")) {
                                    throw new IllegalStateException("Invalid taint arg: " + argSrc);
                                }
                                // 确定`.`号的位置
                                // 
                                int dotIndex = argSrc.indexOf('.');
                                int srcArgIndex;
                                String srcArgPath;
                                // 如果点号不存在则证明被调用方法的污点标识符由调用方法的参数直接传递
                                if (dotIndex == -1) {
                                    // 计算参数索引
                                    srcArgIndex = Integer.parseInt(argSrc.substring(3));
                                    // 参数路径为空 
                                    srcArgPath = null;
                                } else {
                                    // 计算参数索引 因为存在点号 证明该参数由对象间接传递 非直接传递
                                    srcArgIndex = Integer.parseInt(argSrc.substring(3, dotIndex));
                                    // 记录被调用方法的参数来自主调方法的参数的哪个属性
                                    srcArgPath = argSrc.substring(dotIndex+1);
                                }
                                // 构造调用图
                                // 主调方法句柄  被调用方法句柄   主调方法参数索引 主调方法参数传递路径  被调方法参数索引
                                discoveredCalls.add(new GraphCall(
                                        new MethodReference.Handle(new ClassReference.Handle(this.owner), this.name, this.desc),
                                        new MethodReference.Handle(new ClassReference.Handle(owner), name, desc),
                                        srcArgIndex,
                                        srcArgPath,
                                        argIndex));
                            }
                        }
                        // 增加栈索引 继续获取下一个参数
                        stackIndex += type.getSize();
                    }
                    break;
                default:
                    throw new IllegalStateException("Unsupported opcode: " + opcode);
            }

            super.visitMethodInsn(opcode, owner, name, desc, itf);
        }
    }
```
形成的方法间调用图将被存储在 CallGraphDiscovery.discoveredCalls 字段中，最终被持久化到 callgraph.dat 文件中。存储格式如下   
主调方法所属类全类名|主调方法名|主调方法描述符|被调方法所属类全类名|被调方法名|被调方法描述符|主调方法参数索引|主调方法参数传递路径|被调方法参数索引    
如：  
com/sun/org/apache/xerces/internal/impl/dtd/XMLDTDDescription	<init>	(Lcom/sun/org/apache/xerces/internal/xni/XMLResourceIdentifier;Ljava/lang/String;)V	com/sun/org/apache/xerces/internal/xni/XMLResourceIdentifier	getBaseSystemId	()Ljava/lang/String;	1		0    
我们看 XMLDTDDescription 对应的构造函数，被调用的子方法是 id.getBaseSystemId()。getBaseSystemId的调用者id来自 XMLDTDDescription 构造函数的第一个参数，    
即索引1。getLiteralSystemId 也有一个参数 this, 索引为0。 XMLDTDDescription的第一个参数将影响 getBaseSystemId 方法的第0个参数且是直接影响并无参数路径。    
故形成的污染路径为 `1		0`   
```java
public XMLDTDDescription(XMLResourceIdentifier id, String rootName) {
        this.setValues(id.getPublicId(), id.getLiteralSystemId(), id.getBaseSystemId(), id.getExpandedSystemId());
        this.fRootName = rootName;
        this.fPossibleRoots = null;
    }
```
#### Source 点探测
不同的反序列化类型具有不同的入口，Gadget Inspector 默认提供了两种类型的入口点探测类，分别是 JacksonSourceDiscovery 以及 SimpleSourceDiscovery。  
我们以最常用的Java原生反序列化为例，即 SimpleSourceDiscovery。  
逻辑就是根据已知的反序列化入口点取匹配被探测的方法，然后形成一个列表。  
```java
@Override
    public void discover(Map<ClassReference.Handle, ClassReference> classMap,
                         Map<MethodReference.Handle, MethodReference> methodMap,
                         InheritanceMap inheritanceMap) {

        final SerializableDecider serializableDecider = new SimpleSerializableDecider(inheritanceMap);

        for (MethodReference.Handle method : methodMap.keySet()) {
            if (Boolean.TRUE.equals(serializableDecider.apply(method.getClassReference()))) {
                if (method.getName().equals("finalize") && method.getDesc().equals("()V")) {
                    addDiscoveredSource(new Source(method, 0));
                }
            }
        }

        // If a class implements readObject, the ObjectInputStream passed in is considered tainted
        for (MethodReference.Handle method : methodMap.keySet()) {
            if (Boolean.TRUE.equals(serializableDecider.apply(method.getClassReference()))) {
                if (method.getName().equals("readObject") && method.getDesc().equals("(Ljava/io/ObjectInputStream;)V")) {
                    addDiscoveredSource(new Source(method, 1));
                }
            }
        }

        // Using the proxy trick, anything extending serializable and invocation handler is tainted.
        for (ClassReference.Handle clazz : classMap.keySet()) {
            if (Boolean.TRUE.equals(serializableDecider.apply(clazz))
                    && inheritanceMap.isSubclassOf(clazz, new ClassReference.Handle("java/lang/reflect/InvocationHandler"))) {
                MethodReference.Handle method = new MethodReference.Handle(
                        clazz, "invoke", "(Ljava/lang/Object;Ljava/lang/reflect/Method;[Ljava/lang/Object;)Ljava/lang/Object;");

                addDiscoveredSource(new Source(method, 0));
            }
        }

        // hashCode() or equals() are accessible entry points using standard tricks of putting those objects
        // into a HashMap.
        for (MethodReference.Handle method : methodMap.keySet()) {
            if (Boolean.TRUE.equals(serializableDecider.apply(method.getClassReference()))) {
                if (method.getName().equals("hashCode") && method.getDesc().equals("()I")) {
                    addDiscoveredSource(new Source(method, 0));
                }
                if (method.getName().equals("equals") && method.getDesc().equals("(Ljava/lang/Object;)Z")) {
                    addDiscoveredSource(new Source(method, 0));
                    addDiscoveredSource(new Source(method, 1));
                }
            }
        }

        // Using a comparator proxy, we can jump into the call() / doCall() method of any groovy Closure and all the
        // args are tainted.
        // https://github.com/frohoff/ysoserial/blob/master/src/main/java/ysoserial/payloads/Groovy1.java
        for (MethodReference.Handle method : methodMap.keySet()) {
            if (Boolean.TRUE.equals(serializableDecider.apply(method.getClassReference()))
                    && inheritanceMap.isSubclassOf(method.getClassReference(), new ClassReference.Handle("groovy/lang/Closure"))
                    && (method.getName().equals("call") || method.getName().equals("doCall"))) {

                addDiscoveredSource(new Source(method, 0));
                Type[] methodArgs = Type.getArgumentTypes(method.getDesc());
                for (int i = 0; i < methodArgs.length; i++) {
                    addDiscoveredSource(new Source(method, i + 1));
                }
            }
        }
    }
```
最终形成的source点列表将被持久化存储在 sources.dat 文件中。文件格式如下：  
方法所属类全类名|方法名|方法描述|污点参数索引  
#### Gadget Chain 构造
```java
public void discover() throws Exception {
        Map<MethodReference.Handle, MethodReference> methodMap = DataLoader.loadMethods();
        InheritanceMap inheritanceMap = InheritanceMap.load();
        // 查找方法的所有实现
        Map<MethodReference.Handle, Set<MethodReference.Handle>> methodImplMap = InheritanceDeriver.getAllMethodImplementations(
                inheritanceMap, methodMap);

        final ImplementationFinder implementationFinder = config.getImplementationFinder(
                methodMap, methodImplMap, inheritanceMap);
        // 持久化
        try (Writer writer = Files.newBufferedWriter(Paths.get("methodimpl.dat"))) {
            for (Map.Entry<MethodReference.Handle, Set<MethodReference.Handle>> entry : methodImplMap.entrySet()) {
                writer.write(entry.getKey().getClassReference().getName());
                writer.write("\t");
                writer.write(entry.getKey().getName());
                writer.write("\t");
                writer.write(entry.getKey().getDesc());
                writer.write("\n");
                for (MethodReference.Handle method : entry.getValue()) {
                    writer.write("\t");
                    writer.write(method.getClassReference().getName());
                    writer.write("\t");
                    writer.write(method.getName());
                    writer.write("\t");
                    writer.write(method.getDesc());
                    writer.write("\n");
                }
            }
        }
        // 加载调用图并合并
        // graphCallMap 通过主调方法名句柄映射其所有被调方法调用图的集合
        Map<MethodReference.Handle, Set<GraphCall>> graphCallMap = new HashMap<>();
        for (GraphCall graphCall : DataLoader.loadData(Paths.get("callgraph.dat"), new GraphCall.Factory())) {
            MethodReference.Handle caller = graphCall.getCallerMethod();
            if (!graphCallMap.containsKey(caller)) {
                Set<GraphCall> graphCalls = new HashSet<>();
                graphCalls.add(graphCall);
                graphCallMap.put(caller, graphCalls);
            } else {
                graphCallMap.get(caller).add(graphCall);
            }
        }
        // exploredMethods 记录所有被查找过的方法 避免重复搜索
        Set<GadgetChainLink> exploredMethods = new HashSet<>();
        // 记录需要查找的source方法 每个source被当作一条GadgetChain
        LinkedList<GadgetChain> methodsToExplore = new LinkedList<>();
        // 加载入口点
        for (Source source : DataLoader.loadData(Paths.get("sources.dat"), new Source.Factory())) {
            // 封装入口点为一个link
            GadgetChainLink srcLink = new GadgetChainLink(source.getSourceMethod(), source.getTaintedArgIndex());
            // 
            if (exploredMethods.contains(srcLink)) {
                continue;
            }
            // 将source点封装的 GadgetChain 加入到预处理列表中
            methodsToExplore.add(new GadgetChain(Arrays.asList(srcLink)));
            // 将入口点加入到已查找集合中
            exploredMethods.add(srcLink);
        }

        long iteration = 0;
        Set<GadgetChain> discoveredGadgets = new HashSet<>();
        while (methodsToExplore.size() > 0) {
            // 迭代1000次记录一次
            if ((iteration % 1000) == 0) {
                LOGGER.info("Iteration " + iteration + ", Search space: " + methodsToExplore.size());
            }
            iteration += 1;

            GadgetChain chain = methodsToExplore.pop();
            // 取得链中最后一个link
            GadgetChainLink lastLink = chain.links.get(chain.links.size()-1);
            // 从link中获取到方法句柄，根据方法句柄获取到调用图集合
            Set<GraphCall> methodCalls = graphCallMap.get(lastLink.method);
            if (methodCalls != null) {
                // 遍历调用图
                for (GraphCall graphCall : methodCalls) {
                    // 如果调用这的参数索引与链中最后一个link的taintedArgIndex不同，则该方法调用不符合要求。
                    // 即需要调用者的参数可控
                    if (graphCall.getCallerArgIndex() != lastLink.taintedArgIndex) {
                        continue;
                    }
                    // 从调用图中找到被调用方法的句柄，然后查找该方法的所有重载方法
                    Set<MethodReference.Handle> allImpls = implementationFinder.getImplementations(graphCall.getTargetMethod());
                    // 遍历所有重载方法
                    for (MethodReference.Handle methodImpl : allImpls) {
                        // 将该方法重新封装成一个link 第一个参数为方法名句柄  第二个参数表示该方法哪一个参数可以被污染
                        // 在寻找下一个节点时需要保证 第二个参数 出现在调用图图中
                        GadgetChainLink newLink = new GadgetChainLink(methodImpl, graphCall.getTargetArgIndex());
                        if (exploredMethods.contains(newLink)) {
                            continue;
                        }
                        // 形成新的GadgetChain 
                        GadgetChain newChain = new GadgetChain(chain, newLink);
                        // 如果该链的最后一个link是sink点，且满足污染关系 则认为找到了一条反序列化Gadgets链
                        if (isSink(methodImpl, graphCall.getTargetArgIndex(), inheritanceMap)) {
                            discoveredGadgets.add(newChain);
                            // 否则继续寻找
                        } else {
                            // 将新链加入到需要寻找的列表中
                            methodsToExplore.add(newChain);
                            // 将新的方法节点加入到已经被查找过的方法集合中
                            exploredMethods.add(newLink);
                        }
                    }
                }
            }
        }
        // 输出
        try (OutputStream outputStream = Files.newOutputStream(Paths.get("gadget-chains.txt"));
             Writer writer = new OutputStreamWriter(outputStream, StandardCharsets.UTF_8)) {
            for (GadgetChain chain : discoveredGadgets) {
                printGadgetChain(writer, chain);
            }
        }

        LOGGER.info("Found {} gadget chains.", discoveredGadgets.size());
    }
```
关于如何 连接Gadget Chain，这里举例说明。  
以下两个类A与类B分别实现了 Serializable 接口，并且都重写了 readObject 方法。 这里将类A的 readObject 方法作为 Source 点。  
```java
import java.io.Serializable;

class A implements Serializable {
    public void readObject(ObjectInputStream var1) throws IOException {
        B var2 = (B) var1.readObject();

    }
}

class B extends ObjectInputStream {
    public final Object readObject() throws IOException, ClassNotFoundException {
        String var2 = var1.readUTF();
        //...
    }
}
```
在进行 Gadget Chain 构造时首先会将 A 类的 readObject 方法封装为一个 GadgetChainLink 对象，其第一个参数为 readObject 方法名的句柄，  
第二个参数为参数污点索引（1）。然后将这个 GadgetChainLink 添加到一个数组中再封装到 GadgetChain 中。  
搜索时先从 GadgetChain 中取出列表中最后一个 link，也就是 A 类 readObject 方法封装的 GadgetChainLink 对象。然后获取到方法名，  
并从调用图映射中通过方法名取得类A方法readObject 的所有调用图，我们的例子中只有一个，即调用类B的readObject方法。
这个调用图在 callgraph.dat 中是这样的：  
A   readObject  (Ljava/io/ObjectInputStream;)V  B   readObject   ()Ljava/lang/Object;     1         0  
取得了调用图后会比较类A的 readObject 方法的参数污点索引（1）是否与调用图中的调用者参数索引（1）一致，在给出的例子中两者均为1，表明污点可以传递下去。  
然后查找类B的所有实现类是否重写了readObject方法，如果存在重写，则所有的重写方法都将被封装为新的 GadgetChainLink 对象，并将它们添加到 GadgetChain 中。  
这个新的 GadgetChain 接受两个参数，第一个参数为前一个链，第二个参数为当前链的最后一个link。 然后判断该链的最后一个link是否是sink点，如果是则认为找到了一条反序列化Gadgets链，否则继续寻找。  
新生成的 GadgetChain 会被添加到 methodsToExplore 中参加下一轮循环。  


