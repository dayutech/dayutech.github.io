---
title: Apache Struts2 原理学习
abbrlink: 66a16759
date: 2025-04-28 16:44:23
tags:
  - Apache Struts2
categories:
  - [框架学习]
top: 205
---
# 过滤器初始化
Struts2 的访问从配置的`org.apache.struts2.dispatcher.filter.StrutsPrepareAndExecuteFilter`过滤器开始。  
过滤器在程序加载过程中首先被执行的是`init`方法  
```java
public void init(FilterConfig filterConfig) throws ServletException {
    // 创建 InitOperations 对象 负责各个关键组件的初始化操作
        InitOperations init = createInitOperations(); 
        Dispatcher dispatcher = null;
        try {
            // 简单的包装了一下 filterConfig
        FilterHostConfig config = new FilterHostConfig(filterConfig);
        // 初始化日志记录器  不是重点
        init.initLogging(config);
        // 初始化dispatcher 重点
        dispatcher = init.initDispatcher(config);
        // 初始化静态类容加载器
        init.initStaticContentLoader(config, dispatcher);
        
        prepare = createPrepareOperations(dispatcher);
        execute = createExecuteOperations(dispatcher);
        // 设置将哪些path排除到strutsd的filter之外 这些请求将不会被struts处理 而交给之后的filter或者servlet处理
        this.excludedPatterns = init.buildExcludedPatternsList(dispatcher);
        // 用户可以继承该过滤器 重写该方法 做一些额外的初始化操作
        postInit(dispatcher, filterConfig);
        } finally {
        if (dispatcher != null) {
        dispatcher.cleanUpAfterInit();
        }
        init.cleanup();
        }
        }
```
<!--more-->
## Dispatcher 初始化
```java
public Dispatcher initDispatcher( HostConfig filterConfig ) {
    // 创建Dispatcher 设置了servletContext与initParams 
        Dispatcher dispatcher = createDispatcher(filterConfig);
        // 执行初始化 重点
        dispatcher.init();
        return dispatcher;
    }
```
```java
public void init() {

    	if (configurationManager == null) {
    		configurationManager = createConfigurationManager(Container.DEFAULT_NAME);
    	}

        try {
            // 执行文件映射器的初始化
            init_FileManager();
            // 执行默认属性的初始化 位于jar包中的默认属性
            init_DefaultProperties(); // [1]
        // 执行配置文件的初始化 包括 struts.xml struts-plugin.xml 等
            init_TraditionalXmlConfigurations(); // [2]
        // 执行自定义配置文件的初始化 自定义的 struts.properties 属性的初始化
        // 这个文件是用于引用其他的配置文件的
            init_LegacyStrutsProperties(); // [3]
            init_CustomConfigurationProviders(); // [5]
            init_FilterInitParameters() ; // [6]
            init_AliasStandardObjects() ; // [7]

            Container container = init_PreloadConfiguration();
            container.inject(this);
            init_CheckWebLogicWorkaround(container);

            if (!dispatcherListeners.isEmpty()) {
                for (DispatcherListener l : dispatcherListeners) {
                    l.dispatcherInitialized(this);
                }
            }
            errorHandler.init(servletContext);

        } catch (Exception ex) {
            LOG.error("Dispatcher initialization failed", ex);
            throw new StrutsException(ex);
        }
    }
```
### 文件映射器初始化
主要功能是构建了文件管理器与文件管理器工厂  
文件管理器工厂在查找文件的时候首先会尝试从容器中查找是否配置了文件管理器，如果没有找到，则会查找存储在工厂中的systemFileManager 这个systemFileManager应该也是在bean容器初始化的时候被注入的  
```java
private void init_FileManager() throws ClassNotFoundException {
    // 如果 filter初始化参数中配置了 struts.fileManager 参数则使用用户自定以的文件管理器  实现了FileManager类
        // 主要功能是进行文件的读写与修改的监控
        if (initParams.containsKey(StrutsConstants.STRUTS_FILE_MANAGER)) {
            final String fileManagerClassName = initParams.get(StrutsConstants.STRUTS_FILE_MANAGER);
            final Class<FileManager> fileManagerClass = (Class<FileManager>) Class.forName(fileManagerClassName);
            LOG.info("Custom FileManager specified: {}", fileManagerClassName);
            configurationManager.addContainerProvider(new FileManagerProvider(fileManagerClass, fileManagerClass.getSimpleName()));
        } else {
            // 使用默认的文件管理器
            // add any other Struts 2 provided implementations of FileManager
            configurationManager.addContainerProvider(new FileManagerProvider(JBossFileManager.class, "jboss"));
        }
        // 如果设置了文件管理器工厂  struts.fileManagerFactory
        // 这些provider都被添加到  ContainerProvider列表中去了，后面应该会统一调用 他们的register方法将他们一起注册到容器中
        if (initParams.containsKey(StrutsConstants.STRUTS_FILE_MANAGER_FACTORY)) {
            final String fileManagerFactoryClassName = initParams.get(StrutsConstants.STRUTS_FILE_MANAGER_FACTORY);
            final Class<FileManagerFactory> fileManagerFactoryClass = (Class<FileManagerFactory>) Class.forName(fileManagerFactoryClassName);
            LOG.info("Custom FileManagerFactory specified: {}", fileManagerFactoryClassName);
            configurationManager.addContainerProvider(new FileManagerFactoryProvider(fileManagerFactoryClass));
        }
    }
```
### 默认属性初始化
主要动作是向containerProvider中添加了 `DefaultPropertiesProvider`对象，我们重点关注其`register`方法  
```java
public void register(ContainerBuilder builder, LocatableProperties props) throws ConfigurationException {
        try {
            // 从org/apache/struts2/default.properties文件中加载默认属性
            PropertiesSettings defaultSettings = new PropertiesSettings("org/apache/struts2/default");
            loadSettings(props, defaultSettings);
        } catch (Exception e) {
            throw new ConfigurationException("Could not find or error in org/apache/struts2/default.properties", e);
        }
    }
```
```java
public PropertiesSettings(String name) {
        // 尝试从多个不同的类加载器中加载属性文件 默认是从当前上下文类加载器加载
        URL settingsUrl = ClassLoaderUtil.getResource(name + ".properties", getClass());
        
        if (settingsUrl == null) {
            LOG.debug("{}.properties missing", name);
            settings = new LocatableProperties();
            return;
        }
        
        // LocatableProperties 类是 Properties 的子类 增加了属性的定位功能，包括属性所在行 属性的注释 属性所在文件的url信息
        settings = new LocatableProperties(new LocationImpl(null, settingsUrl.toString()));

        // Load settings
        try (InputStream in = settingsUrl.openStream()) {
            // 正式从属性文件中加载属性 属性存储在父类对象 Properties 中
        // LocatableProperties 类中直接存储的是定位信息
            settings.load(in);
        } catch (IOException e) {
            throw new StrutsException("Could not load " + name + ".properties: " + e, e);
        }
    }
```
```java
// 将加载的默认书信复制一份到 register方法传入的 props参数中
protected void loadSettings(LocatableProperties props, final Settings settings) {
        for (Iterator i = settings.list(); i.hasNext(); ) {
            String name = (String) i.next();
            props.setProperty(name, settings.get(name), settings.getLocation(name));
        }
    }
```
### 传统xml配置文件初始化
```java
private void init_TraditionalXmlConfigurations() {
    // 尝试从过滤器初始化参数中获取配置路径
        String configPaths = initParams.get("config");
        if (configPaths == null) {
            // 如果没有配置则使用默认配置路径
        // struts-default.xml,struts-plugin.xml,struts.xml
            configPaths = DEFAULT_CONFIGURATION_PATHS;
        }
        String[] files = configPaths.split("\\s*[,]\\s*");
        for (String file : files) {
            if (file.endsWith(".xml")) {
                // 每一个文件添加 一个xmlConfiguationProider
                configurationManager.addContainerProvider(createStrutsXmlConfigurationProvider(file, false, servletContext));
            } else {
                throw new IllegalArgumentException("Invalid configuration file name");
            }
        }
    }
```
重点关注`StrutsXmlConfigurationProvider`的`register`方法
```java
@Override
    public void register(ContainerBuilder containerBuilder, LocatableProperties props) throws ConfigurationException {
    // 如果有传入servletContext 则此时将servletContext对象添加到容器中
        if (servletContext != null && !containerBuilder.contains(ServletContext.class)) {
            containerBuilder.factory(ServletContext.class, new Factory<ServletContext>() {
                public ServletContext create(Context context) throws Exception {
                    return servletContext;
                }
                public Class<? extends ServletContext> type() {
                    return servletContext.getClass();
                }
            });
        }
        // 调用父类的register方法
        super.register(containerBuilder, props);
    }
```
register 的时候  如果 documents 不为空才会有所动作  
```java
public void register(ContainerBuilder containerBuilder, LocatableProperties props) throws ConfigurationException {
        LOG.trace("Parsing configuration file [{}]", configFileName);
        Map<String, Node> loadedBeans = new HashMap<>();
        for (Document doc : documents) {
            Element rootElement = doc.getDocumentElement();
            NodeList children = rootElement.getChildNodes();
            int childSize = children.getLength();

            for (int i = 0; i < childSize; i++) {
                Node childNode = children.item(i);

                if (childNode instanceof Element) {
                    Element child = (Element) childNode;

                    final String nodeName = child.getNodeName();
                    // 解析bean标签
                    if ("bean".equals(nodeName)) {
                        // 类型属性
                        String type = child.getAttribute("type");
                        // bean名称  同一个类可以有多个bean名称   
                        String name = child.getAttribute("name");
                        // bean 的实现类
                        String impl = child.getAttribute("class");
                        // 是否进行静态插入   容器会解析类的静态属性
                        String onlyStatic = child.getAttribute("static");
                        // bean的生命周期
                        String scopeStr = child.getAttribute("scope");
                        // 是否是可选的
                        // 当optional属性为true时，即便class不存在加载也不会失败
                        boolean optional = "true".equals(child.getAttribute("optional"));
                        Scope scope = Scope.SINGLETON;
                        // 多实例
                        if ("prototype".equals(scopeStr)) {
                            scope = Scope.PROTOTYPE;
                            // 只在一次请求过程中有效
                        } else if ("request".equals(scopeStr)) {
                            scope = Scope.REQUEST;
                            // 在一个session中有效
                        } else if ("session".equals(scopeStr)) {
                            scope = Scope.SESSION;
                            // 单例
                        } else if ("singleton".equals(scopeStr)) {
                            scope = Scope.SINGLETON;
                            // 在当前线程中有效
                        } else if ("thread".equals(scopeStr)) {
                            scope = Scope.THREAD;
                        }

                        if (StringUtils.isEmpty(name)) {
                            name = Container.DEFAULT_NAME;
                        }

                        try {
                            // 加载bean的实现类
                            Class classImpl = ClassLoaderUtil.loadClass(impl, getClass());
                            Class classType = classImpl;
                            // 如果指定了bean的类型则使用指定的类型
                            // 否则以实现类的类型为bean的类型
                            if (StringUtils.isNotEmpty(type)) {
                                classType = ClassLoaderUtil.loadClass(type, getClass());
                            }
                            // 如果是静态注入
                            if ("true".equals(onlyStatic)) {
                                // Force loading of class to detect no class def found exceptions
                                classImpl.getDeclaredClasses();
                                // 在创建时，向bean中注入静态字段以及方法
                                containerBuilder.injectStatics(classImpl);
                            } else {
                                // 如果已经存在同名同类型的bean了
                                if (containerBuilder.contains(classType, name)) {
                                    // 获取当前bean节点在xml文件中的定位 得到一个LocationImpl对象
                                    // 包括行号 列号 uri 这三个来自命名空间 http://struts.apache.org/xwork/location 下的属性
                                    // 如 <t xmlns:s=http://struts.apache.org/xwork/location s:src="" s:row="" s:col="">
                                    Location loc = LocationUtils.getLocation(loadedBeans.get(classType.getName() + name));
                                    // 存在重复的bean直接就抛出异常了 这个值默认为true
                                    if (throwExceptionOnDuplicateBeans) {
                                        throw new ConfigurationException("Bean type " + classType + " with the name " +
                                                name + " has already been loaded by " + loc, child);
                                    }
                                }

                                // Force loading of class to detect no class def found exceptions
                                // 强制进行类加载  可能跟类的加载机制有关系  懒加载
                                // 使用 loadClass 方法加载的类并没有执行静态代码块
                                // 调用该方法进行类的强制加载
                                classImpl.getDeclaredConstructors();

                                LOG.debug("Loaded type: {} name: {} impl: {}", type, name, impl);
                                // 将bean注入到容器中  该方法后面再分析
                                containerBuilder.factory(classType, name, new LocatableFactory(name, classType, classImpl, scope, childNode), scope);
                            }
                            // 记录加载的bean
                            loadedBeans.put(classType.getName() + name, child);
                        } catch (Throwable ex) {
                            if (!optional) {
                                throw new ConfigurationException("Unable to load bean: type:" + type + " class:" + impl, ex, childNode);
                            } else {
                                LOG.debug("Unable to load optional class: {}", impl);
                            }
                        }
                        // 在 struts.xml 中定义常量，这些常量可以在 Struts 2 的配置文件和其他部分使用。
                    } else if ("constant".equals(nodeName)) {
                        String name = child.getAttribute("name");
                        String value = child.getAttribute("value");

                        if (valueSubstitutor != null) {
                            LOG.debug("Substituting value [{}] using [{}]", value, valueSubstitutor.getClass().getName());
                            value = valueSubstitutor.substitute(value);
                        }
                        // 和properties文件的属性一个以西  
                        props.setProperty(name, value, childNode);
                        // 该标签被用于处理那些在正常处理流程中未被识别或未被处理的请求
                    } else if (nodeName.equals("unknown-handler-stack")) {
                        List<UnknownHandlerConfig> unknownHandlerStack = new ArrayList<UnknownHandlerConfig>();
                        // 定义处理器列表
                        NodeList unknownHandlers = child.getElementsByTagName("unknown-handler-ref");
                        int unknownHandlersSize = unknownHandlers.getLength();

                        for (int k = 0; k < unknownHandlersSize; k++) {
                            Element unknownHandler = (Element) unknownHandlers.item(k);
                            Location location = LocationUtils.getLocation(unknownHandler);
                            // 通过名称进行引用
                            // 在使用时需要先定义  unknown-handler 标签
                            // <unknown-handler name="defaultUnknownHandler" class="com.example.DefaultUnknownHandler" />
                            // <unknown-handler name="customUnknownHandler" class="com.example.CustomUnknownHandler" />

                                    unknownHandlerStack.add(new UnknownHandlerConfig(unknownHandler.getAttribute("name"), location));
                        }

                        if (!unknownHandlerStack.isEmpty())
                            // configuration由init方法传入   具体用处目前还不知道
                            // 但应该是在请求无法被匹配的之后将从这个configurration中取出 handler对请求进行处理
                            configuration.setUnknownHandlerStack(unknownHandlerStack);
                    }
                }
            }
        }
    }
```
documents 在`init`方法调用时才会被设置  
这也就是说明  `containerProvider`在调用register方法前会先调用`init`方法
```java
public void init(Configuration configuration) {
        this.configuration = configuration;
        this.includedFileNames = configuration.getLoadedFileNames();
        loadDocuments(configFileName);
        }
private void loadDocuments(String configFileName) {
        try {
        loadedFileUrls.clear();
        documents = loadConfigurationFiles(configFileName, null);
        } catch (ConfigurationException e) {
        throw e;
        } catch (Exception e) {
        throw new ConfigurationException("Error loading configuration file " + configFileName, e);
        }
        }
private List<Document> loadConfigurationFiles(String fileName, Element includeElement) {
        List<Document> docs = new ArrayList<>();
        List<Document> finalDocs = new ArrayList<>();
        if (!includedFileNames.contains(fileName)) {
        LOG.debug("Loading action configurations from: {}", fileName);

        includedFileNames.add(fileName);

        Iterator<URL> urls = null;
        InputStream is = null;

        IOException ioException = null;
        try {
            // 通过资源名获取所有妈祖条件的资源的路径
        urls = getConfigurationUrls(fileName);
        } catch (IOException ex) {
        ioException = ex;
        }

        if (urls == null || !urls.hasNext()) {
        if (errorIfMissing) {
        throw new ConfigurationException("Could not open files of the name " + fileName, ioException);
        } else {
        LOG.trace("Unable to locate configuration files of the name {}, skipping", fileName);
        return docs;
        }
        }

        URL url = null;
        while (urls.hasNext()) {
        try {
        url = urls.next();
        // 通过文件管理器去加载文件了   默认时jbossfilemanager
        is = fileManager.loadFile(url);

        InputSource in = new InputSource(is);

        in.setSystemId(url.toString());
        // 解析xml文件添加到docs中
        docs.add(DomHelper.parse(in, dtdMappings));
        loadedFileUrls.add(url.toString());
        } catch (XWorkException e) {
        if (includeElement != null) {
        throw new ConfigurationException("Unable to load " + url, e, includeElement);
        } else {
        throw new ConfigurationException("Unable to load " + url, e);
        }
        } catch (Exception e) {
        throw new ConfigurationException("Caught exception while loading file " + fileName, e, includeElement);
        } finally {
        if (is != null) {
        try {
        is.close();
        } catch (IOException e) {
        LOG.error("Unable to close input stream", e);
        }
        }
        }
        }

        //sort the documents, according to the "order" attribute
        // 对文档进行排序
        Collections.sort(docs, new Comparator<Document>() {
public int compare(Document doc1, Document doc2) {
        return XmlHelper.getLoadOrder(doc1).compareTo(XmlHelper.getLoadOrder(doc2));
        }
        });
        // 解析文档中的 include 标签 然后将包含的xml文件也加载到docs中
        for (Document doc : docs) {
        Element rootElement = doc.getDocumentElement();
        NodeList children = rootElement.getChildNodes();
        int childSize = children.getLength();

        for (int i = 0; i < childSize; i++) {
        Node childNode = children.item(i);

        if (childNode instanceof Element) {
        Element child = (Element) childNode;

        final String nodeName = child.getNodeName();

        if ("include".equals(nodeName)) {
        String includeFileName = child.getAttribute("file");
        if (includeFileName.indexOf('*') != -1) {
        // handleWildCardIncludes(includeFileName, docs, child);
        ClassPathFinder wildcardFinder = new ClassPathFinder();
        wildcardFinder.setPattern(includeFileName);
        Vector<String> wildcardMatches = wildcardFinder.findMatches();
        for (String match : wildcardMatches) {
        finalDocs.addAll(loadConfigurationFiles(match, child));
        }
        } else {
        finalDocs.addAll(loadConfigurationFiles(includeFileName, child));
        }
        }
        }
        }
        finalDocs.add(doc);
        }

        LOG.debug("Loaded action configuration from: {}", fileName);
        }
        return finalDocs;
        }
```
### 遗留属性的初始化
将 `PropertiesConfigurationProvider`对象添加到`containerProvider`中  关注其register方法 
```java
final DefaultSettings settings = new DefaultSettings();
loadSettings(props, settings);
```

