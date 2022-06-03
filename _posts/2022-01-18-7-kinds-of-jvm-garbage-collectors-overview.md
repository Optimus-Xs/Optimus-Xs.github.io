---
layout: post
title: 7种 JVM 垃圾回收器概览
date: 2022-01-18 15:44 +0800
categories: [Software Development] 
tags: [Java, JVM]
---


# 堆内存详解

![](https://i.ibb.co/42TkWHz/bVcHwwL.webp)

上面这个图大家应该已经很明白了吧。大家就可以理解成一个房子被分成了几个房间，每个房间的作用不同而已，有的是婴儿住的，有的是父母住的，有的是爷爷奶奶住的

- 堆内存被划分为两块，一块的年轻代，另一块是老年代。
- 年轻代又分为Eden和survivor。他俩空间大小比例默认为8:2,
- 幸存区又分为s0和s1。这两个空间大小是一模一样的，就是一对双胞胎，他俩是1:1的比例

## 堆内存垃圾回收过程
1. 新生成的对象首先放到Eden区，当Eden区满了会触发Minor GC。
2. 第一步GC活下来的对象，会被移动到survivor区中的S0区，S0区满了之后会触发Minor GC，S0区存活下来的对象会被移动到S1区，S0区空闲。
  S1满了之后在GC，存活下来的再次移动到S0区，S1区空闲，这样反反复复GC，每GC一次，对象的年龄就涨一岁，达到某个值后（15），就会进入老年代。
3. 在发生一次Minor GC后（前提条件），老年代可能会出现Major GC，这个视垃圾回收器而定。

**Full GC触发条件**
- 手动调用System.gc，会不断的执行Full GC
- 老年代空间不足/满了
- 方法区空间不足/满了
  
>注意
>们需要记住一个单词：stop-the-world。它会在任何一种GC算法中发生。stop-the-world 意味着JVM因为需要执行GC而停止应用程序的执行。
>
>当stop-the-world 发生时，除GC所需的线程外，所有的线程都进入等待状态，直到GC任务完成。GC优化很多时候就是减少stop-the-world 的发生。
{: .prompt-tip }

**回收哪些区域的对象**

需要注意的是，JVM GC只回收堆内存和方法区内的对象。而栈内存的数据，在超出作用域后会被JVM自动释放掉，所以其不在JVM GC的管理范围内。

## 堆内存常见参数配置

| 参数                       | 描述                                                                                |
| :------------------------- | :---------------------------------------------------------------------------------- |
| -Xms                       | 堆内存初始大小，单位m、g                                                            |
| -Xmx                       | 堆内存最大允许大小，一般不要大于物理内存的80%                                       |
| -XX:PermSize               | 非堆内存初始大小，一般应用设置初始化200m，最大1024m就够了                           |
| -XX:MaxPermSize            | 非堆内存最大允许大小                                                                |
| -XX:NewSize（-Xns）        | 年轻代内存初始大小                                                                  |
| -XX:MaxNewSize（-Xmn）     | 年轻代内存最大允许大小                                                              |
| -XX:SurvivorRatio=8        | 年轻代中Eden区与Survivor区的容量比例值，默认为8，即8:1                              |
| -Xss                       | 堆栈内存大小                                                                        |
| -XX:NewRatio=老年代/新生代 | 设置老年代和新生代的大小比例                                                        |
| -XX:+PrintGC               | jvm启动后，只要遇到GC就会打印日志                                                   |
| -XX:+PrintGCDetails        | 查看GC详细信息，包括各个区的情况                                                    |
| -XX:MaxDirectMemorySize    | 在NIO中可以直接访问直接内存，这个就是设置它的大小，不设置默认就是最大堆空间的值-Xmx |
| -XX:+DisableExplicitGC     | 关闭System.gc()                                                                     |
| -XX:MaxTenuringThreshold   | 垃圾可以进入老年代的年龄                                                            |
| -Xnoclassgc                | 禁用垃圾回收                                                                        |
| -XX:TLABWasteTargetPercent | TLAB占eden区的百分比，默认是1%                                                      |
| -XX:+CollectGen0First      | FullGC时是否先YGC，默认false                                                        |

## TLAB 内存
TLAB全称是Thread Local Allocation Buffer即线程本地分配缓存，从名字上看是一个线程专用的内存分配区域，是为了加速对象分配而生的。

每一个线程都会产生一个TLAB，该线程独享的工作区域，java虚拟机使用这种TLAB区来避免多线程冲突问题，提高了对象分配的效率。

TLAB空间一般不会太大，当大对象无法在TLAB分配时，则会直接分配到堆上。

| 参数                        | 描述                                                                                                   |
| :-------------------------- | :----------------------------------------------------------------------------------------------------- |
| -Xx:+UseTLAB                | 使用TLAB                                                                                               |
| -XX:+TLABSize               | 设置TLAB大小                                                                                           |
| -XX:TLABRefillWasteFraction | 设置维护进入TLAB空间的单个对象大小，他是一个比例值，默认为64，即如果对象大于整个空间的1/64，则在堆创建 |
| -XX:+PrintTLAB              | 查看TLAB信息                                                                                           |
| -Xx:ResizeTLAB              | 自调整TLABRefillWasteFraction阀值。                                                                    |

![](https://i.ibb.co/NZtjgMk/20200326170515966.png)


# 垃圾回收器总览
![](https://i.ibb.co/PwG1k1x/bVcHHZL.webp)

新生代可配置的回收器：Serial、ParNew、Parallel Scavenge

老年代配置的回收器：CMS、Serial Old、Parallel Old

新生代和老年代区域的回收器之间进行连线，说明他们之间可以搭配使用。

# 新生代垃圾回收器
## Serial 垃圾回收器
Serial收集器是最基本的、发展历史最悠久的收集器。俗称为：串行回收器，采用复制算法进行垃圾回收

特点

串行回收器是指使用单线程进行垃圾回收的回收器。每次回收时，串行回收器只有一个工作线程。

对于并行能力较弱的单CPU计算机来说，串行回收器的专注性和独占性往往有更好的性能表现。

它存在Stop The World问题，及垃圾回收时，要停止程序的运行。

使用`-XX:+UseSerialGC`参数可以设置新生代使用这个串行回收器

## ParNew 垃圾回收器
ParNew其实就是Serial的多线程版本，除了使用多线程之外，其余参数和Serial一模一样。俗称：并行垃圾回收器，采用复制算法进行垃圾回收

特点
ParNew默认开启的线程数与CPU数量相同，在CPU核数很多的机器上，可以通过参数`-XX:ParallelGCThreads`来设置线程数。

它是目前新生代首选的垃圾回收器，因为除了ParNew之外，它是唯一一个能与老年代CMS配合工作的。

它同样存在Stop The World问题

使用`-XX:+UseParNewGC`参数可以设置新生代使用这个并行回收器

## ParallelGC 回收器
ParallelGC使用复制算法回收垃圾，也是多线程的。

特点
就是非常关注系统的吞吐量，吞吐量=代码运行时间/(代码运行时间+垃圾收集时间)

`-XX:MaxGCPauseMillis`：设置最大垃圾收集停顿时间，可用把虚拟机在GC停顿的时间控制在MaxGCPauseMillis范围内，如果希望减少GC停顿时间可以将MaxGCPauseMillis设置的很小，但是会导致GC频繁，从而增加了GC的总时间，降低了吞吐量。所以需要根据实际情况设置该值。

`-Xx:GCTimeRatio`：设置吞吐量大小，它是一个0到100之间的整数，默认情况下他的取值是99，那么系统将花费不超过1/(1+n)的时间用于垃圾回收，也就是1/(1+99)=1%的时间。

另外还可以指定`-XX:+UseAdaptiveSizePolicy`打开自适应模式，在这种模式下，新生代的大小、eden、from/to的比例，以及晋升老年代的对象年龄参数会被自动调整，以达到在堆大小、吞吐量和停顿时间之间的平衡点。

使用`-XX:+UseParallelGC`参数可以设置新生代使用这个并行回收器


# 老年代垃圾回收器
## SerialOld 垃圾回收器
SerialOld是Serial回收器的老年代回收器版本，它同样是一个单线程回收器。

用途
- 一个是在JDK1.5及之前的版本中与Parallel Scavenge收集器搭配使用，
- 另一个就是作为CMS收集器的后备预案，如果CMS出现Concurrent Mode Failure，则SerialOld将作为后备收集器。

使用算法：标记 - 整理算法

## ParallelOldGC 回收器
老年代ParallelOldGC回收器也是一种多线程的回收器，和新生代的ParallelGC回收器一样，也是一种关注吞吐量的回收器，他使用了标记压缩算法进行实现。

`-XX:+UseParallelOldGc`进行设置老年代使用该回收器

`-XX:+ParallelGCThreads`也可以设置垃圾收集时的线程数量


## CMS 回收器

CMS全称为:Concurrent Mark Sweep意为并发标记清除，他使用的是标记清除法。主要关注系统停顿时间。

使用`-XX:+UseConcMarkSweepGC`进行设置老年代使用该回收器。

使用`-XX:ConcGCThreads`设置并发线程数量。

特点
CMS并不是独占的回收器，也就说CMS回收的过程中，应用程序仍然在不停的工作，又会有新的垃圾不断的产生，所以在使用CMS的过程中应该确保应用程序的内存足够可用。

CMS不会等到应用程序饱和的时候才去回收垃圾，而是在某一阀值的时候开始回收，回收阀值可用指定的参数进行配置：`-XX:CMSInitiatingoccupancyFraction`来指定，默认为68，也就是说当老年代的空间使用率达到68%的时候，会执行CMS回收。

如果内存使用率增长的很快，在CMS执行的过程中，已经出现了内存不足的情况，此时CMS回收就会失败，虚拟机将启动老年代串行回收器；SerialOldGC进行垃圾回收，这会导致应用程序中断，直到垃圾回收完成后才会正常工作。

这个过程GC的停顿时间可能较长，所以`-XX:CMSInitiatingoccupancyFraction`的设置要根据实际的情况。

之前我们在学习算法的时候说过，标记清除法有个缺点就是存在内存碎片的问题，那么CMS有个参数设置`-XX:+UseCMSCompactAtFullCollecion`可以使CMS回收完成之后进行一次碎片整理。

`-XX:CMSFullGCsBeforeCompaction`参数可以设置进行多少次CMS回收之后，对内存进行一次压缩。

## G1 回收器

G1收集器是一款在server端运行的垃圾收集器，专门针对于拥有多核处理器和大内存的机器，在JDK 7u4版本发行时被正式推出，在JDK9中更被指定为官方GC收集器。它满足高吞吐量的同时满足GC停顿的时间尽可能短。G1收集器专门针对以下应用场景设计

- 可以像CMS收集器一样可以和应用并发运行
- 压缩空闲的内存碎片，却不需要冗长的GC停顿
- 对GC停顿可以做更好的预测
- 不想牺牲大量的吞吐量性能
- 不需要更大的Java Heap

G1从长期计划来看是以取代CMS为目标。与CMS相比有几个不同点使得G1成为GC的更好解决方案。第一点：G1会压缩空闲内存使之足够紧凑，做法是用regions代替细粒度的空闲列表进行分配，减少内存碎片的产生。第二点：G1的STW更可控，G1在停顿时间上添加了预测机制，用户可以指定期望停顿时间。

G1收集器的特点

- 设置一个垃圾的预期停顿时间。根据Region的大小和回收价值进行最有效率的回收。
- 内存不再固定划分新生代和老年代，使用Region对于内存进行分块，实现了根据系统资源动态分代。
- Region可能属于新生代或者老年代，同时分配给新生代还是老年代是由G1自己控制的。
- 选择最小回收时间以及最多回收对象的region进行垃圾的回收操作。
