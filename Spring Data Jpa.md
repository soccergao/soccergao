# Spring Data Jpa
### 查询关键字
|关键字|示例|同功能JPQL|
| ------------ | ------------ | ------------ |
|And|findByLastnameAndFirstname|where x.lastname = ?1 and x.firstname = ?2|
|Or|findByLastnameOrFirstName|where x.lastname = ?1 or x.firstname = ?2|
|Is,Equals|findByFirstname,findByFirstNameIs, findByFirstNameEquals|where x.firstname = ?1|
|Between|findByStartDateBetween|where x.startDate between 1? and ?2|
|LessThan|findByAgeLessThan|where x.age < ?1|
|LessThanEqual|findByAgeLessThanEqual|where x.age <= ?1|
|GreaterThan|findByAgeGreaterThan|where x.age > ?1|
|GreaterThanEqual|findByAgeGreaterThanEqual|where x.age >= ?1|
|After|findByStartDateAfter|where x.startDate > ?1|
|Before|findByStartDateBefore|where x.startDate < ?1|
|IsNull|findByAgeIsNull|where x.age is null|
|IsNotNull,NotNull|findByAge(Is)NotNull|where x.age is not null|
|Like|findByFirstnameLike|where x.firstname like ?1|
|NotLike|findByFirstnameNotLike|where x.firstname not like ?1|
|StartingWith|findByFirstnameStartingWith|where x.firstname like ?1 (参数前面加%)|
|EndingWith|findByFirstnameEndingWith|where x.firstname like ?1 (参数后面加%)|
|Containing|findByFirstnameContaining|where x.firstname like ?1 (参数两边加%)|
|OrderBy|findByAgeOrderByLastnameDesc|where x.age = ?1 order by x.lastname desc|
|Not|findByLastnameNot|where x.lastname <> ?1|
|In|findByAgeIn(Collection&lt;Age> ages)|where x.age in ?1|
|NotIn|findByAgeNotIn(Collection&lt;Age> ages|where x.age not in ?1|
|True|findByActiveTrue|where x.active = true|
|False|findByActiveFalse|where x.active = false|
|IgnoreCase|findByFirstnameIgnoreCase|where Upper(x.firstname) = Upper(?1)|

### 审计
Class注解: &#64;EntityListeners(AuditingEntityListener.class)
Field注解: &#64;CreatedBy, &#64;LastModifiedBy, &#64;CreatedDate, &#64;LastModifiedDate
配置:
```java
@Configuration
@EnableJpaAuditing
public class JpaAuditingConfig {
	@Bean
	public AuditorAware<String> auditorProvider() {
		return () -> "";	//@CreatedBy和@LastModifiedBy的值
	}
}
```
