# bean生命周期

## Spring容器的启动

```java
// AnnotationConfigApplicationContext的构造器
public AnnotationConfigApplicationContext(String... basePackages) {
    this();
    // 扫描目标包，收集并注册beanDefinition，上一篇具体讲过，这里就不赘述了
    scan(basePackages);
    // 这里就调用到我们大名鼎鼎的refresh方法啦
    refresh();
}
```

我们看一下这个容器启动的核心方法`refresh`，这个方法的逻辑是在`AbstractApplicationContext`类中的，也是一个典型的模板方法：

```java
public void refresh() throws BeansException, IllegalStateException {
    synchronized (this.startupShutdownMonitor) {
        // 一些准备工作，主要是一下状态的设置事件容器的初始化
        prepareRefresh();

        // 获取一个beanFactory，这个方法里面调用了一个抽象的refreshBeanFactory方法
        // 我们的xml就是在这个入口里解析的，具体的流程有在之前的博文分析过
        ConfigurableListableBeanFactory beanFactory = obtainFreshBeanFactory();

        // 把拿到的beanFactory做一些准备，这里其实没啥逻辑，同学们感兴趣的可以看下
        // 但是这个方法也是一个protected的方法，
        // 也就是说我们如果实现自己的spring启动类/或者spring团队需要写一个新的spring启动类的时候
        // 是可以在beanFactory获取之后做一些事情的，算是一个钩子
        prepareBeanFactory(beanFactory);
        
        try {
            // 这也是一个钩子，在处理beanFactory前允许子类做一些事情
            postProcessBeanFactory(beanFactory);

            // 实例化并且调用factoryPostProcessor的方法，
            // 我们@Compoment等注解的收集处理主要就是在这里做的
            // 有一个ConfigurationClassPostProcessor专门用来做这些注解支撑的工作
            // 这里的逻辑之前也讲过了
            // 那么其实我们可以说，到这里为止，我们的beanDefinition的收集（注解/xml/其他来源...）
            // 、注册（注册到beanFactory的beanDefinitionMap、beanDefinitionNames）容器
            // 工作基本就全部完成了
            invokeBeanFactoryPostProcessors(beanFactory);
            
            // 从这里开始，我们就要专注bean的实例化了
            // 所以我们需要先实例化并注册所有的beanPostProcessor
            // 因为beanPostProcessor主要就是在bean实例化过程中，做一些附加操作的（埋点）
            // 这里的流程也不再讲了，感兴趣的同学可以自己看一下，
            // 这个流程基本跟FactoryPostProcessor的初始化是一样的，
            // 排序，创建实例，然后放入一个list --> AbstractBeanFactory#beanPostProcessors
            registerBeanPostProcessors(beanFactory);

            // 初始化一些国际化相关的组件，这一块我没有去详细了解过（主要是暂时用不到...）
            // 之后如果有时间也可以单独拉个博文来讲吧
            initMessageSource();

            // 初始化事件多播器，本篇不讲
            initApplicationEventMulticaster();

            // 也是个钩子方法，给子类创建一下特殊的bean
            onRefresh();

            // 注册事件监听器，本篇不讲
            registerListeners();

            // !!!实例化所有的、非懒加载的单例bean
            // Instantiate all remaining (non-lazy-init) singletons.
            finishBeanFactoryInitialization(beanFactory);

            // 初始化结束，清理资源，发送事件
            finishRefresh();
        }
        catch (BeansException ex) {
            // 销毁已经注册的单例bean
            destroyBeans();
            // 修改容器状态
            cancelRefresh(ex);
            // Propagate exception to caller.
            throw ex;
        }

        finally {
            // Reset common introspection caches in Spring's core, since we
            // might not ever need metadata for singleton beans anymore...
            resetCommonCaches();
        }
    }
}
```

其实说白了，我们`spring`容器的启动，主要就是要把那些非懒加载的单例`bean`给实例化，并且管理起来。

## bean实例化

### 1.哪些bean需要在启动的时候实例化？

刚刚`refresh`方法中，我们有看到`finishBeanFactoryInitialization`方法是用来实例化`bean`的，并且源码中的英文也说明了，说是要实例化所以剩余的非懒加载的单例`bean`，那么实际情况真的如此么？我们跟源码看一下：

```java
protected void finishBeanFactoryInitialization(ConfigurableListableBeanFactory beanFactory) {
    // skip .. 我把前面的非主流程的跳过了
    // Instantiate all remaining (non-lazy-init) singletons.
    beanFactory.preInstantiateSingletons();
}

// DefaultListableBeanFactory#preInstantiateSingletons
public void preInstantiateSingletons() throws BeansException {
    // 我们之前注册beanDefinition的时候，有把所有的beanName收集到这个beanDefinitionNames容器
    // 这里我们就用到了
    List<String> beanNames = new ArrayList<>(this.beanDefinitionNames);

    // 循环所有的已注册的beanName
    for (String beanName : beanNames) {
        // 获取合并后的beanDefinition，简单来讲，我们的beanDefinition是可以存在继承关系的
        // 比如xml配置从的parent属性，这种时候，我们需要结合父子beanDefinition的属性，生成一个新的
        // 合并的beanDefinition，子beanDefinition中的属性会覆盖父beanDefinition的属性，
        // 并且这是一个递归的过程（父还可以有父），不过这个功能用的实在不多，就不展开了，
        // 同学们有兴趣可以自行看一下，这里可以就理解为拿到对应的beanDefinition就好了
        RootBeanDefinition bd = getMergedLocalBeanDefinition(beanName);
        // 非抽象（xml有一个abstract属性，而不是说这个类不是一个抽象类）、单例的、非懒加载的才需要实例化
        if (!bd.isAbstract() && bd.isSingleton() && !bd.isLazyInit()) {
            if (isFactoryBean(beanName)) {
                // 这里是处理factoryBean的，暂时不讲，之后再专门写博文
                Object bean = getBean(FACTORY_BEAN_PREFIX + beanName);
                if (bean instanceof FactoryBean) {
                    final FactoryBean<?> factory = (FactoryBean<?>) bean;
                    boolean isEagerInit;
                    if (System.getSecurityManager() != null && factory instanceof SmartFactoryBean) {
                        isEagerInit = AccessController.doPrivileged((PrivilegedAction<Boolean>)
                                                                    ((SmartFactoryBean<?>) factory)::isEagerInit,
                                                                    getAccessControlContext());
                    }
                    else {
                        isEagerInit = (factory instanceof SmartFactoryBean &&
                                       ((SmartFactoryBean<?>) factory).isEagerInit());
                    }
                    if (isEagerInit) {
                        getBean(beanName);
                    }
                }
            }
            else {
                // !!!我们正常普通的bean会走到这个流程，这里就把这个bean实例化并且管理起来的
                // 这里是获取一个bean，如果获取不到，则创建一个
                getBean(beanName);
            }
        }
    }

    // 所以的bean实例化之后，还会有一些处理
    for (String beanName : beanNames) {
        // 获取到这个bean实例
        Object singletonInstance = getSingleton(beanName);
        // 如果bean实现了SmartInitializingSingleton接口
        if (singletonInstance instanceof SmartInitializingSingleton) {
            final SmartInitializingSingleton smartSingleton = (SmartInitializingSingleton) singletonInstance;
            // 会调用它的afterSingletonsInstantiated方法
            // 这是最外层的一个钩子了，平常其实用的不多
            // 不过@Listener的发现是在这里做的
            smartSingleton.afterSingletonsInstantiated();
        }
    }
}
```

可以看到，原来是**非抽象**（`xml`有一个`abstract`属性，而不是说这个类不是一个抽象类）、**单例的**、**非懒加载**的`bean`才会在`spring`容器启动的时候实例化。

###  2. 使用`getBean`从`beanFactory`获取`bean`

刚刚有说到，调用`getBean`方法的时候，会先尝试中`spring`容器中获取这个`bean`，获取不到的时候则会创建一个，现在我们就来梳理一下这个流程：

```java
public Object getBean(String name) throws BeansException {
    // 调用了doGetBean
    // 说一下这种方式吧，其实我们能在很多框架代码里看到这种方式
    // 就是会有一个参数最全的，可以最灵活使用的方法，用来处理我们的业务
    // 然后会对不同的使用方，提供一些便于使用的类似于门面的方法，这些方法会简化一些参数，使用默认值填充
    // 或者实际业务可以很灵活，但是不打算完全开放给使用方的时候，也可以使用类似的模式
    return doGetBean(name, null, null, false);
}
```

`getBean->doGetBean`是我们`beanFactory`对外提供的获取`bean`的接口，只是说我们初始化`spring`容器的时候会为所有单例的`beanDefinition`调用`getBean`方法实例化它们定义的`bean`而已，所以它的的逻辑并不仅仅是为`spring`容器初始化定义的，我们也需要带着这个思维去看这个方法：

```java
protected <T> T doGetBean(final String name, @Nullable final Class<T> requiredType,
                          @Nullable final Object[] args, boolean typeCheckOnly) throws BeansException {
    // 转换一下beanName,暂时不看，之后统一讲
    final String beanName = transformedBeanName(name);
    Object bean;

    // 看一下这个bean是否已经实例化了，如果实例化了这里能直接拿到
    // 这个方法涉及到spring bean的3级缓存，之后会开一篇博客细讲
    Object sharedInstance = getSingleton(beanName);
    if (sharedInstance != null && args == null) {
        // 通过这个bean实例获取用户真正需要的bean实例
        // 有点绕，其实这里主要是处理当前bean实现了FactoryBean接口的情况的
        bean = getObjectForBeanInstance(sharedInstance, name, beanName, null);
    }
    else {
        // 当前线程下的，循环依赖检测，如果当前bean已经在创建中，这里又进来创建了，说明是循环依赖了
        // 会直接报错，代码逻辑也很简单，这里主要是一个TheadLocal持有了一个set，
        // 可以认为是一个快速失败检测，和后面的全局循环依赖检测不是一个容器
        // 容器是 prototypesCurrentlyInCreation
        if (isPrototypeCurrentlyInCreation(beanName)) {
            throw new BeanCurrentlyInCreationException(beanName);
        }


        BeanFactory parentBeanFactory = getParentBeanFactory();
        if (parentBeanFactory != null && !containsBeanDefinition(beanName)) {
            // 如果父容器不为空且当前容器没有这个beanName对应的beanDefinition
            // 则尝试从父容器获取（因为当期容器已经确定没有了）
            // 下面就是调用父容器的getBean了
            String nameToLookup = originalBeanName(name);
            if (parentBeanFactory instanceof AbstractBeanFactory) {
                return ((AbstractBeanFactory) parentBeanFactory).doGetBean(
                    nameToLookup, requiredType, args, typeCheckOnly);
            }
            else if (args != null) {
                return (T) parentBeanFactory.getBean(nameToLookup, args);
            }
            else if (requiredType != null) {
                return parentBeanFactory.getBean(nameToLookup, requiredType);
            }
            else {
                return (T) parentBeanFactory.getBean(nameToLookup);
            }
        }
        // 如果不是只检测类型是否匹配的话，这里要标记bean已创建（因为马上就要开始创建了）
        if (!typeCheckOnly) {
            markBeanAsCreated(beanName);
        }

        try {
            final RootBeanDefinition mbd = getMergedLocalBeanDefinition(beanName);
            checkMergedBeanDefinition(mbd, beanName, args);
            // 拿到这个bean的所有依赖的bean
            String[] dependsOn = mbd.getDependsOn();
            if (dependsOn != null) {
                // 如果依赖不为空，需要先循环实例化依赖
                for (String dep : dependsOn) {
                    if (isDependent(beanName, dep)) {
                        throw new BeanCreationException(...);
                    }
                    registerDependentBean(dep, beanName);
                    try {
                        getBean(dep);
                    }
                    catch (NoSuchBeanDefinitionException ex) {
                        throw new BeanCreationException(...);
                    }
                }
            }

            // 这里开始真正创建bean实例的流程了
            if (mbd.isSingleton()) {
                // 如果是单例的bean（当然我们启动的时候会实例化的也就是单例bean了），这里会进行创建
                // 注意这里也是一个getSingleton方法，跟之前那个getSingleton方法差不多，不过这里是
                // 如果获取不到就会使用这个lamdba的逻辑创建一个，
                // 也就是说我的的createBean方法是真正创建bean实例的方法，这里我们之后会重点看
                sharedInstance = getSingleton(beanName, () -> {
                    try {
                        return createBean(beanName, mbd, args);
                    }
                    catch (BeansException ex) {
                        destroySingleton(beanName);
                        throw ex;
                    }
                });
                // 通过这个bean实例获取用户真正需要的bean实例
                bean = getObjectForBeanInstance(sharedInstance, name, beanName, mbd);
            }
            else if (mbd.isPrototype()) {
                // 如果是多例的bean
                // 那么每次获取都是创建一个新的bean实例
                Object prototypeInstance = null;
                try {
                    beforePrototypeCreation(beanName);
                    // 可以看到这里直接去调用createBean了
                    prototypeInstance = createBean(beanName, mbd, args);
                }
                finally {
                    afterPrototypeCreation(beanName);
                }
                // 这里逻辑还是一样的
                bean = getObjectForBeanInstance(prototypeInstance, name, beanName, mbd);
            }
            else {
                // spring是允许我们自定义scope的，这里是自定义scope的逻辑
                // 需要注意的是，spring mvc 的 session、request那些scope也是走这里的逻辑的
                // 这里感兴趣的同学可以自行看下，暂时不讲
                String scopeName = mbd.getScope();
                final Scope scope = this.scopes.get(scopeName);
                if (scope == null) {
                    throw new IllegalStateException(...);
                }
                try {
                    Object scopedInstance = scope.get(beanName, () -> {
                        beforePrototypeCreation(beanName);
                        try {
                            return createBean(beanName, mbd, args);
                        }
                        finally {
                            afterPrototypeCreation(beanName);
                        }
                    });
                    bean = getObjectForBeanInstance(scopedInstance, name, beanName, mbd);
                }
                catch (IllegalStateException ex) {
                    throw new BeanCreationException(...);
                }
            }
        }
        catch (BeansException ex) {
            cleanupAfterBeanCreationFailure(beanName);
            throw ex;
        }
    }
    
    // 这里是类型转换的逻辑，getBean是有可以传类型的重载方法的
    // 不过我们初始化的时候不会走到这个逻辑来，感兴趣的同学可以自行看
    if (requiredType != null && !requiredType.isInstance(bean)) {
        try {
            T convertedBean = getTypeConverter().convertIfNecessary(bean, requiredType);
            if (convertedBean == null) {
                throw new BeanNotOfRequiredTypeException(...);
            }
            return convertedBean;
        }
        catch (TypeMismatchException ex) {
            throw new BeanNotOfRequiredTypeException(...);
        }
    }
    // 返回获取到的bean
    return (T) bean;
}
```

