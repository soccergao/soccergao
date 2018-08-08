### JsonSerializer
Annotation: `@JsonSerialize(using = DateSerialize.class)`
``` java
public class DateSerialize extends JsonSerializer<Date> {

	@Override
	public void serialize(Date value, JsonGenerator gen, SerializerProvider serializers)
			throws IOException, JsonProcessingException {
		DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
		String str = formatter.format(value.toInstant());
		gen.writeString(str);
	}
	
}
```