```java
public DefaultSettings() {

        ArrayList<Settings> list = new ArrayList<>();

        // stuts.properties, default.properties
        try {
            // 加载所有的 struts.properties文件
            list.add(new PropertiesSettings("struts"));
        } catch (Exception e) {
            LOG.warn("DefaultSettings: Could not find or error in struts.properties", e);
        }

        delegate = new DelegatingSettings(list);

        // struts.custom.properties
    // 获取 struts.properties 中的 struts.custom.properties 属性的值 
    // 这个值指向了其他的配置文件 通过逗号分隔
        String files = delegate.get(StrutsConstants.STRUTS_CUSTOM_PROPERTIES);
        if (files != null) {
            StringTokenizer customProperties = new StringTokenizer(files, ",");

            while (customProperties.hasMoreTokens()) {
                String name = customProperties.nextToken();
                try {
                    // 将所有的文件进行读取解析封装成 PropertiesSettings 对象
                    list.add(new PropertiesSettings(name));
                } catch (Exception e) {
                    LOG.error("DefaultSettings: Could not find {}.properties. Skipping.", name);
                }
            }
            // 创建一个委托对象
            // 后面调用的loadSetting方法将调用delegate的list方法获取所有的配置并逐个遍历复制到性的prop对象中
            delegate = new DelegatingSettings(list);
        }
    }
```
### 初始化用户自定义的配置Provider
```java
private void init_CustomConfigurationProviders() {
    // 获取过滤器属性  configProviders
        String configProvs = initParams.get("configProviders");
        if (configProvs != null) {
            String[] classes = configProvs.split("\\s*[,]\\s*");
            for (String cname : classes) {
                try {
                    // 加载类
                    Class cls = ClassLoaderUtil.loadClass(cname, this.getClass());
                    // 类实例化
                    ConfigurationProvider prov = (ConfigurationProvider)cls.newInstance();
                    // 如果时 ServletContextAwareConfigurationProvider 的子类 还需要先调用 initWithContext 方法
                    // 主要是看是否需要使用到servletContext里面的数据
                    if (prov instanceof ServletContextAwareConfigurationProvider) {
                        ((ServletContextAwareConfigurationProvider)prov).initWithContext(servletContext);
                    }
                    // 添加到容器中
                    configurationManager.addContainerProvider(prov);
                } catch (InstantiationException e) {
                    throw new ConfigurationException("Unable to instantiate provider: "+cname, e);
                } catch (IllegalAccessException e) {
                    throw new ConfigurationException("Unable to access provider: "+cname, e);
                } catch (ClassNotFoundException e) {
                    throw new ConfigurationException("Unable to locate provider class: "+cname, e);
                }
            }
        }
    }
```
### 初始化过滤器参数
将过滤器参数添加到  register 方法传入的 LocatableProperties 对象中

