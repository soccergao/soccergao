## HashMap

- 数组+链表(1.7)，数组+链表+红黑树(1.8)，链表长度大于阈值(8)转为红黑树
- 桶的默认容量为 16，负载因子为 0.75
- 存放数据达到了 `16 * 0.75 = 12` 就需要将当前 16 的容量进行扩容，而扩容这个过程涉及到 rehash、复制数据等操作，所以非常消耗性能。

## HashTable

- 通过synchronized加锁保证同步

## ConcurrentHashMap

### Segment + HashEntry + Unsafe (1.7)

Segment 继承了 ReentrantLock，是一种可重入锁。HashEntry 则用于存储键值对数据。一个 ConcurrentHashMap 里包含多个 Segment 数组(默认16个桶)，一个 Segment 里包含多个 HashEntry 数组 ，每个 HashEntry 是多个链表结构的元素，因此 JDK1.7 的 ConcurrentHashMap 是一种**数组+链表结构**。当对 HashEntry 数组的数据进行修改时，必须首先获得与它对应的 Segment 锁，这样只要保证每个 Segment 是线程安全的，也就实现了全局的线程安全（**分段锁**）。

- 不同 Segment 的并发写入【可以并发执行】
- 同一 Segment 的一写一读【可以并发执行】，读通过volatile，保证读取到最新的值
- 同一 Segment 的并发写入【需要上锁】
- 扩容：段内扩容(段内元素超过该段对应 Entry 数组长度的75%触发扩容，不会对整个 Map 进行扩容)
- size()：计算两次，如果不变则返回计算结果，若不一致，则锁住所有的 Segment 求和。

### Synchronized + CAS + Node + Unsafe (1.8)

在 JDK1.8 中，ConcurrentHashMap 选择了与 HashMap 相同的**数组+链表+红黑树**结构，在锁的实现上，采用 CAS 操作和 synchronized 锁实现更加低粒度的锁，将锁的级别控制在了更细粒度的 table 元素级别，也就是说只需要锁住这个链表的首节点，并不会影响其他的 table 元素的读写，大大提高了并发度。

- synchronized 锁的性能得到了很大的提高
- 移除了 Segment，类似 [HashMap](https://www.jianshu.com/p/6c70d265aa7b)，可以直接定位到桶，拿到 first 节点后进行判断：①为空则 [CAS](https://www.jianshu.com/p/98220486426a) 插入；②为 -1 则说明在扩容，则跟着一起扩容；③ else 则加锁 put(类似1.7)
- 用 baseCount 来存储当前的节点个数，这就设计到 baseCount 并发环境下修改的问题。

### 总结

- 1.7分成默认16个Segment，Segment之间独立加锁，每个Segment里是数据+链表，可以16个线程同时写入
- 1.8取消了Segment，采用Synchronized + CAS ，粒度更细，每个桶之间独立加锁，可写入线程数更多。