我们继续看一下单例`bean`的创建逻辑，即：

```java
if (mbd.isSingleton()) {
    sharedInstance = getSingleton(beanName, () -> {
        try {
            return createBean(beanName, mbd, args);
        }
        catch (BeansException ex) {
            // ...
            destroySingleton(beanName);
            throw ex;
        }
    });
    bean = getObjectForBeanInstance(sharedInstance, name, beanName, mbd);
}
```

我们看一下这个`getSingleton`方法，需要注意的是，这个方法在`DefaultSingletonBeanRegistry`类中：

```java
/** Cache of singleton objects: bean name to bean instance. */
private final Map<String, Object> singletonObjects = new ConcurrentHashMap<>(256);
/** Names of beans that are currently in creation. */
private final Set<String> singletonsCurrentlyInCreation = Collections.newSetFromMap(new ConcurrentHashMap<>(16));

public Object getSingleton(String beanName, ObjectFactory<?> singletonFactory) {
    synchronized (this.singletonObjects) {
        // 可以看到，我们先从singletonObjects通过beanName获取实例
        // 这是不是说明singletonObjects就是spring用来存放所以单例bean的容器呢？可以说是的。
        Object singletonObject = this.singletonObjects.get(beanName);
        if (singletonObject == null) {
            // 跳过了一个spring单例bean容器状态判断，
            // 如果spring单例bean容器正在销毁时不允许继续创建单例bean的
            
            // 创建容器之前的钩子，这里默认会把bean那么加入到一个正在创建的beanNameSet，
            // 如果加入失败就代表是循环依赖了。
            // 检测容器是  singletonsCurrentlyInCreation
            beforeSingletonCreation(beanName);
            boolean newSingleton = false;
            boolean recordSuppressedExceptions = (this.suppressedExceptions == null);
            if (recordSuppressedExceptions) {
                this.suppressedExceptions = new LinkedHashSet<>();
            }
            try {
                // 这里就是调用传进来的lamdba了
                // 也就是调用了createBean创建了bean实例
                singletonObject = singletonFactory.getObject();
                newSingleton = true;
            }
            catch (IllegalStateException ex) {
                // Has the singleton object implicitly appeared in the meantime ->
                // if yes, proceed with it since the exception indicates that state.
                singletonObject = this.singletonObjects.get(beanName);
                if (singletonObject == null) {
                    throw ex;
                }
            }
            catch (BeanCreationException ex) {
                if (recordSuppressedExceptions) {
                    for (Exception suppressedException : this.suppressedExceptions) {
                        ex.addRelatedCause(suppressedException);
                    }
                }
                throw ex;
            }
            finally {
                if (recordSuppressedExceptions) {
                    this.suppressedExceptions = null;
                }
                // 从正在创建的beanNameSet移除
                afterSingletonCreation(beanName);
            }
            // 如果成功创建了bean实例，需要加入singletonObjects容器
            // 这样下次再获取就能直接中容器中拿了
            if (newSingleton) {
                addSingleton(beanName, singletonObject);
            }
        }
        return singletonObject;
    }
}
```

可以看到，这个`getSingleton`方法就是先从`singletonObjects`获取`bean`实例，获取不到就创建一个，其中还加了一些循环依赖的检测逻辑。

### 3. `createBean`，真正的`bean`初始化逻辑

我们说`createBean`方法是真正的`bean`初始化逻辑，但是这个初始化不仅仅是说创建一个实例就好了，还涉及到一些校验，以及类里的依赖注入、初始化方法调用等逻辑，我们现在就一起来简单看一下：

```java
protected Object createBean(String beanName, RootBeanDefinition mbd, @Nullable Object[] args)
    throws BeanCreationException {
    
    RootBeanDefinition mbdToUse = mbd;
    // 获取bean的类型
    Class<?> resolvedClass = resolveBeanClass(mbd, beanName);
    if (resolvedClass != null && !mbd.hasBeanClass() && mbd.getBeanClassName() != null) {
        mbdToUse = new RootBeanDefinition(mbd);
        mbdToUse.setBeanClass(resolvedClass);
    }
    
    // Prepare method overrides.
    try {
        // 这里对beanDefinition中的MethodOverrides做一些准备
        // 主要是梳理一下所有重写方法（xml<replaced-method><lockup-method>标签对应的属性）
        // 看下这些方法是否是真的有重载方法，没有重载的话会设置overloaded=false，
        // 毕竟有些人配置的时候即使没有重载方法也会使用<replaced-method>标签
        // (这功能我确实也没用过。。
        mbdToUse.prepareMethodOverrides();
    }
    catch (BeanDefinitionValidationException ex) {
        throw new BeanDefinitionStoreException(...);
    }

    try {
        // Give BeanPostProcessors a chance to return a proxy instead of the target bean instance.
        // 给BeanPostProcessors一个机会，在我们的bean实例化之前返回一个代理对象，即完全不走spring的实例化逻辑
        // 也是个BeanPostProcessors的钩子，就是循环beanPostProcessors然后调用的逻辑
        Object bean = resolveBeforeInstantiation(beanName, mbdToUse);
        if (bean != null) {
            return bean;
        }
    }
    catch (Throwable ex) {
        throw new BeanCreationException(...);
    }

    try {
        // 这里是spring真正bean实例化的地方了
        Object beanInstance = doCreateBean(beanName, mbdToUse, args);
        // 获取到了直接返回
        return beanInstance;
    }
    // 跳过异常处理
}
```

#### 3.0. `doCreateBean`是如何实例化一个`bean`的？

刚刚有说到，`doCreateBean`是我们`spring`真正的实例化`bean`的逻辑，那我们一起来看一下：

```java
protected Object doCreateBean(final String beanName, final RootBeanDefinition mbd, final @Nullable Object[] args)
    throws BeanCreationException {

    // Instantiate the bean.
    BeanWrapper instanceWrapper = null;
    if (mbd.isSingleton()) {
        instanceWrapper = this.factoryBeanInstanceCache.remove(beanName);
    }
    if (instanceWrapper == null) {
        // 创建bean实例
        instanceWrapper = createBeanInstance(beanName, mbd, args);
    }
    final Object bean = instanceWrapper.getWrappedInstance();
    Class<?> beanType = instanceWrapper.getWrappedClass();
    if (beanType != NullBean.class) {
        mbd.resolvedTargetType = beanType;
    }

    synchronized (mbd.postProcessingLock) {
        if (!mbd.postProcessed) {
            try {
                // 调用一个BeanPostProcessor的钩子方法,这里调用的是
                // MergedBeanDefinitionPostProcessor#postProcessMergedBeanDefinition
                // 这个钩子方法是在bean实例创建之后，依赖注入之前调用的，需要注意的是
                // @Autowired和@Value注解的信息收集-AutowiredAnnotationBeanPostProcessor
                // @PostConstruct、@PreDestroy注解信息收集-CommonAnnotationBeanPostProcessor
                applyMergedBeanDefinitionPostProcessors(mbd, beanType, beanName);
            }
            catch (Throwable ex) {
                throw new BeanCreationException(...);
            }
            mbd.postProcessed = true;
        }
    }

    // 这一部分是使用3级缓存来解决循环依赖问题的，之后再看
    boolean earlySingletonExposure = (mbd.isSingleton() && this.allowCircularReferences &&
                                      isSingletonCurrentlyInCreation(beanName));
    if (earlySingletonExposure) {
        // 加入三级缓存
        addSingletonFactory(beanName, () -> getEarlyBeanReference(beanName, mbd, bean));
    }

    
    Object exposedObject = bean;
    try {
        // 依赖注入
        populateBean(beanName, mbd, instanceWrapper);
        // bean初始化-主要是调用一下初始化方法
        exposedObject = initializeBean(beanName, exposedObject, mbd);
    }
    catch (Throwable ex) {
        if (ex instanceof BeanCreationException && beanName.equals(((BeanCreationException) ex).getBeanName())) {
            throw (BeanCreationException) ex;
        }
        else {
            throw new BeanCreationException(...);
        }
    }
    // 这里也算是循环依赖检测的，暂时不讲
    if (earlySingletonExposure) {
        Object earlySingletonReference = getSingleton(beanName, false);
        if (earlySingletonReference != null) {
            if (exposedObject == bean) {
                exposedObject = earlySingletonReference;
            }
            else if (!this.allowRawInjectionDespiteWrapping && hasDependentBean(beanName)) {
                String[] dependentBeans = getDependentBeans(beanName);
                Set<String> actualDependentBeans = new LinkedHashSet<>(dependentBeans.length);
                for (String dependentBean : dependentBeans) {
                    if (!removeSingletonIfCreatedForTypeCheckOnly(dependentBean)) {
                        actualDependentBeans.add(dependentBean);
                    }
                }
                if (!actualDependentBeans.isEmpty()) {
                    throw new BeanCurrentlyInCreationException(...);
                }
            }
        }
    }
    try {
        // 如果是单例bean，还会注册销毁事件
        registerDisposableBeanIfNecessary(beanName, bean, mbd);
    }
    catch (BeanDefinitionValidationException ex) {
        throw new BeanCreationException(...);
    }

    return exposedObject;
}
```

可以看到，我们的`doCreateBean`大致做了5件事：

1. 创建`bean`实例
2. 调用`beanPostProcessor`的埋点方法
3. 注入当前类依赖的`bean`
4. 调用当前`bean`的初始化方法
5. 注册当前`bean`的销毁逻辑

