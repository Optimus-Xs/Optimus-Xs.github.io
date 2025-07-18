---
layout: post
title: HashMap的原理和动态扩容
date: 2022-02-03 16:34 +0800
categories: [Software Development] 
tags: [Java, Data Structure]
---

# HashMap的底层实现
HashMap基于**Map**接口实现，继承AbstractMap，它存储的内容是键值对(key:value)，它的key是唯一的，且key和value都可以为null。此外，HashMap中的映射不是有序的。

HashMap 的实现不是同步的，这意味着它不是线程安全的。如果想要线程安全的HashMap，可以通过Collections类的静态方法synchronizedMap获得线程安全的HashMap，或者ConcurrentHashmap。它之所以有相当快的查询速度主要是因为它是通过计算哈希值来决定存储的位置。

**初始容量**，**负载因子**是影响HashMap性能的重要参数。

其中容量表示HashMap中数组的大小，初始容量是创建HashMap时的容量，负载因子是HashMap在其扩容之前可以达到多满的一种尺度，它衡量的是HashMap的空间的使用程度，负载因子越大表示HashMap元素的填满程度。负载因子越大，填满程度越高，好处是空间利用率高了，但冲突的机会加大了，链表长度会越来越长，查找效率降低。负载因子越小，填满程度越低，好处是冲突的机会减小了，但空间浪费严重，表中的数据将过于稀疏（很多空间还没用，就开始扩容了）。

系统默认负载因子为0.75，一般情况下我们是无需修改的。

## JDK1.8之前和JDK1.8之后的内部结构
JDK1.8 之前 HashMap 底层是数组和链表结合在一起使用也就是链表散列。HashMap 通过 key 的 hashCode 经过扰动函数处理过后得到 hash 值，然后通过hash & (n - 1) 判断当前元素存放的位置（这里的 n 指的是数组的长度），如果当前位置存在元素的话，就判断该元素与要存入的元素的 hash 值以及 key 是否相同，如果相同的话，直接覆盖，不相同就通过拉链法解决冲突。

所谓扰动函数指的就是 HashMap 的 hash 方法。使用 hash 方法也就是扰动函数是为了防止一些实现比较差的 hashCode() 方法 换句话说使用扰动函数之后可以减少碰撞。

JDK 1.8 HashMap 的 hash 方法源码如下，相比于 JDK 1.7 hash 方法更加简化，但是原理不变。
```java
static final int hash(Object key) {
  int h;
  // key.hashCode()：返回散列值也就是hashcode
  // ^ ：按位异或
  // >>>:无符号右移，忽略符号位，空位都以0补齐
  return (key == null) ? 0 : (h = key.hashCode()) ^ (h >>> 16);
}
```
对比一下 JDK1.7的 HashMap 的 hash 方法源码.
```java
static int hash(int h) {
  // This function ensures that hashCodes that differ only by
  // constant multiples at each bit position have a bounded
  // number of collisions (approximately 8 at default load factor).

  h ^= (h >>> 20) ^ (h >>> 12);
  return h ^ (h >>> 7) ^ (h >>> 4);
}
```
整个过程本质上就是三步：

1. 拿到key的hashCode值
2. 将hashCode的高位参与运算，重新计算hash值
3. 将计算出来的hash值与(table.length - 1)进行&运算

相比于 JDK1.8 的 hash 方法 ，JDK 1.7 的 hash 方法的性能会稍差一点点，因为毕竟扰动了 4 次。

所谓 “拉链法” 就是：将链表和数组相结合。也就是说创建一个链表数组，数组中每个格就是一个链表。若遇到哈希冲突，则将冲突键值以头插或者尾插的方式插入数组下标所在的链表。

![](https://cdn.jsdelivr.net/gh/Optimus-Xs/Blog-Images/2022-02-03-the-principle-of-hashmap-and-dynamic-scaling/816762-20210303102042048-1066595758.jpg)
_JDK1.8之前的内部结构_

相比于之前的版本， JDK1.8之后在解决哈希冲突时有了较大的变化，当链表长度大于阈值（默认为8）时且数组长度不小于64时，将链表转化为红黑树，以减少搜索时间。

![](https://cdn.jsdelivr.net/gh/Optimus-Xs/Blog-Images/2022-02-03-the-principle-of-hashmap-and-dynamic-scaling/20181120170735304.jpg)
_JDK1.8之后的HashMap底层数据结构_

TreeMap、TreeSet以及JDK1.8之后的HashMap底层都用到了红黑树。红黑树就是为了解决二叉查找树的缺陷，因为二叉查找树在某些情况下会退化成一个线性结构。

一句话总结：JDK1.8后，HashMap存储的数据结构由数组+链表的方式，变化为数组+链表+红黑树的方式，在性能上进一步得到提升。

# HashMap扩容
## 什么时候扩容
**JDK 1.7:**

扩容必须同时满足两个条件：

- 存放新值的时候当前已有元素的个数达到阈值；
- 存放新值的时候发生哈希冲突（当前key的hash值计算出来的数组下标位置已存在值）

**JDK 1.8:**

发生扩容的时候有两种情况：

- 已有的元素达到阈值了；
- HashMap准备转为红黑树但又发现数组长度小于64。

## 扩容方法
**JDK 1.7**

- 新建一个数组，容量为原来的2倍，并通过transfer方法，遍历原来table中每个位置的链表，并对每个元素进行重新hash，得到在新数组的位置后插入。最后重新计算阈值。
- 并发时可能会产生死锁：复制链表时逆序，形成环形链表。
- 因为原数组中的数据必须重新计算其在新数组中的位置，再放进新数组，特别耗性能。如果我们已经预知HashMap中元素的个数，那么预设元素的个数能够有效的提高HashMap的性能，避免map进行频繁的扩容。

**JDK 1.8**

- 不管怎么样都不需要重新再计算hash；
- 复制链表时元素的相对顺序不会改变；
- 不会在并发扩容中发生死锁。

## HashMap 的长度必须是2的整数次幂

- HashMap的数组长度一定保持2的整数次幂，比如长度16的二进制表示为 10000，那么n-1就是15，二进制为01111，同理扩容后的数组长度为32，二进制表示为100000，n-1为31，二进制表示为011111。这样会保证低位全为1，而扩容后只有一位差异，也就是多出了最左位的1，这样在计算 h & (n-1)的时候，只要h对应的最左边的那一个差异位为0，就能保证得到的新的数组下标和旧数组下标一致，大大减少了之前已经哈希好的旧数组的数据位置重新调换。
- n取2的整数次幂，n-1的值是低位全为1，这种情况下，对于h低位部分来说，任何一位的变化都会对结果产生影响，哈希冲突的几率降低，这样就能使元素在表中均匀地散列。
- 最后，n为2的整数次幂的话，h&(n-1)就相当于对n取模，位运算相比取余运算提升了效率。

