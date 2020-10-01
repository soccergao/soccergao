# BeanFactory

在Spring官方文档中，称`org.springframework.context.ApplicationContext`这个接口就代表了Spring的容器，在解释`ApplicationContext`之前，必须要先介绍Spring容器的基石，`BeanFactory`接口。`ApplicationContext`就是继承了`BeanFactory`接口的一种高级容器接口。而`BeanFactory`是简单容器的代表，是Spring容器家族的基石，所有的容器都必须实现这个接口。

首先，先看一下`BeanFactory`接口的源码。

```java
package org.springframework.beans.factory;

public interface BeanFactory {
	/**
	 * 对FactoryBean的转移定义，提供获取FactoryBean实例的方法。
	 * 如果定义bean时是通过工厂模式配置Bean的，那么通过bean的名字检索FactoryBean时
	 * 得到的会是FactoryBean生产出来的实例，如果想得到工厂本身，需要进行转义
	 */
	String FACTORY_BEAN_PREFIX = "&";

	/**
	 * 不同的获取Bean的方法
	 */
	Object getBean(String name) throws BeansException;
	<T> T getBean(String name, Class<T> requiredType) throws BeansException;
	Object getBean(String name, Object... args) throws BeansException;
	<T> T getBean(Class<T> requiredType) throws BeansException;
	<T> T getBean(Class<T> requiredType, Object... args) throws BeansException;

	/**
	 * 获取Bean的提供者（工厂）
	 */
	<T> ObjectProvider<T> getBeanProvider(Class<T> requiredType);
	<T> ObjectProvider<T> getBeanProvider(ResolvableType requiredType);
	
	// 检索是否包含指定名字的bean
	boolean containsBean(String name);
	// 判断指定名字的bean是否为单例
	boolean isSingleton(String name) throws NoSuchBeanDefinitionException;
	// 判断指定名字的bean是否为原型
	boolean isPrototype(String name) throws NoSuchBeanDefinitionException;

	/**
	 * 指定名字的Bean是否匹配指定的类型
	 */
	boolean isTypeMatch(String name, ResolvableType typeToMatch) throws NoSuchBeanDefinitionException;
	boolean isTypeMatch(String name, Class<?> typeToMatch) throws NoSuchBeanDefinitionException;

	/**
	 * 获取指定名字的Bean的类型
	 */
	@Nullable
	Class<?> getType(String name) throws NoSuchBeanDefinitionException;
	@Nullable
	Class<?> getType(String name, boolean allowFactoryBeanInit) throws NoSuchBeanDefinitionException;

	// 获取指定名字Bean的所有别名
	String[] getAliases(String name);
}
```

可以看出，`BeanFactory`接口的源码并不复杂，主要规定了一些容器的基本功能，其中有7个获取Bean或者Bean提供者的方法，5个判断型的方法，2个获取类型的方法，1个获取别名的方法。通过这些方法，可以看出`BeanFactory`是一个典型的工厂模式的工厂接口。

**Spring框架的设计中，充满了通过上下继承关系来对基类进行功能扩充与功能分隔的类体系。** `BeanFactory`体系也是如此。

下面看一下在顶级容器接口的下面，Spring又做了哪些骚操作吧：

![DefaultListableBeanFactory](C:\Users\gaoqiwei\Desktop\笔记\图片\DefaultListableBeanFactory.png)

`BeanFactory`家族的核心成员主要就是上面的几个，其关系类图如图所示，`BeanFactory`位于家族顶层。这些接口和实现类，每一个都代表了对`BeanFactory`不同方向的功能扩展，下面逐一进行分析。

**顶级二级接口**：`ListableBeanFactory`和`HierarchicalBeanFactroy`。

## ListableBeanFactory

该接口拥有列出工厂中所有Bean的能力。

