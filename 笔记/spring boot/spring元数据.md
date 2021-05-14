## 聊聊Spring中的那些【Metadata】

### 顶级接口：ClassMetadata

> `ClassMetadata`：对Class的封装适配
>
>  使用它时，并不要求该Bean已经被加载~
>
> 它的所有方法，基本上都跟Class有关。

```java
// underlying class:基础的class
public interface ClassMetadata {
	// 返回类名（注意返回的是最原始的那个className）
	String getClassName();
	boolean isInterface();
	// 是否是注解
	boolean isAnnotation();
	boolean isAbstract();
	// 是否允许创建  不是接口且不是抽象类  这里就返回true了
	boolean isConcrete();
	boolean isFinal();
	// 是否是独立的(能够创建对象的)  比如是Class、或者内部类、静态内部类
	boolean isIndependent();
	// 是否有内部类之类的东东
	boolean hasEnclosingClass();
	@Nullable
	String getEnclosingClassName();
	boolean hasSuperClass();
	@Nullable
	String getSuperClassName();
	// 会把实现的所有接口名称都返回  具体依赖于Class#getSuperclass
	String[] getInterfaceNames();
	// 基于：Class#getDeclaredClasses  返回类中定义的公共、私有、保护的内部类
	String[] getMemberClassNames();
}
```

### 顶级接口：`AnnotatedTypeMetadata`

`AnnotatedTypeMetadata`：对`AnnotatedElement`的封装适配

```java
public interface AnnotatedTypeMetadata {
    // 根据“全类名”判断是否被指定 直接注解或元注解 标注
    boolean isAnnotated(String annotationName);
    // 根据”全类名“获取所有注解属性（包括元注解）
    @Nullable
    Map<String, Object> getAnnotationAttributes(String annotationName);
    // 同上，但是第二个参数传 true 时会把属性中对应值为 Class 的值
    // 转为 字符串，避免需要预先加载对应 Class
    @Nullable
    Map<String, Object> getAnnotationAttributes(String annotationName, boolean classValuesAsString);
    // 同上，MultiValueMap 是一个 key 可以对应多个 value 的变种 map
    @Nullable
    MultiValueMap<String, Object> getAllAnnotationAttributes(String annotationName);
    @Nullable
    MultiValueMap<String, Object> getAllAnnotationAttributes(String annotationName, boolean classValuesAsString);
}
```

主要提供了两个核心方法：

- 根据 `全类名` 判断是否被指定注解标注
- 根据 `全类名` 返回指定注解的属性集合（包括元注解）

### 二级接口：`AnnotationMetadata`

`AnnotationMetadata`：对Class相关的多个注解进行获取和判断

```java
public interface AnnotationMetadata extends ClassMetadata, AnnotatedTypeMetadata {
    //拿到Class上标注的所有注解，依赖于Class#getAnnotations
    Set<String> getAnnotationTypes();
    // 拿到所有的元注解信息AnnotatedElementUtils#getMetaAnnotationTypes
    //annotationName:注解类型的全类名
    Set<String> getMetaAnnotationTypes(String annotationName);
    // 是否包含指定注解 （annotationName：全类名）
    boolean hasAnnotation(String annotationName);
    //这个厉害了，依赖于AnnotatedElementUtils#hasMetaAnnotationTypes
    boolean hasMetaAnnotation(String metaAnnotationName);
    // 类里面只有有一个方法标注有指定注解，就返回true
    //getDeclaredMethods获得所有方法， AnnotatedElementUtils.isAnnotated是否标注有指定注解
    boolean hasAnnotatedMethods(String annotationName);
    // 注意返回的是MethodMetadata 原理基本同上
    // .getDeclaredMethods和AnnotatedElementUtils.isAnnotated  最后吧Method转为MethodMetadata
    Set<MethodMetadata> getAnnotatedMethods(String annotationName);
}
```

### 二级接口：`MethodMetadata`

 `MethodMetadata`：方法的元数据

```java
// 基本上是代理了Method introspectedMethod;
public interface MethodMetadata extends AnnotatedTypeMetadata {
    // 方法名称
    String getMethodName();
    // 此方法所属类的全类名
    String getDeclaringClassName();
    // 方法返回值的全类名
    String getReturnTypeName();
    // 是否是抽象方法
    boolean isAbstract();
    // 是否是静态方法
    boolean isStatic();
    //是否是final方法
    boolean isFinal();
    // 是否可以被复写（不是静态、不是final、不是private的  就表示可以被复写）
    boolean isOverridable();
}
```

