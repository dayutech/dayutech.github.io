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

                    if ("bean".equals(nodeName)) {
                        String type = child.getAttribute("type");
                        String name = child.getAttribute("name");
                        String impl = child.getAttribute("class");
                        String onlyStatic = child.getAttribute("static");
                        String scopeStr = child.getAttribute("scope");
                        boolean optional = "true".equals(child.getAttribute("optional"));
                        Scope scope = Scope.SINGLETON;
                        if ("prototype".equals(scopeStr)) {
                            scope = Scope.PROTOTYPE;
                        } else if ("request".equals(scopeStr)) {
                            scope = Scope.REQUEST;
                        } else if ("session".equals(scopeStr)) {
                            scope = Scope.SESSION;
                        } else if ("singleton".equals(scopeStr)) {
                            scope = Scope.SINGLETON;
                        } else if ("thread".equals(scopeStr)) {
                            scope = Scope.THREAD;
                        }

                        if (StringUtils.isEmpty(name)) {
                            name = Container.DEFAULT_NAME;
                        }

                        try {
                            Class classImpl = ClassLoaderUtil.loadClass(impl, getClass());
                            Class classType = classImpl;
                            if (StringUtils.isNotEmpty(type)) {
                                classType = ClassLoaderUtil.loadClass(type, getClass());
                            }
                            if ("true".equals(onlyStatic)) {
                                // Force loading of class to detect no class def found exceptions
                                classImpl.getDeclaredClasses();
                                containerBuilder.injectStatics(classImpl);
                            } else {
                                if (containerBuilder.contains(classType, name)) {
                                    Location loc = LocationUtils.getLocation(loadedBeans.get(classType.getName() + name));
                                    if (throwExceptionOnDuplicateBeans) {
                                        throw new ConfigurationException("Bean type " + classType + " with the name " +
                                                name + " has already been loaded by " + loc, child);
                                    }
                                }

                                // Force loading of class to detect no class def found exceptions
                                classImpl.getDeclaredConstructors();

                                LOG.debug("Loaded type: {} name: {} impl: {}", type, name, impl);
                                containerBuilder.factory(classType, name, new LocatableFactory(name, classType, classImpl, scope, childNode), scope);
                            }
                            loadedBeans.put(classType.getName() + name, child);
                        } catch (Throwable ex) {
                            if (!optional) {
                                throw new ConfigurationException("Unable to load bean: type:" + type + " class:" + impl, ex, childNode);
                            } else {
                                LOG.debug("Unable to load optional class: {}", impl);
                            }
                        }
                    } else if ("constant".equals(nodeName)) {
                        String name = child.getAttribute("name");
                        String value = child.getAttribute("value");

                        if (valueSubstitutor != null) {
                            LOG.debug("Substituting value [{}] using [{}]", value, valueSubstitutor.getClass().getName());
                            value = valueSubstitutor.substitute(value);
                        }

                        props.setProperty(name, value, childNode);
                    } else if (nodeName.equals("unknown-handler-stack")) {
                        List<UnknownHandlerConfig> unknownHandlerStack = new ArrayList<UnknownHandlerConfig>();
                        NodeList unknownHandlers = child.getElementsByTagName("unknown-handler-ref");
                        int unknownHandlersSize = unknownHandlers.getLength();

                        for (int k = 0; k < unknownHandlersSize; k++) {
                            Element unknownHandler = (Element) unknownHandlers.item(k);
                            Location location = LocationUtils.getLocation(unknownHandler);
                            unknownHandlerStack.add(new UnknownHandlerConfig(unknownHandler.getAttribute("name"), location));
                        }

                        if (!unknownHandlerStack.isEmpty())
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