```java
public interface ListableBeanFactory extends BeanFactory {
	
	// 检索是否包含给定beanName的BeanDefinition
	boolean containsBeanDefinition(String beanName);
	// 获取工厂中BeanDefinition的数量
	int getBeanDefinitionCount();
	// 获取工厂中所有BeanDefinition的Names
	String[] getBeanDefinitionNames();
	// 获取指定类型的beanNames
	String[] getBeanNamesForType(ResolvableType type);
	String[] getBeanNamesForType(ResolvableType type, boolean includeNonSingletons, boolean allowEagerInit);
	String[] getBeanNamesForType(@Nullable Class<?> type);
	String[] getBeanNamesForType(@Nullable Class<?> type, boolean includeNonSingletons, boolean allowEagerInit);
	// 根据指定的类型来获取所有Bean
	<T> Map<String, T> getBeansOfType(@Nullable Class<T> type) throws BeansException;
	<T> Map<String, T> getBeansOfType(@Nullable Class<T> type, boolean includeNonSingletons, boolean allowEagerInit) throws BeansException;
	// 根据指定的类型直接获取beanNames
	String[] getBeanNamesForAnnotation(Class<? extends Annotation> annotationType);
	// 获取所有指定注解标注的Bean实例，Autowired就是使用的该接口
	Map<String, Object> getBeansWithAnnotation(Class<? extends Annotation> annotationType) throws BeansException;
	// 查找指定Bean中含有的注解类型
	@Nullable
	<A extends Annotation> A findAnnotationOnBean(String beanName, Class<A> annotationType)
			throws NoSuchBeanDefinitionException;

}
```

可以看出`ListableBeanFactory`主要对外提供了`批量`获取`Bean`和`BeanDefinition`的方法，拓展类了`BeanFactory`的功能，是一个非常重要的接口。

## HierarchicalBeanFactroy

顾名思义，这是一个分层的工厂。该接口实现了Bean工厂的分层。

```java
public interface HierarchicalBeanFactory extends BeanFactory {

	/**
	 * 返回父级工厂
	 */
	@Nullable
	BeanFactory getParentBeanFactory();

	/**
	 * 检索本地工厂是否包含指定名字的Bean
	 */
	boolean containsLocalBean(String name);

}
```

这个接口非常简单，也是继承自`BeanFactory`，虽然简单，但却提供了一个非常重要的功能——工厂分层。工厂分层有什么用呢？通过工厂分层，SpringIoC容器可以建立父子层级关联的容器体系，子容器可以访问父容器中的Bean，而父容器不能访问子容器中的Bean。在容器内，Bean的id必须是唯一的，但子容器可以拥有一个和父容器id相同的Bean。

父子容器层级体系增强了Spring容器架构的扩展性和灵活性，因为第三方可以通过编程的方式，为一个已经存在的容器添加一个或多个特殊用途的子容器，以提供一些额外的功能。

Spring使用父子容器实现了很多功能，比如在Spring MVC中，展现层Bean位于一个子容器中，而业务层和持久层的Bean位于父容器中。这样，展现层Bean就可以引用业务层和持久层的Bean，而业务层和持久层的Bean则看不到展现层的Bean。

## ConfigurableBeanFactory

 **复杂配置的Bean工厂**。

```java
public interface ConfigurableBeanFactory extends HierarchicalBeanFactory, SingletonBeanRegistry {
	...    
}
```

`ConfigurableBeanFactory`接口是一个继承了`HierarchicalBeanFactroy`的子接口，同时该接口还继承了`SingletonBeanRegistry`接口，`SingletonBeanRegistry`是一个用来注册单例类的接口，提供了同意访问单例Bean的功能，该接口的方法如下图：

```java
public interface SingletonBeanRegistry {
	void registerSingleton(String beanName, Object singletonObject);
	@Nullable
	Object getSingleton(String beanName);
	boolean containsSingleton(String beanName);
	String[] getSingletonNames();
	int getSingletonCount();
	Object getSingletonMutex();
}
```

 也就是说`ConfigurableBeanFactory`同时拥有了工厂分层和单例注册的功能，并且为了不辜负`ConfigurableBeanFactory`这个名字，该接口又继续扩展了几十个方法！加上继承来的方法，这个接口中的方法数量非常之多。

