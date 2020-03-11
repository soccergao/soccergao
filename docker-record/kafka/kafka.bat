docker run -d --name kafka ^
--env KAFKA_BROKER_ID=0 ^
--env KAFKA_ADVERTISED_HOST_NAME=localhost ^
--env KAFKA_ZOOKEEPER_CONNECT=localhost:2181 ^
--env KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://localhost:9092 ^
--env KAFKA_LISTENERS=PLAINTEXT://0.0.0.0:9092 ^
--env KAFKA_HEAP_OPTS="-Xmx256M -Xms128M" ^
--net=host wurstmeister/kafka