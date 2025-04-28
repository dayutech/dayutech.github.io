---
title: Apache Struts2 原理学习
date: 2025-04-28 16:44:23
tags:
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
        this.excludedPatterns = init.buildExcludedPatternsList(dispatcher);

        postInit(dispatcher, filterConfig);
        } finally {
        if (dispatcher != null) {
        dispatcher.cleanUpAfterInit();
        }
        init.cleanup();
        }
        }
```
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

```