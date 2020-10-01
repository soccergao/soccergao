# BeanDefinition

> 在Java中, 我们通过一个Class对象来描述一个类的信息, 比如方法、属性等信息, 在Spring中, 则是通过
> `BeanDefinition`来描述一个Bean对象的, 比如这个对象的作用域(单例/多例), 本文将会从`BeanDefinition`的顶层接口开始讲起, 指明每一个接口/类的作用, 从而能够从整体上看懂`BeanDefinition`的体系结构

``` java
public interface BeanDefinition extends AttributeAccessor, BeanMetadataElement {
	...
}
```

![BeanDefinition](C:\Users\gaoqiwei\Desktop\笔记\图片\BeanDefinition.png)

## AttributeAccessor

> `AttributeAccessor`接口定义了最基本的对任意对象的元数据的修改或者获取，主要方法有：

```java
public interface AttributeAccessor {
    
    
    // 将name定义的属性设置为提供的value值。如果value的值为null，则该属性为{@link #removeAttribute removed}。
	// 通常，用户应该注意通过使用完全限定的名称（可能使用类或包名称作为前缀）来防止与其他元数据属性重叠。
	void setAttribute(String name, @Nullable Object value);

    // 获取标识为name的属性的值。
	@Nullable
	Object getAttribute(String name);
 
    // 删除标识为name的属性，并返回属性值
	@Nullable
	Object removeAttribute(String name);

    // 如果名为name的属性是否存在，存在返回true，否则返回false。
	boolean hasAttribute(String name);

    // 返回所有属性的名称。
	String[] attributeNames();
}

分析: 由名字可以知道, 这就是一个属性的访问接口, 提供了对属性的访问、设置功能, 同样的, BeanDefiniton
也是间接的实现了这个接口的, 之所以要实现这个接口是为了存储一些属性, 这些属性不应该放入到Bean的定义
中, 即为了实现类的单一职责, BeanDefinition仅仅用来定义bean对象的公共属性, 对于特殊的bean对象, 如
果还需要其它属性的定义, 那么就应该通过AttributeAccessor接口提供的功能来实现
```

## BeanMetadataElement

```java
public interface BeanMetadataElement {

	//返回此元数据元素的配置源对象（可能为null）。
	@Nullable
	Object getSource();

}

分析: 该接口仅仅定义了一个getSource方法, 该方法用于返回一个source源, 其实就是返回一个Class文件在
      磁盘中的绝对路径而已, 在Spring中, BeanDefinition是间接的实现了这个接口的, 从而返回的是在
      BeanDefinition中定义的类的绝对路径

```

## BeanDefinition Method

```java
//标准单例作用域的作用域标识符：“singleton”。
//对于扩展的bean工厂可能支持更多的作用域。
String SCOPE_SINGLETON = ConfigurableBeanFactory.SCOPE_SINGLETON;
```

```java
//标准原型作用域的范围标识符：“prototype”。
//对于扩展的bean工厂可能支持更多的作用域。
String SCOPE_PROTOTYPE = ConfigurableBeanFactory.SCOPE_PROTOTYPE;
```

```java
//表示BeanDefinition是应用程序主要部分的角色提示。 通常对应于用户定义的bean。
int ROLE_APPLICATION = 0;
```

> ROLE_SUPPORT =1实际上就是说，我这个Bean是用户的，是从配置文件中过来的。

```java
//表示BeanDefinition是某些大型配置的支持部分的角色提示，通常是一个外部ComponentDefinition。
//当查看某个特定的ComponentDefinition时，认为bean非常重要，
//以便在查看应用程序的整体配置时能够意识到这一点。
int ROLE_SUPPORT = 1;
```

> ROLE_INFRASTRUCTURE = 2就是我这Bean是Spring自己的，和你用户没有一毛钱关系。

```java
//角色提示表明一个BeanDefinition是提供一个完全背景的角色，并且与最终用户没有关系。
//这个提示用于注册完全是ComponentDefinition内部工作的一部分的bean
int ROLE_INFRASTRUCTURE = 2;
```

> 上面是BeanDifinition的一些基本属性信息，一个就是标识下当前Bean的作用域，另外就是标识一下这个Bean是内部的还是外部的。下面来看这个接口为其子类都提供了哪些具体的行为方法：

1. 当前Bean父类名称get&set方法

```java
//如果父类存在，设置这个bean定义的父定义的名称。
void setParentName(String parentName);
//如果父类存在，则返回当前Bean的父类的名称
String getParentName();
```

2. 当前Bean的className get&set方法

```java
//指定此bean定义的bean类名称。
//类名称可以在bean factory后期处理中修改，通常用它的解析变体替换原来的类名称。
void setBeanClassName(String beanClassName);

//返回此bean定义的当前bean类名称。
//需要注意的是，这不一定是在运行时使用的实际类名，以防子类定义覆盖/继承其父类的类名。
//此外，这可能只是调用工厂方法的类，或者它 在调用方法的工厂bean引用的情况下甚至可能是空的。
//因此，不要认为这是在运行时定义的bean类型，而只是将其用于在单独的bean定义级别进行解析。
String getBeanClassName();
```

3. Bean的作用域get&set方法

```java
//覆盖此bean的目标范围，指定一个新的范围名称。
void setScope(String scope);
//返回此bean的当前目标作用域的名称，如果没有确定，返回null
String getScope();
```

4. 懒加载的get&set方法

```java
//设置这个bean是否应该被延迟初始化。如果{false}，那么这个bean将在启动时由bean工厂实例化，
//这些工厂执行单例的立即初始化。
//懒加载 <bean lazy-init="true/false">
void setLazyInit(boolean lazyInit);
//返回这个bean是否应该被延迟初始化，即不是在启动时立即实例化。只适用于单例bean。
boolean isLazyInit();
```

5. 依赖关系设置

```java
//设置这个bean依赖被初始化的bean的名字。 bean工厂将保证这些bean首先被初始化。
//<bean depends-on="">
void setDependsOn(String... dependsOn);
//返回这个bean依赖的bean名称。
String[] getDependsOn();
```