接下来我们来详细看一下这些流程

#### 3.1. `createBeanInstance`创建`bean`实例

大家平常是怎么实例化一个类呢？是直接使用构造器`new`出来一个？还是使用工厂方法获取？

很显然，`spring`也是支持这两种方式的，如果同学们还记得bean标签的解析的话，那应该还会记得`spring`除了有提供使用构造器实例化`bean`的`constructor-arg`标签外，还提供了`factory-bean`和`factory-method`属性来配置使用工厂方法来实例化`bean`。

并且之前在讲`ConfigurationClassPostProcessor`的时候，我们讲到`@bean`标签的时候，也有看到，对于`@bean`标签的处理，就是新建一个`beanDefinition`，并把当前的配置类和`@Bean`修饰的方法分别塞入了这个`beanDefinition`的`factoryBeanName`和`factoryMethodName`属性（可以空降`ConfigurationClassBeanDefinitionReader#loadBeanDefinitionsForBeanMethod`）。

接下来我们就来看一下`createBeanInstance`的代码：

```java
protected BeanWrapper createBeanInstance(String beanName, RootBeanDefinition mbd, @Nullable Object[] args) {
    Class<?> beanClass = resolveBeanClass(mbd, beanName);
    // 校验
    if (beanClass != null && !Modifier.isPublic(beanClass.getModifiers()) && !mbd.isNonPublicAccessAllowed()) {
        throw new BeanCreationException(mbd.getResourceDescription(), beanName,
                                        "Bean class isn't public, and non-public access not allowed: " + beanClass.getName());
    }
    // 如果beanDefinition里有instanceSupplier，直接通过instanceSupplier拿就行了
    // 这种情况我们就不重点讲了，其实跟工厂方法的方式也差不多
    Supplier<?> instanceSupplier = mbd.getInstanceSupplier();
    if (instanceSupplier != null) {
        return obtainFromSupplier(instanceSupplier, beanName);
    }
    
    // 如果工厂方法不为空，就使用工厂方法实例化
    if (mbd.getFactoryMethodName() != null) {
        return instantiateUsingFactoryMethod(beanName, mbd, args);
    }

    // 这里是对非单例bean做的优化，如果创建过一次了，
    // spring会把相应的构造器或者工厂方法存到resolvedConstructorOrFactoryMethod字段
    // 这样再次创建这个类的实例的时候就可以直接使用resolvedConstructorOrFactoryMethod创建了
    boolean resolved = false;
    boolean autowireNecessary = false;
    if (args == null) {
        synchronized (mbd.constructorArgumentLock) {
            if (mbd.resolvedConstructorOrFactoryMethod != null) {
                resolved = true;
                autowireNecessary = mbd.constructorArgumentsResolved;
            }
        }
    }
    if (resolved) {
        if (autowireNecessary) {
            return autowireConstructor(beanName, mbd, null, null);
        }
        else {
            return instantiateBean(beanName, mbd);
        }
    }

    // 如果beanDefinition没有构造器信息，则通过beanPostProcessor选择一个
    Constructor<?>[] ctors = determineConstructorsFromBeanPostProcessors(beanClass, beanName);
    // 1.如果通过beanPostProcessor找到了合适的构造器
    // 2.或者autowireMode==AUTOWIRE_CONSTRUCTOR（这个xml配置的时候也可以指定的）
    // 3.或者有配置构造器的参数（xml配置constructor-arg标签）
    // 4.获取实例化bean是直接传进来了参数
    // 只要符合上面四种情况之一，我们就会通过autowireConstructor方法来实例化这个bean
    if (ctors != null || mbd.getResolvedAutowireMode() == AUTOWIRE_CONSTRUCTOR ||
        mbd.hasConstructorArgumentValues() || !ObjectUtils.isEmpty(args)) {
        // 需要构造器方式注入的bean的实例化
        return autowireConstructor(beanName, mbd, ctors, args);
    }

    // 这里主要逻辑是兼容kotlin的，我们暂时不看
    ctors = mbd.getPreferredConstructors();
    if (ctors != null) {
        // 需要构造器方式注入的bean的实例化
        return autowireConstructor(beanName, mbd, ctors, null);
    }

    // 不需要特殊处理的话，就直接使用无参构造器了
    return instantiateBean(beanName, mbd);
}
```

具体的`instantiateUsingFactoryMethod`、`autowireConstructo`方法这边就不带同学们看了，因为里面涉及到的一些参数注入的逻辑比较复杂，之后会单独开一篇博客来讲。

而拿到具体的参数之后，其实不管是构造器还是工厂方法实例化，都是很清晰的，直接反射调用就好了。

`instantiateBean`就是获取无参构造器然后反射实例化的一个逻辑，逻辑比较简单，这边也不跟了。

##### 3.1.1. 通过`determineConstructorsFromBeanPostProcessors`方法选择构造器

这边主要带大家跟一下`determineConstructorsFromBeanPostProcessors`这个方法，因为我们现在大部分都是使用注解来声明`bean`的，而如果大家在使用注解的时候也是使用构造器的方式注入的话，那么是通过这个方法来拿到相应的构造器的。

```java
protected Constructor<?>[] determineConstructorsFromBeanPostProcessors(@Nullable Class<?> beanClass, String beanName)
    throws BeansException {
    if (beanClass != null && hasInstantiationAwareBeanPostProcessors()) {
        for (BeanPostProcessor bp : getBeanPostProcessors()) {
            if (bp instanceof SmartInstantiationAwareBeanPostProcessor) {
                SmartInstantiationAwareBeanPostProcessor ibp = (SmartInstantiationAwareBeanPostProcessor) bp;
                Constructor<?>[] ctors = ibp.determineCandidateConstructors(beanClass, beanName);
                if (ctors != null) {
                    // 一旦拿到构造器就返回了
                    return ctors;
                }
            }
        }
    }
    return null;
}
```

可以看到，还是通过`beanPostProcessor`的埋点来做的，这里是调用的`SmartInstantiationAwareBeanPostProcessor#determineCandidateConstructors`，这里也不给大家卖关子了，我们真正支撑注解方式，选择构造器的逻辑在`AutowiredAnnotationBeanPostProcessor`中，有没有感觉这个类好像也有点熟悉？

```java
public static Set<BeanDefinitionHolder> registerAnnotationConfigProcessors(
            BeanDefinitionRegistry registry, @Nullable Object source) {
    // ...
    if (!registry.containsBeanDefinition(AUTOWIRED_ANNOTATION_PROCESSOR_BEAN_NAME)) {
        RootBeanDefinition def = new RootBeanDefinition(AutowiredAnnotationBeanPostProcessor.class);
        def.setSource(source);
        beanDefs.add(registerPostProcessor(registry, def, AUTOWIRED_ANNOTATION_PROCESSOR_BEAN_NAME));
    }
    // ...
}
```

也是有在调用`AnnotationConfigUtils#registerAnnotationConfigProcessors`方法的时候有注入哦~

从名称可以看到，这个`beanPostProcessor`是应该是用来处理`@Autowired`注解的，有同学要说了，这不是属性注入的注解么，跟构造器有什么关系？那我们已一个构造器注入的bean来举例：

```java
@Service
public class ConstructorAutowiredBean {
    private Student student;
    @Autowired
    public ConstructorAutowiredBean(Student student) {
        this.student = student;
    }
}
```

大部分同学可能忘了，`@Autowired`是可以用来修饰构造器的，被`@Autowired`修饰的构造器的参数也将会中`spring`容器中获取（这么说可能不太准确，大家明白我的意思就好，就是说构造器注入的意思...）。

不过，其实我们平常即使使用构造器注入也不打`@Autowired`注解也是没问题的，这其实也是`AutowiredAnnotationBeanPostProcessor`获取构造器时的一个容错逻辑，我们一起看一下代码就知道了：

```java
public Constructor<?>[] determineCandidateConstructors(Class<?> beanClass, final String beanName)
    throws BeanCreationException {
    // 整个方法分为了两个部分
    // 第一部分是收集这个类上被@Lookup修饰的方法
    // 这个注解的功能和我们xml的lookup-method标签是一样的
    // 而收集部分也是一样的封装到了一个MethodOverride并且加入到beanDefinition里面去了
    // 虽然这部分工作（@Lookup注解的收集工作）是应该放在bean创建之前（有MethodOverride的话会直接生成代理实例）
    // 但是放在当前这个determineCandidateConstructors方法里我还是觉得不太合适
    // 毕竟跟方法名的语意不符，不过好像确实没有其它合适的钩子了，可能也只能放这了
    if (!this.lookupMethodsChecked.contains(beanName)) {
        if (AnnotationUtils.isCandidateClass(beanClass, Lookup.class)) {
            try {
                Class<?> targetClass = beanClass;
                do {
                    ReflectionUtils.doWithLocalMethods(targetClass, method -> {
                        // 循环处理所有的方法，获取@Lookup注解并封装信息
                        Lookup lookup = method.getAnnotation(Lookup.class);
                        if (lookup != null) {
                            LookupOverride override = new LookupOverride(method, lookup.value());
                            try {
                                RootBeanDefinition mbd = (RootBeanDefinition)
                                    this.beanFactory.getMergedBeanDefinition(beanName);
                                mbd.getMethodOverrides().addOverride(override);
                            }
                            catch (NoSuchBeanDefinitionException ex) {
                                throw new BeanCreationException(...);
                            }
                        }
                    });
                    targetClass = targetClass.getSuperclass();
                }
                while (targetClass != null && targetClass != Object.class);

            }
            catch (IllegalStateException ex) {
                throw new BeanCreationException(...);
            }
        }
        this.lookupMethodsChecked.add(beanName);
    }

    // 这里开始是选择构造器的逻辑了
    // 先从缓存拿...这些也是为非单例bean设计的，这样就不用每次进来都走选择构造器的逻辑了
    Constructor<?>[] candidateConstructors = this.candidateConstructorsCache.get(beanClass);
    if (candidateConstructors == null) {
        synchronized (this.candidateConstructorsCache) {
            candidateConstructors = this.candidateConstructorsCache.get(beanClass);
            if (candidateConstructors == null) {
                Constructor<?>[] rawCandidates;
                try {
                    // 获取当前类的所有的构造器
                    rawCandidates = beanClass.getDeclaredConstructors();
                }
                catch (Throwable ex) {
                    throw new BeanCreationException(...);
                }
                // 这个列表存符合条件的构造器
                List<Constructor<?>> candidates = new ArrayList<>(rawCandidates.length);
                Constructor<?> requiredConstructor = null;
                Constructor<?> defaultConstructor = null;
                // 这个primaryConstructor我们不管，是兼容kotlin的逻辑
                Constructor<?> primaryConstructor = BeanUtils.findPrimaryConstructor(beanClass);
                int nonSyntheticConstructors = 0;
                for (Constructor<?> candidate : rawCandidates) {
                    // 循环每个构造器
                    if (!candidate.isSynthetic()) {
                        // 这个判断是判断不是合成的构造器，同学们想了解这个Synthetic可以自行查一下
                        // 这边就不展开了，这个主意是和内部类有关，Synthetic的构造器是编译器自行生成的
                        nonSyntheticConstructors++;
                    }
                    else if (primaryConstructor != null) {
                        continue;
                    }
                    // 找一下构造器上有没有目标注解，说白了就是找@Autowired注解
                    MergedAnnotation<?> ann = findAutowiredAnnotation(candidate);
                    if (ann == null) {
                        // 如果找不到，这里认为可能是因为当前这个class是spring生成的cglib代理类
                        // 所以这里尝试拿一下用户的class
                        Class<?> userClass = ClassUtils.getUserClass(beanClass);
                        // 如果用户的class和之前的beanClass不一致，说明之前那个class真的是代理类了
                        if (userClass != beanClass) {
                            try {
                                // 这个时候去userClass拿一下对应的构造器
                                Constructor<?> superCtor =
                                    userClass.getDeclaredConstructor(candidate.getParameterTypes());
                                // 再在用户的构造器上找一下注解
                                ann = findAutowiredAnnotation(superCtor);
                            }
                            catch (NoSuchMethodException ex) {
                            }
                        }
                    }
                    if (ann != null) {
                        // 这里是找到注解了
                        if (requiredConstructor != null) {
                            // 这个分支直接报错了，意思是之前已经如果有被@Autowired注解修饰了的构造器
                            // 且注解中的Required属性为true的时候，
                            // 就不允许再出现其他被@Autowired注解修饰的构造器了
                            // 说明@Autowired(required=true)在构造器上的语言是必须使用这个构造器
                            throw new BeanCreationException(...);
                        }
                        // 拿注解上的required属性
                        boolean required = determineRequiredStatus(ann);
                        if (required) {
                            if (!candidates.isEmpty()) {
                                // 这里也是一样的，有required的构造器，就不预约有其他被
                                // @Autowired注解修饰的构造器了
                                throw new BeanCreationException(...);
                            }
                            // requiredConstructor只能有一个
                            requiredConstructor = candidate;
                        }
                        // 符合条件的构造器加入列表-即有@Autowired的构造器
                        candidates.add(candidate);
                    }
                    else if (candidate.getParameterCount() == 0) {
                        // 如果构造器的参数为空，那就是默认构造器了
                        defaultConstructor = candidate;
                    }
                }
                
                if (!candidates.isEmpty()) {
                    // 如果被@Autowired修饰的构造器不为空
                    if (requiredConstructor == null) {
                        // 如果没有requiredConstructor，就把默认构造器加入列表
                        // 如果有requiredConstructor，实际上candidates中就只有一个构造器了
                        if (defaultConstructor != null) {
                            candidates.add(defaultConstructor);
                        }
                        else if (candidates.size() == 1 && logger.isInfoEnabled()) {
                            logger.info(...);
                        }
                    }
                    // 然后把candidates列表赋值给返回值
                    candidateConstructors = candidates.toArray(new Constructor<?>[0]);
                }
                else if (rawCandidates.length == 1 && rawCandidates[0].getParameterCount() > 0) {
                    // 如果当前类总共也只有一个构造器，并且这个构造器是需要参数的
                    // 那就直接使用这个构造器了
                    // 这就是为什么我们平常构造器注入不打@Autowired注解也可以的原因
                    candidateConstructors = new Constructor<?>[] {rawCandidates[0]};
                }
                // 以下主要是处理primaryConstructor的，我们就不读了
                else if (nonSyntheticConstructors == 2 && primaryConstructor != null &&
                         defaultConstructor != null && !primaryConstructor.equals(defaultConstructor)) {
                    candidateConstructors = new Constructor<?>[] {primaryConstructor, defaultConstructor};
                }
                else if (nonSyntheticConstructors == 1 && primaryConstructor != null) {
                    candidateConstructors = new Constructor<?>[] {primaryConstructor};
                }
                else {
                    // 都不满足，就是空数组了
                    candidateConstructors = new Constructor<?>[0];
                }
                // 处理完之后放入缓存
                this.candidateConstructorsCache.put(beanClass, candidateConstructors);
            }
        } 
    }
    // 之所以上面解析的时候，没找到构造器也是使用空数组而不是null
    // 就是为了从缓存拿的时候，能区分究竟是没处理过（null），还是处理了但是找不到匹配的（空数组）
    // 避免缓存穿透
    return (candidateConstructors.length > 0 ? candidateConstructors : null);
}
```