### 初始化标准对象的别名（将标准对象添加到容器中）
创建 DefaultBeanSelectionProvider 并放到容器里
为一些标准对象设置别名  
```java
public void register(ContainerBuilder builder, LocatableProperties props) {
    // 创建别名 其实就是将一些标准对象加入到容器中
    alias(ObjectFactory.class, StrutsConstants.STRUTS_OBJECTFACTORY, builder, props);
    alias(ActionFactory.class, StrutsConstants.STRUTS_OBJECTFACTORY_ACTIONFACTORY, builder, props);
    alias(ResultFactory.class, StrutsConstants.STRUTS_OBJECTFACTORY_RESULTFACTORY, builder, props);
    alias(ConverterFactory.class, StrutsConstants.STRUTS_OBJECTFACTORY_CONVERTERFACTORY, builder, props);
    alias(InterceptorFactory.class, StrutsConstants.STRUTS_OBJECTFACTORY_INTERCEPTORFACTORY, builder, props);
    alias(ValidatorFactory.class, StrutsConstants.STRUTS_OBJECTFACTORY_VALIDATORFACTORY, builder, props);
    alias(UnknownHandlerFactory.class, StrutsConstants.STRUTS_OBJECTFACTORY_UNKNOWNHANDLERFACTORY, builder, props);

    alias(FileManagerFactory.class, StrutsConstants.STRUTS_FILE_MANAGER_FACTORY, builder, props, Scope.SINGLETON);

    alias(XWorkConverter.class, StrutsConstants.STRUTS_XWORKCONVERTER, builder, props);
    alias(CollectionConverter.class, StrutsConstants.STRUTS_CONVERTER_COLLECTION, builder, props);
    alias(ArrayConverter.class, StrutsConstants.STRUTS_CONVERTER_ARRAY, builder, props);
    alias(DateConverter.class, StrutsConstants.STRUTS_CONVERTER_DATE, builder, props);
    alias(NumberConverter.class, StrutsConstants.STRUTS_CONVERTER_NUMBER, builder, props);
    alias(StringConverter.class, StrutsConstants.STRUTS_CONVERTER_STRING, builder, props);

    alias(ConversionPropertiesProcessor.class, StrutsConstants.STRUTS_CONVERTER_PROPERTIES_PROCESSOR, builder, props);
    alias(ConversionFileProcessor.class, StrutsConstants.STRUTS_CONVERTER_FILE_PROCESSOR, builder, props);
    alias(ConversionAnnotationProcessor.class, StrutsConstants.STRUTS_CONVERTER_ANNOTATION_PROCESSOR, builder, props);
    alias(TypeConverterCreator.class, StrutsConstants.STRUTS_CONVERTER_CREATOR, builder, props);
    alias(TypeConverterHolder.class, StrutsConstants.STRUTS_CONVERTER_HOLDER, builder, props);

    alias(TextProvider.class, StrutsConstants.STRUTS_XWORKTEXTPROVIDER, builder, props, Scope.PROTOTYPE);
    alias(TextProvider.class, StrutsConstants.STRUTS_TEXT_PROVIDER, builder, props, Scope.PROTOTYPE);
    alias(TextProviderFactory.class, StrutsConstants.STRUTS_TEXT_PROVIDER_FACTORY, builder, props, Scope.PROTOTYPE);
    alias(LocaleProviderFactory.class, StrutsConstants.STRUTS_LOCALE_PROVIDER_FACTORY, builder, props);
    alias(LocalizedTextProvider.class, StrutsConstants.STRUTS_LOCALIZED_TEXT_PROVIDER, builder, props);

    alias(ActionProxyFactory.class, StrutsConstants.STRUTS_ACTIONPROXYFACTORY, builder, props);
    alias(ObjectTypeDeterminer.class, StrutsConstants.STRUTS_OBJECTTYPEDETERMINER, builder, props);
    alias(ActionMapper.class, StrutsConstants.STRUTS_MAPPER_CLASS, builder, props);
    alias(MultiPartRequest.class, StrutsConstants.STRUTS_MULTIPART_PARSER, builder, props, Scope.PROTOTYPE);
    alias(FreemarkerManager.class, StrutsConstants.STRUTS_FREEMARKER_MANAGER_CLASSNAME, builder, props);
    alias(VelocityManager.class, StrutsConstants.STRUTS_VELOCITY_MANAGER_CLASSNAME, builder, props);
    alias(UrlRenderer.class, StrutsConstants.STRUTS_URL_RENDERER, builder, props);
    alias(ActionValidatorManager.class, StrutsConstants.STRUTS_ACTIONVALIDATORMANAGER, builder, props);
    alias(ValueStackFactory.class, StrutsConstants.STRUTS_VALUESTACKFACTORY, builder, props);
    alias(ReflectionProvider.class, StrutsConstants.STRUTS_REFLECTIONPROVIDER, builder, props);
    alias(ReflectionContextFactory.class, StrutsConstants.STRUTS_REFLECTIONCONTEXTFACTORY, builder, props);
    alias(PatternMatcher.class, StrutsConstants.STRUTS_PATTERNMATCHER, builder, props);
    alias(ContentTypeMatcher.class, StrutsConstants.STRUTS_CONTENT_TYPE_MATCHER, builder, props);
    alias(StaticContentLoader.class, StrutsConstants.STRUTS_STATIC_CONTENT_LOADER, builder, props);
    alias(UnknownHandlerManager.class, StrutsConstants.STRUTS_UNKNOWN_HANDLER_MANAGER, builder, props);
    alias(UrlHelper.class, StrutsConstants.STRUTS_URL_HELPER, builder, props);

    alias(TextParser.class, StrutsConstants.STRUTS_EXPRESSION_PARSER, builder, props);

    alias(DispatcherErrorHandler.class, StrutsConstants.STRUTS_DISPATCHER_ERROR_HANDLER, builder, props);

    /** Checker is used mostly in interceptors, so there be one instance of checker per interceptor with Scope.PROTOTYPE **/
    alias(ExcludedPatternsChecker.class, StrutsConstants.STRUTS_EXCLUDED_PATTERNS_CHECKER, builder, props, Scope.PROTOTYPE);
    alias(AcceptedPatternsChecker.class, StrutsConstants.STRUTS_ACCEPTED_PATTERNS_CHECKER, builder, props, Scope.PROTOTYPE);
    alias(NotExcludedAcceptedPatternsChecker.class, StrutsConstants.STRUTS_NOT_EXCLUDED_ACCEPTED_PATTERNS_CHECKER
            , builder, props, Scope.SINGLETON);
    // 切换到啊开发模式 取决于  配置文件中是否有配置
    switchDevMode(props);

    // Convert Struts properties into XWork properties
    // 给struts的一些参数换个名字  有啥用不清楚
    convertIfExist(props, StrutsConstants.STRUTS_LOG_MISSING_PROPERTIES, XWorkConstants.LOG_MISSING_PROPERTIES);
    convertIfExist(props, StrutsConstants.STRUTS_ENABLE_OGNL_EXPRESSION_CACHE, XWorkConstants.ENABLE_OGNL_EXPRESSION_CACHE);
    convertIfExist(props, StrutsConstants.STRUTS_ENABLE_OGNL_EVAL_EXPRESSION, XWorkConstants.ENABLE_OGNL_EVAL_EXPRESSION);
    convertIfExist(props, StrutsConstants.STRUTS_ALLOW_STATIC_METHOD_ACCESS, XWorkConstants.ALLOW_STATIC_METHOD_ACCESS);
    convertIfExist(props, StrutsConstants.STRUTS_CONFIGURATION_XML_RELOAD, XWorkConstants.RELOAD_XML_CONFIGURATION);

    convertIfExist(props, StrutsConstants.STRUTS_EXCLUDED_CLASSES, XWorkConstants.OGNL_EXCLUDED_CLASSES);
    convertIfExist(props, StrutsConstants.STRUTS_EXCLUDED_PACKAGE_NAME_PATTERNS, XWorkConstants.OGNL_EXCLUDED_PACKAGE_NAME_PATTERNS);
    convertIfExist(props, StrutsConstants.STRUTS_EXCLUDED_PACKAGE_NAMES, XWorkConstants.OGNL_EXCLUDED_PACKAGE_NAMES);

    convertIfExist(props, StrutsConstants.STRUTS_ADDITIONAL_EXCLUDED_PATTERNS, XWorkConstants.ADDITIONAL_EXCLUDED_PATTERNS);
    convertIfExist(props, StrutsConstants.STRUTS_ADDITIONAL_ACCEPTED_PATTERNS, XWorkConstants.ADDITIONAL_ACCEPTED_PATTERNS);
    convertIfExist(props, StrutsConstants.STRUTS_OVERRIDE_EXCLUDED_PATTERNS, XWorkConstants.OVERRIDE_EXCLUDED_PATTERNS);
    convertIfExist(props, StrutsConstants.STRUTS_OVERRIDE_ACCEPTED_PATTERNS, XWorkConstants.OVERRIDE_ACCEPTED_PATTERNS);
}
```


