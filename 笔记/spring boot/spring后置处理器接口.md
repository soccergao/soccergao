# BeanPostProcessor

# InstantiationAwareBeanPostProcessor

## 接口介绍

``` java
public interface InstantiationAwareBeanPostProcessor extends BeanPostProcessor {

	/**
	 * spring第一次调用后置处理器的方法
	 * 这个方法是在实例化之前产生作用，当这个方法不返回null的时候，就会直接调用BeanPostProcessor的postProcessAfterInitialization方法然后直接返回出去
	 * 这样就跳过了中间的许多步骤（如推断构造方法，自动装配）
	 * 如果这个方法返回null，则会按照spring的流程继续走下去
	 * @param beanClass the class of the bean to be instantiated
	 * @param beanName the name of the bean
	 * @return
	 * @throws BeansException
	 */
	@Nullable
	default Object postProcessBeforeInstantiation(Class<?> beanClass, String beanName) throws BeansException {
		return null;
	}

	/**
	 * 这个方法是在实例化之后产生作用，由于返回的值是bool类型
	 * 判断是否需要对属性的填充或修改（@Autowired要不要管）
	 * @param bean the bean instance created, with properties not having been set yet
	 * @param beanName the name of the bean
	 * @return
	 * @throws BeansException
	 */
	default boolean postProcessAfterInstantiation(Object bean, String beanName) throws BeansException {
		return true;
	}

    /**
	 * 完成对属性的填充
	 */
    @Nullable
	default PropertyValues postProcessProperties(PropertyValues pvs, Object bean, String beanName)
			throws BeansException {

		return null;
	}
    
	@Deprecated
	@Nullable
	default PropertyValues postProcessPropertyValues(
			PropertyValues pvs, PropertyDescriptor[] pds, Object bean, String beanName) throws BeansException {

		return pvs;
    }
```