如果能找到合适的构造器的话，就可以直接通过反射实例化对象了~

#### 3.2. 通过`beanPostProcessor`埋点来收集注解信息

通过`createBeanInstance`创建完类的实例之后，注入属性之前，我们有一个`beanPostProcessor`的埋点方法的调用：

```java
synchronized (mbd.postProcessingLock) {
    if (!mbd.postProcessed) {
        try {
            applyMergedBeanDefinitionPostProcessors(mbd, beanType, beanName);
        }
        catch (Throwable ex) {
            throw new BeanCreationException(...);
        }
        mbd.postProcessed = true;
    }
}
protected void applyMergedBeanDefinitionPostProcessors(RootBeanDefinition mbd, Class<?> beanType, String beanName) {
    for (BeanPostProcessor bp : getBeanPostProcessors()) {
        if (bp instanceof MergedBeanDefinitionPostProcessor) {
            MergedBeanDefinitionPostProcessor bdp = (MergedBeanDefinitionPostProcessor) bp;
            bdp.postProcessMergedBeanDefinition(mbd, beanType, beanName);
        }
    }
}
```

由于这个埋点中有一部分对注解进行支撑的逻辑还挺重要的，所以这里单独拿出来讲一下。

##### 3.2.1. `CommonAnnotationBeanPostProcessor`收集`@PostConstruct`、`@PreDestroy`、`@Resource`信息

`CommonAnnotationBeanPostProcessor`也是`AnnotationConfigUtils#registerAnnotationConfigProcessors`方法注入的，这里我就不带大家再看了。由于`CommonAnnotationBeanPostProcessor`实现了`MergedBeanDefinitionPostProcessor`接口，所以在这个埋点中也会被调用到，我们来看一下这个逻辑：

```java
public class CommonAnnotationBeanPostProcessor extends InitDestroyAnnotationBeanPostProcessor
    implements InstantiationAwareBeanPostProcessor, BeanFactoryAware, Serializable{
    // 构造器
    public CommonAnnotationBeanPostProcessor() {
        setOrder(Ordered.LOWEST_PRECEDENCE - 3);
        // 给两个关键字段设置了
        setInitAnnotationType(PostConstruct.class);
        setDestroyAnnotationType(PreDestroy.class);
        ignoreResourceType("javax.xml.ws.WebServiceContext");
    }
    
    @Override
    public void postProcessMergedBeanDefinition(RootBeanDefinition beanDefinition, Class<?> beanType, String beanName) {
        // 这里调用了父类的方法，正真的收集`@PostConstruct`、`@PreDestroy`注解的逻辑是在这里做的
        super.postProcessMergedBeanDefinition(beanDefinition, beanType, beanName);
        // 这里就是收集@Resource注解的信息啦
        InjectionMetadata metadata = findResourceMetadata(beanName, beanType, null);
        // 检查一下
        metadata.checkConfigMembers(beanDefinition);
    }
}
```

###### **3.2.1.1. 生命周期注解**`@PostConstruct`**、**`@PreDestroy`**信息收集**

我们先看一下父类收集生命周期注解的实现：

```java
public class InitDestroyAnnotationBeanPostProcessor
    implements DestructionAwareBeanPostProcessor, MergedBeanDefinitionPostProcessor, PriorityOrdered, Serializable{
    @Override
    public void postProcessMergedBeanDefinition(RootBeanDefinition beanDefinition, Class<?> beanType, String beanName) {
        // 寻找生命周期元数据
        LifecycleMetadata metadata = findLifecycleMetadata(beanType);
        // 对收集到的声明周期方法做一下校验处理
        metadata.checkConfigMembers(beanDefinition);
    }

    private LifecycleMetadata findLifecycleMetadata(Class<?> clazz) {
        if (this.lifecycleMetadataCache == null) {
            // 没有开启缓存就直接拿构建生命周期元数据了
            return buildLifecycleMetadata(clazz);
        }
        // 有开启缓存的话，就先从缓存找，找不到再构建，然后丢回缓存
        LifecycleMetadata metadata = this.lifecycleMetadataCache.get(clazz);
        if (metadata == null) {
            synchronized (this.lifecycleMetadataCache) {
                metadata = this.lifecycleMetadataCache.get(clazz);
                if (metadata == null) {
                    // 构建
                    metadata = buildLifecycleMetadata(clazz);
                    this.lifecycleMetadataCache.put(clazz, metadata);
                }
                return metadata;
            }
        }
        return metadata;
    }
    
    private LifecycleMetadata buildLifecycleMetadata(final Class<?> clazz) {
        // 简单判断类上是不是一定没有initAnnotationType和destroyAnnotationType这两个注解修饰的方法
        // 相当于快速失败
        // 需要注意的是，当前场景下，这两个注解实例化的时候已经初始化为PostConstruct和PreDestroy了
        if (!AnnotationUtils.isCandidateClass(clazz, Arrays.asList(this.initAnnotationType, this.destroyAnnotationType))) {
            return this.emptyLifecycleMetadata;
        }
        // 用来储存类上所有初始化/销毁方法的容器
        List<LifecycleElement> initMethods = new ArrayList<>();
        List<LifecycleElement> destroyMethods = new ArrayList<>();
        Class<?> targetClass = clazz;

        do {
            // 中间容器来储存当前类的初始化/销毁方法
            final List<LifecycleElement> currInitMethods = new ArrayList<>();
            final List<LifecycleElement> currDestroyMethods = new ArrayList<>();
            // 循环类上的每一个方法
            ReflectionUtils.doWithLocalMethods(targetClass, method -> {
                if (this.initAnnotationType != null && method.isAnnotationPresent(this.initAnnotationType)) {
                    // 如果方法被@PostConstruct注解修饰，包装成一个LifecycleElement
                    LifecycleElement element = new LifecycleElement(method);
                    // 加入收集初始化方法的中间容器
                    currInitMethods.add(element);
                }
                if (this.destroyAnnotationType != null && method.isAnnotationPresent(this.destroyAnnotationType)) {
                    // 如果方法被@PreDestroy注解修饰，包装成一个LifecycleElement
                    // 加入收集销毁方法的中间容器
                    currDestroyMethods.add(new LifecycleElement(method));
                }
            });
            // 加入所有初始化/销毁方法的容器
            // 需要注意的是，在整个循环过程中，
            // 当前类的初始化方法都是加入初始化方法容器的头部
            // 当前类的销毁方法都是加入销毁方法容器的尾部
            // 所以可以推断，初始化方法调用的时候是从父类->子类调用
            // 而销毁方法从子类->父类调用。
            // 即 bean初始化->调用父类初始化方法->调用子类初始化方法->...->调用子类销毁方法->调用父类销毁方法->销毁bean
            initMethods.addAll(0, currInitMethods);
            destroyMethods.addAll(currDestroyMethods);
            // 获取父类，循环处理所有父类上的初始化/销毁方法
            targetClass = targetClass.getSuperclass();
        }
        while (targetClass != null && targetClass != Object.class);
        // 把当前类class对象+初始化方法列表+销毁方法列表封装成一个LifecycleMetadata对象
        return (initMethods.isEmpty() && destroyMethods.isEmpty() ? this.emptyLifecycleMetadata :
                new LifecycleMetadata(clazz, initMethods, destroyMethods));
    }
}
```

看一下这个生命周期元数据`LifecycleMetadata`的结构：

```java
private class LifecycleMetadata {
    // 目标类
    private final Class<?> targetClass;
    // 目标类上收集到的初始化方法
    private final Collection<LifecycleElement> initMethods;
    // 目标类上收集到的销毁方法
    private final Collection<LifecycleElement> destroyMethods;
    // 检查、校验后的初始化方法
    @Nullable
    private volatile Set<LifecycleElement> checkedInitMethods;
    // 检查、校验后的销毁方法
    @Nullable
    private volatile Set<LifecycleElement> checkedDestroyMethods;
    
    public void checkConfigMembers(RootBeanDefinition beanDefinition) {
        // 这是那个检查、校验方法
        Set<LifecycleElement> checkedInitMethods = new LinkedHashSet<>(this.initMethods.size());
        for (LifecycleElement element : this.initMethods) {
            // 循环处理每个初始化方法
            String methodIdentifier = element.getIdentifier();
            // 判断是否是标记为外部处理的初始化方法，
            // 如果是外部处理的方法的话，其实spring是不会管理这些方法的
            if (!beanDefinition.isExternallyManagedInitMethod(methodIdentifier)) {
                // 这里把当前方法注册到这个externallyManagedDestroyMethods
                // 我猜想是方法签名相同的方法就不调用两次了
                // 比如可能父类的方法打了@PostConstruct,子类重写之后也在方法上打了@PostConstruct
                // 这两个方法都会被收集到initMethods，但是当然不应该调用多次
                beanDefinition.registerExternallyManagedInitMethod(methodIdentifier);
                // 加入了检查后的初始化方法列表，实际调用初始化方法时也是会调用这个列表
                checkedInitMethods.add(element);
            }
        }
        // 销毁方法的处理逻辑和初始化方法一样，我直接跳过了
        this.checkedInitMethods = checkedInitMethods;
        this.checkedDestroyMethods = checkedDestroyMethods;
    }
}
```