```java
protected void alias(Class type, String key, ContainerBuilder builder, Properties props, Scope scope) {
    // 如果这个标准对象目前还没有被添加到容器中
        if (!builder.contains(type, Container.DEFAULT_NAME)) {
            // 查看配置文件中是否设置了这个对象的名称
            String foundName = props.getProperty(key, DEFAULT_BEAN_NAME);
            // 如果在容器中通过配置的名称和类型找到了对应的bean 
            // 什么情况下bean会先于程序启动被装入到容器中？
            // 只能是用于在struts.xml等配置文件中配置了bean，覆盖了标准对象
            // 那么就需要为这个对象进行添加系统默认的名称以避免框架运行时找不到标准对象
            if (builder.contains(type, foundName)) {
                LOG.trace("Choosing bean ({}) for ({})", foundName, type.getName());
                // 那么给这个标准对象添加一个别名为  default
                builder.alias(type, foundName, Container.DEFAULT_NAME);
            } else {
                try {
                    // 如果容器中找不到对象 则证明该标准对象还没有被添加到容器中
                    // 通过配置的名称进行类加载  这里证明配置的名称应该是一个全类名
                    Class cls = ClassLoaderUtil.loadClass(foundName, this.getClass());
                    LOG.trace("Choosing bean ({}) for ({})", cls.getName(), type.getName());
                    // 如果找到了对一个的类并成功加载 那么加u将这个类添加到容器中
                    // 使用的名称为 default 
                    builder.factory(type, cls, scope);
                } catch (ClassNotFoundException ex) {
                    // Perhaps a spring bean id, so we'll delegate to the object factory at runtime
                    LOG.trace("Choosing bean ({}) for ({}) to be loaded from the ObjectFactory", foundName, type.getName());
                    if (DEFAULT_BEAN_NAME.equals(foundName)) {
                        // Probably an optional bean, will ignore
                    } else {
                        if (ObjectFactory.class != type) {
                            builder.factory(type, new ObjectFactoryDelegateFactory(foundName, type), scope);
                        } else {
                            throw new ConfigurationException("Cannot locate the chosen ObjectFactory implementation: " + foundName);
                        }
                    }
                }
            }
        } else {
            LOG.warn("Unable to alias bean type ({}), default mapping already assigned.", type.getName());
        }
    }
```

### 初始化预加载配置对象（创建容器）

