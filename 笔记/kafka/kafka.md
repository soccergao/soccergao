# kafaka

## producer

### producer端基本数据结构

- ProducerRecord: 一个ProducerRecord表示一条待发送的消息记录，主要由5个字段构成：

```bash
  topic          所属topic
  partition      所属分区
  key            键值
  value          消息体
  timestamp      时间戳
```

- RecordMetadata: Kafka服务器端返回给客户端的消息的元数据信息,前3项相对比较重要，Producer端可以使用这些消息做一些消息发送成功之后的处理。

```bash
  offset                   该条消息的位移
  timestamp                消息时间戳
  topic + partition        所属topic的分区
  checksum                 消息CRC32码
  serializedKeySize        序列化后的消息键字节数
  serializedValueSize      序列化后的消息体字节数
```

### producer端消息发送流程

![1676fa43d76b5554](C:\project\soccergao\笔记\kafka\图片\1676fa43d76b5554.jpg)

- 在send()的发送消息动作触发之前，通过props属性中指定的servers连接到broker集群，从Zookeeper收集集群Metedata信息，从而了解哪些broker掌管哪一个Topic的哪一个partition，以及brokers的健康状态。
- 下面就是流水线操作，ProducerRecord对象携带者topic，partition，message等信息，在Serializer这个“车间”被序列化。
- 序列化过后的ProducerRecord对象进入Partitioner“车间”，按照上文所述的Partitioning 策略决定这个消息将被分配到哪个Partition中。
- 确定partition的ProducerRecord进入一个缓冲区，通过减少IO来提升性能，在这个“车间”，消息被按照TopicPartition信息进行归类整理，相同Topic且相同parition的ProducerRecord被放在同一个RecordBatch中，等待被发送。什么时候发送？都在Producer的props中被指定了，有默认值，显然我们可以自己指定。

```bash
(1) batch.size:设置每个RecordBatch可以缓存的最大字节数 
(2) buffer.memory:设置所有RecordBatch的总共最大字节数 
(3) linger.ms设置每个RecordBatch的最长延迟发送时间 
(4) max.block.ms 设置每个RecordBatch的最长阻塞时间 
```

- 一旦，当单个RecordBatch的linger.ms延迟到达或者batch.size达到上限，这个 RecordBatch会被立即发送。另外，如果所有RecordBatch作为一个整体，达到了buffer.memroy或者max.block.ms上限，所有的RecordBatch都会被发送。
- ProducerRecord消息按照分配好的Partition发送到具体的broker中,broker接收保存消息，更新Metadata信息，同步给Zookeeper。
- Producer端其他优化点：

```bash
(5) acks：Producer的数据确认阻塞设置，0表示不管任何响应，只管发，发完了立即执行下个任务，这种方式最快，但是很不保险。1表示只确保leader成功响应，接收到数据。2表示确保leader及其所有follwer成功接收保存消息，也可以用”all”。
(6) retries：消息发送失败重试的次数。
(7) retry.backoff.ms：失败补偿时间，每次失败重试的时间间隔，不可设置太短，避免第一条消息的响应还没返回，第二条消息又发出去了，造成逻辑错误。
(8) max.in.flight.request.per.connection：同一时间，每个Producer能够发送的消息上限。
(9) compression.type  producer所使用的压缩器，目前支持gzip, snappy和lz4。压缩是在用户主线程完成的，通常都需要花费大量的CPU时间，但对于减少网络IO来说确实利器。生产环境中可以结合压力测试进行适当配置

```





# 参考

作者：云原生数据云社区
链接：https://juejin.im/post/6844903729355833357
来源：掘金
著作权归作者所有。商业转载请联系作者获得授权，非商业转载请注明出处。