6. 是否是自动转配设置

```java
//设置这个bean是否是获得自动装配到其他bean的候选人。
//需要注意是，此标志旨在仅影响基于类型的自动装配。
//它不会影响按名称的显式引用，即使指定的bean没有标记为autowire候选，也可以解决这个问题。
//因此，如果名称匹配，通过名称的自动装配将注入一个bean。
void setAutowireCandidate(boolean autowireCandidate);

//返回这个bean是否是自动装配到其他bean的候选者。就是是否在其他类中使用autowired来注入当前Bean的
//是否为被自动装配 <bean autowire-candidate="true/false">
boolean isAutowireCandidate();
```

7. 主候选Bean

```java
//是否为主候选bean    使用注解：@Primary
void setPrimary(boolean primary);
//返回这个bean是否是主要的autowire候选者。
boolean isPrimary();
```

8. 定义创建该Bean对象的工厂类

```java
//指定要使用的工厂bean（如果有的话）。 这是调用指定的工厂方法的bean的名称。
void setFactoryBeanName(String factoryBeanName);
//返回工厂bean的名字，如果有的话。
String getFactoryBeanName();
```

9. 创建该Bean对象的工厂方法

```java
//如果有的话，指定工厂方法。
//这个方法先将通过构造函数参数被调用，或者如果参数，将调用该方法的无参数构造。
//方法将在指定的工厂bean（如果有的话）上被调用，或者作为本地bean类的静态方法被调用。
void setFactoryMethodName(String factoryMethodName);
//如果存在，返回工厂方法名
String getFactoryMethodName();
```

10. 返回此bean的构造函数参数值。

```java
//返回此bean的构造函数参数值。
ConstructorArgumentValues getConstructorArgumentValues();
```

11. 获取普通属性集合

```java
//获取普通属性集合
MutablePropertyValues getPropertyValues();
```

12. 当前Bean的基本特性

```java
//是否是单例的
boolean isSingleton();
//是否是多例的
boolean isPrototype();
//是否是抽象类
boolean isAbstract();
```

13. 当前Bean的应用

```java
//获取这个bean的应用
int getRole();
```

14. 可读描述

```java
//返回对bean定义的可读描述。
String getDescription();
```

```java
//返回该bean定义来自的资源的描述
String getResourceDescription();
```

```java
//返回原始的BeanDefinition;如果没有，则返回null。允许检索装饰的bean定义（如果有的话）。
//注意，这个方法返回直接的发起者。 迭代原始链，找到用户定义的原始BeanDefinition。
BeanDefinition getOriginatingBeanDefinition();
```



## BeanDefinition 实现类

### AbstractBeanDefinition

> 抽象类统一实现了`BeanDefinition`定义的一部分操作，可以说是定义了`BeanDefinition`很多默认的属性。 正是在`AbstractBeanDefinition`基础上， Spring衍生出了一些列`BeaDefinition`。

> 这里我们可以关注下重写的`equals()`,`hashcode()`, `toString()`方法

> 此外`initMethodName`属性，`destroyMethodName` 属性， 这两个属性bean的生命周期有关

### GenericBeanDefinition

### RootBeanDefinition

### ChildBeanDefinition

## BeanDefinitionBuilder

> `BeanDefinition`工具类

## BeanDefinitionHolder

具有名称和别名的`BeanDefinition`的持有人。 可以注册为内部bean的占位符。 还可以用于内部bean定义的程序化注册。

## BeanDefinitionReader

> 既可以使用`BeanDefinitionRegistry`构造。也可以通过`loadBeanDefinitions`把配置加载为多个`BeanDefinition`并注册到`BeanDefinitionRegistry`中。 可以说是高效版本的`BeanDefinitionRegistry`. 实现类有 `XmlBeanDefinitionReader`从xml中读取`BeanDefinition`； `PropertiesBeanDefinitionReader`从`Properties`文件读取`BeanDefinition`

## AnnotatedBeanDefinitionReader

> 对带有注解的`BeanDefinition`进行注册

## ClassPathBeanDefinitionScanner

> 可以扫描到`@Component` `@Repository` `@Service` `@Controller` 的BeanDefinition注册到容器中。

## BeanDefinitionRegistry

> `BeanDefinition` 的注册接口，如 `RootBeanDefinition` 和 `ChildBeanDefinition`。它通常由 `BeanFactories` 实现，在 Spring 中已知的实现者为：`DefaultListableBeanFactory` 和 `GenericApplicationContext`。`BeanDefinitionRegistry` 是 Spring 的 Bean 工厂包中唯一封装 `BeanDefinition` 注册的接口。

> `BeanDefinitionRegistry` 接口定义了关于 `BeanDefinition` 注册、注销、查询等一系列的操作。

```java
public interface BeanDefinitionRegistry extends AliasRegistry {

    // 注册 BeanDefinition
    void registerBeanDefinition(String beanName, BeanDefinition beanDefinition) throws BeanDefinitionStoreException;

    // 移除 BeanDefinition
    void removeBeanDefinition(String beanName) throws NoSuchBeanDefinitionException;

    // 获取 BeanDefinition
    BeanDefinition getBeanDefinition(String beanName) throws NoSuchBeanDefinitionException;

    // 根据 beanName 判断容器是否存在对应的 BeanDefinition 
    boolean containsBeanDefinition(String beanName);

    // 获取所有的 BeanDefinition
    String[] getBeanDefinitionNames();

    // 获取 BeanDefinition 数量
    int getBeanDefinitionCount();

    // 判断 beanName 是否被占用
    boolean isBeanNameInUse(String beanName);
}
```

> 该接口有三个实现类：DefaultListableBeanFactory、GenericApplicationContext、SimpleBeanDefinitionRegistry，其中 GenericApplicationContext 底层调用的是 DefaultListableBeanFactory 中的实现方法，所以严格意义上来说，只有两个实现类。这里，我们主要讨论 DefaultListableBeanFactory 中的方法实现。

### AliasRegistry

> **用于别名管理的通用型接口，作为 BeanDefinitionRegistry 的顶层接口。** AliasRegistry 定义了一些别名管理的方法。

