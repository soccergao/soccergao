# Lock

## Lock 锁的实现原理

- Lock 锁是基于 Java 实现的锁，Lock 是一个接口类，常用的实现类有 ReentrantLock、ReentrantReadWriteLock（RRW），它们都是依赖 AbstractQueuedSynchronizer（AQS）类实现的。
- AQS 类结构中包含一个基于链表实现的等待队列（CLH 队列），用于存储所有阻塞的线程，AQS 中还有一个 state 变量，该变量对 ReentrantLock 来说表示加锁状态。

## 锁分离优化 Lock 同步锁

### 独占锁ReentrantLock 

### 读写锁 ReentrantReadWriteLock

### 读写锁再优化之 StampedLock

