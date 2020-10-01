# Environment

## Environment类体系

![](C:\Users\gaoqiwei\Desktop\笔记\图片\environment类体系.jpg)

- `PropertyResolver`：提供属性访问功能。
- `ConfigurablePropertyResolver`：继承自`PropertyResolver`，额外主要提供属性类型转换(基于`org.springframework.core.convert.ConversionService`)功能。
- `Environment`：继承自`PropertyResolver`，额外提供访问和判断profiles的功能。
- `ConfigurableEnvironment`：继承自`ConfigurablePropertyResolver`和`Environment`，并且提供设置激活的profile和默认的profile的功能。

* `ConfigurableWebEnvironment`：继承自`ConfigurableEnvironment`，并且提供配置`Servlet`上下文和`Servlet`参数的功能。

- `AbstractEnvironment`：实现了`ConfigurableEnvironment`接口，默认属性和存储容器的定义，并且实现了`ConfigurableEnvironment`种的方法，并且为子类预留可覆盖了扩展方法。
- `StandardEnvironment`：继承自`AbstractEnvironment`，非`Servlet`(Web)环境下的标准`Environment`实现。
- `StandardServletEnvironment`：继承自`StandardEnvironment`，`Servlet`(Web)环境下的标准`Environment`实现。



## Environment的存储容器

### PropertySource

`Environment`的静态属性和存储容器都是在`AbstractEnvironment`中定义的，`ConfigurableWebEnvironment`接口提供的`getPropertySources()`方法可以获取到返回的`MutablePropertySources`实例，然后添加额外的`PropertySource`。实际上，`Environment`的存储容器就是`org.springframework.core.env.PropertySource`的子类集合，`AbstractEnvironment`中使用的实例是`org.springframework.core.env.MutablePropertySources`，下面看下`PropertySource`的源码：

``` java
public abstract class PropertySource<T> {

	protected final Log logger = LogFactory.getLog(getClass());

	protected final String name;

	protected final T source;

    public PropertySource(String name, T source) {
		Assert.hasText(name, "Property source name must contain at least one character");
		Assert.notNull(source, "Property source must not be null");
		this.name = name;
		this.source = source;
	}

    @SuppressWarnings("unchecked")
	public PropertySource(String name) {
		this(name, (T) new Object());
	}

    public String getName() {
		return this.name;
	}

	public T getSource() {
		return this.source;
	} 

	public boolean containsProperty(String name) {
		return (getProperty(name) != null);
	} 

	@Nullable
	public abstract Object getProperty(String name);     

 	@Override
	public boolean equals(Object obj) {
		return (this == obj || (obj instanceof PropertySource &&
				ObjectUtils.nullSafeEquals(this.name, ((PropertySource<?>) obj).name)));
	}  

	@Override
	public int hashCode() {
		return ObjectUtils.nullSafeHashCode(this.name);
	}  
//省略其他方法和内部类的源码            
}
```

源码相对简单，预留了一个`getProperty`抽象方法给子类实现，**重点需要关注的是覆写了的`equals`和`hashCode`方法，实际上只和`name`属性相关，这一点很重要，说明一个PropertySource实例绑定到一个唯一的name，这个name有点像HashMap里面的key**，部分移除、判断方法都是基于name属性。`PropertySource`的最常用子类是`MapPropertySource`、`PropertiesPropertySource`、`ResourcePropertySource`、`StubPropertySource`、`ComparisonPropertySource`：

- `MapPropertySource`：source指定为Map实例的`PropertySource`实现。
- `PropertiesPropertySource`：source指定为`Map`实例的`PropertySource`实现，内部的`Map`实例由`Properties`实例转换而来。
- `ResourcePropertySource`：继承自`PropertiesPropertySource`，source指定为通过`Resource`实例转化为`Properties`再转换为Map实例。
- `SystemEnvironmentPropertySource` : 继承自`MapPropertySource`，它的source也是一个map，但来源于系统环境。 与`MapPropertySource`不同的是，取值时它将会忽略大小写，”.”和”_”将会转化。
- `CompositePropertySource` : 内部可以保存多个`PropertySource`, 取值时依次遍历这些`PropertySource`
- ` MutablePropertySources` : 它包含了一个`CopyOnWriteArrayLis`t集合，用来包含多个`PropertySource`
- `StubPropertySource`：`PropertySource`的一个内部类，source设置为null，实际上就是空实现。
- `ComparisonPropertySource`：继承自`StubPropertySource`，所有属性访问方法强制抛出异常，作用就是一个不可访问属性的空实现。



`PropertySource`类体系

![](C:\Users\gaoqiwei\Desktop\笔记\图片\propertysource类体系.jpg)



### PropertySource顺序

Spring Boot uses a very particular `PropertySource` order that is designed to allow sensible overriding of values. Properties are considered in the following order:

