---
layout: post
title: Java 并发集合概览
date: 2020-12-12 22:43 +0800
---

这篇主要简单介绍 Java 集合库包含哪些常用的容器类，它们可以简单区分为:

- 非同步集合
- 同步集合
- 并发集合

# Java 集合框架
Java 集合工具包在 Java.util 包下，它包含了常用的数据结构，比如数组、链表、栈、队列、集合、哈希表等等。

这里先放一张 Java 集合类的框架图：

![Java 集合类的框架图](https://i.ibb.co/Tv3pCXp/1029728-20180804171528286-1773816723.png)

Collection 接口是集合类的根接口，Java 中没有提供这个接口的直接的实现类。但是让其被继承产生了两个接口，就是 Set 和 List。Set中不能包含重复的元素。List是一个有序的集合，可以包含重复的元素，提供了按索引访问的方式。

Map 是 Java.util 包中的另一个接口，它和 Collection 接口没有关系，是相互独立的，但是都属于集合类的一部分。Map 包含了 key-value 对。Map 不能包含重复的 key，但是可以包含相同的 value。

其中还有一个 Iterator\<E\> 接口，Collection 继承了它，也就是说所有的集合类，都实现了Iterator接口，这是一个用于遍历集合中元素的接口，主要包含以下三种方法：

hasNext()是否还有下一个元素。
next()返回下一个元素。
remove()删除当前元素。
对于 Java 集合框架，这里不再做过多的说明，如果要完全剖析，那估计得再开一个专栏来讲。下面对具体容器类分类，我们直接来看他们分别属于哪些类型。

Java 集合详细内容：[Java 集合类概览]({% post_url 2020-10-03-java-collection-overview %})

# 非同步集合
非同步集合，在并发访问的时候，是非线程安全的；但是由于它们没有同步策略(加锁机制)，它们的效率更高。常用的非同步集合它们包括下面几个：

- ArrayList
- HashSet
- HashMap
- LinkedList
- TreeSet
- TreeMap
- PriorityQueue


# 同步集合(容器)
## 什么是同步容器
Java的集合容器框架中，主要有四大类别：List、Set、Queue、Map，大家熟知的这些集合类ArrayList、LinkedList、HashMap这些容器都是非线程安全的。

如果有多个线程并发地访问这些容器时，就会出现问题。因此，在编写程序时，在多线程环境下必须要求程序员手动地在任何访问到这些容器的地方进行同步处理，这样导致在使用这些容器的时候非常地不方便。

所以，Java先提供了同步容器供用户使用。

同步容器可以简单地理解为通过synchronized来实现同步的容器，通过对每个方法都进行同步加锁，保证线程安全。

- HashTable
- Vector
- Stack
- 同步包装器 : [ Collections.synchronizedMap(), Collections.synchronizedList() ]

Java 集合类中非线程安全的集合可以用同步包装器使集合变成线程安全，其实实现原理就是相当于对每个方法加多一层同步锁而已，比如：

- HashMap --> Collections.synchronizedMap(new HashMap())
- ArrayList --> Collections.synchronizedList(new ArrayList<>())

## 同步容器面临的问题
- 同步容器类在单个方法被使用时可以保证线程安全。复合操作则需要额外的客户端加锁来保护。

- 使用Iterator迭代容器或使用使用for-each遍历容器，在迭代过程中修改容器会抛出ConcurrentModificationException异常。想要避免出现ConcurrentModificationException，就必须在迭代过程持有容器的锁。但是若容器较大，则迭代的时间也会较长。那么需要访问该容器的其他线程将会长时间等待。从而会极大降低性能。

  若不希望在迭代期间对容器加锁，可以使用"克隆"容器的方式。使用线程封闭，由于其他线程不会对容器进行修改，可以避免ConcurrentModificationException。但是在创建副本的时候，存在较大性能开销。

- 隐式迭代

  toString，hashCode，equalse，containsAll，removeAll，retainAll等方法都会隐式的Iterate，也即可能抛出ConcurrentModificationException。

- 通过查看Vector，Hashtable等这些同步容器的实现代码，可以看到这些容器实现线程安全的方式就是将它们的状态封装起来，并在需要同步的方法上加上关键字synchronized。

  这样做的代价是削弱了并发性，当多个线程共同竞争容器级的锁时，吞吐量就会降低。

  例如： HashTable只要有一条线程获取了容器的锁之后，其他所有的线程访问同步函数都会被阻塞，因此同一时刻只能有一条线程访问同步函数。

因此为了解决同步容器的性能问题，所以才有了并发容器。

# 并发集合(容器)
## 什么是并发容器
java.util.concurrent包中提供了多种并发类容器。

并发类容器是专门针对多线程并发设计的，使用了锁分段技术，只对操作的位置进行同步操作，但是其他没有操作的位置其他线程仍然可以访问，提高了程序的吞吐量。

采用了CAS算法和部分代码使用synchronized锁保证线程安全。

并发容器包注重以下特性：
- 根据具体场景进行设计，尽量避免使用锁，提高容器的并发访问性。
- 并发容器定义了一些线程安全的复合操作。
- 并发容器在迭代时，可以不封闭在synchronized中。但是未必每次看到的都是"最新的、当前的"数据。如果说将迭代操作包装在synchronized中，可以达到"串行"的并发安全性，那么并发容器的迭代达到了"脏读"。

CopyOnWriteArrayList和CopyOnWriteArraySet分别代替List和Set，主要是在遍历操作为主的情况下来代替同步的List和同步的Set，这也就是上面所述的思路：迭代过程要保证不出错，除了加锁，另外一种方法就是"克隆"容器对象。

ConcurrentLinkedQuerue是Query实现，是一个先进先出的队列。一般的Queue实现中操作不会阻塞，如果队列为空，那么取元素的操作将返回空。Queue一般用LinkedList实现的，因为去掉了List的随机访问需求，因此并发性更好。

BlockingQueue扩展了Queue，增加了可阻塞的插入和获取操作，如果队列为空，那么获取操作将阻塞，直到队列中有一个可用的元素。如果队列已满，那么插入操作就阻塞，直到队列中出现可用的空间。

## 1.ConcurrentHashMap 
并发版HashMap

最常见的并发容器之一，可以用作并发场景下的缓存。底层依然是哈希表，但在JAVA 8中有了不小的改变，而JAVA 7和JAVA 8都是用的比较多的版本，因此经常会将这两个版本的实现方式做一些比较（比如面试中）。

一个比较大的差异就是，JAVA 7中采用分段锁来减少锁的竞争，JAVA 8中放弃了分段锁，采用CAS（一种乐观锁），同时为了防止哈希冲突严重时退化成链表（冲突时会在该位置生成一个链表，哈希值相同的对象就链在一起），会在链表长度达到阈值（8）后转换成红黑树（比起链表，树的查询效率更稳定）。

## 2.CopyOnWriteArrayList
并发版ArrayList

底层结构也是数组，和ArrayList不同之处在于：当新增和删除元素时会创建一个新的数组，在新的数组中增加或者排除指定对象，最后用新增数组替换原来的数组。

适用场景：由于读操作不加锁，写（增、删、改）操作加锁，因此适用于读多写少的场景。

局限：由于读的时候不会加锁（读的效率高，就和普通ArrayList一样），读取的当前副本，因此可能读取到脏数据。如果介意，建议不用。

看看源码感受下：

```java
public class CopyOnWriteArrayList<E>
    implements List<E>, RandomAccess, Cloneable, java.io.Serializable {
    final transient ReentrantLock lock = new ReentrantLock();
    private transient volatile Object[] array;
    // 添加元素，有锁
    public boolean add(E e) {
        final ReentrantLock lock = this.lock;
        lock.lock(); // 修改时加锁，保证并发安全
        try {
            Object[] elements = getArray(); // 当前数组
            int len = elements.length;
            Object[] newElements = Arrays.copyOf(elements, len + 1); // 创建一个新数组，比老的大一个空间
            newElements[len] = e; // 要添加的元素放进新数组
            setArray(newElements); // 用新数组替换原来的数组
            return true;
        } finally {
            lock.unlock(); // 解锁
        }
    }
    // 读元素，不加锁，因此可能读取到旧数据
    public E get(int index) {
        return get(getArray(), index);
    }
}
```
原理：利用高并发往往是读多写少的特性，对读操作不加锁，对写操作，先复制一份新的集合，在新的集合上面修改，然后将新集合赋值给旧的引用，并通过volatile 保证其可见性，当然写操作的锁是必不可少的了。

## 3.CopyOnWriteArraySet 
并发Set

基于CopyOnWriteArrayList实现（内含一个CopyOnWriteArrayList成员变量），也就是说底层是一个数组，意味着每次add都要遍历整个集合才能知道是否存在，不存在时需要插入（加锁）。

适用场景：在CopyOnWriteArrayList适用场景下加一个，集合别太大（全部遍历伤不起）。

## 4.ConcurrentLinkedQueue 
并发队列(基于链表)

基于链表实现的并发队列, LinkedList的并发版本，使用乐观锁(CAS)保证线程安全。因为数据结构是链表，所以理论上是没有队列大小限制的，也就是说添加数据一定能成功。

## 5.ConcurrentLinkedDeque 
并发队列(基于双向链表)

基于双向链表实现的并发队列，可以分别对头尾进行操作，因此除了先进先出(FIFO)，也可以先进后出（FILO），当然先进后出的话应该叫它栈了。

## 6.ConcurrentSkipListMap 
基于跳表的并发Map

SkipList即跳表，跳表是一种空间换时间的数据结构，通过冗余数据，将链表一层一层索引，达到类似二分查找的效果

![](https://i.ibb.co/82BpBqx/mgu9fdr66l.jpg)


## 7.ConcurrentSkipListSet 
基于跳表的并发Set

类似HashSet和HashMap的关系，ConcurrentSkipListSet里面就是一个ConcurrentSkipListMap，就不细说了。

## 8.ArrayBlockingQueue 
阻塞队列(基于数组)

基于数组实现的可阻塞队列，构造时必须制定数组大小，往里面放东西时如果数组满了便会阻塞直到有位置（也支持直接返回和超时等待），通过一个锁ReentrantLock保证线程安全。

举个例子:
```java
public class ArrayBlockingQueue<E> extends AbstractQueue<E>
        implements BlockingQueue<E>, java.io.Serializable {
    /**
     * 读写共用此锁，线程间通过下面两个Condition通信
     * 这两个Condition和lock有紧密联系（就是lock的方法生成的）
     * 类似Object的wait/notify
     */
    final ReentrantLock lock;
    /** 队列不为空的信号，取数据的线程需要关注 */
    private final Condition notEmpty;
    /** 队列没满的信号，写数据的线程需要关注 */
    private final Condition notFull;
    // 一直阻塞直到有东西可以拿出来
    public E take() throws InterruptedException {
        final ReentrantLock lock = this.lock;
        lock.lockInterruptibly();
        try {
            while (count == 0)
                notEmpty.await();
            return dequeue();
        } finally {
            lock.unlock();
        }
    }
    // 在尾部插入一个元素，队列已满时等待指定时间，如果还是不能插入则返回
    public boolean offer(E e, long timeout, TimeUnit unit)
        throws InterruptedException {
        checkNotNull(e);
        long nanos = unit.toNanos(timeout);
        final ReentrantLock lock = this.lock;
        lock.lockInterruptibly(); // 锁住
        try {
            // 循环等待直到队列有空闲
            while (count == items.length) {
                if (nanos <= 0)
                    return false;// 等待超时，返回
                // 暂时放出锁，等待一段时间（可能被提前唤醒并抢到锁，所以需要循环判断条件）
                // 这段时间可能其他线程取走了元素，这样就有机会插入了
                nanos = notFull.awaitNanos(nanos);
            }
            enqueue(e);//插入一个元素
            return true;
        } finally {
            lock.unlock(); //解锁
        }
    }
```
乍一看会有点疑惑，读和写都是同一个锁，那要是空的时候正好一个读线程来了不会一直阻塞吗？

答案就在notEmpty、notFull里，这两个出自lock的小东西让锁有了类似synchronized + wait + notify的功能。

## 9.LinkedBlockingQueue 
阻塞队列(基于链表)

基于链表实现的阻塞队列，想比与不阻塞的ConcurrentLinkedQueue，它多了一个容量限制，如果不设置默认为int最大值

## 10.LinkedBlockingDeque 
阻塞队列(基于双向链表)

类似LinkedBlockingQueue，但提供了双向链表特有的操作。

## 11.PriorityBlockingQueue 
线程安全的优先队列

构造时可以传入一个比较器，可以看做放进去的元素会被排序，然后读取的时候按顺序消费。某些低优先级的元素可能长期无法被消费，因为不断有更高优先级的元素进来。

## 12.SynchronousQueue 
数据同步交换的队列

一个虚假的队列，因为它实际上没有真正用于存储元素的空间，每个插入操作都必须有对应的取出操作，没取出时无法继续放入。

一个简单的例子
```java
import java.util.concurrent.*;
public class Main {
    public static void main(String[] args) {
        SynchronousQueue<Integer> queue = new SynchronousQueue<>();
        new Thread(() -> {
            try {
                // 没有休息，疯狂写入
                for (int i = 0; ; i++) {
                    System.out.println("放入: " + i);
                    queue.put(i);
                }
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }).start();
        new Thread(() -> {
            try {
                // 咸鱼模式取数据
                while (true) {
                    System.out.println("取出: " + queue.take());
                    Thread.sleep((long) (Math.random() * 2000));
                }
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }).start();
    }
}
```
输出:
```
放入: 0
取出: 0
放入: 1
取出: 1
放入: 2
取出: 2
放入: 3
取出: 3
*/
```
可以看到，写入的线程没有任何sleep，可以说是全力往队列放东西，而读取的线程又很不积极，读一个又sleep一会。输出的结果却是读写操作成对出现。

JAVA中一个使用场景就是Executors.newCachedThreadPool()，创建一个缓存线程池。
```java
public static ExecutorService newCachedThreadPool() {
    return new ThreadPoolExecutor(
        0, // 核心线程为0，没用的线程都被无情抛弃
        Integer.MAX_VALUE, // 最大线程数理论上是无限了，还没到这个值机器资源就被掏空了
        60L, TimeUnit.SECONDS, // 闲置线程60秒后销毁
        new SynchronousQueue<Runnable>()); // offer时如果没有空闲线程取出任务，则会失败，线程池就会新建一个线程
}
```

## 13.LinkedTransferQueue 
基于链表的数据交换队列

实现了接口TransferQueue，通过transfer方法放入元素时，如果发现有线程在阻塞在取元素，会直接把这个元素给等待线程。如果没有人等着消费，那么会把这个元素放到队列尾部，并且此方法阻塞直到有人读取这个元素。和SynchronousQueue有点像，但比它更强大。

## 14.DelayQueue 
延时队列

可以使放入队列的元素在指定的延时后才被消费者取出，元素需要实现Delayed接口。


# 同步集合类和并发集合类的区别
不管是同步集合还是并发集合他们都支持线程安全，他们之间主要的**区别体现在性能和可扩展性，还有他们如何实现的线程安全**。

同步集合类，Hashtable 和 Vector 还有同步集合包装类，Collections.synchronizedMap()和Collections.synchronizedList()，相比并发的实现（比如：ConcurrentHashMap, CopyOnWriteArrayList, CopyOnWriteHashSet）会慢得多。

造成如此慢的主要原因是锁， **同步集合会把整个Map或List锁起来，每个操作都是串行的操作，同一时刻只有一个线程能操作。而并发集合不会**，并发集合实现线程安全是通过使用先进的和成熟的技术把锁剥离。

比如ConcurrentHashMap 会把整个Map 划分成几个片段，只对相关的几个片段上锁，同时允许多线程访问其他未上锁的片段。

CopyOnWriteArrayList 允许多个线程以非同步的方式读，当有线程写的时候它会将整个List复制一个副本给它。如果在读多写少这种对并发集合有利的条件下使用并发集合，这会比使用同步集合更具有可伸缩性。


