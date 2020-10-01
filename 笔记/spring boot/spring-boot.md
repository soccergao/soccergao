# spring-boot

### 外部化配置(Externalized Configuration)

[官方文档](https://docs.spring.io/spring-boot/docs/2.3.1.RELEASE/reference/html/spring-boot-features.html#boot-features)



### Spring Environment

``` sequence
Environment -> ConfigurableEnvironment: 父子层次
ConfigurableEnvironment -> MutablePropertySources: 获取可变多个配置源
MutablePropertySources -> List PropertySource: 包含多个PropertySource
```

`PropertySource`: 配置源

- `MapPropertySource`:
  - `PropertiesPropertySource`
- `CompositePropertySource` : 组合
- `SystemEnvironmentPropertySource` : 环境变量