```java
public interface AliasRegistry {
 void registerAlias(String name, String alias);
 void removeAlias(String alias);
 boolean isAlias(String name);
 String[] getAliases(String name);
}
```

### DefaultListableBeanFactory

> `DefaultListableBeanFactory`，`ConfigurableListableBeanFactory`（其实就是 `BeanFactory` ） 和 BeanDefinitionRegistry 接口的默认实现：一个基于 `BeanDefinition` 元数据的完整 bean 工厂。所以相对于 `SimpleBeanDefinitionRegistry` 而言，`DefaultListableBeanFactory` 则是一个具有注册功能的完整 bean 工厂。它同样是用 `ConcurrentHashMap` 数据结构来存储注册的 `BeanDefinition`。

```java
public class DefaultListableBeanFactory extends AbstractAutowireCapableBeanFactory implements ConfigurableListableBeanFactory, BeanDefinitionRegistry, Serializable {
    // 注册表，由 BeanDefinition 的标识 （beanName） 与其实例组成
    private final Map<String, BeanDefinition> beanDefinitionMap = new ConcurrentHashMap<String, bean>(64);

    // 标识（beanName）集合
    private final List<String> beanDefinitionNames = new ArrayList<String>(64);
    
    ...
}
```

### GenericApplicationContext

> 对于类 `GenericApplicationContext `，查看源码你会发现他实现注册、注销功能都是委托 `DefaultListableBeatnFactory` 实现的。

# BeanFactoryPostProcessor

```java
/**
 * Allows for custom modification of an application context's bean definitions,
 * adapting the bean property values of the context's underlying bean factory.
 *
 * <p>Application contexts can auto-detect BeanFactoryPostProcessor beans in
 * their bean definitions and apply them before any other beans get created.
 *
 * <p>Useful for custom config files targeted at system administrators that
 * override bean properties configured in the application context.
 *
 * <p>See PropertyResourceConfigurer and its concrete implementations
 * for out-of-the-box solutions that address such configuration needs.
 *
 * <p>A BeanFactoryPostProcessor may interact with and modify bean
 * definitions, but never bean instances. Doing so may cause premature bean
 * instantiation, violating the container and causing unintended side-effects.
 * If bean instance interaction is required, consider implementing
 * {@link BeanPostProcessor} instead.
 *
 * @author Juergen Hoeller
 * @since 06.07.2003
 * @see BeanPostProcessor
 * @see PropertyResourceConfigurer
 */
public interface BeanFactoryPostProcessor {

    /**
     * Modify the application context's internal bean factory after its standard
     * initialization. All bean definitions will have been loaded, but no beans
     * will have been instantiated yet. This allows for overriding or adding
     * properties even to eager-initializing beans.
     * @param beanFactory the bean factory used by the application context
     * @throws org.springframework.beans.BeansException in case of errors
     */
    void postProcessBeanFactory(ConfigurableListableBeanFactory beanFactory) throws BeansException;

}
```

## BeanDefinitionRegistryPostProcessor

```java
/**
 * Extension to the standard {@link BeanFactoryPostProcessor} SPI, allowing for
 * the registration of further bean definitions <i>before</i> regular
 * BeanFactoryPostProcessor detection kicks in. In particular,
 * BeanDefinitionRegistryPostProcessor may register further bean definitions
 * which in turn define BeanFactoryPostProcessor instances.
 *
 * @author Juergen Hoeller
 * @since 3.0.1
 * @see org.springframework.context.annotation.ConfigurationClassPostProcessor
 */
public interface BeanDefinitionRegistryPostProcessor extends BeanFactoryPostProcessor {

	/**
	 * Modify the application context's internal bean definition registry after its
	 * standard initialization. All regular bean definitions will have been loaded,
	 * but no beans will have been instantiated yet. This allows for adding further
	 * bean definitions before the next post-processing phase kicks in.
	 * @param registry the bean definition registry used by the application context
	 * @throws org.springframework.beans.BeansException in case of errors
	 */
	void postProcessBeanDefinitionRegistry(BeanDefinitionRegistry registry) throws BeansException;

}
```

`BeanDefinitionRegistryPostProcessor`是`BeanFactoryPostProcessor`的扩展。实现这个接口之类，会在`BeanFactoryPostProcessor`之前就被执行，`BeanDefinitionRegistryPostProcessor`可以注册更多的`bean definition`在`BeanFactoryPostProcessor`调用之前

### ConfigurationClassPostProcessor

#### 作用

- `ConfigurationClassPostProcessor`是一个`BeanFactory`的后置处理器，因此它的主要功能是参与`BeanFactory`的建造，在这个类中，会解析加了`@Configuration`的配置类，还会解析`@ComponentScan`、`@ComponentScans`注解扫描的包，以及解析`@Import`等注解。
- `ConfigurationClassPostProcessor` 实现了 `BeanDefinitionRegistryPostProcessor` 接口，而 `BeanDefinitionRegistryPostProcessor` 接口继承了 `BeanFactoryPostProcessor` 接口，所以 `ConfigurationClassPostProcessor` 中需要重写 `postProcessBeanDefinitionRegistry()` 方法和 `postProcessBeanFactory()`方法。而`ConfigurationClassPostProcessor`类的作用就是通过这两个方法去实现的。
- `ConfigurationClassPostProcessor`这个类是Spring内置的一个`BeanFactory`后置处理器，是在`this()`方法中将其添加到`BeanDefinitionMap`中的。在执行过程中，会先执行`postProcessBeanDefinitionRegistry()`，然后执行`postProcessBeanFactory()`。

#### postProcessBeanDefinitionRegistry()

- `postProcessBeanDefinitionRegistry()`方法中调用了`processConfigBeanDefinitions()`，所以核心逻辑在`processConfigBeanDefinition()`方法中。

```java
public void postProcessBeanDefinitionRegistry(BeanDefinitionRegistry registry){
    processConfigBeanDefinitions(registry);
}
```

> processConfigBeanDefinitions()方法代码如下(省略了部分不重要的代码)，源码中添加了许多注释，解释了部分重要方法的作用。