### 字段

```java
String SCOPE_SINGLETON = "singleton";//单例
String SCOPE_PROTOTYPE = "prototype";//多例
```

### 方法解析

> 设置父类容器

```java
void setParentBeanFactory(BeanFactory parentBeanFactory) throws IllegalStateException;
```

> 类加载器

```java
// 设置类加载器
void setBeanClassLoader(@Nullable ClassLoader beanClassLoader);
// 获取类加载器
ClassLoader getBeanClassLoader();
// 设置临时加载器，如果涉及到加载时编织，通常只指定一个临时类装入器，以确保实际的bean类被尽可能延迟地装入
void setTempClassLoader(@Nullable ClassLoader tempClassLoader);
// 获取临时加载器
ClassLoader getTempClassLoader();
```

> bean的元数据缓存，默认为true。如果为false，每次创建bean都要从类加载器获取信息。

```java
// 设置是否缓存
void setCacheBeanMetadata(boolean cacheBeanMetadata);
// 获取是否缓存
boolean isCacheBeanMetadata();
```

> bean的表达式解析器

```java
// 设置表达式解析器
void setBeanExpressionResolver(@Nullable BeanExpressionResolver resolver);
// 获取表达式解析器
BeanExpressionResolver getBeanExpressionResolver();
```

> 类型转换器

```java
// 设置类型转换器
void setConversionService(@Nullable ConversionService conversionService);
// 获取类型转换器
ConversionService getConversionService();
```

>  属性编辑器

```java
// 添加属性编辑器
void addPropertyEditorRegistrar(PropertyEditorRegistrar registrar);
// 注册给定类型的属性编辑器
void registerCustomEditor(Class<?> requiredType, Class<? extends PropertyEditor> propertyEditorClass);
// 使用在这个BeanFactory中注册的自定义编辑器初始化给定的PropertyEditorRegistry
void copyRegisteredEditorsTo(PropertyEditorRegistry registry);
```

> 类型转换器

```java
// 设置类型转换器
void setTypeConverter(TypeConverter typeConverter);
// 获取类型转换器
TypeConverter getTypeConverter();
```

> 为嵌入的值(如注释属性)添加字符串解析器

```java
// 添加
void addEmbeddedValueResolver(StringValueResolver valueResolver);
// 是否有
boolean hasEmbeddedValueResolver();
// 解析给定的嵌入值
String resolveEmbeddedValue(String value);
```

> 后置处理器，BeanPostProcessor

```java
// 增加后置处理器
void addBeanPostProcessor(BeanPostProcessor beanPostProcessor);
// 获取后置处理器的个数
int getBeanPostProcessorCount();
```

> 作用域

```java
// 注册作用域
void registerScope(String scopeName, Scope scope);
// 获取作用域，除了单例和多例
String[] getRegisteredScopeNames();
// 通过名称获取作用域
Scope getRegisteredScope(String scopeName);
```

> 安全作用域

```java
// 获取安全作用域
AccessControlContext getAccessControlContext();
```

> 配置复制。复制内容包括所有标准配置设置以及beanpostprocessor、作用域和特定于工厂的内部设置。不应该包含任何实际bean定义的元数据，例如BeanDefinition对象和bean名称别名。

```java
void copyConfigurationFrom(ConfigurableBeanFactory otherFactory);
```

> 别名

```java
// 注册别名
void registerAlias(String beanName, String alias) throws BeanDefinitionStoreException;
// 根据valueResolver移除别名
void resolveAliases(StringValueResolver valueResolver);
```

> BeanDefinition

```java
// 合并bean的定义，包括父类继承下来的
BeanDefinition getMergedBeanDefinition(String beanName) throws NoSuchBeanDefinitionException;
```

> FactoryBean

```java
// 是否是FactoryBean
boolean isFactoryBean(String name) throws NoSuchBeanDefinitionException;
```

