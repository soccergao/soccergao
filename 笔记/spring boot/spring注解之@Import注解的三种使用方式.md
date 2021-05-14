## spring注解之@Import注解的三种使用方式

### @Import注解须知

> 1、**@Import只能用在类上** ，@Import通过快速导入的方式实现把实例加入spring的IOC容器中
>
> 2、加入IOC容器的方式有很多种，@Import注解就相对很牛皮了，**@Import注解可以用于导入第三方包** ，当然@Bean注解也可以，但是@Import注解快速导入的方式更加便捷
>
> 3、@Import注解有三种用法

### @Import的三种用法

@Import的三种用法主要包括：

- 直接填class数组方式 
- ImportSelector
- ImportBeanDefinitionRegistrar

#### 一、直接填class数组

``` java
@Import({ 类名.class , 类名.class... })
public class TestDemo {

}
```

#### 二、ImportSelector方式

实现ImportSelector接口

``` java
public class Myclass implements ImportSelector {
    @Override
    public String[] selectImports(AnnotationMetadata annotationMetadata) {
        return new String[0];
    }
}
```

- 返回值： 就是我们实际上要导入到容器中的组件全类名
- 参数： AnnotationMetadata表示当前被@Import注解给标注的所有注解信息