```java
public void processConfigBeanDefinitions(BeanDefinitionRegistry registry) {
	List<BeanDefinitionHolder> configCandidates = new ArrayList<>();
	String[] candidateNames = registry.getBeanDefinitionNames();

	for (String beanName : candidateNames) {
		BeanDefinition beanDef = registry.getBeanDefinition(beanName);
		if (ConfigurationClassUtils.isFullConfigurationClass(beanDef) ||
				ConfigurationClassUtils.isLiteConfigurationClass(beanDef)) {
			// log 日志
		}
        // checkConfigurationClassCandidate()会判断一个是否是一个配置类,并为BeanDefinition设置属性为lite或者full。
        // 在这儿为BeanDefinition设置lite和full属性值是为了后面在使用
        // 如果加了@Configuration，那么对应的BeanDefinition为full;
        // 如果加了@Bean,@Component,@ComponentScan,@Import,@ImportResource这些注解，则为lite。
        //lite和full均表示这个BeanDefinition对应的类是一个配置类
		else if (ConfigurationClassUtils.checkConfigurationClassCandidate(beanDef, this.metadataReaderFactory)) {
			configCandidates.add(new BeanDefinitionHolder(beanDef, beanName));
		}
	}
	// ... 省略部分代码
	SingletonBeanRegistry sbr = null;
	if (registry instanceof SingletonBeanRegistry) {
		sbr = (SingletonBeanRegistry) registry;
		if (!this.localBeanNameGeneratorSet) {
			// beanName的生成器，因为后面会扫描出所有加入到spring容器中calss类，然后把这些class
			// 解析成BeanDefinition类，此时需要利用BeanNameGenerator为这些BeanDefinition生成beanName
			BeanNameGenerator generator = (BeanNameGenerator) sbr.getSingleton(CONFIGURATION_BEAN_NAME_GENERATOR);
			if (generator != null) {
				this.componentScanBeanNameGenerator = generator;
				this.importBeanNameGenerator = generator;
			}
		}
	}
	// ... 省略部分代码

	// 解析所有加了@Configuration注解的类
	ConfigurationClassParser parser = new ConfigurationClassParser(
			this.metadataReaderFactory, this.problemReporter, this.environment,
			this.resourceLoader, this.componentScanBeanNameGenerator, registry);

	Set<BeanDefinitionHolder> candidates = new LinkedHashSet<>(configCandidates);
	Set<ConfigurationClass> alreadyParsed = new HashSet<>(configCandidates.size());
	do {
		// 解析配置类，在此处会解析配置类上的注解(ComponentScan扫描出的类，@Import注册的类，以及@Bean方法定义的类)
        // 注意：这一步只会将加了@Configuration注解以及通过@ComponentScan注解扫描的类才会加入到BeanDefinitionMap中
        // 通过其他注解(例如@Import、@Bean)的方式，在parse()方法这一步并不会将其解析为BeanDefinition放入到BeanDefinitionMap中，而是先解析成ConfigurationClass类
        // 真正放入到map中是在下面的this.reader.loadBeanDefinitions()方法中实现的
		parser.parse(candidates);
		parser.validate();

		Set<ConfigurationClass> configClasses = new LinkedHashSet<>(parser.getConfigurationClasses());
		configClasses.removeAll(alreadyParsed);

		// Read the model and create bean definitions based on its content
		if (this.reader == null) {
			this.reader = new ConfigurationClassBeanDefinitionReader(
					registry, this.sourceExtractor, this.resourceLoader, this.environment,
					this.importBeanNameGenerator, parser.getImportRegistry());
		}
		// 将上一步parser解析出的ConfigurationClass类加载成BeanDefinition
		// 实际上经过上一步的parse()后，解析出来的bean已经放入到BeanDefinition中了，但是由于这些bean可能会引入新的bean，例如实现了ImportBeanDefinitionRegistrar或者ImportSelector接口的bean，或者bean中存在被@Bean注解的方法
		// 因此需要执行一次loadBeanDefinition()，这样就会执行ImportBeanDefinitionRegistrar或者ImportSelector接口的方法或者@Bean注释的方法
		this.reader.loadBeanDefinitions(configClasses);
		alreadyParsed.addAll(configClasses);

		candidates.clear();
		// 这里判断registry.getBeanDefinitionCount() > candidateNames.length的目的是为了知道reader.loadBeanDefinitions(configClasses)这一步有没有向BeanDefinitionMap中添加新的BeanDefinition
		// 实际上就是看配置类(例如AppConfig类会向BeanDefinitionMap中添加bean)
		// 如果有，registry.getBeanDefinitionCount()就会大于candidateNames.length
		// 这样就需要再次遍历新加入的BeanDefinition，并判断这些bean是否已经被解析过了，如果未解析，需要重新进行解析
		// 这里的AppConfig类向容器中添加的bean，实际上在parser.parse()这一步已经全部被解析了
		// 所以为什么还需要做这个判断，目前没看懂，似乎没有任何意义。
		if (registry.getBeanDefinitionCount() > candidateNames.length) {
			String[] newCandidateNames = registry.getBeanDefinitionNames();
			Set<String> oldCandidateNames = new HashSet<>(Arrays.asList(candidateNames));
			Set<String> alreadyParsedClasses = new HashSet<>();
			for (ConfigurationClass configurationClass : alreadyParsed) {
				alreadyParsedClasses.add(configurationClass.getMetadata().getClassName());
			}
			// 如果有未解析的类，则将其添加到candidates中，这样candidates不为空，就会进入到下一次的while的循环中
			for (String candidateName : newCandidateNames) {
				if (!oldCandidateNames.contains(candidateName)) {
					BeanDefinition bd = registry.getBeanDefinition(candidateName);
					if (ConfigurationClassUtils.checkConfigurationClassCandidate(bd, this.metadataReaderFactory) &&
							!alreadyParsedClasses.contains(bd.getBeanClassName())) {
						candidates.add(new BeanDefinitionHolder(bd, candidateName));
					}
				}
			}
			candidateNames = newCandidateNames;
		}
	}
	while (!candidates.isEmpty());

	// Register the ImportRegistry as a bean in order to support ImportAware @Configuration classes
	if (sbr != null && !sbr.containsSingleton(IMPORT_REGISTRY_BEAN_NAME)) {
		sbr.registerSingleton(IMPORT_REGISTRY_BEAN_NAME, parser.getImportRegistry());
	}

	if (this.metadataReaderFactory instanceof CachingMetadataReaderFactory) {
		((CachingMetadataReaderFactory) this.metadataReaderFactory).clearCache();
	}
}

```