> 正在创建的bean

```java
// 设置bean是否在创建，循环依赖的时候要靠这个解决
void setCurrentlyInCreation(String beanName, boolean inCreation);
boolean isCurrentlyInCreation(String beanName);
```

> 依赖的bean

```java
// 注册一个指定bean的依赖bean
void registerDependentBean(String beanName, String dependentBeanName);
// 获取依赖指定bean的所有bean
String[] getDependentBeans(String beanName);
// 获取指定bean的所有依赖
String[] getDependenciesForBean(String beanName);
```

> 销毁bean

```java
// 销毁指定的bean
void destroyBean(String beanName, Object beanInstance);
// 销毁指定范围的bean
void destroyScopedBean(String beanName);
// 销毁所有的单例bean
void destroySingletons();
```

该接口主要扩展了一些复杂的对单例Bean的配置与操作，虽然这个接口并没有被`ApplicationContext`高级容器体系所继承，但是一般的容器实现类都会继承或实现这个接口，目的是使用一种统一的方式对外暴露管理单例Bean的方式。

## AutowireCapableBeanFactory

自动装配工厂。`AutowireCapableBeanFactory`实现了`BeanFactory`接口，负责bean生命周期的管理。

```java
public interface AutowireCapableBeanFactory extends BeanFactory {
	...
}
```

### 字段

```java
int AUTOWIRE_NO = 0;//表示没有外部定义的自动装配
int AUTOWIRE_BY_NAME = 1;//通过名称指示自动装配bean属性(适用于Bean所有属性的setter)
int AUTOWIRE_BY_TYPE = 2;//通过类型指示自动装配bean属性(适用于Bean所有属性的setter)
int AUTOWIRE_CONSTRUCTOR = 3;//构造函数
int AUTOWIRE_AUTODETECT = 4;//通过bean类的内省确定适当的自动装配策略,已弃用
String ORIGINAL_INSTANCE_SUFFIX = ".ORIGINAL";//用于没有代理的时候，也能强制返回实例
```

### 方法解析

> bean的创建

```java
//autowireMode就是上面的常量，dependencyCheck是否对依赖进行检查
Object createBean(Class<?> beanClass, int autowireMode, boolean dependencyCheck) throws BeansException;
<T> T createBean(Class<T> beanClass) throws BeansException;
```

> bean的初始化

```java
Object initializeBean(Object existingBean, String beanName) throws BeansException;
```

> bean的后置处理器

```java
Object applyBeanPostProcessorsAfterInitialization(Object existingBean, String beanName)
            throws BeansException;
Object applyBeanPostProcessorsBeforeInitialization(Object existingBean, String beanName)
            throws BeansException;
```

> bean的销毁

```java
void destroyBean(Object existingBean);
```

> 自动装配bean

```java
Object autowire(Class<?> beanClass, int autowireMode, boolean dependencyCheck) throws BeansException;
void autowireBean(Object existingBean) throws BeansException;
void autowireBeanProperties(Object existingBean, int autowireMode, boolean dependencyCheck)
            throws BeansException;
```

> 配置bean

```java
Object configureBean(Object existingBean, String beanName) throws BeansException;
```

> 解析bean

```java
Object resolveBeanByName(String name, DependencyDescriptor descriptor) throws BeansException;
Object resolveDependency(DependencyDescriptor descriptor, @Nullable String requestingBeanName) throws BeansException;
Object resolveDependency(DependencyDescriptor descriptor, @Nullable String requestingBeanName,
            @Nullable Set<String> autowiredBeanNames, @Nullable TypeConverter typeConverter) throws BeansException;
<T> NamedBeanHolder<T> resolveNamedBean(Class<T> requiredType) throws BeansException;
```

## ConfigurableListableBeanFactory

```java
public interface ConfigurableListableBeanFactory
		extends ListableBeanFactory, AutowireCapableBeanFactory, ConfigurableBeanFactory {
	...
}
```