到这里为止，其实我们`CommonAnnotationBeanPostProcessor`对生命周期注解的收集过程就完成了，其实主要是通过父类的模本方法，把被`@PostConstruct`、`@PreDestroy`修饰的方法的信息封装到了`LifecycleMetadata`。看完`InitDestroyAnnotationBeanPostProcessor`的逻辑之后，同学们会不会有实现一套自己的生命周期注解的冲动呢？毕竟写一个类继承一下然后在自己的类构造器中`set`一下`initAnnotationType`、`destroyAnnotationType`就可以了！

###### 3.2.1.2. 依赖注入注解`@Resource`信息收集

刚刚有说道我们的`findResourceMetadata`方法是用来收集`@Resource`注解信息的，我们现在来看一下这里的逻辑：

```java
private InjectionMetadata findResourceMetadata(String beanName, final Class<?> clazz, @Nullable PropertyValues pvs) {
    // 也是一个缓存逻辑
    String cacheKey = (StringUtils.hasLength(beanName) ? beanName : clazz.getName());
    InjectionMetadata metadata = this.injectionMetadataCache.get(cacheKey);
    if (InjectionMetadata.needsRefresh(metadata, clazz)) {
        synchronized (this.injectionMetadataCache) {
            metadata = this.injectionMetadataCache.get(cacheKey);
            if (InjectionMetadata.needsRefresh(metadata, clazz)) {
                if (metadata != null) {
                    metadata.clear(pvs);
                }
                // 构建逻辑
                metadata = buildResourceMetadata(clazz);
                this.injectionMetadataCache.put(cacheKey, metadata);
            }
        }
    }
    return metadata;
}

private InjectionMetadata buildResourceMetadata(final Class<?> clazz) {
    // 这个方法除了收集@Resource注解之外，
    // 其实还会收集@WebServiceRef和@EJB注解（如果你的项目有引入这些）
    // 不过由于@WebServiceRef和@EJB我们现在基本也不用了（反正我没用过）
    // 我这边就把相应的逻辑删除掉了，这样看也清晰点
    // 而且这些收集逻辑也是一致的，最多只是说最后把注解信息封装到不同的子类型而已
    // 快速失败检测
    if (!AnnotationUtils.isCandidateClass(clazz, resourceAnnotationTypes)) {
        return InjectionMetadata.EMPTY;
    }
    // 收集到注入元素
    List<InjectionMetadata.InjectedElement> elements = new ArrayList<>();
    Class<?> targetClass = clazz;

    do {
        // 这里套路其实跟收集生命周期注解差不多了
        // 也是循环收集父类的
        final List<InjectionMetadata.InjectedElement> currElements = new ArrayList<>();
        // 循环处理每个属性
        ReflectionUtils.doWithLocalFields(targetClass, field -> {
            if (...) {...} // 其他注解的处理
            else if (field.isAnnotationPresent(Resource.class)) {
                // 静态属性不允许注入，当然其实@Autowired和@Value也是不允许的，
                // 只是那边不会报错，只是忽略当前方法/属性而已
                if (Modifier.isStatic(field.getModifiers())) {
                    throw new IllegalStateException(...);
                }
                if (!this.ignoredResourceTypes.contains(field.getType().getName())) {
                    // 不是忽略的资源就加入容器
                    // ejb那些就是封装成EjbRefElement
                    currElements.add(new ResourceElement(field, field, null));
                }
            }
        });
        // 循环处理每个方法，比如@Resource修饰的set方法啦（当然没规定要叫setXxx）
        // 这里会循环当前类声明的方法和接口的默认（default）方法
        ReflectionUtils.doWithLocalMethods(targetClass, method -> {
            // 这里是处理桥接方法的逻辑，桥接方法是编译器自行生成的方法。
            // 主要跟泛型相关，这里也不多拓展了
            Method bridgedMethod = BridgeMethodResolver.findBridgedMethod(method);
            if (!BridgeMethodResolver.isVisibilityBridgeMethodPair(method, bridgedMethod)) {
                return;
            }
            // 由于这个工具类的循环是会循环到接口的默认方法的
            // 这里这个判断是处理以下场景的：
            // 接口有一个default方法，而当前类重写了这个方法
            // 那如果子类重写的method循环的时候，这个if块能进去
            // 接下来接口的相同签名的默认method进来时，
            // ClassUtils.getMostSpecificMethod(method, clazz)会返回子类中重写的那个方法
            // 这是就和当前方法（接口方法）不一致，就不会再进if块收集一遍了
            if (method.equals(ClassUtils.getMostSpecificMethod(method, clazz))) {
                if (...) {...} // 其他注解的处理
                else if (bridgedMethod.isAnnotationPresent(Resource.class)) {
                    if (Modifier.isStatic(method.getModifiers())) {
                        throw new IllegalStateException(...);
                    }
                    Class<?>[] paramTypes = method.getParameterTypes();
                    if (paramTypes.length != 1) {
                        // 原来@Resource方法注入只支持一个参数的方法（set方法）
                        // 这个限制估计是规范定的
                        // @Autowired没有这个限制
                        throw new IllegalStateException(...);
                    }
                    if (!this.ignoredResourceTypes.contains(paramTypes[0].getName())) {
                        // 封装了一个属性描述符，这个主要用来加载方法参数的，暂时不展开
                        PropertyDescriptor pd = BeanUtils.findPropertyForMethod(bridgedMethod, clazz);
                        // 也封装成一个ResourceElement加入容器
                        currElements.add(new ResourceElement(method, bridgedMethod, pd));
                    }
                }
            }
        });
        // 每次都放到列表的最前面，说明是优先会注入父类的
        elements.addAll(0, currElements);
        targetClass = targetClass.getSuperclass();
    }
    while (targetClass != null && targetClass != Object.class);
    // 把当前类的class和收集到的注入元素封装成一个注入元数据
    return InjectionMetadata.forElements(elements, clazz);
}
```

可以看到，其实跟生命周期那一块差不多，也是收集注解信息然后封装，只是这个注入元素的收集要同时收集属性和（`set`）方法而已，我们还是照常瞄一下这个数据结构：

```java
public class InjectionMetadata {
    // 目标类--属性需要注入到哪个类
    private final Class<?> targetClass;
    // 注入元素
    private final Collection<InjectedElement> injectedElements;
    // 检查后的注入元素
    @Nullable
    private volatile Set<InjectedElement> checkedElements;
}

public abstract static class InjectedElement {
        // Member是Method和Field的父类
        protected final Member member;
        // 通过这个属性区分是field还是method
        protected final boolean isField;
        // 属性描述符，如果是method会通过这个描述符获取入参
        @Nullable
        protected final PropertyDescriptor pd;
        @Nullable
        protected volatile Boolean skip;
}
```

获取到`InjectionMetadata`之后的`metadata.checkConfigMembers`逻辑，和生命周期那一块是一模一样的，这边就不跟了。

那么到这里为止我们`CommonAnnotationBeanPostProcessor`类在bean实例创建之后的埋点的逻辑就分析完了。

##### 3.2.2. `AutowiredAnnotationBeanPostProcessor`收集`@Autowired`、`@Value`信息

`AutowiredAnnotationBeanPostProcessor`这个类的注册时机已经讲过很多遍了，也是`AnnotationConfigUtils#registerAnnotationConfigProcessors`方法注入的，这边我们直接看一下它的`postProcessMergedBeanDefinition`方法是如何收集注解信息的：


```java
public class AutowiredAnnotationBeanPostProcessor extends InstantiationAwareBeanPostProcessorAdapter
    implements MergedBeanDefinitionPostProcessor, PriorityOrdered, BeanFactoryAware {
    // 自动注入注解类型
    private final Set<Class<? extends Annotation>> autowiredAnnotationTypes = new LinkedHashSet<>(4);
    
    public AutowiredAnnotationBeanPostProcessor() {
        // autowiredAnnotationTypes中放入@Autowired、@Value
        this.autowiredAnnotationTypes.add(Autowired.class);
        this.autowiredAnnotationTypes.add(Value.class);
        try {
            this.autowiredAnnotationTypes.add((Class<? extends Annotation>)
                                              ClassUtils.forName("javax.inject.Inject", AutowiredAnnotationBeanPostProcessor.class.getClassLoader()));
        }
        catch (ClassNotFoundException ex) {
            // JSR-330 API not available - simply skip.
        }
    }
    
    @Override
    public void postProcessMergedBeanDefinition(RootBeanDefinition beanDefinition, Class<?> beanType, String beanName) {
        // 这里其实就很熟悉了，和@Resource的处理过程看起来就是一模一样的
        InjectionMetadata metadata = findAutowiringMetadata(beanName, beanType, null);
        metadata.checkConfigMembers(beanDefinition);
    }
    
    private InjectionMetadata buildAutowiringMetadata(final Class<?> clazz) {
        // 缓存逻辑我这边就不看了，都是一模一样的
        // 这个，其实连收集逻辑都基本是一致的，我们就简单过一下吧
        if (!AnnotationUtils.isCandidateClass(clazz, this.autowiredAnnotationTypes)) {
            return InjectionMetadata.EMPTY;
        }

        List<InjectionMetadata.InjectedElement> elements = new ArrayList<>();
        Class<?> targetClass = clazz;

        do {
            final List<InjectionMetadata.InjectedElement> currElements = new ArrayList<>();
            // 处理属性
            ReflectionUtils.doWithLocalFields(targetClass, field -> {
                MergedAnnotation<?> ann = findAutowiredAnnotation(field);
                if (ann != null) {
                    // 静态属性不允许注入
                    if (Modifier.isStatic(field.getModifiers())) {
                        return;
                    }
                    // @Autowrired有一个required属性需要收集一下
                    boolean required = determineRequiredStatus(ann);
                    currElements.add(new AutowiredFieldElement(field, required));
                }
            });
            // 处理方法
            ReflectionUtils.doWithLocalMethods(targetClass, method -> {
                Method bridgedMethod = BridgeMethodResolver.findBridgedMethod(method);
                if (!BridgeMethodResolver.isVisibilityBridgeMethodPair(method, bridgedMethod)) {
                    return;
                }
                MergedAnnotation<?> ann = findAutowiredAnnotation(bridgedMethod);
                if (ann != null && method.equals(ClassUtils.getMostSpecificMethod(method, clazz))) {
                    if (Modifier.isStatic(method.getModifiers())) {
                        // 静态方法不处理，忽略，相当于不生效，@Resource那边是会报错的。
                        return;
                    }
                    boolean required = determineRequiredStatus(ann);
                    // 封装一个属性描述符描述符
                    PropertyDescriptor pd = BeanUtils.findPropertyForMethod(bridgedMethod, clazz);
                    currElements.add(new AutowiredMethodElement(method, required, pd));
                }
            });
            // 父类优先
            elements.addAll(0, currElements);
            targetClass = targetClass.getSuperclass();
        }
        while (targetClass != null && targetClass != Object.class);
        // 封装到InjectionMetadata
        return InjectionMetadata.forElements(elements, clazz);
    }
}
```

啊，索然无味，这个逻辑简直跟`@Resource`的处理一模一样的，同学们有没有一丢丢疑惑--这样如此雷同的方法，`spring`为什么要写两遍呢？**这是不是违反了`DRY`原则呢**？同学们可以思考一下这个问题。

> 我倒是认为没有违反`DRY`原则，但是对于`javax.inject.Inject`注解的划分还是不太合适，应该划分到`common`的；而`common`中对各种类型的注解的处理（`@EJB`、`@Resource`、`@WebServiceRef`）使用`if-else`也不太优雅，完全可以使用一个小小的策略模式的。
>
> 不过这东西每个人看法也不一样的，同学们有兴趣也可以在评论区探讨一下~