##### ConfigurationClassUtils.checkConfigurationClassCandidate()

- 该方法是用来判断一个是否是一个配置类，并为`BeanDefinition`设置属性为`lite`或者`full`。如果加了`@Configuration`，那么对应的`BeanDefinition`为`full`，如果加了`@Bean`，`@Component`，`@ComponentScan`，`@Import`，`@ImportResource`这些注解，则为`lite`。`lite`和`full`均表示这个`BeanDefinition`对应的类是一个配置类。

- 部分代码如下：

```java
public static boolean checkConfigurationClassCandidate(BeanDefinition beanDef, MetadataReaderFactory metadataReaderFactory) {
	// ... 省略部分不重要的代码
	if (isFullConfigurationCandidate(metadata)) {
		// 含有@Configuration注解，那么对应的BeanDefinition的configurationClass属性值设置为full
		beanDef.setAttribute(CONFIGURATION_CLASS_ATTRIBUTE, CONFIGURATION_CLASS_FULL);
	}
	else if (isLiteConfigurationCandidate(metadata)) {
		// 含有@Bean,@Component,@ComponentScan,@Import,@ImportResource注解
		// configurationClass属性值设置为lite
		beanDef.setAttribute(CONFIGURATION_CLASS_ATTRIBUTE, CONFIGURATION_CLASS_LITE);
	}
	else {
		return false;
	}
	return true;
}
```

- `isFullConfigurationCandidate()`方法用来判断一个类是否加了`@Configuration注解`

```java
// 含有@Configuration注解
public static boolean isFullConfigurationCandidate(AnnotationMetadata metadata) {
	return metadata.isAnnotated(Configuration.class.getName());
}
```

- `isLiteConfigurationCandidate()`方法用来判断类是否加了`@Bean,@Component,@ComponentScan,@Import,@ImportResource`注解

```java
// 判断是否含有candidateIndicators这个集合中的注解
public static boolean isLiteConfigurationCandidate(AnnotationMetadata metadata) {
	// candidateIndicators 是一个静态常量，在初始化时，包含了四个元素
	// 分别为@Component,@ComponentScan,@Import,@ImportResource这四个注解
	// 只要这个类上添加了这四种注解中的一个，就便是这个类是一个配置类，
	// 这个类对应的BeanDefinition中的configurationClass属性值为lite
	for (String indicator : candidateIndicators) {
		if (metadata.isAnnotated(indicator)) {
			return true;
		}
	}
        // 查找有没有加了@Bean注解的方法
	try {
		return metadata.hasAnnotatedMethods(Bean.class.getName());
	}
	catch (Throwable ex) {
		return false;
	}
}

private static final Set<String> candidateIndicators = new HashSet<>(8);

// 类加载至JVM时，向集合中添加了四个元素
static {
	candidateIndicators.add(Component.class.getName());
	candidateIndicators.add(ComponentScan.class.getName());
	candidateIndicators.add(Import.class.getName());
	candidateIndicators.add(ImportResource.class.getName());
}

```

##### parser.pase()

> 该方法调用的是`ConfigurationClassParser.parse()`，`ConfigurationClassParser`类，根据类名就能猜测出，这个类是用来解析配置类的。

- parse()方法会解析配置类上的注解(`ComponentScan`扫描出的类，`@Import`注册的类，以及`@Bean`方法定义的类)，解析完以后(解析成`ConfigurationClass`类)，会将解析出的结果放入到`parser`的`configurationClasses`这个属性中(这个属性是个`Map`)。`parse`会将`@Import`注解要注册的类解析为`BeanDefinition`，但是不会把解析出来的`BeanDefinition`放入到`BeanDefinitionMap`中，真正放入到`map`中是在这一行代码实现的: `this.reader.loadBeanDefinitions(configClasses)`
- 下面先看下`parse()`的具体代码`parser.parse(candidates)`， `parse()`方法需要一个参数，参数candidates是一个集合，集合中的元素个数由我们写的这一行代码决定：

```java
AnnotationConfigApplicationContext applicationContext = new AnnotationConfigApplicationContext(AppConfig.class);
```

- 在`AnnotationConfigApplicationContext`的构造方法中，我们传入了一个AppConfig类，那么candidates的大小为1，里面的元素为AppConfig类所对应的BeanDefinitionHolder(或者说是BeanDefinition,BeanDefinitionHolder只是将BeanDefinition封装了一下，可以简单的认为两者等价)。AnnotationConfigApplicationContext构造方法可以传入多个类，对应的candidates的大小等于这里传入类的个数(这种说法其实不太严谨，因为`AnnotationConfigApplicationContext.register()`方法也能像容器中注册配置类)

- parse()具体代码

```java
public void parse(Set<BeanDefinitionHolder> configCandidates) {
	this.deferredImportSelectors = new LinkedList<>();
    // 根据BeanDefinition类型的不同，调用parse()不同的重载方法
    // 实际上最终都是调用processConfigurationClass()方法
	for (BeanDefinitionHolder holder : configCandidates) {
		BeanDefinition bd = holder.getBeanDefinition();
		try {
			if (bd instanceof AnnotatedBeanDefinition) {
				parse(((AnnotatedBeanDefinition) bd).getMetadata(), holder.getBeanName());
			}else if (bd instanceof AbstractBeanDefinition && ((AbstractBeanDefinition) bd).hasBeanClass()) {
				parse(((AbstractBeanDefinition) bd).getBeanClass(), holder.getBeanName());
			}else {
				parse(bd.getBeanClassName(), holder.getBeanName());
			}
		}
	}
	// 处理延迟importSelector
	processDeferredImportSelectors();
}

```