ConfigurableListableBeanFactory继承了`ListableBeanFactory`, `AutowireCapableBeanFactory`, `ConfigurableBeanFactory`。在`ConfigurableBeanFactory`的基础上，它还提供了分析和修改bean定义以及预实例化单例的工具。

### 方法解析

> 忽略自动装配

```java
// 在装配的时候忽略指定的依赖类型
void ignoreDependencyType(Class<?> type);
// 在装配的时候忽略指定的接口
void ignoreDependencyInterface(Class<?> ifc);
```

> 依赖

```java
// 注册可解析的依赖
void registerResolvableDependency(Class<?> dependencyType, @Nullable Object autowiredValue);
// 指定的bean是否可以作为自动选派的候选，
boolean isAutowireCandidate(String beanName, DependencyDescriptor descriptor)
            throws NoSuchBeanDefinitionException;
```

> BeanDefinition

```java
// 根据bean名称获取BeanDefinition
BeanDefinition getBeanDefinition(String beanName) throws NoSuchBeanDefinitionException;
/ /获取bean名称的Iterator
Iterator<String> getBeanNamesIterator()
```

> bean的元数据缓存

```java
void clearMetadataCache();
```

> 冻结bean的配置

```java
// 冻结所有bean定义，表明注册的bean定义将不再修改或后期处理。
void freezeConfiguration();
// bean的定义是否被冻结
boolean isConfigurationFrozen();
```

> lazy-init相关

```java
// 非延迟加载的bean都实例化
void preInstantiateSingletons() throws BeansException;
```

## AbstractBeanFactory

> `AbstractBeanFactory`这个抽象类是Spring容器体系中最重要的一个抽象类，该抽象类实现了BeanFactory重要的二级接口`ConfigurableBeanFactory`，实现了其中的绝大多数基本方法，实现了Bean工厂的许多重要功能，如对BeanDefinition、原型、单例Bean的各种操作。

> 这里需要多拓展一步，更加深入对`AbstractBeanFactory`的了解，从源码中我们可以发现，`AbstractBeanFactory`其实还继承了另外一个抽象类——`FactoryBeanRegistrySupport`。这个继承体系是Spring的AliasRegistry体系，也就是别名注册接口体系。`AbstractBeanFactory`既然继承了这个体系，说明容器本身也是个别名注册器、FactroyBean注册器和单例Bean注册器，也会维护别名注册表、支持FactroyBean的注册和单例Bean注册的各种操作（注册、获取、移除、销毁等）。

## DefaultListableBeanFactory

> `DefaultListableBeanFactory`类是Spring提供的默认简单容器实现类，也是从BeanFactory接口一路继承与实现下来的第一个可以独立运行的容器类，该类间接继承了`AbstractBeanFactory`抽象类，同时还实现了Spring集大成的容器接口——`ConfigurableListableBeanFactory` 接口，这保证了`DefaultListableBeanFactory`完整实现了简单容器中对Bean的各种操作功能。

> 而且我们还在源码中发现，`DefaultListableBeanFactory`同时还实现了`BeanDefinitionRegistry`接口。正是因为实现了此接口，所以`DefaultListableBeanFactory`也是一个BeanDefinition注册器，拥有了注册BeanDefinition的作用。可以从源码中发现，`DefaultListableBeanFactory`中维护了一个`beanDefinitionMap`，即BeanDefinition注册表。

# ApplicationContext

# 参考

> 作者：[星如月勿忘初心](https://cloud.tencent.com/developer/user/2960573)
> 链接：https://cloud.tencent.com/developer/article/1672254
> 来源：腾讯云
> 著作权归作者所有。商业转载请联系作者获得授权，非商业转载请注明出处。

> 作者：大军
> 链接：https://segmentfault.com/a/1190000020898453、https://segmentfault.com/a/1190000020896558
> 来源：segmentfault
> 著作权归作者所有。商业转载请联系作者获得授权，非商业转载请注明出处。