##### 3.2.3. 总结`CommonAnnotationBeanPostProcessor`和`AutowiredAnnotationBeanPostProcessor`

这个埋点基本上就这两个`beanPostProcessor`做了事情了，而且也与我们平常的开发息息相关，这边简单总结一下。

###### **3.2.3.1 职能划分**

这两个`beanPostProcessor`的职能上是有划分的：

- `CommonAnnotationBeanPostProcessor`主要处理`jdk`相关的规范的注解，`@Resource`、`@PostConstruct`等注解都是`jdk`的规范中定义的。
  - 收集生命周期相关的`@PostConstruct`、`@PreDestroy`注解信息封装成`LifecycleMetadata`
  - 收集资源注入注解（我们主要关注`@Resource`）信息封装成`InjectionMetadata`
- `AutowiredAnnotationBeanPostProcessor`主要处理`spring`定义的`@Autowired`相关的功能
  - 这里不得不说一下我觉得这个类也用来处理`javax.inject.Inject`不合理
  - 收集自动注入相关的注解`@Autowired`、`@Value`信息封装成`InjectionMetadata`

###### **3.2.3.2 使用**`@Resouce`**还是**`@Autowired`**？**

那么日常我们开发过程中，究竟推荐使用`@Resouce`还是`@Autowired`呢？这个问题我认为仁者见仁智者见智，我这边只稍微列一下使用这两个注解时需要注意的问题：

- `@Resouce`和`@Autowired`都不能用来注入静态属性（通过在静态属性上使用注解和静态方法上使用注解）

- 使用`@Resouce`注入静态属性时，会直接抛出`IllegalStateException`导致当前实例初始化流程失败

- 而使用`@Autowired`注入静态属性时，只会忽略当前属性，不注入了，不会导致实例初始化流程失败

- 使用`@Resouce`修饰方法时，方法只能有一个入参，而`@Autowired`没有限制

- `@Resouce`属于`jdk`的规范，可以认为对项目零入侵；`@Autowired`属于`spring`的规范，使用了`@Autowired`的话就不能替换成别的`IOC`框架了（这个我确实也没替换过...）

#### 3.3. `populateBean`，对`bean`进行自动装配

接下来我们继续回到`bean`实例化的主流程，调用完`beanPostProcessor`的一个埋点之后，我们就进入自动装配的流程了，也就是这个：

```java
// 自动装配
populateBean(beanName, mbd, instanceWrapper);
// 执行初始化方法
exposedObject = initializeBean(beanName, exposedObject, mbd);
```

跟着往下看：

```java
protected void populateBean(String beanName, RootBeanDefinition mbd, @Nullable BeanWrapper bw) {

    // 这里又是一个埋点，放入三级缓存之后，自动装配之前
    if (!mbd.isSynthetic() && hasInstantiationAwareBeanPostProcessors()) {
        for (BeanPostProcessor bp : getBeanPostProcessors()) {
            if (bp instanceof InstantiationAwareBeanPostProcessor) {
                InstantiationAwareBeanPostProcessor ibp = (InstantiationAwareBeanPostProcessor) bp;
                // 可以看到，这个埋点是bean实例和beanName传入了
                // 所以我们可以在这个埋点做一下自定义的属性的注入（拿到实例了很好说嘛），
                // 比如公共字段的set啦（反正我没在这里拓展过）
                // 不过需要主要的是，如果这个埋点返回false的话，是认为不需要spring来进行自动装配了
                // 会直接结束当前方法，跳过该bean的自动装配流程的
                if (!ibp.postProcessAfterInstantiation(bw.getWrappedInstance(), beanName)) {
                    return;
                }
            }
        }
    }

    PropertyValues pvs = (mbd.hasPropertyValues() ? mbd.getPropertyValues() : null);
    // 这里是通过resolvedAutowireMode，来通过不同的方式注入propertyValues中的属性了
    // 这个propertyValues就是我们xml标签解析中的property标签封装的对象啦
    // 当然我们后期也可以修改
    int resolvedAutowireMode = mbd.getResolvedAutowireMode();
    if (resolvedAutowireMode == AUTOWIRE_BY_NAME || resolvedAutowireMode == AUTOWIRE_BY_TYPE) {
        MutablePropertyValues newPvs = new MutablePropertyValues(pvs);
        if (resolvedAutowireMode == AUTOWIRE_BY_NAME) {
            // 通过名称注入，其实就是getBean(beanName)
            autowireByName(beanName, mbd, bw, newPvs);
        }
        if (resolvedAutowireMode == AUTOWIRE_BY_TYPE) {
            // 这里逻辑稍微复杂点，不过简单说就是getBean(beanName, beanClass)而已
            autowireByType(beanName, mbd, bw, newPvs);
        }
        pvs = newPvs;
    }
    // 到这里为止就处理好了beanDefinition中封装的propertyValues依赖的信息

    boolean hasInstAwareBpps = hasInstantiationAwareBeanPostProcessors();
    boolean needsDepCheck = (mbd.getDependencyCheck() != AbstractBeanDefinition.DEPENDENCY_CHECK_NONE);
    // 这里又是一个埋点啦
    PropertyDescriptor[] filteredPds = null;
    if (hasInstAwareBpps) {
        if (pvs == null) {
            pvs = mbd.getPropertyValues();
        }

        // 这个埋点的时机是在把pvs的值注入到bean实例之前，给一个埋点，
        // 允许beanPostProcessor修改pvs和bean实例的信息
        // 所以之前创建bean实例之后的埋点收集的属性注入的信息
        // 这里就可以用这些信息，来修改pvs或者bean实例了
        for (BeanPostProcessor bp : getBeanPostProcessors()) {
            if (bp instanceof InstantiationAwareBeanPostProcessor) {
                InstantiationAwareBeanPostProcessor ibp = (InstantiationAwareBeanPostProcessor) bp;
                PropertyValues pvsToUse = ibp.postProcessProperties(pvs, bw.getWrappedInstance(), beanName);
                // 如果通过新接口没做任何逻辑，则还是走旧接口试下
                if (pvsToUse == null) {
                    if (filteredPds == null) {
                        filteredPds = filterPropertyDescriptorsForDependencyCheck(bw, mbd.allowCaching);
                    }
                    // 这个接口在5.1版本基本已经废弃了，我们就不看了
                    pvsToUse = ibp.postProcessPropertyValues(pvs, filteredPds, bw.getWrappedInstance(), beanName);
                    if (pvsToUse == null) {
                        return;
                    }
                }
                pvs = pvsToUse;
            }
        }
    }
    // 依赖检查，不讲
    if (needsDepCheck) {
        if (filteredPds == null) {
            filteredPds = filterPropertyDescriptorsForDependencyCheck(bw, mbd.allowCaching);
        }
        checkDependencies(beanName, mbd, filteredPds, pvs);
    }

    if (pvs != null) {
        // 真正把pvs中的属性注入到bean实例里面去
        applyPropertyValues(beanName, mbd, bw, pvs);
    }
}
```

##### 3.3.1. `@Resource`、`@Autowired`的注入逻辑

`xml`方式配置的信息的注入我这边就不仔细讲了，主要现在这种方式也用的很少，并且对我们了解`spring`的逻辑没有太大的帮助，需要注意的是，`beanDefinition`的`propertyValues`中的属性的注入，是调用`bean`对象的对应`set`方法进行注入的，如果该属性没有`set`方法，注入会报错并且导致`spring`启动失败。

解下来我们稍微讲一下基于注解的属性注入方式。因为`@Resource`和`@Autowired`注解的信息最后都封装成了`InjectionMetadata`，那么他们的注入的逻辑应该也是差别不大的，我们可以看一下：

```java
// CommonAnnotationBeanPostProcessor
@Override
public PropertyValues postProcessProperties(PropertyValues pvs, Object bean, String beanName) {
    // 这一次肯定能从缓存中拿到了，之前已经构建了
    InjectionMetadata metadata = findResourceMetadata(beanName, bean.getClass(), pvs);
    try {
        // 注入
        metadata.inject(bean, beanName, pvs);
    }
    catch (Throwable ex) {
        throw new BeanCreationException(beanName, "Injection of resource dependencies failed", ex);
    }
    return pvs;
}
// AutowiredAnnotationBeanPostProcessor
@Override
public PropertyValues postProcessProperties(PropertyValues pvs, Object bean, String beanName) {
    InjectionMetadata metadata = findAutowiringMetadata(beanName, bean.getClass(), pvs);
    try {
        metadata.inject(bean, beanName, pvs);
    }
    catch (BeanCreationException ex) {
        throw ex;
    }
    catch (Throwable ex) {
        throw new BeanCreationException(beanName, "Injection of autowired dependencies failed", ex);
    }
    return pvs;
}
```

逻辑确实是一样的，都是委托给`InjectionMetadata`来注入：

```java
public void inject(Object target, @Nullable String beanName, @Nullable PropertyValues pvs) throws Throwable {
    Collection<InjectedElement> checkedElements = this.checkedElements;
    Collection<InjectedElement> elementsToIterate =
        (checkedElements != null ? checkedElements : this.injectedElements);
    if (!elementsToIterate.isEmpty()) {
        for (InjectedElement element : elementsToIterate) {
            // 接下来委托给具体的注入元素来操作
            // 这里往下就有点不一样了
            element.inject(target, beanName, pvs);
        }
    }
}
```

我们接下来简单讲一下`@Resource`的注入逻辑，由于`ResourceElement`没有重写`inject`方法，所以它走的还是父类`InjectedElement`的逻辑：

```java
protected void inject(Object target, @Nullable String requestingBeanName, @Nullable PropertyValues pvs)
    throws Throwable {
    // 可以看到，就是通过isField判断是属性还是方法
    // 然后直接通过反射把属性设置或者调用方法了
    if (this.isField) {
        Field field = (Field) this.member;
        ReflectionUtils.makeAccessible(field);
        // 通过这个getResourceToInject来获取了需要注入的资源
        field.set(target, getResourceToInject(target, requestingBeanName));
    }
    else {
        if (checkPropertySkipping(pvs)) {
            return;
        }
        try {
            Method method = (Method) this.member;
            ReflectionUtils.makeAccessible(method);
            method.invoke(target, getResourceToInject(target, requestingBeanName));
        }
        catch (InvocationTargetException ex) {
            throw ex.getTargetException();
        }
    }
}
```

我们来看一下这个模板方法`inject`中留给子类实现的`getResourceToInject`方法在`ResourceElement`中的实现：

```java
@Override
protected Object getResourceToInject(Object target, @Nullable String requestingBeanName) {
    // 懒加载的逻辑我们就暂时不看了
    // 解释一下，无非就是把需要注入的类代理一层，暂时不使用getBean获取需要注入的类的实例
    // 当我们通过这个懒加载的属性去做任何动作时，代理层就会先根据这个属性的信息，去从beanFactory.getBean
    return (this.lazyLookup ? buildLazyResourceProxy(this, requestingBeanName) :
            getResource(this, requestingBeanName));
}

protected Object getResource(LookupElement element, @Nullable String requestingBeanName)
    throws NoSuchBeanDefinitionException {
    // ...
    return autowireResource(this.resourceFactory, element, requestingBeanName);
}
protected Object autowireResource(BeanFactory factory, LookupElement element, @Nullable String requestingBeanName)
    throws NoSuchBeanDefinitionException {
    Object resource;
    Set<String> autowiredBeanNames;
    String name = element.name;

    if (factory instanceof AutowireCapableBeanFactory) {
        AutowireCapableBeanFactory beanFactory = (AutowireCapableBeanFactory) factory;
        DependencyDescriptor descriptor = element.getDependencyDescriptor();
        if (this.fallbackToDefaultTypeMatch && element.isDefaultName && !factory.containsBean(name)) {
            autowiredBeanNames = new LinkedHashSet<>();
            // 通过beanFactory获取依赖的bean实例
            resource = beanFactory.resolveDependency(descriptor, requestingBeanName, autowiredBeanNames, null);
            if (resource == null) {
                throw new NoSuchBeanDefinitionException(element.getLookupType(), "No resolvable resource object");
            }
        }
        else {
            // 通过beanName获取依赖的bean实例
            resource = beanFactory.resolveBeanByName(name, descriptor);
            autowiredBeanNames = Collections.singleton(name);
        }
    }
    else {
        // 通过beanFactory获取bean
        resource = factory.getBean(name, element.lookupType);
        autowiredBeanNames = Collections.singleton(name);
    }
    
    // 注册bean的依赖信息
    if (factory instanceof ConfigurableBeanFactory) {
        ConfigurableBeanFactory beanFactory = (ConfigurableBeanFactory) factory;
        for (String autowiredBeanName : autowiredBeanNames) {
            if (requestingBeanName != null && beanFactory.containsBean(autowiredBeanName)) {
                beanFactory.registerDependentBean(autowiredBeanName, requestingBeanName);
            }
        }
    }
    return resource;
}
```