###### processConfigurationClass() 核心代码

> 该方法的核心方法为doProcessConfigurationClass

```java
protected void processConfigurationClass(ConfigurationClass configClass) throws IOException {
	// 处理配置类，由于配置类可能存在父类(若父类的全类名是以java开头的，则除外)，所有需要将configClass变成sourceClass去解析，然后返回sourceClass的父类。
	// 如果此时父类为空，则不会进行while循环去解析，如果父类不为空，则会循环的去解析父类
	// SourceClass的意义：简单的包装类，目的是为了以统一的方式去处理带有注解的类，不管这些类是如何加载的
	// 如果无法理解，可以把它当做一个黑盒，不会影响看spring源码的主流程
	SourceClass sourceClass = asSourceClass(configClass);
	do {
    // 核心处理逻辑
		sourceClass = doProcessConfigurationClass(configClass, sourceClass);
	}
	while (sourceClass != null);
    // 将解析的配置类存储起来，这样回到parse()方法时，能取到值
	this.configurationClasses.put(configClass, configClass);
}
```

###### doProcessConfigurationClass()代码

> doProcessConfigurationClass()方法中，执行流程如下:

- (1) 处理内部类，如果内部类也是一个配置类(判断一个类是否是一个配置类，通过`ConfigurationClassUtils.checkConfigurationClassCandidate()`可以判断)。

- (2) 处理属性资源文件，加了`@PropertySource`注解。

- (3) 首先解析出类上的@ComponentScan和@ComponentScans注解，然后根据配置的扫描包路径，利用ASM技术(ASM技术是一种操作字节码的技术，有兴趣的朋友可以去网上了解下)扫描出所有需要交给Spring管理的类，由于扫描出的类中可能也被加了@ComponentScan和@ComponentScans注解，因此需要进行递归解析，直到所有加了这两个注解的类被解析完成。

- (4) 处理@Import注解。通过@Import注解，有三种方式可以将一个Bean注册到Spring容器中。

- (5) 处理@ImportResource注解，解析配置文件。

- (6) 处理加了@Bean注解的方法。

- (7) 通过`processInterfaces()`处理接口的默认方法，从JDK8开始，接口中的方法可以有自己的默认实现，因此，如果这个接口中的方法也加了@Bean注解，也需要被解析。(很少用)

- (8) 解析父类，如果被解析的配置类继承了某个类，那么配置类的父类也会被进行解析`doProcessConfigurationClass()`(父类是JDK内置的类例外，即全类名以java开头的)。

> 关于第(7)步，举个例子解释下。如下代码示例，`AppConfig`类加了`Configuration`注解，是一个配置类，且实现了`AppConfigInterface`接口，这个接口中有一个默认的实现方法(JDK8开始，接口中的方法可以有默认实现)，该方法上添加了`@Bean`注解。这个时候，经过第(7)步的解析，会想spring容器中添加一个`InterfaceMethodBean`类型的bean。

```java
@Configuration
public class AppConfig implements AppConfigInterface{
}

public interface AppConfigInterface {
	@Bean
	default InterfaceMethodBean interfaceMethodBean() {
		return new InterfaceMethodBean();
	}
}
```

> `doProcessConfigurationClass()`的源码如下，源码中加了中文注释

```java
protected final SourceClass doProcessConfigurationClass(ConfigurationClass configClass, SourceClass sourceClass)
		throws IOException {

	// 1、首先处理内部类，处理内部类时，最终还是调用doProcessConfigurationClass()方法
	processMemberClasses(configClass, sourceClass);
	// 2、处理属性资源文件，加了@PropertySource注解
	for (AnnotationAttributes propertySource : AnnotationConfigUtils.attributesForRepeatable(
			sourceClass.getMetadata(), PropertySources.class,
			org.springframework.context.annotation.PropertySource.class)) {
		if (this.environment instanceof ConfigurableEnvironment) {
			processPropertySource(propertySource);
		}
	}
	// 3、处理@ComponentScan或者@ComponentScans注解
	// 3.1 先找出类上的@ComponentScan和@ComponentScans注解的所有属性(例如basePackages等属性值)
	Set<AnnotationAttributes> componentScans = AnnotationConfigUtils.attributesForRepeatable(
			sourceClass.getMetadata(), ComponentScans.class, ComponentScan.class);
	if (!componentScans.isEmpty() &&
			!this.conditionEvaluator.shouldSkip(sourceClass.getMetadata(), ConfigurationPhase.REGISTER_BEAN)) {
		for (AnnotationAttributes componentScan : componentScans) {
			// 3.2 解析@ComponentScan和@ComponentScans配置的扫描的包所包含的类
			// 比如 basePackages = com.tiantang.study, 那么在这一步会扫描出这个包及子包下的class，然后将其解析成BeanDefinition
			// (BeanDefinition可以理解为等价于BeanDefinitionHolder)
			Set<BeanDefinitionHolder> scannedBeanDefinitions =
					this.componentScanParser.parse(componentScan, sourceClass.getMetadata().getClassName());
			// 3.3 通过上一步扫描包com.tiantang.com下的类，有可能扫描出来的bean中可能也添加了ComponentScan或者ComponentScans注解.
			//所以这里需要循环遍历一次，进行递归(parse)，继续解析，直到解析出的类上没有ComponentScan和ComponentScans
			// (这时3.1这一步解析出componentScans为空列表，不会进入到if语句，递归终止)
			for (BeanDefinitionHolder holder : scannedBeanDefinitions) {
				BeanDefinition bdCand = holder.getBeanDefinition().getOriginatingBeanDefinition();
				if (bdCand == null) {
					bdCand = holder.getBeanDefinition();
				}
				// 同样，这里会调用ConfigurationClassUtils.checkConfigurationClassCandidate()方法来判断类是否是一个配置类
				if (ConfigurationClassUtils.checkConfigurationClassCandidate(bdCand, this.metadataReaderFactory)) {
					parse(bdCand.getBeanClassName(), holder.getBeanName());
				}
			}
		}
	}
	// 4.处理Import注解注册的bean，这一步只会将import注册的bean变为ConfigurationClass,不会变成BeanDefinition
	// 而是在loadBeanDefinitions()方法中变成BeanDefinition，再放入到BeanDefinitionMap中
	// 关于Import注解,后面会单独写文章介绍
	processImports(configClass, sourceClass, getImports(sourceClass), true);

	// 5.处理@ImportResource注解引入的配置文件
	AnnotationAttributes importResource =
			AnnotationConfigUtils.attributesFor(sourceClass.getMetadata(), ImportResource.class);
	if (importResource != null) {
		String[] resources = importResource.getStringArray("locations");
		Class<? extends BeanDefinitionReader> readerClass = importResource.getClass("reader");
		for (String resource : resources) {
			String resolvedResource = this.environment.resolveRequiredPlaceholders(resource);
			configClass.addImportedResource(resolvedResource, readerClass);
		}
	}
	// 处理加了@Bean注解的方法
	Set<MethodMetadata> beanMethods = retrieveBeanMethodMetadata(sourceClass);
	for (MethodMetadata methodMetadata : beanMethods) {
		configClass.addBeanMethod(new BeanMethod(methodMetadata, configClass));
	}
	// ... 省略部分代码
	// No superclass -> processing is complete
	return null;
}

```