### 主要实现类

主要实现类有：`StandardAnnotationMetadata`、`StandardMethodMetadata`、`AnnotationMetadataReadingVisitor`、`MethodMetadataReadingVisitor`。先聊聊标准实现（前两个）

#### StandardAnnotationMetadata

StandardAnnotationMetadata：扩展了StandardClassMetadata增加对注解的支持
它继承了StandardClassMetadata，然后实现了AnnotationMetadata来提供对注解的主持扩展。

```java
public class StandardAnnotationMetadata extends StandardClassMetadata implements AnnotationMetadata {
	// 持有对本类所有注解的引用
	private final Annotation[] annotations;
	private final boolean nestedAnnotationsAsMap;

	public StandardAnnotationMetadata(Class<?> introspectedClass, boolean nestedAnnotationsAsMap) {
		super(introspectedClass);
		this.annotations = introspectedClass.getAnnotations();
		this.nestedAnnotationsAsMap = nestedAnnotationsAsMap;
	}
	...// 它实现了所有AnnotationMetadata 接口的方法 因为实现很简单 此处就省略掉了
}
```

#### StandardMethodMetadata

`StandardMethodMetadata`：只实现了MethodMetadata，属于标准实现

需要注意的是，它还得实现`AnnotatedTypeMetadata`这个接口里的所有方法

```java
public class StandardMethodMetadata implements MethodMetadata {
	// 持有方法的引用：内省方法
	private final Method introspectedMethod;
	private final boolean nestedAnnotationsAsMap;

	public StandardMethodMetadata(Method introspectedMethod, boolean nestedAnnotationsAsMap) {
		Assert.notNull(introspectedMethod, "Method must not be null");
		this.introspectedMethod = introspectedMethod;
		this.nestedAnnotationsAsMap = nestedAnnotationsAsMap;
	}
	... // 实现都非常简单，此处省略  说说AnnotatedTypeMetadata接口的实现
	@Override
	public boolean isAnnotated(String annotationName) {
		return AnnotatedElementUtils.isAnnotated(this.introspectedMethod, annotationName);
	}
	@Override
	@Nullable
	public Map<String, Object> getAnnotationAttributes(String annotationName) {
		return getAnnotationAttributes(annotationName, false);
	}
	@Override
	@Nullable
	public Map<String, Object> getAnnotationAttributes(String annotationName, boolean classValuesAsString) {
		return AnnotatedElementUtils.getMergedAnnotationAttributes(this.introspectedMethod,
				annotationName, classValuesAsString, this.nestedAnnotationsAsMap);
	}
	@Override
	@Nullable
	public MultiValueMap<String, Object> getAllAnnotationAttributes(String annotationName) {
		return getAllAnnotationAttributes(annotationName, false);
	}
	// 这个和getMergedAnnotationAttributes有关
	@Override
	@Nullable
	public MultiValueMap<String, Object> getAllAnnotationAttributes(String annotationName, boolean classValuesAsString) {
		return AnnotatedElementUtils.getAllAnnotationAttributes(this.introspectedMethod,
				annotationName, classValuesAsString, this.nestedAnnotationsAsMap);
	}
	
}
```

最后关于`AnnotationMetadataReadingVisitor`和`MethodMetadataReadingVisitor`，它俩都实现了`xxxVisitor`接口的，和Spring中处理ASM技术有关，不在本文讨论的范围之内，暂且略过。

>  Spring内部使用得字节码技术，比如`SimpleMetadataReader`，`CachingMetadataReaderFactory`等等

### **MetadataReader**

它是一个访问`ClassMetadata`等的简单门面。它的唯一实现`SimpleMetadataReader`内部实现原理就是基于`AnnotationMetadataReadingVisitor`使用ASM相关的

```java
public interface MetadataReader {
	// 返回此Class来自的资源（创建的时候需要指定此资源，然后交给`AnnotationMetadataReadingVisitor`去处理）
	Resource getResource();
	// ClassMeta，实现为通过`AnnotationMetadataReadingVisitor`中获取
	ClassMetadata getClassMetadata();
	// 注解元信息 也是通过`AnnotationMetadataReadingVisitor`获取
	AnnotationMetadata getAnnotationMetadata();
}
```