这一块通过`beanFactory`来加载`bean`的逻辑就暂时不深入了，里面逻辑比较绕，之后如果有机会，我再单独开博客讲。

但是我们要知道，这个逻辑不管它怎么绕，它最终无非还是要通过`beanFactory.getBean`来获取依赖的`bean`的嘛，我都拿到这个注入元素的信息了，拿到这个需要注入的`Field`或者`Method`了，我难到还不知道我需要注入的`bean`是什么类型么？拿到类型我们肯定就能从`beanFactory`获取到实例啦。

#### 3.4. `initializeBean`调用`bean`的初始化方法

不知道同学们日常开发时，有没有使用过`XxxAware`接口来获取一些`spring`的组件，或者是使用`@PostConstruct`注解/实现`InitializingBean`接口来做一些`bean`的初始化逻辑呢？`initializeBean`方法就是处理这些逻辑的地方。

一个`bean`并不是说实例创建好，做完依赖注入之后，就可以交给用户使用了。`spring`还需要对这个`bean`做一些初始化工作。

```java
// 自动装配
populateBean(beanName, mbd, instanceWrapper);
// 执行初始化方法
exposedObject = initializeBean(beanName, exposedObject, mbd);
```

接下来，我们就一起看一下这个`initializeBean`的逻辑：

```java
protected Object initializeBean(final String beanName, final Object bean, @Nullable RootBeanDefinition mbd) {
    // 调用aware方法 -- 需要注意的是这里只调用了一部分aware接口的方法
    // 还有一部分XxxAware接口的调用是通过beanPostProcessor来实现的
    invokeAwareMethods(beanName, bean);

    Object wrappedBean = bean;
    if (mbd == null || !mbd.isSynthetic()) {
        // bean实例初始化之前的埋点
        wrappedBean = applyBeanPostProcessorsBeforeInitialization(wrappedBean, beanName);
    }

    try {
        // 调用初始化方法
        invokeInitMethods(beanName, wrappedBean, mbd);
    }
    catch (Throwable ex) {
        throw new BeanCreationException(
            (mbd != null ? mbd.getResourceDescription() : null),
            beanName, "Invocation of init method failed", ex);
    }
    if (mbd == null || !mbd.isSynthetic()) {
        // bean实例初始化之后的埋点
        wrappedBean = applyBeanPostProcessorsAfterInitialization(wrappedBean, beanName);
    }

    return wrappedBean;
}
```

可以看到，逻辑也是比较清晰的，主要分为四步，接下来我们一步一步讲解。

##### 3.4.1. `invokeAwareMethods`调用`aware`接口

`spring`提供了一个标记接口`Aware`，用来给用户标记当前`bean`是需要获取某些`spring`能提供的**组件/信息**的：

```java
public interface Aware {
    // 这是一个空的标记接口
}
```

而具体用户的`bean`需要`spring`提供什么**组件/信息**，则可以选择性的实现`Aware`的某个子接口。例如，如果我们的某个`bean`中需要拿到实例化它的`beanFactory`，那么我们可以实现`BeanFactoryAware`接口：

```java
public interface BeanFactoryAware extends Aware {
    // bean中实现这接口就可以了，我们可以把beanFactory的引用保存下来
    void setBeanFactory(BeanFactory beanFactory) throws BeansException;
}
```

那么对于这一些`Aware`接口的调用，`spring`是怎么做的呢？其实这也分为了两部分，一部分就是我们现在讲到的`invokeAwareMethods`方法：

```java
private void invokeAwareMethods(final String beanName, final Object bean) {
    if (bean instanceof Aware) {
        // 判断->强转->调用一目了然，就不多说了
        if (bean instanceof BeanNameAware) {
            ((BeanNameAware) bean).setBeanName(beanName);
        }
        if (bean instanceof BeanClassLoaderAware) {
            ClassLoader bcl = getBeanClassLoader();
            if (bcl != null) {
                ((BeanClassLoaderAware) bean).setBeanClassLoader(bcl);
            }
        }
        if (bean instanceof BeanFactoryAware) {
            ((BeanFactoryAware) bean).setBeanFactory(AbstractAutowireCapableBeanFactory.this);
        }
    }
}
```

就是这样简单的**判断->强转->调用**就可以了，但是有同学可能会说了，这里才处理了三种`Aware`接口的情况，平常我用的`ApplicationContextAware`那些的处理逻辑怎么没有？

其实这里也可以算是`spring`早期给自己挖的坑了，`invokeAwareMethods`这个方法是在`bean`初始化的主流程里的，属于很基础的代码。可是随着`spring`的慢慢开发，可能会有各类开发人员开始给`spring`团队提需求，希望新增一个`XxxAware`接口。这个时候`spring`团队一看，有些`Aware`接口确实可以由`spring`管理起来，这难道继续在这个`invokeAwareMethods`方法里加`if-else`么？**显然是不行的，这违反了开闭原则！**

##### 3.4.2. `postProcessBeforeInitialization`埋点调用

`invokeAwareMethods`方法之后，我们马上有一个埋点的调用：

```java
wrappedBean = applyBeanPostProcessorsBeforeInitialization(wrappedBean, beanName);

public Object applyBeanPostProcessorsBeforeInitialization(Object existingBean, String beanName)
    throws BeansException {
    Object result = existingBean;
    for (BeanPostProcessor processor : getBeanPostProcessors()) {
        // 调用BeanPostProcessor.postProcessBeforeInitialization
        Object current = processor.postProcessBeforeInitialization(result, beanName);
        if (current == null) {
            return result;
        }
        result = current;
    }
    return result;
}
```

说起来才发现这个`postProcessBeforeInitialization`居然是`BeanPostProcessor`接口的方法，而`BeanPostProcessor`的声明的两个方法其实就是这个`initializeBean`方法中的两个埋点。那是不是说明其实第一版的`spring`是只有这两个埋点的，随着框架的发展，才慢慢新增其他的继承`BeanPostProcessor`接口的埋点接口并且在`bean`初始化流程中被调用的呢？（这个我也不确定，毕竟也没看过第一版的代码）

说回这个`postProcessBeforeInitialization`方法，这里也简单讲几个与我们平常使用相关的例子。

###### **3.4.2.1. 使用**`ApplicationContextAwareProcessor`**处理**`XxxAware`**接口需求**

刚刚讲`invokeAwareMethods`方法的时候有提过，对于日益增多的`XxxAware`接口需求，`spring`应该怎么做才会更优雅一点，符合开闭原则呢？

`spring`的答案是，使用`postProcessBeforeInitialization`这个埋点方法，所以有了`ApplicationContextAwareProcessor`，我们直接来看下它的埋点方法：

```java
public Object postProcessBeforeInitialization(Object bean, String beanName) throws BeansException {
    // 判断是否是需要处理的Aware接口
    if (!(bean instanceof EnvironmentAware || bean instanceof EmbeddedValueResolverAware ||
          bean instanceof ResourceLoaderAware || bean instanceof ApplicationEventPublisherAware ||
          bean instanceof MessageSourceAware || bean instanceof ApplicationContextAware)){
        return bean;
    }
    invokeAwareInterfaces(bean);
    return bean;
}

private void invokeAwareInterfaces(Object bean) {
    if (bean instanceof EnvironmentAware) {
        ((EnvironmentAware) bean).setEnvironment(this.applicationContext.getEnvironment());
    }
    if (bean instanceof EmbeddedValueResolverAware) {
        ((EmbeddedValueResolverAware) bean).setEmbeddedValueResolver(this.embeddedValueResolver);
    }
    // ...跳过了其他XxxAware接口的处理逻辑，都是一样的
}
```

可以看到，逻辑还是挺简单的，差不多就是把`invokeAwareMethods`中的模式搬过来了。

###### **3.4.2.2.** `InitDestroyAnnotationBeanPostProcessor`**生命周期方法的调用**

如果同学们不至于太健忘的话，应该还记得我们刚刚有讲过一个`CommonAnnotationBeanPostProcessor`，它会在bean创建之后，依赖注入之前，调用`postProcessMergedBeanDefinition`这个埋点方法收集`@PostConstruct`、`@PreDestroy`注解的信息，而这个`beanPostProcessor`是继承自`InitDestroyAnnotationBeanPostProcessor`的，`InitDestroyAnnotationBeanPostProcessor`的两个埋点方法中就分别调用了收集到的生命周期方法：

```java
public Object postProcessBeforeInitialization(Object bean, String beanName) throws BeansException {
    LifecycleMetadata metadata = findLifecycleMetadata(bean.getClass());
    try {
        metadata.invokeInitMethods(bean, beanName);
    } catch (Throwable ex) {
        throw new BeanCreationException(...);
    }
    return bean;
}
```

获取`LifecycleMetadata`的流程就不再讲了，这里肯定是直接从缓存拿到了，我们来看一下`invokeInitMethods`方法：

```java
public void invokeInitMethods(Object target, String beanName) throws Throwable {
    Collection<LifecycleElement> checkedInitMethods = this.checkedInitMethods;
    Collection<LifecycleElement> initMethodsToIterate =
        (checkedInitMethods != null ? checkedInitMethods : this.initMethods);
    if (!initMethodsToIterate.isEmpty()) {
        for (LifecycleElement element : initMethodsToIterate) {
            // 调用方法
            element.invoke(target);
        }
    }
}

public void invoke(Object target) throws Throwable {
    // 直接就是反射调用了
    ReflectionUtils.makeAccessible(this.method);
    this.method.invoke(target, (Object[]) null);
}
```

所以从我们现在的角度来看，初始化方法中，通过`@PostConstruct`注解来声明的方法会最先被调用。

##### 3.4.3. `invokeInitMethods`调用初始化方法

接下来就是初始化方法的调用了，这里主要需要处理两种方法的调用：

1. 实现了`InitializingBean`接口的`bean`，需要调用`InitializingBean#afterPropertiesSet`
2. `beanDefinition`中有`initMethodName`属性的（比如通过`xml`解析加载来的）

我们来看一下逻辑：

```java
protected void invokeInitMethods(String beanName, final Object bean, @Nullable RootBeanDefinition mbd)
    throws Throwable {

    boolean isInitializingBean = (bean instanceof InitializingBean);
    if (isInitializingBean && (mbd == null || !mbd.isExternallyManagedInitMethod("afterPropertiesSet"))) {
        // 调用InitializingBean.afterPropertiesSet
        ((InitializingBean) bean).afterPropertiesSet();
    }
        
    if (mbd != null && bean.getClass() != NullBean.class) {
        String initMethodName = mbd.getInitMethodName();
        if (StringUtils.hasLength(initMethodName) &&
            !(isInitializingBean && "afterPropertiesSet".equals(initMethodName)) &&
            !mbd.isExternallyManagedInitMethod(initMethodName)) {
            // 调用beanDefinition中的initMethod
            // 就是个反射调用，我们就不再看了
            invokeCustomInitMethod(beanName, bean, mbd);
        }
    }
}
```

稍微说一下这个`isExternallyManagedInitMethod`判断的作用吧，这个判断主要是避免一个方法被调用两次的。在我们的`beanDefinition`中有一个`Set<String> externallyManagedInitMethods`用来记录哪些方法是不需要再调用了（销毁方法同理），而生命周期注解收集的时候，会把收集到的初始化方法的方法名塞进去，这样到这里`invokeInitMethods`的逻辑中，如果是被`@PostConstruct`注解收集并且调用过的方法，这里是不会再被调用的。