##### this.reader.loadBeanDefinitions()

> 该方法实际上是将通过`@Import`、`@Bean`等注解方式注册的类解析成`BeanDefinition`，然后注册到`BeanDefinitionMap`中。

```java
public void loadBeanDefinitions(Set<ConfigurationClass> configurationModel) {
	TrackedConditionEvaluator trackedConditionEvaluator = new TrackedConditionEvaluator();
	for (ConfigurationClass configClass : configurationModel) {
    // 循环调用loadBeanDefinitionsForConfigurationClass()
		loadBeanDefinitionsForConfigurationClass(configClass, trackedConditionEvaluator);
	}
}

private void loadBeanDefinitionsForConfigurationClass(
		ConfigurationClass configClass, TrackedConditionEvaluator trackedConditionEvaluator) {
	// 省略部分代码 ... 

	// 如果一个bean是通过@Import(ImportSelector)的方式添加到容器中的，那么此时configClass.isImported()返回的是true
	// 而且configClass的importedBy属性里面存储的是ConfigurationClass就是将bean导入的类
	// 这一步的目的是
	if (configClass.isImported()) {
		registerBeanDefinitionForImportedConfigurationClass(configClass);
	}
	// 判断当前的bean中是否含有@Bean注解的方法，如果有，需要把这些方法产生的bean放入到BeanDefinitionMap当中
	for (BeanMethod beanMethod : configClass.getBeanMethods()) {
		loadBeanDefinitionsForBeanMethod(beanMethod);
	}
	loadBeanDefinitionsFromImportedResources(configClass.getImportedResources());
	// 如果bean上存在@Import注解，且import的是一个实现了ImportBeanDefinitionRegistrar接口,则执行ImportBeanDefinitionRegistrar的registerBeanDefinitions()方法
	loadBeanDefinitionsFromRegistrars(configClass.getImportBeanDefinitionRegistrars());
}

```

#### postProcessBeanFactory()方法

> 该方法是对`BeanFactory`进行处理，用来干预`BeanFactory`的创建过程。主要干了两件事，(1)对加了`@Configuration`注解的类进行CGLIB代理。(2)向Spring中添加一个后置处理器`ImportAwareBeanPostProcessor`。

```java
public void postProcessBeanFactory(ConfigurableListableBeanFactory beanFactory) {
	int factoryId = System.identityHashCode(beanFactory);
	if (this.factoriesPostProcessed.contains(factoryId)) {
		throw new IllegalStateException(
				"postProcessBeanFactory already called on this post-processor against " + beanFactory);
	}
	this.factoriesPostProcessed.add(factoryId);
	// 下面的if语句不会进入，因为在执行BeanFactoryPostProcessor时，会先执行BeanDefinitionRegistryPostProcessor的postProcessorBeanDefinitionRegistry()方法
	// 而在执行postProcessorBeanDefinitionRegistry方法时，都会调用processConfigBeanDefinitions方法，这与postProcessorBeanFactory()方法的执行逻辑是一样的
	// postProcessorBeanFactory()方法也会调用processConfigBeanDefinitions方法，为了避免重复执行，所以在执行方法之前会先生成一个id，将id放入到一个set当中，每次执行之前
	// 先判断id是否存在，所以在此处，永远不会进入到if语句中
	if (!this.registriesPostProcessed.contains(factoryId)) {
		// BeanDefinitionRegistryPostProcessor hook apparently not supported...
		// Simply call processConfigurationClasses lazily at this point then.
		// 该方法在这里不会被执行到
		processConfigBeanDefinitions((BeanDefinitionRegistry) beanFactory);
	}
	// 对加了@Configuration注解的配置类进行Cglib代理
	enhanceConfigurationClasses(beanFactory);
	// 添加一个BeanPostProcessor后置处理器
	beanFactory.addBeanPostProcessor(new ImportAwareBeanPostProcessor(beanFactory));
}

```

##### CGLIB增强Configuration类

- 利用enhanceConfigurationClasses(beanFactory)方法对Configuration类进行增强，采用CGLIB来创建动态代理

```java
public void enhanceConfigurationClasses(ConfigurableListableBeanFactory beanFactory) {
	// 省去部分代码...
	ConfigurationClassEnhancer enhancer = new ConfigurationClassEnhancer();
	for (Map.Entry<String, AbstractBeanDefinition> entry : configBeanDefs.entrySet()) {
		// 省去部分代码...
        
        // 调用ConfigurationClassEnhancer.enhance()方法创建增强类
		Class<?> enhancedClass = enhancer.enhance(configClass, this.beanClassLoader);
		// 	省去部分代码...
	}
}

```

- ConfigurationClassEnhancer.enhance()方法