```java
import com.opensymphony.xwork2.inject.Inject;

public Container getContainer() {
    if (ContainerHolder.get() != null) {
        return ContainerHolder.get();
    }
    // 容器管理器之前已经有创建了
    ConfigurationManager mgr = getConfigurationManager();
    if (mgr == null) {
        throw new IllegalStateException("The configuration manager shouldn't be null");
    } else {
        // Configuration 对象之前没有创建  这里会创建  
        Configuration config = mgr.getConfiguration();
        if (config == null) {
            throw new IllegalStateException("Unable to load configuration");
        } else {
            Container container = config.getContainer();
            ContainerHolder.store(container);
            return container;
        }
    }
}

public synchronized Configuration getConfiguration() {
    if (configuration == null) {
        // 创建 DefaultConfiguration 对象 并设置到属性中
        setConfiguration(createConfiguration(defaultFrameworkBeanName));
        try {
            // 加载容器   ContainerProviders 就是之气那那一些列的init方法中设置的那些
            configuration.reloadContainer(getContainerProviders());
        } catch (ConfigurationException e) {
            setConfiguration(null);
            throw new ConfigurationException("Unable to load configuration.", e);
        }
    } else {
        conditionalReload();
    }

    return configuration;
}

public synchronized List<PackageProvider> reloadContainer(List<ContainerProvider> providers) throws ConfigurationException {
    packageContexts.clear();
    loadedFileNames.clear();
    List<PackageProvider> packageProviders = new ArrayList<>();
    // 这个参数就是传入到  containerProvider 的 register方法的第二个参数  
    // 所以在register方法调用完毕后 props中存的就是struts的所有配置属性
    ContainerProperties props = new ContainerProperties();
    // 容器的构建器 这个容器的构建器属于用户，包含用户注入的bean等
    ContainerBuilder builder = new ContainerBuilder();
    // 创建根容器 跟容器中主要包含的时系统的标准对象
    Container bootstrap = createBootstrapContainer(providers);
    // 遍历provider
    for (final ContainerProvider containerProvider : providers) {
        // 容器注入  为provider注入字段  通过inject标签注入
        bootstrap.inject(containerProvider);
        // 调用容器provider的init方法
        containerProvider.init(this);
        // 调用register方法
        containerProvider.register(builder, props);
    }
    // 将provider设置的属性 转换为string类型的bean注入到容器中
    props.setConstants(builder);

    builder.factory(Configuration.class, new Factory<Configuration>() {
        public Configuration create(Context context) throws Exception {
            return DefaultConfiguration.this;
        }

        @Override
        public Class<? extends Configuration> type() {
            return DefaultConfiguration.this.getClass();
        }
    });
    // 创建actionContext 最开始应该为空
    ActionContext oldContext = ActionContext.getContext();
    try {
        // Set the bootstrap container for the purposes of factory creation
        // 创建 ActionContext 包括 值栈的创建
        setContext(bootstrap);
        // 创建 用户容器  不加载单例对象
        container = builder.create(false);
        // 这里啥也不会做  之前已经创建了ActionContext了  不会再重复创建
        // 这一步应该是为了避免前面 bootStrap 容器 中没有加载的有值栈对象工厂的情况
        // 但是这种情况真的会出现吗
        setContext(container);
        // 获取  ObjectFactory 的bean实例
        objectFactory = container.getInstance(ObjectFactory.class);

        // Process the configuration providers first
        for (final ContainerProvider containerProvider : providers) {
            // 对PackageProvider进行特殊处理
        // 所有的ConfigurationProvider的子类都是 packageProvider
        // 包括 struts.xml等文件对应的provider
            if (containerProvider instanceof PackageProvider) {
                // 前面已经注入过依次了  这里再次注入意义何在
                container.inject(containerProvider);
                // 调用loadPackages方法
                // 其实就是处理 struts.xml等文件对应的 package标签  
                // 即与action有关
                ((PackageProvider) containerProvider).loadPackages();
                packageProviders.add((PackageProvider) containerProvider);
            }
        }

        // Then process any package providers from the plugins
        // 用户可以自定义 packageProvider 
        Set<String> packageProviderNames = container.getInstanceNames(PackageProvider.class);
        for (String name : packageProviderNames) {
            PackageProvider provider = container.getInstance(PackageProvider.class, name);
            provider.init(this);
            provider.loadPackages();
            packageProviders.add(provider);
        }
        // 重构运行时配置 主要是对每个Action的配置进行补充， 如果一些关键配置缺省的话从父包的配置中获取默认的配置
        // 如 result 以及拦截器的配置
        rebuildRuntimeConfiguration();
    } finally {
        if (oldContext == null) {
            ActionContext.setContext(null);
        }
    }
    return packageProviders;
}


protected Container createBootstrapContainer(List<ContainerProvider> providers) {
    // 创建容器builder 
    // 构造方法里主要创价了两个 factories 即 CONTAINER_FACTORY 以及 LOGGER_FACTORY
    ContainerBuilder builder = new ContainerBuilder();
    boolean fmFactoryRegistered = false;
    // 遍历containerProvider
    for (ContainerProvider provider : providers) {
        if (provider instanceof FileManagerProvider) {
            // 调用fileManagerProvider的register注入文件管理器
            // 文件管理器后面还会被注入一次 但是因为其是单例的所以没啥影响
            // 这里提前注入是因为后面有些provider的register方法会使用到filemanager取访问文件1
            provider.register(builder, null);
        }
        if (provider instanceof FileManagerFactoryProvider) {
            // 同上
            provider.register(builder, null);
            fmFactoryRegistered = true;
        }
    }
    // 注入标准对象
    builder.factory(ObjectFactory.class, Scope.SINGLETON);
    builder.factory(ActionFactory.class, DefaultActionFactory.class, Scope.SINGLETON);
    builder.factory(ResultFactory.class, DefaultResultFactory.class, Scope.SINGLETON);
    builder.factory(InterceptorFactory.class, DefaultInterceptorFactory.class, Scope.SINGLETON);
    builder.factory(com.opensymphony.xwork2.factory.ValidatorFactory.class, com.opensymphony.xwork2.factory.DefaultValidatorFactory.class, Scope.SINGLETON);
    builder.factory(ConverterFactory.class, DefaultConverterFactory.class, Scope.SINGLETON);
    builder.factory(UnknownHandlerFactory.class, DefaultUnknownHandlerFactory.class, Scope.SINGLETON);

    builder.factory(FileManager.class, "system", DefaultFileManager.class, Scope.SINGLETON);
    if (!fmFactoryRegistered) {
        builder.factory(FileManagerFactory.class, DefaultFileManagerFactory.class, Scope.SINGLETON);
    }
    builder.factory(ReflectionProvider.class, OgnlReflectionProvider.class, Scope.SINGLETON);
    builder.factory(ValueStackFactory.class, OgnlValueStackFactory.class, Scope.SINGLETON);

    builder.factory(XWorkConverter.class, Scope.SINGLETON);
    builder.factory(ConversionPropertiesProcessor.class, DefaultConversionPropertiesProcessor.class, Scope.SINGLETON);
    builder.factory(ConversionFileProcessor.class, DefaultConversionFileProcessor.class, Scope.SINGLETON);
    builder.factory(ConversionAnnotationProcessor.class, DefaultConversionAnnotationProcessor.class, Scope.SINGLETON);
    builder.factory(TypeConverterCreator.class, DefaultTypeConverterCreator.class, Scope.SINGLETON);
    builder.factory(TypeConverterHolder.class, DefaultTypeConverterHolder.class, Scope.SINGLETON);

    builder.factory(XWorkBasicConverter.class, Scope.SINGLETON);
    builder.factory(TypeConverter.class, XWorkConstants.COLLECTION_CONVERTER, CollectionConverter.class, Scope.SINGLETON);
    builder.factory(TypeConverter.class, XWorkConstants.ARRAY_CONVERTER, ArrayConverter.class, Scope.SINGLETON);
    builder.factory(TypeConverter.class, XWorkConstants.DATE_CONVERTER, DateConverter.class, Scope.SINGLETON);
    builder.factory(TypeConverter.class, XWorkConstants.NUMBER_CONVERTER, NumberConverter.class, Scope.SINGLETON);
    builder.factory(TypeConverter.class, XWorkConstants.STRING_CONVERTER, StringConverter.class, Scope.SINGLETON);

    builder.factory(TextProvider.class, "system", DefaultTextProvider.class, Scope.SINGLETON);

    builder.factory(LocalizedTextProvider.class, StrutsLocalizedTextProvider.class, Scope.SINGLETON);
    builder.factory(TextProviderFactory.class, StrutsTextProviderFactory.class, Scope.SINGLETON);
    builder.factory(LocaleProviderFactory.class, DefaultLocaleProviderFactory.class, Scope.SINGLETON);

    builder.factory(TextParser.class, OgnlTextParser.class, Scope.SINGLETON);

    builder.factory(ObjectTypeDeterminer.class, DefaultObjectTypeDeterminer.class, Scope.SINGLETON);
    builder.factory(PropertyAccessor.class, CompoundRoot.class.getName(), CompoundRootAccessor.class, Scope.SINGLETON);
    builder.factory(OgnlUtil.class, Scope.SINGLETON);

    builder.factory(ValueSubstitutor.class, EnvsValueSubstitutor.class, Scope.SINGLETON);
    // 常量是一个 prototype类型的 String类型的bean 每一次访问都会创建一个新的bean
    builder.constant(XWorkConstants.DEV_MODE, "false");
    builder.constant(StrutsConstants.STRUTS_DEVMODE, "false");
    builder.constant(XWorkConstants.LOG_MISSING_PROPERTIES, "false");
    builder.constant(XWorkConstants.ENABLE_OGNL_EVAL_EXPRESSION, "false");
    builder.constant(XWorkConstants.ENABLE_OGNL_EXPRESSION_CACHE, "true");
    builder.constant(XWorkConstants.RELOAD_XML_CONFIGURATION, "false");
    builder.constant(StrutsConstants.STRUTS_I18N_RELOAD, "false");

    builder.constant(StrutsConstants.STRUTS_MATCHER_APPEND_NAMED_PARAMETERS, "true");
    // 创建container实例
    return builder.create(true);
}

// 看看factory方法具体干了啥
public <T> ContainerBuilder factory(final Class<T> type, final String name,
                                    final Class<? extends T> implementation, final Scope scope) {
    // This factory creates new instances of the given implementation.
    // We have to lazy load the constructor because the Container
    // hasn't been created yet.
    InternalFactory<? extends T> factory = new InternalFactory<T>() {

        volatile ContainerImpl.ConstructorInjector<? extends T> constructor;

        // 当调用factory的create的时候就会真正的创建bean实例
        // internalFacotry是最内层的factory，外面还有其他的包装用的factory用来完成不同的功能
        // 如scopeFactory 用来确定bean的生命周期
        @SuppressWarnings("unchecked")
        public T create(InternalContext context) {
            if (constructor == null) {
                // 获取bean的构造函数
                // 这里采用了单例设计 即只获取一次构造方法 避免每一次创建bean的时候都重复获取
                this.constructor =
                        context.getContainerImpl().getConstructor(implementation);
            }
            // 创建对象实例
            return (T) constructor.construct(context, type);
        }

        @Override
        public Class<? extends T> type() {
            return implementation;
        }

        @Override
        public String toString() {
            return new LinkedHashMap<String, Object>() {{
                put("type", type);
                put("name", name);
                put("implementation", implementation);
                put("scope", scope);
            }}.toString();
        }
    };

    return factory(Key.newInstance(type, name), factory, scope);
}

private <T> ContainerBuilder factory(final Key<T> key,
                                     InternalFactory<? extends T> factory, Scope scope) {
    // 确认容器是否被创建  没有被创建才能继续执行
    ensureNotCreated();
    // 检查容器中是否已经被注入了 同名的bean  type+name
    checkKey(key);
    // 创建bean生命周期工厂  不同的生命周期得到的工厂是不一样的 具体体现在其create方法的实现不同上
    // 因为不同作用与需要使用不同的存储方案 如 thread就需要使用threadLocal的变量类型进行存储
    final InternalFactory<? extends T> scopedFactory = scope.scopeFactory(key.getType(), key.getName(), factory);
    // 所有的 factory 都保存在factories中
    factories.put(key, scopedFactory);
    // 对scopefactory更进一步的包装  
    // 主要设计 ExternalContext 的设置
    // 这个类主要设计了 ExternalContext 的设置 只有 单例以及  EarlyInitializable类型的bean才被使用
    // 那么对于其他类型的bean来说岂不就是无用的，那么就存在一个自选消耗的问题，那么是否应该把一步放到if里面去。  
    // 这不提个pr吗？？？ 
    InternalFactory<T> callableFactory = createCallableFactory(key, scopedFactory);
    // 判断factor的类型  即bean标签的type属性指定的值
    // 指示这些bean需要提前进行装配  
    if (EarlyInitializable.class.isAssignableFrom(factory.type())) {
        earlyInitializableFactories.add(callableFactory);
        // 单例类型的bean也需要单独存放在一个列表中
    } else if (scope == Scope.SINGLETON) {
        singletonFactories.add(callableFactory);
    }

    return this;
}

// 创建容器实例
public Container create(boolean loadSingletons) {
    // 确保容器没有被创建
    ensureNotCreated();
    created = true;
    // 新建一个 ContainerImpl 实例对象
    // // 将 创建从 type 到 bean name的不可变映射关系 线程安全
    final ContainerImpl container = new ContainerImpl(new HashMap<>(factories));
    // 
    if (loadSingletons) {
        container.callInContext(new ContainerImpl.ContextualCallable<Void>() {
            public Void call(InternalContext context) {
                for (InternalFactory<?> factory : singletonFactories) {
                    // 单例的bean 不需要接收返回值  因为创建后其直接被工厂类的instance 变量引用
                    // 每次创建都会直接从 instance 变量中找
                    factory.create(context);
                }
                return null;
            }
        });
    }

    container.callInContext(new ContainerImpl.ContextualCallable<Void>() {
        public Void call(InternalContext context) {
            // 提前初始化的bean 被标记为 
            // 这类型的bean 有个特定就是实现了 Initializable 接口 并且会在创建时调用  init方法
            // 默认有一个这样的bean被配置  即 DefaultConversionPropertiesProcessor   用作properties 转化器
            // 该类会读取两个properties配置文件取查找对应的转换器
            for (InternalFactory<?> factory : earlyInitializableFactories) {
                factory.create(context);
            }
            return null;
        }
    });
    // 处理被标注为 static的bean 处理其静态字段以及静态方法
    container.injectStatics(staticInjections);
    return container;
}

// 将 创建从 type 到 bean name的不可变映射关系 线程安全
ContainerImpl(Map<Key<?>, InternalFactory<?>> factories) {
    this.factories = factories;
    Map<Class<?>, Set<String>> map = new HashMap<>();
    for (Key<?> key : factories.keySet()) {
        Set<String> names = map.get(key.getType());
        if (names == null) {
            names = new HashSet<>();
            map.put(key.getType(), names);
        }
        names.add(key.getName());
    }

    for (Entry<Class<?>, Set<String>> entry : map.entrySet()) {
        entry.setValue(Collections.unmodifiableSet(entry.getValue()));
    }

    this.factoryNamesByType = Collections.unmodifiableMap(map);
}

void injectStatics(List<Class<?>> staticInjections) {
    final List<Injector> injectors = new ArrayList<>();
    // 遍历需要被注入静态字段与方法的bean
    for (Class<?> clazz : staticInjections) {
        // 查找字段注入器 并添加到  injectors 中
        addInjectorsForFields(clazz.getDeclaredFields(), true, injectors);
        // 查找方法注入器 并添加到 injectors 中
        addInjectorsForMethods(clazz.getDeclaredMethods(), true, injectors);
    }
    // 调用注入器进行注入
    callInContext(new ContextualCallable<Void>() {
        public Void call(InternalContext context) {
            for (Injector injector : injectors) {
                injector.inject(context, null);
            }
            return null;
        }
    });
}

// 以字段注入器为例子
// name就是字段的Inject注解的value 指向了另一个bean
// field 为需要注入的字段
// container为根容器
public FieldInjector(ContainerImpl container, Field field, String name)
        throws MissingDependencyException {
    this.field = field;
    if ((!Modifier.isPublic(field.getModifiers()) || !Modifier.isPublic(field.getDeclaringClass().getModifiers()))
            && !field.isAccessible()) {
        SecurityManager sm = System.getSecurityManager();
        try {
            if (sm != null) {
                sm.checkPermission(new ReflectPermission("suppressAccessChecks"));
            }
            field.setAccessible(true);
        } catch (AccessControlException e) {
            throw new DependencyException("Security manager in use, could not access field: "
                    + field.getDeclaringClass().getName() + "(" + field.getName() + ")", e);
        }
    }
    // 创建用户注入的key
    Key<?> key = Key.newInstance(field.getType(), name);
    // 在容器中查找待注入的bean 找到的是一个factory 再调用factory的create方法就可以创建bean了
    factory = container.getFactory(key);
    if (factory == null) {
        throw new MissingDependencyException("No mapping found for dependency " + key + " in " + field + ".");
    }

    this.externalContext = ExternalContext.newInstance(field, key, container);
}

public void inject(InternalContext context, Object o) {
    ExternalContext<?> previous = context.getExternalContext();
    context.setExternalContext(externalContext);
    try {
        // 给字段设置值
        // 因为是静态字段 所以o应该为null
        // 调用create方法查找bean
        field.set(o, factory.create(context));
    } catch (IllegalAccessException e) {
        throw new AssertionError(e);
    } finally {
        context.setExternalContext(previous);
    }
}

// 对于方法上的注入器来说
// 首先会查找方法上是否有Inject注解 Inject注解的value为默认的bean的名称
// 然后取遍历参数  获得每一个参数的类型然后 查找参数是否被Inject注解 如果有则使用这个注解的值作为 bean的名称取查找bean，
// 如果参数没有被注解 则使用默认名称取查找对应的bean。
// 方法上的Inject注解是必须要有的
@Inject("default")
public static methodA(@Inject("id") String id, Test test);
// 重构运行时配置
protected synchronized RuntimeConfiguration buildRuntimeConfiguration() throws ConfigurationException {
        Map<String, Map<String, ActionConfig>> namespaceActionConfigs = new LinkedHashMap<>();
        Map<String, String> namespaceConfigs = new LinkedHashMap<>();
        // 遍历包配置
        for (PackageConfig packageConfig : packageContexts.values()) {
        // 如果包配置不是抽象的
        // 这里借鉴了面向对象的理念  抽象包作为父包被集成 不直接参与action以及bean等的定义
        if (!packageConfig.isAbstract()) {
            // 获取包命名空间   我未配置
        String namespace = packageConfig.getNamespace();
        // null
        Map<String, ActionConfig> configs = namespaceActionConfigs.get(namespace);

        if (configs == null) {
        configs = new LinkedHashMap<>();
        }
        // 获取cationConfig
        Map<String, ActionConfig> actionConfigs = packageConfig.getAllActionConfigs();
        // 遍历actionConfig
        for (Object o : actionConfigs.keySet()) {
        String actionName = (String) o;
        // 通过actionname获取对应的配置对象
        ActionConfig baseConfig = actionConfigs.get(actionName);
        // buildFullActionConfig 方法负责重构actionConfig 主要时对result以及interpretor的重构
        configs.put(actionName, buildFullActionConfig(packageConfig, baseConfig));
        }
        
        namespaceActionConfigs.put(namespace, configs);
        if (packageConfig.getFullDefaultActionRef() != null) {
        namespaceConfigs.put(namespace, packageConfig.getFullDefaultActionRef());
        }
        }
        }

        PatternMatcher<int[]> matcher = container.getInstance(PatternMatcher.class);
        boolean appendNamedParameters = Boolean.parseBoolean(
        container.getInstance(String.class, StrutsConstants.STRUTS_MATCHER_APPEND_NAMED_PARAMETERS)
        );

        return new RuntimeConfigurationImpl(Collections.unmodifiableMap(namespaceActionConfigs),
        Collections.unmodifiableMap(namespaceConfigs), matcher, appendNamedParameters);
        }
```
#### 容器注入方法是如何工作的
o是调用构造方法创建的bean实例 inject方法负责将该bean中的被Inject注解修饰的字段或者方法参数注入到bean对象中
```java
public void inject(final Object o) {
    // callInContext 会先创建一个 InternalContext 然后调用call方法
        callInContext(new ContextualCallable<Void>() {
            public Void call(InternalContext context) {
                inject(o, context);
                return null;
            }
        });
    }
void inject(Object o, InternalContext context) {
    // 调用 jnjectors的get方法获取方法与字段的注入器，然后调用注入器的inject方法
List<Injector> injectors = this.injectors.get(o.getClass());
for (Injector injector : injectors) {
injector.inject(context, o);
}
}
// jnjectors在容器初始化的时候被定义 
// 定义了一个匿名类对象  该对象为 ReferenceCache类型 
// 重写了create方法

final Map<Class<?>, List<Injector>> injectors =
        new ReferenceCache<Class<?>, List<Injector>>() {
@Override
protected List<Injector> create(Class<?> key) {
        List<Injector> injectors = new ArrayList<>();
        addInjectors(key, injectors);
        return injectors;
        }
        };


// 找到其get方法
@Override
public V get(final Object key) {
    // 先尝试从父类中查找  找不到再调用 internalCreate 方法进行创建
        V value = super.get(key);
        return (value == null) ? internalCreate((K) key) : value;
        }
// 父类的查找方法
        V internalGet(K key) {
    // delegate 为一个并发Map，被初始话为空
        // makeKeyReferenceAware 创建了key的引用 默认为强引用类型
        // 这种Class类型的对象 会被经常使用所以被定义为强引用类型 不会再gc的时候被回收 除非不在存在引用计数
        Object valueReference = delegate.get(makeKeyReferenceAware(key));
        // 返回null
        return valueReference == null ? null : (V) dereferenceValue(valueReference);
        }
// 子类创建
V internalCreate(K key) {
try {
    // 创建一个未来任务
        // 这里使用多线程的必要性是什么   整个初始化过程都是再单线程的环境中运行的  
        // 这里搞这么复杂的必要性没看出来
        // 且创建线程也是额外的开销 
        // 上面只考虑了初始化过程是单线程的 但实际使用是并不只有初始化时参会调用到该方法
        // 如果时用户触发了这个方法则可能时在多线程环境中 这时候就要保证线程安全
        // CallableCreate 的call方法是核心
FutureTask<V> futureTask = new FutureTask<>(new CallableCreate(key));

// use a reference so we get the same equality semantics.
Object keyReference = referenceKey(key);
// 将任务放入到线程安全的map中
Future<V> future = futures.putIfAbsent(keyReference, futureTask);
// 如果map中没有已经存在的future，那么当前线程负责调用该future
if (future == null) {
// winning thread.
try {
if (localFuture.get() != null) {
throw new IllegalStateException("Nested creations within the same cache are not allowed.");
}
// threadLocal 类型 每个线程各一
        // 用来避免重复嵌套创建
localFuture.set(futureTask);
// 运行task
futureTask.run();
// 阻塞等待获取
V value = futureTask.get();
// 通过put的策略将注入器添加到引用map中
        // 下次访问的时候直接通过keyReference进行get 就不再需要重新创建了
putStrategy().execute(this, keyReference, referenceValue(keyReference, value));
return value;
} finally {
localFuture.remove();
futures.remove(keyReference);
}
} else {
    // 如果map中存在已经存在的future，那么当前线程负责等待该future执行完毕 
        // 避免重复创建注入器
// wait for winning thread.
return future.get();
}
} catch (InterruptedException e) {
throw new RuntimeException(e);
} catch (ExecutionException e) {
Throwable cause = e.getCause();
if (cause instanceof RuntimeException) {
throw (RuntimeException) cause;
} else if (cause instanceof Error) {
throw (Error) cause;
}
throw new RuntimeException(cause);
}
}

public V call() {
        // try one more time (a previous future could have come and gone.)
        // 再次尝试从缓存中获取  说是为了避免其他future以及成功创建了注入器
        // 但问题是这个init过程也不是多线程的啊。。。。
        V value = internalGet(key);
        if (value != null) {
        return value;
        }

        // create value.
        value = create(key);
        if (value == null) {
        throw new NullPointerException("create(K) returned null for: " + key);
        }
        return value;
        }

final Map<Class<?>, List<Injector>> injectors = new ReferenceCache<Class<?>, List<Injector>>() {
protected List<Injector> create(Class<?> key) {
        List<Injector> injectors = new ArrayList();
        ContainerImpl.this.addInjectors(key, injectors);
        return injectors;
        }
        };

// 注入器的部分前面提到过 这里不再赘述
void addInjectors(Class clazz, List<Injector> injectors) {
if (clazz == Object.class) {
return;
}
// 递归调用  获取父类字段以及方法注入器
// Add injectors for superclass first.
addInjectors(clazz.getSuperclass(), injectors);

// TODO (crazybob): Filter out overridden members.
        // 获取字段注入器
addInjectorsForFields(clazz.getDeclaredFields(), false, injectors);
// 获取方法注入器
addInjectorsForMethods(clazz.getDeclaredMethods(), false, injectors);
}       
// 注入器会通过反射的方式去设置bean对象的字段以及方法

        
        
        
```
### struts.xml package处理
对package的处理实际上也就是对action的处理，通过StutsXmlCOnfigurationProvider的loadPackages方法来进行
```java
@Override
public void loadPackages() {
        ActionContext ctx = ActionContext.getContext();
        ctx.put(reloadKey, Boolean.TRUE);
        // 调用父类方法
        super.loadPackages();
        }
// 
public void loadPackages() throws ConfigurationException {
        List<Element> reloads = new ArrayList<Element>();
        verifyPackageStructure();
        // struts标签下的内容
        for (Document doc : documents) {
        Element rootElement = doc.getDocumentElement();
        // 获取所有子标签
        NodeList children = rootElement.getChildNodes();
        int childSize = children.getLength();

        for (int i = 0; i < childSize; i++) {
        Node childNode = children.item(i);
        // 如果时元素标签
        if (childNode instanceof Element) {
        Element child = (Element) childNode;
        
final String nodeName = child.getNodeName();
        // 如果节点名为 package
        if ("package".equals(nodeName)) {
            // 向配置类中添加 packageConfig
        PackageConfig cfg = addPackage(child);
        if (cfg.isNeedsRefresh()) {
        reloads.add(child);
        }
        }
        }
        }
        // 用户可集成strutsConfigurationProvider 重写 loadExtraConfiguration方法 实现扩展的功能 主要时对struts.xml等文件的解析 如增加新的标签等  。。。。
        loadExtraConfiguration(doc);
        }

        if (reloads.size() > 0) {
        reloadRequiredPackages(reloads);
        }
        // 重复调用
        for (Document doc : documents) {
        loadExtraConfiguration(doc);
        }

        documents.clear();
        declaredPackages.clear();
        configuration = null;
        }
protected PackageConfig addPackage(Element packageElement) throws ConfigurationException {
    // 获取package name
        String packageName = packageElement.getAttribute("name");
        // configguration 中存在一个默认的包配置名为struts-default
        // 我们配置的包名为 default  现在还没有被创建
        // 如果我们将我们的包名设置为 struts-default 则会导致我们的包的内容无效
        PackageConfig packageConfig = configuration.getPackageConfig(packageName);
        if (packageConfig != null) {
        LOG.debug("Package [{}] already loaded, skipping re-loading it and using existing PackageConfig [{}]", packageName, packageConfig);
        return packageConfig;
        }
        // 创建包配置构建器
        PackageConfig.Builder newPackage = buildPackageContext(packageElement);

        if (newPackage.isNeedsRefresh()) {
        return newPackage.build();
        }

        LOG.debug("Loaded {}", newPackage);

        // add result types (and default result) to this package
        // 解析 result-type标签 
        addResultTypes(newPackage, packageElement);

        // load the interceptors and interceptor stacks for this package
        // 加载拦截器 以及拦截器栈
        // 拦截器通过 interceptor 标签指定  被解析为拦截器配置 添加到拦截器配置列表中
        // 包拦截器生效需要通过 包拦截器栈来配置  通过 interceptor-stack 标签下的interceptor-ref来指定
        // 拦截器栈可以有多个 通过不同的名字区分 和拦截器配置一起被添加到拦截器配置列表中
        // 不同的action可以引用不同的拦截器或者拦截器栈
        // 拦截器栈类似于组的概念 表示一组拦截器
        loadInterceptors(newPackage, packageElement);

        // load the default interceptor reference for this package
        // 加载默认拦截器引用 通过default-interpretor-ref标签指定
        // 对包的所有action都有效?
        loadDefaultInterceptorRef(newPackage, packageElement);

        // load the default class ref for this package
        // 加载默认类引用  通过 default-class-ref标签指定 
        // 当某些标签的class属性没有被指定的时候就是使用该标签指定的class
        loadDefaultClassRef(newPackage, packageElement);

        // load the global result list for this package
        // 加载全局结果处理
        // action执行完后的行为  默认行为吗？
        loadGlobalResults(newPackage, packageElement);
        // 允许调用的action方法 
        // 如果不配置 那么所有的 public cation方法均可以被调用
        loadGlobalAllowedMethods(newPackage, packageElement);

        // load the global exception handler list for this package
        // 定义全局异常映射结果
        loadGlobalExceptionMappings(newPackage, packageElement);

        // get actions
        // action节点处理
        NodeList actionList = packageElement.getElementsByTagName("action");

        for (int i = 0; i < actionList.getLength(); i++) {
        Element actionElement = (Element) actionList.item(i);
        // 创建action配置
        addAction(actionElement, newPackage);
        }

        // load the default action reference for this package
        // 默认action引用   当用户访问该命名空间但没有指定具体的action的时候将调用默认的action
        loadDefaultActionRef(newPackage, packageElement);

        PackageConfig cfg = newPackage.build();
        configuration.addPackageConfig(cfg.getName(), cfg);
        return cfg;
        }


protected PackageConfig.Builder buildPackageContext(Element packageElement) {
    // extends为 struts-default 即默认存在的一个包配置  作为 当前包配置的父亲
        // 父配置可以有多个 通过都好分割  字符串中越靠后的父包 被插入到当前包配置的父包列表的第一个
        String parent = packageElement.getAttribute("extends");
        // 是否时抽象的
        String abstractVal = packageElement.getAttribute("abstract");
        boolean isAbstract = Boolean.parseBoolean(abstractVal);
        // 获取包名
        String name = StringUtils.defaultString(packageElement.getAttribute("name"));
        // 获取包命名空间
        String namespace = StringUtils.defaultString(packageElement.getAttribute("namespace"));

        // Strict DMI is enabled by default, it can disabled by user
        boolean strictDMI = true;
        // 是否启用严格方法调用 默认为true
        if (packageElement.hasAttribute("strict-method-invocation")) {
        strictDMI = Boolean.parseBoolean(packageElement.getAttribute("strict-method-invocation"));
        }
        // 创建包配置其构建器 并设置一些属性
        PackageConfig.Builder cfg = new PackageConfig.Builder(name)
        .namespace(namespace)
        .isAbstract(isAbstract)
        .strictMethodInvocation(strictDMI)
        .location(DomHelper.getLocationObject(packageElement));
        // 获取父包配置
        if (StringUtils.isNotEmpty(StringUtils.defaultString(parent))) { // has parents, let's look it up
        List<PackageConfig> parents = new ArrayList<>();
        for (String parentPackageName : ConfigurationUtil.buildParentListFromString(parent)) {
        if (configuration.getPackageConfigNames().contains(parentPackageName)) {
        parents.add(configuration.getPackageConfig(parentPackageName));
        } else if (declaredPackages.containsKey(parentPackageName)) {
        if (configuration.getPackageConfig(parentPackageName) == null) {
        addPackage(declaredPackages.get(parentPackageName));
        }
        parents.add(configuration.getPackageConfig(parentPackageName));
        } else {
        throw new ConfigurationException("Parent package is not defined: " + parentPackageName);
        }

        }

        if (parents.size() <= 0) {
        cfg.needsRefresh(true);
        } else {
            // 将父包配置添加到当前包配置中
        cfg.addParents(parents);
        }
        }

        return cfg;
        }

protected void addAction(Element actionElement, PackageConfig.Builder packageContext) throws ConfigurationException {
        String name = actionElement.getAttribute("name");
        String className = actionElement.getAttribute("class");
        //methodName should be null if it's not set
        String methodName = StringUtils.trimToNull(actionElement.getAttribute("method"));
        Location location = DomHelper.getLocationObject(actionElement);

        if (location == null) {
        LOG.warn("Location null for {}", className);
        }

        // if there isn't a class name specified for an <action/> then try to
        // use the default-class-ref from the <package/>
        if (StringUtils.isEmpty(className)) {
        // if there is a package default-class-ref use that, otherwise use action support
           /* if (StringUtils.isNotEmpty(packageContext.getDefaultClassRef())) {
                className = packageContext.getDefaultClassRef();
            } else {
                className = ActionSupport.class.getName();
            }*/

        } else {
            // 校验cation是否存在 是否可访问
        if (!verifyAction(className, name, location)) {
        LOG.error("Unable to verify action [{}] with class [{}], from [{}]", name, className, location);
        return;
        }
        }

        Map<String, ResultConfig> results;
        try {
            // action处理完成后的行为
        results = buildResults(actionElement, packageContext);
        } catch (ConfigurationException e) {
        throw new ConfigurationException("Error building results for action " + name + " in namespace " + packageContext.getNamespace(), e, actionElement);
        }

        // 构造 action的拦截器列表
        List<InterceptorMapping> interceptorList = buildInterceptorList(actionElement, packageContext);
        // 构造action的异常处理列表
        List<ExceptionMappingConfig> exceptionMappings = buildExceptionMappings(actionElement, packageContext);
        // 构造action允许访问的方法
        Set<String> allowedMethods = buildAllowedMethods(actionElement, packageContext);
        // 构造actionConfig
        ActionConfig actionConfig = new ActionConfig.Builder(packageContext.getName(), name, className)
        .methodName(methodName)
        .addResultConfigs(results)
        .addInterceptors(interceptorList)
        .addExceptionMappings(exceptionMappings)
        .addParams(XmlHelper.getParams(actionElement))
        .setStrictMethodInvocation(packageContext.isStrictMethodInvocation())
        .addAllowedMethod(allowedMethods)
        .location(location)
        .build();
        // 通过名称引用actionConfig
        // 添加到包配置中
        packageContext.addActionConfig(name, actionConfig);

        LOG.debug("Loaded {}{} in '{}' package: {}",
        StringUtils.isNotEmpty(packageContext.getNamespace()) ? (packageContext.getNamespace() + "/") : "",
        name, packageContext.getName(), actionConfig);
        }        
        
```
# 过滤器执行
```java

```