##### 3.4.4. `postProcessAfterInitialization`埋点调用

初始化方法调用完后，又有一个埋点方法，这是这个bean创建好后，返回到用户手中之前的最后一个埋点了，这个时候bean中的所有信息都是齐全的。同学们可以想一想，我们可以在这个埋点做什么工作呢？

```java
wrappedBean = applyBeanPostProcessorsAfterInitialization(wrappedBean, beanName);

public Object applyBeanPostProcessorsAfterInitialization(Object existingBean, String beanName)
    throws BeansException {

    Object result = existingBean;
    for (BeanPostProcessor processor : getBeanPostProcessors()) {
        // 初始化之后的埋点
        Object current = processor.postProcessAfterInitialization(result, beanName);
        if (current == null) {
            return result;
        }
        result = current;
    }
    return result;
}
```

我们著名的`aop`的代理类创建的逻辑，就是在这个埋点做的。具体的入口类是`AbstractAutoProxyCreator`：

```java
public Object postProcessAfterInitialization(@Nullable Object bean, String beanName) {
    if (bean != null) {
        Object cacheKey = getCacheKey(bean.getClass(), beanName);
        if (this.earlyProxyReferences.remove(cacheKey) != bean) {
            // 如果需要的话，返回一个代理类
            return wrapIfNecessary(bean, beanName, cacheKey);
        }
    }
    return bean;
}
```

不过`aop`的逻辑这里就不多讲了，期待我之后的博客吧~

##### 3.4.5. `registerDisposableBeanIfNecessary`注册`bean`的销毁逻辑

整个`bean`初始化完成之后，我们还需要做最后一步，那就是注册`bean`的销毁逻辑：

```java
// 忘了这个逻辑在哪的同学可以跳回3.0目录看下
registerDisposableBeanIfNecessary(beanName, bean, mbd);

protected void registerDisposableBeanIfNecessary(String beanName, Object bean, RootBeanDefinition mbd) {
    // 如果是非prototype且需要销毁的bean
    if (!mbd.isPrototype() && requiresDestruction(bean, mbd)) {
        // 如果是单例的
        if (mbd.isSingleton()) {
            // 直接包装成DisposableBeanAdapter且DefaultSingletonBeanRegistry
            // DefaultSingletonBeanRegistry#registerDisposableBean
            registerDisposableBean(beanName,
                                   new DisposableBeanAdapter(bean, beanName, mbd, getBeanPostProcessors(), acc));
        }
        else {
            // 如果是自定义的scope
            Scope scope = this.scopes.get(mbd.getScope());
            if (scope == null) {
                throw new IllegalStateException(...);
            }
            // 像scope注册
            scope.registerDestructionCallback(beanName,
                                              new DisposableBeanAdapter(bean, beanName, mbd, getBeanPostProcessors(), acc));
        }
    }
}
```

我们先看下`requiresDestruction`的逻辑：

```java
protected boolean requiresDestruction(Object bean, RootBeanDefinition mbd) {
    return (bean.getClass() != NullBean.class &&
            (DisposableBeanAdapter.hasDestroyMethod(bean, mbd) || (hasDestructionAwareBeanPostProcessors() &&
                                                                   DisposableBeanAdapter.hasApplicableProcessors(bean, getBeanPostProcessors()))));
}
```

逐一看一下`DisposableBeanAdapter`中的这两个方法：

```java
public static boolean hasDestroyMethod(Object bean, RootBeanDefinition beanDefinition) {
    // 如果实现了DisposableBean接口或者AutoCloseable接口
    // 认为有销毁方法
    if (bean instanceof DisposableBean || bean instanceof AutoCloseable) {
        return true;
    }
    // 获取beanDefinition中的destoryMethodName属性
    String destroyMethodName = beanDefinition.getDestroyMethodName();
    if (AbstractBeanDefinition.INFER_METHOD.equals(destroyMethodName)) {
        // 如果是一个特殊值-(inferred)，就看这个类有没有close或者shutdown方法
        return (ClassUtils.hasMethod(bean.getClass(), CLOSE_METHOD_NAME) ||
                ClassUtils.hasMethod(bean.getClass(), SHUTDOWN_METHOD_NAME));
    }
    // 看下有没有配置
    return StringUtils.hasLength(destroyMethodName);
}
// 如果容器中有注册DestructionAwareBeanPostProcessor，则还会有以下这个方法的判断
public static boolean hasApplicableProcessors(Object bean, List<BeanPostProcessor> postProcessors) {
    if (!CollectionUtils.isEmpty(postProcessors)) {
        for (BeanPostProcessor processor : postProcessors) {
            if (processor instanceof DestructionAwareBeanPostProcessor) {
                DestructionAwareBeanPostProcessor dabpp = (DestructionAwareBeanPostProcessor) processor;
                if (dabpp.requiresDestruction(bean)) {
                    return true;
                }
            }
        }
    }
    return false;
}
```

简单说一下，`InitDestroyAnnotationBeanPostProcessor`实现了`DestructionAwareBeanPostProcessor`，大家应该知道这个`requiresDestruction`的逻辑大概是怎么样了吧？

```java
@Override
public boolean requiresDestruction(Object bean) {
    // 就看有没有收集到销毁方法就好了
    return findLifecycleMetadata(bean.getClass()).hasDestroyMethods();
}
```

确定是一个需要销毁的单例`bean`之后，spring会把它包装成一个`DisposableBean`并且注册到`DefaultSingletonBeanRegistry`：

```java
public void registerDisposableBean(String beanName, DisposableBean bean) {
    synchronized (this.disposableBeans) {
        // 可以看到是一个map而已
        this.disposableBeans.put(beanName, bean);
    }
}
```

#### 3.5. `doCreateBean`小结

`doCreateBean`的逻辑我们讲完了，总体来讲，`doCreateBean`方法创建了一个可以直接使用的`bean`并返回给了调用方。回顾一下，它主要做了以下几件事：

1. 创建`bean`实例，可能是通过**工厂方法**或者**构造器**，且参数都支持依赖注入。
2. 依赖注入，解决`@Resource`、`@Autowired`等注解注入以及`beanDefinition`的`propertyValues`属性注入问题。
3. 初始化逻辑
   1. `XxxAware`接口调用
   2. 初始化方法调用，初始化注解(`@PostConstruct`)->初始化接口(`InitializingBean`)->`beanDefinition`的`initMethodName`属性（例如`xml`配置）
4. 注册单例`bean`的销毁逻辑

当然其中还有多个埋点方法的调用，这一部分我尽量之后补充一个时序图。

## 四、bean的销毁

刚刚我们有看到，实例化`bean`时，我们会注册一个销毁逻辑到对应的`scope`，而对于单例bean来讲，其实可以说单例的`scope`就是由`spring`提供的，这个时候我们是把需要销毁的`bean`包装成了一个`DisposableBeanAdapter`并注册到了`DefaultSingletonBeanRegistry`的`disposableBeans`容器中。

那么我们具体又是如何触发销毁方法的呢？我们随意找一个常用的`ApplicationContext`往上追踪，会发现它实现了`ConfigurableApplicationContext`接口，而这个接口中定义了销毁的`close`方法（`refresh`方法也是这个接口定义的）。我们找一个实现跟一下，会发现最终调用到了`DefaultSingletonBeanRegistry#destroySingletons`方法：

```java
public void AbstractApplicationContext#close() {
    // ...
    doClose();
    // ...
}
public void AbstractApplicationContext#doClose() {
    // ...
    destroyBeans();
    // ...
}
protected void AbstractApplicationContext#destroyBeans() {
    getBeanFactory().destroySingletons();
}
public void DefaultSingletonBeanRegistry#destroySingletons() {
    String[] disposableBeanNames;
    // 我们注册的disposableBeans
    synchronized (this.disposableBeans) {
        disposableBeanNames = StringUtils.toStringArray(this.disposableBeans.keySet());
    }
    for (int i = disposableBeanNames.length - 1; i >= 0; i--) {
        // 按注册的倒序销毁。主要是避免bean之间资源依赖，
        // 先创建的bean肯定不会依赖后创建的bean的资源，所以先创建的bean先销毁
        destroySingleton(disposableBeanNames[i]);
    }
}
public void DefaultSingletonBeanRegistry#destroySingleton(String beanName) {
    // 从IOC容器删除
    removeSingleton(beanName);

    // 从disposableBeans删除
    DisposableBean disposableBean;
    synchronized (this.disposableBeans) {
        disposableBean = (DisposableBean) this.disposableBeans.remove(beanName);
    }
    // 调用销毁方法
    destroyBean(beanName, disposableBean);
}
```

我们来看简单一下这个销毁方法：

```java
protected void destroyBean(String beanName, @Nullable DisposableBean bean) {
    // 先把它依赖的bean销毁
    Set<String> dependencies;
    synchronized (this.dependentBeanMap) {
        dependencies = this.dependentBeanMap.remove(beanName);
    }
    if (dependencies != null) {
        for (String dependentBeanName : dependencies) {
            destroySingleton(dependentBeanName);
        }
    }

    if (bean != null) {
        try {
            // 执行当前bean的销毁逻辑
            bean.destroy();
        }
        catch (Throwable ex) {
        }
    }
    // 跳过
}
```

依稀记得，我们之前注册进`disposableBeans`的，是包装成了一个`DisposableBeanAdapter`实例，那么我们来看一下它的`destroy`方法：

```java
public void destroy() {
    if (!CollectionUtils.isEmpty(this.beanPostProcessors)) {
        for (DestructionAwareBeanPostProcessor processor : this.beanPostProcessors) {
            // 这里明显就是去调用InitDestroyAnnotationBeanPostProcessor的逻辑了
            // 就不再跟了，跟初始化方法调用时一个套路
            processor.postProcessBeforeDestruction(this.bean, this.beanName);
        }
    }

    if (this.invokeDisposableBean) {
        try {
            // 调用实现了DisposableBean接口的bean的销毁方法
            ((DisposableBean) this.bean).destroy();
        }
        catch (Throwable ex) {
        }
    }
    // 调用beanDefinition中配置的销毁方法
    if (this.destroyMethod != null) {
        invokeCustomDestroyMethod(this.destroyMethod);
    }
    else if (this.destroyMethodName != null) {
        Method methodToInvoke = determineDestroyMethod(this.destroyMethodName);
        if (methodToInvoke != null) {
            invokeCustomDestroyMethod(ClassUtils.getInterfaceMethodIfPossible(methodToInvoke));
        }
    }
}
```

这个逻辑就很清晰了，而且调用顺序和初始化方法的调用顺序是一样的。具体`DisposableBeanAdapter`中的这些属性的值是哪来的，感兴趣的同学可以跟一下这个类的构造方法，也是蛮清晰的，这边就不跟了。

## 五、总结

到这里为止，可以说我们的`bean`的生命周期就讲完了。

对于bean的生命周期，我们可以分为两个阶段：

1. 初始化阶段：创建`bean`实例->注入`bean`依赖->执行`bean`的初始化方法（注解->接口->`beanDefinition`配置）
2. 销毁阶段：销毁当前`bean`依赖的`bean`->将当前`bean`从`IOC`容器移除->调用当前`bean`的销毁方法（注解->接口->`beanDefinition`配置）

我们现在按照`bean`的`scope`属性，来对`bean`的生命周期进行一个归纳总结：

1. 对于单例（`singleton`）的`bean`，`spring`管理其全生命周期，包括初始化阶段和销毁阶段。
2. 对应多例（`prototype`）的`bean`，spring只管理它的初始化阶段；销毁阶段有用户代码处理。
3. 其他自定义`scope`，`spring`管理其初始化阶段，并向调用`scope#registerDestructionCallback`注册`bean`的销毁逻辑，但销毁阶段的具体执行由该`scope`定义。

# 参考

> 作者：小希子
> 链接：https://juejin.im/post/6859672060789489672
> 来源：掘金
> 著作权归作者所有。商业转载请联系作者获得授权，非商业转载请注明出处。