```java
public Class<?> enhance(Class<?> configClass, @Nullable ClassLoader classLoader) {
	// 省略部分代码。。。。
    // 核心代码为 newEnHancer()
	Class<?> enhancedClass = createClass(newEnhancer(configClass, classLoader));
	// 省略部分代码。。。。
	return enhancedClass;
}

```

- ConfigurationClassEnhancer.newEnhancer()方法

```java
private Enhancer newEnhancer(Class<?> configSuperClass, @Nullable ClassLoader classLoader) {
	Enhancer enhancer = new Enhancer();
    // CGLIB的动态代理基于继承
	enhancer.setSuperclass(configSuperClass);
    // 为新创建的代理对象设置一个父接口
	enhancer.setInterfaces(new Class<?>[] {EnhancedConfiguration.class});
	enhancer.setUseFactory(false);
	enhancer.setNamingPolicy(SpringNamingPolicy.INSTANCE);
	enhancer.setStrategy(new BeanFactoryAwareGeneratorStrategy(classLoader));
	// 添加了两个MethodInterceptor。(BeanMethodInterceptor和BeanFactoryAwareMethodInterceptor)
	// 通过这两个类的名称，可以猜出，前者是对加了@Bean注解的方法进行增强，后者是为代理对象的beanFactory属性进行增强
	// 被代理的对象，如何对方法进行增强呢？就是通过MethodInterceptor拦截器实现的
	// 类似于SpringMVC中的拦截器，每次执行请求时，都会对经过拦截器。
	// 同样，加了MethodInterceptor，那么在每次代理对象的方法时，都会先经过MethodInterceptor中的方法
	enhancer.setCallbackFilter(CALLBACK_FILTER);
	enhancer.setCallbackTypes(CALLBACK_FILTER.getCallbackTypes());
	return enhancer;
}

```

- `CGLIB`创建动态代理是基于继承来是实现的(JDK的动态代理是基于接口实现)，因此`enhancer.setSupperclass(configSuperClass)`这一行代码，就是为即将产生的代理对象设置父类，同时为产生的代理对象实现`EnhancedConfiguration.class`接口，实现该接口的目的，是为了该`Configuration`类在实例化、初始化过程中，执行相关的BeanPostProcessor。
- 例如在执行`ImportAwareBeanPostProcessor`后置处理器时，`postProcessPropertyValues()`方法，会对`EnhancedConfiguration`类进行属性设置，实际就是为`EnhancedConfiguration`实现类的`beanfactory`属性赋值

##### 添加ImportAwareBeanPostProcessor后置处理器

- `ConfigurationClassPostProcessor`类的`postProcessBeanFactory()`方法在最后会向spring容器中添加一个Bean后置处理器：`ImportAwareBeanPostProcessor`，Bean后置处理器最终会在Bean实例化和初始化的过程中执行，参与Bean的创建过程。在上面已经通过源码分析了该后置处理器`postProcessPropertyValues()`方法，其作用是为`EnhanceConfiguration`类的beanFactory属性赋值。
- `ImportAwareBeanPostProcessor`代码

```java
private static class ImportAwareBeanPostProcessor extends InstantiationAwareBeanPostProcessorAdapter {

	private final BeanFactory beanFactory;

	public ImportAwareBeanPostProcessor(BeanFactory beanFactory) {
		this.beanFactory = beanFactory;
	}

	@Override
	public PropertyValues postProcessPropertyValues(
			PropertyValues pvs, PropertyDescriptor[] pds, Object bean, String beanName) {
            // 为被CGLIB增强时实现了EnhancedConfiguration接口的代理类，设置beanFactory属性
		if (bean instanceof EnhancedConfiguration) {
			((EnhancedConfiguration) bean).setBeanFactory(this.beanFactory);
		}
		return pvs;
	}

	@Override
	public Object postProcessBeforeInitialization(Object bean, String beanName) {
		if (bean instanceof ImportAware) {
			ImportRegistry ir = this.beanFactory.getBean(IMPORT_REGISTRY_BEAN_NAME, ImportRegistry.class);
			AnnotationMetadata importingClass = ir.getImportingClassFor(bean.getClass().getSuperclass().getName());
			if (importingClass != null) {
				((ImportAware) bean).setImportMetadata(importingClass);
			}
		}
		return bean;
	}
}

```

#### 总结

- 本文主要分析了 `ConfigurationClassPostProcessor` 类的作用，由于该类实现了 `BeanFactoryPostProcessor` 接口和 `BeanDefinitionRegistryPostProcessor` 接口，所以会重写 `postProcessBeanDefinitionRegistry()` 方法和 `postProcessBeanFactory()` 方法。

- 在`postProcessBeanDefinitionRegistry()`方法中解析了加了`Configuration`注解的类，同时解析出 `@ComponentScan` 和 `@ComponentScans` 扫描出的Bean，也会解析出加了`@Bean` 注解的方法所注册的Bean，以及通过 `@Import` 注解注册的Bean和 `@ImportResource` 注解导入的配置文件中配置的Bean。在 `postProcessBeanDefinitionRegistry()` 方法中，通过源码分析了两个十分重要的方法:`ConfigurationClassParser.parse()`和`this.reader.loadBeanDefinitions()`

- 在`postProcessBeanFactory()`方法中，会利用CGLIB对加了`@Configuration`注解的类创建动态代理，进行增强。最后还会向spring容器中添加一个Bean后置处理器：`ImportAwareBeanPostProcessor`

## 参考

> 作者：glmapper
> 链接：https://juejin.im/post/6844903553820000269
> 来源：掘金
> 著作权归作者所有。商业转载请联系作者获得授权，非商业转载请注明出处。

> 作者：zhongshenglong
> 链接：https://juejin.im/post/6844904167933231117
> 来源：掘金
> 著作权归作者所有。商业转载请联系作者获得授权，非商业转载请注明出处。

> 作者：天堂同志
> 链接：https://juejin.im/post/6844903944146124808
> 来源：掘金
> 著作权归作者所有。商业转载请联系作者获得授权，非商业转载请注明出处。