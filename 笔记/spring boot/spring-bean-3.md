# BeanPostProcessor

在Spring当中，对BeanFactory中的Bean做控制有两种方式：

- 一种是通过`BeanFactoryPostProcessor`，修改IOC容器中的`BeanDefinition`，相当于修改了类的class文件
- 另一种就是我们今天要讲的使用`BeanPostProcessor`，相当于改变了实例化的对象

既然要了解，那我们就要知道有关BeanPostProcessor在Spring上下文初始化的时候，什么时候被注册到BeanFactory的？什么时候被使用的？并且通过实践来清楚如何使用BeanPostProcessor

## 注册BeanPostProcessor

```java
@Override
public void refresh() throws BeansException, IllegalStateException {
    synchronized (this.startupShutdownMonitor) {
        ...
        try {
            ...
                
            // Register bean processors that intercept bean creation.
            registerBeanPostProcessors(beanFactory);
            
		   ...
        }
        catch (BeansException ex) {
            ...
        }
        finally {
            ...        
        }
    }
}
```

`AbstractApplicationContext`中的`registerBeanPostProcessors`方法实际上是委托了`PostProcessorRegistrationDelegate`中的`registerBeanPostProcessors(ConfigurableListableBeanFactory beanFactory, AbstractApplicationContext applicationContext)`方法

```java
public static void registerBeanPostProcessors(
        ConfigurableListableBeanFactory beanFactory, AbstractApplicationContext applicationContext) {
    //获取所有实现BeanPostProcessor接口的bean的名称
    String[] postProcessorNames = beanFactory.getBeanNamesForType(BeanPostProcessor.class, true, false);
 
    //注意，此时尽管注册操作还没有开始，但是之前已经有一些特殊的bean已经注册进来了，
    //详情请看AbstractApplicationContext类的prepareBeanFactory方法，
    //因此getBeanPostProcessorCount()方法返回的数量并不为零，
    //加一是因为方法末尾会注册一个ApplicationListenerDetector接口的实现类
    int beanProcessorTargetCount = beanFactory.getBeanPostProcessorCount() + 1 + postProcessorNames.length;
    //这里的BeanPostProcessorChecker也是个BeanPostProcessor的实现类，用于每个bean的初始化完成后，做一些简单的检查
    beanFactory.addBeanPostProcessor(new BeanPostProcessorChecker(beanFactory, beanProcessorTargetCount));
 
    //如果这些bean还实现了PriorityOrdered接口（在意执行顺序），就全部放入集合priorityOrderedPostProcessors 
    List<BeanPostProcessor> priorityOrderedPostProcessors = new ArrayList<BeanPostProcessor>();
    //集合internalPostProcessors，用来存放同时实现了PriorityOrdered和MergedBeanDefinitionPostProcessor接口的bean
    List<BeanPostProcessor> internalPostProcessors = new ArrayList<BeanPostProcessor>();
    //集合orderedPostProcessorNames用来存放实现了Ordered接口的bean的名称（在意执行顺序）
    List<String> orderedPostProcessorNames = new ArrayList<String>();
    //集合nonOrderedPostProcessorNames用来存放即没实现PriorityOrdered接口，也没有实现Ordered接口的bean的名称（不关心执行顺序）
    List<String> nonOrderedPostProcessorNames = new ArrayList<String>();
    for (String ppName : postProcessorNames) {
        if (beanFactory.isTypeMatch(ppName, PriorityOrdered.class)) {
            // 注意这里直接调用了BeanFactory的getBean方法，获取了BeanPostProcessor的实体，后面在注册的时候直接将BeanPostProcessor的实体放入了BeanFactory的一个BeanPostProcessor的集合
            BeanPostProcessor pp = beanFactory.getBean(ppName, BeanPostProcessor.class);
            //实现了PriorityOrdered接口的bean，都放入集合priorityOrderedPostProcessors
            priorityOrderedPostProcessors.add(pp);
            if (pp instanceof MergedBeanDefinitionPostProcessor) {
                //实现了MergedBeanDefinitionPostProcessor接口的bean，都放入internalPostProcessors集合
                internalPostProcessors.add(pp);
            }
        }
        else if (beanFactory.isTypeMatch(ppName, Ordered.class)) {
            //实现了Ordered接口的bean，将其名称都放入orderedPostProcessorNames集合
            orderedPostProcessorNames.add(ppName);
        }
        else {
            //既没实现PriorityOrdered接口，也没有实现Ordered接口的bean，将其名称放入nonOrderedPostProcessorNames集合
            nonOrderedPostProcessorNames.add(ppName);
        }
    }
 
    //实现了PriorityOrdered接口的bean排序
    OrderComparator.sort(priorityOrderedPostProcessors);
    //注册到容器，实际上是将BeanPostProcessor的实体添加到BeanFactory的一个收集BeanPostProcessor的集合
    registerBeanPostProcessors(beanFactory, priorityOrderedPostProcessors);
 
    List<BeanPostProcessor> orderedPostProcessors = new ArrayList<BeanPostProcessor>();
    //处理所有实现了Ordered接口的bean
    for (String ppName : orderedPostProcessorNames) {
        BeanPostProcessor pp = beanFactory.getBean(ppName, BeanPostProcessor.class);
        orderedPostProcessors.add(pp);
        //前面将所有实现了PriorityOrdered和MergedBeanDefinitionPostProcessor的bean放入internalPostProcessors，
        //此处将所有实现了Ordered和MergedBeanDefinitionPostProcessor的bean放入internalPostProcessors
        if (pp instanceof MergedBeanDefinitionPostProcessor) {
            internalPostProcessors.add(pp);
        }
    }
 
    //实现了Ordered接口的bean排序
    OrderComparator.sort(orderedPostProcessors);
    //注册到容器
    registerBeanPostProcessors(beanFactory, orderedPostProcessors);
 
    List<BeanPostProcessor> nonOrderedPostProcessors = new ArrayList<BeanPostProcessor>();
    for (String ppName : nonOrderedPostProcessorNames) {
        BeanPostProcessor pp = beanFactory.getBean(ppName, BeanPostProcessor.class);
        nonOrderedPostProcessors.add(pp);
        //此处将其余实现了MergedBeanDefinitionPostProcessor的bean放入internalPostProcessors
        if (pp instanceof MergedBeanDefinitionPostProcessor) {
            internalPostProcessors.add(pp);
        }
    }
    //注册到容器
    registerBeanPostProcessors(beanFactory, nonOrderedPostProcessors);
 
    OrderComparator.sort(internalPostProcessors);
    //将所有实现了MergedBeanDefinitionPostProcessor接口的bean也注册到容器
    registerBeanPostProcessors(beanFactory, internalPostProcessors);
    //创建一个ApplicationListenerDetector对象并且注册到容器，这就是前面计算beanProcessorTargetCount的值时加一的原因
    beanFactory.addBeanPostProcessor(new ApplicationListenerDetector(applicationContext));
}
```