1. [Devtools global settings properties](https://docs.spring.io/spring-boot/docs/2.3.1.RELEASE/reference/html/using-spring-boot.html#using-boot-devtools-globalsettings) in the `$HOME/.config/spring-boot` directory when devtools is active.
2. [`@TestPropertySource`](https://docs.spring.io/spring/docs/5.2.7.RELEASE/javadoc-api/org/springframework/test/context/TestPropertySource.html) annotations on your tests.
3. `properties` attribute on your tests. Available on [`@SpringBootTest`](https://docs.spring.io/spring-boot/docs/2.3.1.RELEASE/api/org/springframework/boot/test/context/SpringBootTest.html) and the [test annotations for testing a particular slice of your application](https://docs.spring.io/spring-boot/docs/2.3.1.RELEASE/reference/html/spring-boot-features.html#boot-features-testing-spring-boot-applications-testing-autoconfigured-tests).
4. Command line arguments.
5. Properties from `SPRING_APPLICATION_JSON` (inline JSON embedded in an environment variable or system property).
6. `ServletConfig` init parameters.
7. `ServletContext` init parameters.
8. JNDI attributes from `java:comp/env`.
9. Java System properties (`System.getProperties()`).
10. OS environment variables.
11. A `RandomValuePropertySource` that has properties only in `random.*`.
12. [Profile-specific application properties](https://docs.spring.io/spring-boot/docs/2.3.1.RELEASE/reference/html/spring-boot-features.html#boot-features-external-config-profile-specific-properties) outside of your packaged jar (`application-{profile}.properties` and YAML variants).
13. [Profile-specific application properties](https://docs.spring.io/spring-boot/docs/2.3.1.RELEASE/reference/html/spring-boot-features.html#boot-features-external-config-profile-specific-properties) packaged inside your jar (`application-{profile}.properties` and YAML variants).
14. Application properties outside of your packaged jar (`application.properties` and YAML variants).
15. Application properties packaged inside your jar (`application.properties` and YAML variants).
16. [`@PropertySource`](https://docs.spring.io/spring/docs/5.2.7.RELEASE/javadoc-api/org/springframework/context/annotation/PropertySource.html) annotations on your `@Configuration` classes. Please note that such property sources are not added to the `Environment` until the application context is being refreshed. This is too late to configure certain properties such as `logging.*` and `spring.main.*` which are read before refresh begins.
17. Default properties (specified by setting `SpringApplication.setDefaultProperties`).

> 参考spring-boot官方文档(Externalized Configuration): https://docs.spring.io/spring-boot/docs/2.3.1.RELEASE/reference/html/spring-boot-features.html#boot-features-web-environment

## Environment加载过程

Environment加载的源码位于`SpringApplication#prepareEnvironment`：

``` java
private ConfigurableEnvironment prepareEnvironment(
			SpringApplicationRunListeners listeners,
			ApplicationArguments applicationArguments) {
    // Create and configure the environment
    //创建ConfigurableEnvironment实例
    ConfigurableEnvironment environment = getOrCreateEnvironment();
    //启动参数绑定到ConfigurableEnvironment中
    configureEnvironment(environment, applicationArguments.getSourceArgs());
    //发布ConfigurableEnvironment准备完毕事件
    listeners.environmentPrepared(environment);
    //绑定ConfigurableEnvironment到当前的SpringApplication实例中
    bindToSpringApplication(environment);
    //这一步是非SpringMVC项目的处理，暂时忽略
    if (this.webApplicationType == WebApplicationType.NONE) {
        environment = new EnvironmentConverter(getClassLoader())
            .convertToStandardEnvironmentIfNecessary(environment);
    }
    //绑定ConfigurationPropertySourcesPropertySource到ConfigurableEnvironment中，name为configurationProperties，实例是SpringConfigurationPropertySources，属性实际是ConfigurableEnvironment中的MutablePropertySources
    ConfigurationPropertySources.attach(environment);
    return environment;
}
```

这里重点看下`getOrCreateEnvironment`方法：

``` java
private ConfigurableEnvironment getOrCreateEnvironment() {
	if (this.environment != null) {
		return this.environment;
	}
    //在SpringMVC项目，ConfigurableEnvironment接口的实例就是新建的StandardServletEnvironment实例
	if (this.webApplicationType == WebApplicationType.SERVLET) {
		return new StandardServletEnvironment();
	}
	return new StandardEnvironment();
}
//REACTIVE_WEB_ENVIRONMENT_CLASS=org.springframework.web.reactive.DispatcherHandler
//MVC_WEB_ENVIRONMENT_CLASS=org.springframework.web.servlet.DispatcherServlet
//MVC_WEB_ENVIRONMENT_CLASS={"javax.servlet.Servlet","org.springframework.web.context.ConfigurableWebApplicationContext"}
//这里，默认就是WebApplicationType.SERVLET
private WebApplicationType deduceWebApplicationType() {
	if (ClassUtils.isPresent(REACTIVE_WEB_ENVIRONMENT_CLASS, null)
		&& !ClassUtils.isPresent(MVC_WEB_ENVIRONMENT_CLASS, null)) {
		return WebApplicationType.REACTIVE;
	}
	for (String className : WEB_ENVIRONMENT_CLASSES) {
		if (!ClassUtils.isPresent(className, null)) {
			return WebApplicationType.NONE;
		}
	}
	return WebApplicationType.SERVLET;
}
```

还有一个地方要重点关注：发布`ConfigurableEnvironment`准备完毕事件`listeners.environmentPrepared(environment)`，实际上这里用到了同步的EventBus，事件的监听者是`ConfigFileApplicationListener`，具体处理逻辑是`onApplicationEnvironmentPreparedEvent`方法：

``` java
private void onApplicationEnvironmentPreparedEvent(
			ApplicationEnvironmentPreparedEvent event) {
	List<EnvironmentPostProcessor> postProcessors = loadPostProcessors();
	postProcessors.add(this);
	AnnotationAwareOrderComparator.sort(postProcessors);
    //遍历所有的EnvironmentPostProcessor对Environment实例进行处理
	for (EnvironmentPostProcessor postProcessor : postProcessors) {
		postProcessor.postProcessEnvironment(event.getEnvironment(),
					event.getSpringApplication());
	}
}

//从spring.factories文件中加载，一共有四个实例
//ConfigFileApplicationListener
//CloudFoundryVcapEnvironmentPostProcessor
//SpringApplicationJsonEnvironmentPostProcessor
//SystemEnvironmentPropertySourceEnvironmentPostProcessor
List<EnvironmentPostProcessor> loadPostProcessors() {
	return SpringFactoriesLoader.loadFactories(EnvironmentPostProcessor.class,
				getClass().getClassLoader());
}
```

实际上，处理工作大部分都在`ConfigFileApplicationListener`中，见它的`postProcessEnvironment`方法：

``` java
public void postProcessEnvironment(ConfigurableEnvironment environment,
			SpringApplication application) {
	addPropertySources(environment, application.getResourceLoader());
}

protected void addPropertySources(ConfigurableEnvironment environment,
			ResourceLoader resourceLoader) {
	RandomValuePropertySource.addToEnvironment(environment);
	new Loader(environment, resourceLoader).load();
}
```

主要的配置环境加载逻辑在内部类`Loader`，`Loader`会匹配多个路径下的文件把属性加载到`ConfigurableEnvironment`中，加载器主要是`PropertySourceLoader`的实例，例如我们用到application-${profile}.yaml文件做应用主配置文件，使用的是`YamlPropertySourceLoader`，这个时候activeProfiles也会被设置到`ConfigurableEnvironment`中。加载完毕之后，`ConfigurableEnvironment`中基本包含了所有需要加载的属性(activeProfiles是这个时候被写入`ConfigurableEnvironment`)。值得注意的是，几乎所有属性都是key-value形式存储，如xxx.yyyy.zzzzz=value、xxx.yyyy[0].zzzzz=value-1、xxx.yyyy[1].zzzzz=value-2。`Loader`中的逻辑相对复杂，有比较多的遍历和过滤条件，这里不做展开。

## Environment属性访问

上文提到过，都是委托到`PropertySourcesPropertyResolver`，先看它的构造函数：

``` java
@Nullable
private final PropertySources propertySources;

public PropertySourcesPropertyResolver(@Nullable PropertySources propertySources) {
	this.propertySources = propertySources;
}
```

只依赖于一个`PropertySources`实例，在SpringBoot项目中就是`MutablePropertySources`的实例。重点分析一下最复杂的一个方法：

``` java
protected <T> T getProperty(String key, Class<T> targetValueType, boolean resolveNestedPlaceholders) {
	if (this.propertySources != null) {
        //遍历所有的PropertySource
		for (PropertySource<?> propertySource : this.propertySources) {
			if (logger.isTraceEnabled()) {
				logger.trace("Searching for key '" + key + "' in PropertySource '" +
							propertySource.getName() + "'");
			}
			Object value = propertySource.getProperty(key);
            //选用第一个不为null的匹配key的属性值
			if (value != null) {
				if (resolveNestedPlaceholders && value instanceof String) {
                    //处理属性占位符，如${server.port}，底层委托到PropertyPlaceholderHelper完成
					value = resolveNestedPlaceholders((String) value);
				}
				logKeyFound(key, propertySource, value);
                //如果需要的话，进行一次类型转换，底层委托到DefaultConversionService完成
				return convertValueIfNecessary(value, targetValueType);
			}
		}
	}
	if (logger.isDebugEnabled()) {
		logger.debug("Could not find key '" + key + "' in any property source");
	}
	return null;
}
```

这里的源码告诉我们，如果出现多个`PropertySource`中存在同名的key，返回的是第一个`PropertySource`对应key的属性值的处理结果，因此我们如果需要自定义一些环境属性，需要十分清楚各个`PropertySource`的顺序。

# Resource



# ResourceLoader

## classpath与classpath*的区别

`classpath`和`classpath*`默认一般是classes(编译后的class文件)下路劲

- `classpath`：只会到你的class路径中查找找文件;

- `classpath*`：不仅包含class路径，还包括jar文件中(class路径)进行查找.