---
layout: post
title: Java 多线程概览
date: 2020-11-27 16:43 +0800
categories: [Software Development] 
tags: [Java]
---

# 前言
用多线程只有一个目的，那就是更好的利用cpu的资源，因为所有的多线程代码都可以用单线程来实现。说这个话其实只有一半对，因为反应“多角色”的程序代码，最起码每个角色要给他一个线程吧，否则连实际场景都无法模拟，当然也没法说能用单线程来实现：比如最常见的“生产者，消费者模型”。

其中的一些概念不够明确，如同步、并发等等，让我们先建立一个数据字典，以免产生误会。

- 多线程：指的是这个程序（一个进程）运行时产生了不止一个线程
- 并行：多个cpu实例或者多台机器同时执行一段处理逻辑，是真正的同时。
- 并发：通过cpu调度算法，让用户看上去同时执行，实际上从cpu操作层面不是真正的同时。并发往往在场景中有公用的资源，那么针对这个公用的资源往往产生瓶颈，我们会用TPS或者QPS来反应这个系统的处理能力。
- 线程安全：经常用来描绘一段代码。指在并发的情况之下，该代码经过多线程使用，线程的调度顺序不影响任何结果。这个时候使用多线程，我们只需要关注系统的内存，cpu是不是够用即可。反过来，线程不安全就意味着线程的调度顺序会影响最终结果，如不加事务的转账代码
```java
void transferMoney(User from, User to, float amount){
  to.setMoney(to.getBalance() + amount);
  from.setMoney(from.getBalance() - amount);
}
```
- 同步：Java中的同步指的是通过人为的控制和调度，保证共享资源的多线程访问成为线程安全，来保证结果的准确。如上面的代码简单加入@synchronized关键字。在保证结果准确的同时，提高性能，才是优秀的程序。线程安全的优先级高于性能。


# 什么是Java多线程?
## 进程与线程
进程
- 当一个程序被运行，就开启了一个进程， 比如启动了qq，word
- 程序由指令和数据组成，指令要运行，数据要加载，指令被cpu加载运行，数据被加载到内存，指令运行时可由cpu调度硬盘、网络等设备
  
线程
- 一个进程内可分为多个线程
- 一个线程就是一个指令流，cpu调度的最小单位，由cpu一条一条执行指令
  
## 并行与并发
并发：单核cpu运行多线程时，时间片进行很快的切换。线程轮流执行cpu

并行：多核cpu运行 多线程时，真正的在同一时刻运行

![并发对比并行](https://i.ibb.co/k2HXt2R/a-HR0c-HM6-Ly9w-OS1qd-WVqa-W4u-Ynl0-ZWlt-Zy5jb20vd-G9z-LWNu-LWktaz-N1-MWZic-GZjc-C84-MWU5-OWUx-ODk3.png)

Java提供了丰富的api来支持多线程。


# 为什么用多线程?
多线程能实现的都可以用单线程来完成，那单线程运行的好好的，为什么Java要引入多线程的概念呢？

多线程的好处：

- 程序运行的更快！快！快！
- 充分利用cpu资源，目前几乎没有线上的cpu是单核的，发挥多核cpu强大的能力

# 多线程难在哪里？
单线程只有一条执行线，过程容易理解，可以在大脑中清晰的勾勒出代码的执行流程

多线程却是多条线，而且一般多条线之间有交互，多条线之间需要通信，一般难点有以下几点

- 多线程的执行结果不确定,受到cpu调度的影响
- 多线程的安全问题
- 线程资源宝贵，依赖线程池操作线程，线程池的参数设置问题
- 多线程执行是动态的，同时的,难以追踪过程
- 多线程的底层是操作系统层面的，源码难度大

# Java多线程的基本使用
## 定义任务、创建和运行线程
任务： 线程的执行体。也就是我们的核心代码逻辑

定义任务

- 继承Thread类 （可以说是 将任务和线程合并在一起）
- 实现Runnable接口 （可以说是 将任务和线程分开了）
- 实现Callable接口 (利用FutureTask执行任务)

Thread实现任务的局限性

- 任务逻辑写在Thread类的run方法中，有单继承的局限性
- 创建多线程时，每个任务有成员变量时不共享，必须加static才能做到共享
  
Runnable和Callable解决了Thread的局限性

但是Runbale相比Callable有以下的局限性

- 任务没有返回值
- 任务无法抛异常给调用方
  
如下代码 几种定义线程的方式
```java
@Slf4j
class T extends Thread {
    @Override
    public void run() {
        log.info("我是继承Thread的任务");
    }
}
@Slf4j
class R implements Runnable {

    @Override
    public void run() {
        log.info("我是实现Runnable的任务");
    }
}
@Slf4j
class C implements Callable<String> {

    @Override
    public String call() throws Exception {
        log.info("我是实现Callable的任务");
        return "success";
    }
}
```
创建线程的方式

- 通过Thread类直接创建线程
- 利用线程池内部创建线程

启动线程的方式

调用线程的start()方法
```java
// 启动继承Thread类的任务
new T().start();

// 启动继承Thread匿名内部类的任务 可用lambda优化
Thread t = new Thread(){
  @Override
  public void run() {
    log.info("我是Thread匿名内部类的任务");
  }
};

//  启动实现Runnable接口的任务
new Thread(new R()).start();

//  启动实现Runnable匿名实现类的任务
new Thread(new Runnable() {
    @Override
    public void run() {
        log.info("我是Runnable匿名内部类的任务");
    }
}).start();

//  启动实现Runnable的lambda简化后的任务
new Thread(() -> log.info("我是Runnable的lambda简化后的任务")).start();

// 启动实现了Callable接口的任务 结合FutureTask 可以获取线程执行的结果
FutureTask<String> target = new FutureTask<>(new C());
new Thread(target).start();
log.info(target.get());
```
以上各个线程相关的类的类图如下

![线程相关的类的类图](https://i.ibb.co/SyfScfN/a-HR0c-HM6-Ly9w-MS1qd-WVqa-W4u-Ynl0-ZWlt-Zy5jb20vd-G9z-LWNu-LWktaz-N1-MWZic-GZjc-C9l-Zj-U0-Yj-Qy-Zj.png)

## 上下文切换
多核cpu下，多线程是并行工作的，如果线程数多，单个核又会并发的调度线程,运行时会有上下文切换的概念

cpu执行线程的任务时，会为线程分配时间片，以下几种情况会发生上下文切换。

- 线程的cpu时间片用完
- 垃圾回收
- 线程自己调用了 sleep、yield、wait、join、park、synchronized、lock 等方法

当发生上下文切换时，操作系统会保存当前线程的状态，并恢复另一个线程的状态,jvm中有块内存地址叫程序计数器，用于记录线程执行到哪一行代码,是线程私有的。

## 线程的礼让-yield()&线程的优先级
yield()方法会让运行中的线程切换到就绪状态，重新争抢cpu的时间片，争抢时是否获取到时间片看cpu的分配。
```java
public static native void yield();

Runnable r1 = () -> {
    int count = 0;
    for (;;){
       log.info("---- 1>" + count++);
    }
};
Runnable r2 = () -> {
    int count = 0;
    for (;;){
        Thread.yield();
        log.info("            ---- 2>" + count++);
    }
};
Thread t1 = new Thread(r1,"t1");
Thread t2 = new Thread(r2,"t2");
t1.start();
t2.start();
```
运行结果
```
11:49:15.796 [t1] INFO thread.TestYield - ---- 1>129504
11:49:15.796 [t1] INFO thread.TestYield - ---- 1>129505
11:49:15.796 [t1] INFO thread.TestYield - ---- 1>129506
11:49:15.796 [t1] INFO thread.TestYield - ---- 1>129507
11:49:15.796 [t1] INFO thread.TestYield - ---- 1>129508
11:49:15.796 [t1] INFO thread.TestYield - ---- 1>129509
11:49:15.796 [t1] INFO thread.TestYield - ---- 1>129510
11:49:15.796 [t1] INFO thread.TestYield - ---- 1>129511
11:49:15.796 [t1] INFO thread.TestYield - ---- 1>129512
11:49:15.798 [t2] INFO thread.TestYield -             ---- 2>293
11:49:15.798 [t1] INFO thread.TestYield - ---- 1>129513
11:49:15.798 [t1] INFO thread.TestYield - ---- 1>129514
11:49:15.798 [t1] INFO thread.TestYield - ---- 1>129515
11:49:15.798 [t1] INFO thread.TestYield - ---- 1>129516
11:49:15.798 [t1] INFO thread.TestYield - ---- 1>129517
11:49:15.798 [t1] INFO thread.TestYield - ---- 1>129518
```
如上述结果所示，t2线程每次执行时进行了yield()，线程1执行的机会明显比线程2要多。

## 线程的优先级

​ 线程内部用1~10的数来调整线程的优先级，默认的线程优先级为NORM_PRIORITY:5

​ cpu比较忙时，优先级高的线程获取更多的时间片

​ cpu比较闲时，优先级设置基本没用

## 守护线程
默认情况下，Java进程需要等待所有线程都运行结束，才会结束，有一种特殊线程叫守护线程，当所有的非守护线程都结束后，即使它没有执行完，也会强制结束。

默认的线程都是非守护线程。

垃圾回收线程就是典型的守护线程
```java
// 方法的定义
public final void setDaemon(boolean on) {
}

Thread thread = new Thread(() -> {
    while (true) {
    }
});
// 具体的api。设为true表示未守护线程，当主线程结束后，守护线程也结束。
// 默认是false，当主线程结束后，thread继续运行，程序不停止
thread.setDaemon(true);
thread.start();
log.info("结束");
```

## 线程的阻塞
线程的阻塞可以分为好多种，从操作系统层面和Java层面阻塞的定义可能不同，但是广义上使得线程阻塞的方式有下面几种

- BIO阻塞，即使用了阻塞式的io流
- sleep(long time) 让线程休眠进入阻塞状态
- a.join() 调用该方法的线程进入阻塞，等待a线程执行完恢复运行
- sychronized或ReentrantLock 造成线程未获得锁进入阻塞状态 (同步锁章节细说)
- 获得锁之后调用wait()方法 也会让线程进入阻塞状态 (同步锁章节细说)
- LockSupport.park() 让线程进入阻塞状态 (同步锁章节细说)

### sleep()
使线程休眠，会将运行中的线程进入阻塞状态。当休眠时间结束后，重新争抢cpu的时间片继续运行
```java
// 方法的定义 native方法
public static native void sleep(long millis) throws InterruptedException; 

try {
   // 休眠2秒
   // 该方法会抛出 InterruptedException异常 即休眠过程中可被中断，被中断后抛出异常
   Thread.sleep(2000);
 } catch (InterruptedException异常 e) {
 }
 try {
   // 使用TimeUnit的api可替代 Thread.sleep 
   TimeUnit.SECONDS.sleep(1);
 } catch (InterruptedException e) {
 }
```
### join()
​join是指调用该方法的线程进入阻塞状态，等待某线程执行完成后恢复运行
```java
// 方法的定义 有重载
// 等待线程执行完才恢复运行
public final void join() throws InterruptedException {
}
// 指定join的时间。指定时间内 线程还未执行完 调用方线程不继续等待就恢复运行
public final synchronized void join(long millis)
    throws InterruptedException{}
```

```java
Thread t = new Thread(() -> {
    try {
        Thread.sleep(1000);
    } catch (InterruptedException e) {
        e.printStackTrace();
    }
    r = 10;
});

t.start();
// 让主线程阻塞 等待t线程执行完才继续执行 
// 去除该行，执行结果为0，加上该行 执行结果为10
t.join();
log.info("r:{}", r);
```
运行结果
```
13:09:13.892 [main] INFO thread.TestJoin - r:10
```

## 线程的打断-interrupt()
```java
// 相关方法的定义
public void interrupt() {
}
public boolean isInterrupted() {
}
public static boolean interrupted() {
}
```
打断标记：线程是否被打断，true表示被打断了，false表示没有

isInterrupted() 获取线程的打断标记 ,调用后不会修改线程的打断标记

interrupt()方法用于中断线程

- 可以打断sleep,wait,join等显式的抛出InterruptedException方法的线程，但是打断后,线程的打断标记还是false
- 打断正常线程 ，线程不会真正被中断，但是线程的打断标记为true

interrupted() 获取线程的打断标记，调用后清空打断标记 即如果获取为true 调用后打断标记为false (不常用)

interrupt实例： 有个后台监控线程不停的监控，当外界打断它时，就结束运行。代码如下
```java
@Slf4j
class TwoPhaseTerminal{
    // 监控线程
    private Thread monitor;

    public void start(){
        monitor = new Thread(() ->{
           // 不停的监控
            while (true){
                Thread thread = Thread.currentThread();
             	// 判断当前线程是否被打断
                if (thread.isInterrupted()){
                    log.info("当前线程被打断,结束运行");
                    break;
                }
                try {
                    Thread.sleep(1000);
                	// 监控逻辑中被打断后，打断标记为true
                    log.info("监控");
                } catch (InterruptedException e) {
                    // 睡眠时被打断时抛出异常 在该处捕获到 此时打断标记还是false
                    // 在调用一次中断 使得中断标记为true
                    thread.interrupt();
                }
            }
        });
        monitor.start();
    }

    public void stop(){
        monitor.interrupt();
    }
}
```
## 线程的状态
上面说了一些基本的api的使用，调用上面的方法后都会使得线程有对应的状态。

线程的状态可从 操作系统层面分为五种状态 从Java api层面分为六种状态。

### 五种状态
![线程五种状态](https://i.ibb.co/Hq3WS80/M44-KQ8-VFEG1216-MTJ9-Q9-GK3-ID.png)

1. 初始状态：创建线程对象时的状态
2. 可运行状态(就绪状态)：调用start()方法后进入就绪状态，也就是准备好被cpu调度执行
3. 运行状态：线程获取到cpu的时间片，执行run()方法的逻辑
4. 阻塞状态: 线程被阻塞，放弃cpu的时间片，等待解除阻塞重新回到就绪状态争抢时间片
5. 终止状态: 线程执行完成或抛出异常后的状态

### 六种状态

![线程六种状态](https://i.ibb.co/1nqFD2n/1689841-383f7101e6588094.png)

```java
public enum State {
	NEW,
	RUNNABLE,
	BLOCKED,
	WAITING,
	TIMED_WAITING,
	TERMINATED;
}
```
六种线程状态和方法的对应关系
![线程六种状态方法](https://imgconvert.csdnimg.cn/aHR0cHM6Ly9wMy1qdWVqaW4uYnl0ZWltZy5jb20vdG9zLWNuLWktazN1MWZicGZjcC82MjI2NTkzMzdmY2E0NDZjOGNjYjRkZTZjMjZiMTJiNX50cGx2LWszdTFmYnBmY3Atem9vbS0xLmltYWdl?x-oss-process=image/format,png)

1. NEW 线程对象被创建
2. Runnable 线程调用了start()方法后进入该状态，该状态包含了三种情况
   1. 就绪状态 :等待cpu分配时间片
   2. 运行状态:进入Runnable方法执行任务
   3. 阻塞状态:BIO 执行阻塞式io流时的状态
3. Blocked 没获取到锁时的阻塞状态(同步锁章节会细说)
4. WAITING（等待） 调用wait()、join()等方法后的状态
5. TIMED_WAITING（锁定） 调用 sleep(time)、wait(time)、join(time)等方法后的状态
6. TERMINATED 线程执行完成或抛出异常后的状态

## 线程的相关方法总结
主要总结Thread类中的核心方法

| 方法名称          | 是否static | 方法说明                                                                                                                 |
| :---------------- | :--------- | :----------------------------------------------------------------------------------------------------------------------- |
| start()           | 否         | 让线程启动，进入就绪状态,等待cpu分配时间片                                                                               |
| run()             | 否         | 重写Runnable接口的方法,线程获取到cpu时间片时执行的具体逻辑                                                               |
| yield()           | 是         | 线程的礼让，使得获取到cpu时间片的线程进入就绪状态，重新争抢时间片                                                        |
| sleep(time)       | 是         | 线程休眠固定时间，进入阻塞状态，休眠时间完成后重新争抢时间片,休眠可被打断                                                |
| join()/join(time) | 否         | 调用线程对象的join方法，调用者线程进入阻塞,等待线程对象执行完或者到达指定时间才恢复，重新争抢时间片                      |
| isInterrupted()   | 否         | 获取线程的打断标记，true:被打断，false：没有被打断。调用后不会修改打断标记                                               |
| interrupt()       | 否         | 打断线程，抛出InterruptedException异常的方法均可被打断，但是打断后不会修改打断标记，正常执行的线程被打断后会修改打断标记 |
| interrupted()     | 否         | 获取线程的打断标记。调用后会清空打断标记                                                                                 |
| stop()            | 否         | 停止线程运行 不推荐                                                                                                      |
| suspend()         | 否         | 挂起线程 不推荐                                                                                                          |
| resume()          | 否         | 恢复线程运行 不推荐                                                                                                      |
| currentThread()   | 是         | 获取当前线程                                                                                                             |

Object中与线程相关方法

| 方法名称                  | 方法说明                               |
| :------------------------ | :------------------------------------- |
| wait()/wait(long timeout) | 获取到锁的线程进入阻塞状态             |
| notify()                  | 随机唤醒被wait()的一个线程             |
| notifyAll();              | 唤醒被wait()的所有线程，重新争抢时间片 |


# 同步锁
## 线程安全
- 一个程序运行多个线程本身是没有问题的
- 问题有可能出现在多个线程访问共享资源
  - 多个线程都是读共享资源也是没有问题的
  - 当多个线程读写共享资源时,如果发生指令交错，就会出现问题

临界区: 一段代码如果对共享资源的多线程读写操作,这段代码就被称为临界区。

注意的是 指令交错指的是 Java代码在解析成字节码文件时，Java代码的一行代码在字节码中可能有多行，在线程上下文切换时就有可能交错。

线程安全指的是多线程调用同一个对象的临界区的方法时，对象的属性值一定不会发生错误，这就是保证了线程安全。

如下面不安全的代码

```java
// 对象的成员变量
private static int count = 0;

public static void main(String[] args) throws InterruptedException {
  // t1线程对变量+5000次
    Thread t1 = new Thread(() -> {
        for (int i = 0; i < 5000; i++) {
            count++;
        }
    });
  // t2线程对变量-5000次
    Thread t2 = new Thread(() -> {
        for (int i = 0; i < 5000; i++) {
            count--;
        }
    });

    t1.start();
    t2.start();

    // 让t1 t2都执行完
    t1.join();
    t2.join();
    System.out.println(count);
}

// 运行结果 
-1399
```
>上面的代码 两个线程，一个+5000次，一个-5000次，如果线程安全，count的值应该还是0。
>
>但是运行很多次，每次的结果不同，且都不是0，所以是线程不安全的。
{: .prompt-info }

**线程安全的类一定所有的操作都线程安全吗？**

开发中经常会说到一些线程安全的类，如ConcurrentHashMap，线程安全指的是类里每一个独立的方法是线程安全的，但是方法的组合就不一定是线程安全的。

**成员变量和静态变量是否线程安全?**

- 如果没有多线程共享，则线程安全
- 如果存在多线程共享
  - 多线程只有读操作，则线程安全
  - 多线程存在写操作，写操作的代码又是临界区,则线程不安全

**局部变量是否线程安全?**

- 局部变量是线程安全的
- 局部变量引用的对象未必是线程安全的
  - 如果该对象没有逃离该方法的作用范围，则线程安全
  - 如果该对象逃离了该方法的作用范围，比如：方法的返回值,需要考虑线程安全

## synchronized
同步锁也叫对象锁，是锁在对象上的，不同的对象就是不同的锁。

该关键字是用于保证线程安全的，是阻塞式的解决方案。

让同一个时刻最多只有一个线程能持有对象锁，其他线程在想获取这个对象锁就会被阻塞，不用担心上下文切换的问题。

注意： 不要理解为一个线程加了锁 ，进入 synchronized代码块中就会一直执行下去。如果时间片切换了，也会执行其他线程，再切换回来会紧接着执行，只是不会执行到有竞争锁的资源，因为当前线程还未释放锁。

当一个线程执行完synchronized的代码块后 会唤醒正在等待的线程

synchronized实际上使用对象锁保证临界区的原子性 临界区的代码是不可分割的 不会因为线程切换所打断

基本使用
```java
// 加在方法上 实际是对this对象加锁
private synchronized void a() {
}

// 同步代码块,锁对象可以是任意的，加在this上 和a()方法作用相同
private void b(){
    synchronized (this){

    }
}

// 加在静态方法上 实际是对类对象加锁
private synchronized static void c() {

}

// 同步代码块 实际是对类对象加锁 和c()方法作用相同
private void d(){
    synchronized (TestSynchronized.class){
        
    }
}
```
```c
// 上述b方法对应的字节码源码 其中monitorenter就是加锁的地方
aload_0
dup
astore_1
monitorenter
aload_1
monitorexit
goto 14 (+8)
astore_2
aload_1
monitorexit
aload_2
athrow
return
```
{: file='.class'}

线程安全的代码
```java
private static int count = 0;

private static Object lock = new Object();

private static Object lock2 = new Object();

 // t1线程和t2对象都是对同一对象加锁。保证了线程安全。此段代码无论执行多少次，结果都是0
public static void main(String[] args) throws InterruptedException {
    Thread t1 = new Thread(() -> {
        for (int i = 0; i < 5000; i++) {
            synchronized (lock) {
                count++;
            }
        }
    });
    Thread t2 = new Thread(() -> {
        for (int i = 0; i < 5000; i++) {
            synchronized (lock) {
                count--;
            }
        }
    });
 
    t1.start();
    t2.start();

    // 让t1 t2都执行完
    t1.join();
    t2.join();
    System.out.println(count);
}
```

>重点：加锁是加在对象上，一定要保证是同一对象，加锁才能生效
{: .prompt-tip }

## 线程通信
### wait+notify
线程间通信可以通过共享变量+wait()¬ify()来实现

wait()将线程进入阻塞状态，notify()将线程唤醒

当多线程竞争访问对象的同步方法时，锁对象会关联一个底层的Monitor对象(重量级锁的实现)

如下图所示 Thread0,1先竞争到锁执行了代码后，2,3,4,5线程同时来执行临界区的代码,开始竞争锁

![](https://i.ibb.co/vv4M5jZ/a-HR0c-HM6-Ly9w-My1qd-WVqa-W4u-Ynl0-ZWlt-Zy5jb20vd-G9z-LWNu-LWktaz-N1-MWZic-GZjc-C8z-Zj-A0-Zjlk-MTIw.png)

1. Thread-0先获取到对象的锁，关联到monitor的owner，同步代码块内调用了锁对象的wait()方法，调用后会进入waitSet等待，Thread-1同样如此，此时Thread-0的状态为Waitting
2. Thread2、3、4、5同时竞争，2获取到锁后，关联了monitor的owner，3、4、5只能进入EntryList中等待，此时2线程状态为 Runnable，3、4、5状态为Blocked
3. 2执行后，唤醒entryList中的线程，3、4、5进行竞争锁，获取到的线程即会关联monitor的owner
4. 3、4、5线程在执行过程中，调用了锁对象的notify()或notifyAll()时，会唤醒waitSet的线程，唤醒的线程进入entryList等待重新竞争锁

注意:
- Blocked状态和Waitting状态都是阻塞状态
- Blocked线程会在owner线程释放锁时唤醒
- wait和notify使用场景是必须要有同步，且必须获得对象的锁才能调用,使用锁对象去调用,否则会抛异常
- wait() 释放锁 进入 waitSet 可传入时间，如果指定时间内未被唤醒 则自动唤醒
- notify()随机唤醒一个waitSet里的线程
- notifyAll()唤醒waitSet中所有的线程

```java
static final Object lock = new Object();
new Thread(() -> {
    synchronized (lock) {
        log.info("开始执行");
        try {
          	// 同步代码内部才能调用
            lock.wait();
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        log.info("继续执行核心逻辑");
    }
}, "t1").start();

new Thread(() -> {
    synchronized (lock) {
        log.info("开始执行");
        try {
            lock.wait();
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        log.info("继续执行核心逻辑");
    }
}, "t2").start();

try {
    Thread.sleep(2000);
} catch (InterruptedException e) {
    e.printStackTrace();
}
log.info("开始唤醒");

synchronized (lock) {
  // 同步代码内部才能调用
    lock.notifyAll();
}
```
执行结果
```
14:29:47.138 [t1] INFO TestWaitNotify - 开始执行
14:29:47.141 [t2] INFO TestWaitNotify - 开始执行
14:29:49.136 [main] INFO TestWaitNotify - 开始唤醒
14:29:49.136 [t2] INFO TestWaitNotify - 继续执行核心逻辑
14:29:49.136 [t1] INFO TestWaitNotify - 继续执行核心逻辑
```

**wait 和 sleep的区别?**
二者都会让线程进入阻塞状态，有以下区别

- wait是Object的方法 sleep是Thread的方法
- wait会立即释放锁 sleep不会释放锁
- wait后线程的状态是Watting sleep后线程的状态为 Time_Waiting

### park&unpark
LockSupport是juc下的工具类，提供了park和unpark方法，可以实现线程通信

**与wait和notity相比的不同点**

- wait 和notify需要获取对象锁 park unpark不要
- unpark 可以指定唤醒线程 notify随机唤醒
- park和unpark的顺序可以先unpark wait和notify的顺序不能颠倒

## 生产者消费者模型
指的是有生产者来生产数据，消费者来消费数据，生产者生产满了就不生产了，通知消费者取，等消费了再进行生产。

消费者消费不到了就不消费了，通知生产者生产，生产到了再继续消费。

```java
  public static void main(String[] args) throws InterruptedException {
        MessageQueue queue = new MessageQueue(2);
		
		// 三个生产者向队列里存值
        for (int i = 0; i < 3; i++) {
            int id = i;
            new Thread(() -> {
                queue.put(new Message(id, "值" + id));
            }, "生产者" + i).start();
        }

        Thread.sleep(1000);

		// 一个消费者不停的从队列里取值
        new Thread(() -> {
            while (true) {
                queue.take();
            }
        }, "消费者").start();

    }
}

// 消息队列被生产者和消费者持有
class MessageQueue {
    private LinkedList<Message> list = new LinkedList<>();

    // 容量
    private int capacity;

    public MessageQueue(int capacity) {
        this.capacity = capacity;
    }

    /**
     * 生产
     */
    public void put(Message message) {
        synchronized (list) {
            while (list.size() == capacity) {
                log.info("队列已满，生产者等待");
                try {
                    list.wait();
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
            list.addLast(message);
            log.info("生产消息:{}", message);
            // 生产后通知消费者
            list.notifyAll();
        }
    }

    public Message take() {
        synchronized (list) {
            while (list.isEmpty()) {
                log.info("队列已空，消费者等待");
                try {
                    list.wait();
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
            Message message = list.removeFirst();
            log.info("消费消息:{}", message);
            // 消费后通知生产者
            list.notifyAll();
            return message;
        }
    }
}
 // 消息
class Message {

    private int id;

    private Object value;
}
```

## 同步锁案例
为了更形象的表达加同步锁的概念，这里举一个生活中的例子，尽量把以上的概念具体化出来。

现实中，我们去银行门口的自动取款机取钱，取款机的钱就是共享变量，为了保障安全，不可能两个陌生人同时进入同一个取款机内取钱，所以只能一个人进入取钱，然后锁上取款机的门，其他人只能在取款机门口等待。

取款机有多个，里面的钱互不影响，锁也有多个（多个对象锁），取钱人在多个取款机里同时取钱也没有安全问题。

假如每个取钱的陌生人都是线程，当取钱人进入取款机锁了门后(线程获得锁)，取到钱后出门(线程释放锁)，下一个人竞争到锁来取钱。

假设工作人员也是一个线程,如果取钱人进入后发现取款机钱不足了，这时通知工作人员来向取款机里加钱(调用notifyAll方法)，取钱人暂停取钱，进入银行大堂阻塞等待(调用wait方法)。

银行大堂里的工作人员和取钱人都被唤醒，重新竞争锁，进入后如果是取钱人，由于取款机没钱，还得进入银行大堂等待。

当工作人员获得取款机的锁进入后，加了钱后会通知大厅里的人来取钱(调用notifyAll方法)。自己暂停加钱，进入银行大堂等待唤醒加钱(调用wait方法)。

这时大堂里等待的人都来竞争锁，谁获取到谁进入继续取钱。

![](https://i.ibb.co/r7g7bTb/a-HR0c-HM6-Ly9w-MS1qd-WVqa-W4u-Ynl0-ZWlt-Zy5jb20vd-G9z-LWNu-LWktaz-N1-MWZic-GZjc-C9j-Nz-Zj-MGYw-Yzhk.png)

和现实中不同的就是这里没有排队的概念，谁抢到锁谁进去取。

## ReentrantLock
可重入锁 : 一个线程获取到对象的锁后，执行方法内部在需要获取锁的时候是可以获取到的。如以下代码
```java
private static final ReentrantLock LOCK = new ReentrantLock();

private static void m() {
    LOCK.lock();
    try {
        log.info("begin");
      	// 调用m1()
        m1();
    } finally {
        // 注意锁的释放
        LOCK.unlock();
    }
}
public static void m1() {
    LOCK.lock();
    try {
        log.info("m1");
        m2();
    } finally {
        // 注意锁的释放
        LOCK.unlock();
    }
}
```
synchronized 也是可重入锁，ReentrantLock有以下优点

- 支持获取锁的超时时间
- 获取锁时可被打断
- 可设为公平锁
- 可以有不同的条件变量，即有多个waitSet，可以指定唤醒

api
```java
// 默认非公平锁，参数传true 表示未公平锁
ReentrantLock lock = new ReentrantLock(false);
// 尝试获取锁
lock()
// 释放锁 应放在finally块中 必须执行到
unlock()
try {
    // 获取锁时可被打断,阻塞中的线程可被打断
    LOCK.lockInterruptibly();
} catch (InterruptedException e) {
    return;
}
// 尝试获取锁 获取不到就返回false
LOCK.tryLock()
// 支持超时时间 一段时间没获取到就返回false
tryLock(long timeout, TimeUnit unit)
// 指定条件变量 休息室 一个锁可以创建多个休息室
Condition waitSet = ROOM.newCondition();
// 释放锁  进入waitSet等待 释放后其他线程可以抢锁
yanWaitSet.await()
// 唤醒具体休息室的线程 唤醒后 重写竞争锁
yanWaitSet.signal()
```
实例：一个线程输出a，一个线程输出b，一个线程输出c，abc按照顺序输出，连续输出5次

这个考的就是线程的通信，利用 wait()/notify()和控制变量可以实现，此处使用ReentrantLock即可实现该功能。
```java
  public static void main(String[] args) {
        AwaitSignal awaitSignal = new AwaitSignal(5);
        // 构建三个条件变量
        Condition a = awaitSignal.newCondition();
        Condition b = awaitSignal.newCondition();
        Condition c = awaitSignal.newCondition();
        // 开启三个线程
        new Thread(() -> {
            awaitSignal.print("a", a, b);
        }).start();

        new Thread(() -> {
            awaitSignal.print("b", b, c);
        }).start();

        new Thread(() -> {
            awaitSignal.print("c", c, a);
        }).start();

        try {
            Thread.sleep(1000);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        awaitSignal.lock();
        try {
            // 先唤醒a
            a.signal();
        } finally {
            awaitSignal.unlock();
        }
    }


}

class AwaitSignal extends ReentrantLock {

    // 循环次数
    private int loopNumber;

    public AwaitSignal(int loopNumber) {
        this.loopNumber = loopNumber;
    }

    /**
     * @param print   输出的字符
     * @param current 当前条件变量
     * @param next    下一个条件变量
     */
    public void print(String print, Condition current, Condition next) {

        for (int i = 0; i < loopNumber; i++) {
            lock();
            try {
                try {
                    // 获取锁之后等待
                    current.await();
                    System.out.print(print);
                } catch (InterruptedException e) {
                }
                next.signal();
            } finally {
                unlock();
            }
        }
    }
```


## 死锁
说到死锁,先举个例子，

![](https://i.ibb.co/Dbgq2wS/a-HR0c-HM6-Ly9w-MS1qd-WVqa-W4u-Ynl0-ZWlt-Zy5jb20vd-G9z-LWNu-LWktaz-N1-MWZic-GZjc-C85-MTVh-Yj-Rj-ZGE0.png)

下面是代码实现
```java
static Beer beer = new Beer();
static Story story = new Story();

public static void main(String[] args) {
    new Thread(() ->{
        synchronized (beer){
            log.info("我有酒，给我故事");
            try {
                Thread.sleep(1000);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
            synchronized (story){
                log.info("小王开始喝酒讲故事");
            }
        }
    },"小王").start();

    new Thread(() ->{
        synchronized (story){
            log.info("我有故事，给我酒");
            try {
                Thread.sleep(1000);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
            synchronized (beer){
                log.info("老王开始喝酒讲故事");
            }
        }
    },"老王").start();
}
class Beer {
}

class Story{
}
```
死锁导致程序无法正常运行下去

![](https://i.ibb.co/RBMH3Bp/a-HR0c-HM6-Ly9w-MS1qd-WVqa-W4u-Ynl0-ZWlt-Zy5jb20vd-G9z-LWNu-LWktaz-N1-MWZic-GZjc-C9h-ODE3-ODRh-ODQ0.png)

## Java内存模型(JMM)
JMM 体现在以下三个方面

- 原子性 保证指令不会受到上下文切换的影响
- 可见性 保证指令不会受到cpu缓存的影响
- 有序性 保证指令不会受并行优化的影响

### 可见性
停不下来的程序
```java
static boolean run = true;

public static void main(String[] args) throws InterruptedException {
    Thread t = new Thread(() -> {
        while (run) {
            // ....
        }
    });
    t.start();
    Thread.sleep(1000);
   // 线程t不会如预想的停下来
    run = false; 
}
```

![](https://i.ibb.co/y8ybwL6/a-HR0c-HM6-Ly9w-MS1qd-WVqa-W4u-Ynl0-ZWlt-Zy5jb20vd-G9z-LWNu-LWktaz-N1-MWZic-GZjc-C9k-ODg4-MDA0-ZTBj.png)

如上图所示，线程有自己的工作缓存，当主线程修改了变量并同步到主内存时，t线程没有读取到，所以程序停不下来

### 有序性
JVM在不影响程序正确性的情况下可能会调整语句的执行顺序，该情况也称为 指令重排序
```java
  static int i;
  static int j;
// 在某个线程内执行如下赋值操作
        i = ...;
        j = ...;
  有可能将j先赋值
```

### 原子性
原子性大家应该比较熟悉，上述同步锁的synchronized代码块就是保证了原子性，就是一段代码是一个整体，原子性保证了线程安全，不会受到上下文切换的影响。

### volatile
该关键字解决了可见性和有序性，volatile通过内存屏障来实现的

- 写屏障
  
  会在对象写操作之后加写屏障，会对写屏障的之前的数据都同步到主存，并且保证写屏障的执行顺序在写屏障之前

- 读屏障
  
  会在对象读操作之前加读屏障，会在读屏障之后的语句都从主存读，并保证读屏障之后的代码执行在读屏障之后

注意： volatile不能解决原子性，即不能通过该关键字实现线程安全。

volatile应用场景：一个线程读取变量，另外的线程操作变量，加了该关键字后保证写变量后，读变量的线程可以及时感知。


# 无锁-cas
cas （compare and swap) 比较并交换

为变量赋值时，从内存中读取到的值v，获取到要交换的新值n，执行 compareAndSwap()方法时，比较v和当前内存中的值是否一致，如果一致则将n和v交换，如果不一致，则自旋重试。

cas底层是cpu层面的，即不使用同步锁也可以保证操作的原子性。
```java
private AtomicInteger balance;

// 模拟cas的具体操作
@Override
public void withdraw(Integer amount) {
    while (true) {
        // 获取当前值
        int pre = balance.get();
        // 进行操作后得到新值
        int next = pre - amount;
        // 比较并设置成功 则中断 否则自旋重试
        if (balance.compareAndSet(pre, next)) {
            break;
        }
    }
}
```
无锁的效率是要高于之前的锁的，由于无锁不会涉及线程的上下文切换

cas是乐观锁的思想，sychronized是悲观锁的思想

cas适合很少有线程竞争的场景，如果竞争很强，重试经常发生，反而降低效率

juc并发包下包含了实现了cas的原子类

- AtomicInteger/AtomicBoolean/AtomicLong
- AtomicIntegerArray/AtomicLongArray/AtomicReferenceArray
- AtomicReference/AtomicStampedReference/AtomicMarkableReference

## AtomicInteger
```java
new AtomicInteger(balance)
get()
compareAndSet(pre, next)
//        i.incrementAndGet() ++i
//        i.decrementAndGet() --i
//        i.getAndIncrement() i++
//        i.getAndDecrement() ++i
 i.addAndGet()
  // 传入函数式接口 修改i
  int getAndUpdate(IntUnaryOperator updateFunction)
  // cas 的核心方法
  compareAndSet(int expect, int update)
```

## ABA问题
cas存在ABA问题，即比较并交换时，如果原值为A,有其他线程将其修改为B，在有其他线程将其修改为A。

此时实际发生过交换，但是比较和交换由于值没改变可以交换成功

解决方式

AtomicStampedReference/AtomicMarkableReference

上面两个类解决ABA问题，原理就是为对象增加版本号,每次修改时增加版本号，就可以避免ABA问题

或者增加个布尔变量标识，修改后调整布尔变量值，也可以避免ABA问题


# 线程池
## 线程池的介绍
线程池是Java并发最重要的一个知识点，也是难点，是实际应用最广泛的。

线程的资源很宝贵，不可能无限的创建，必须要有管理线程的工具，线程池就是一种管理线程的工具，Java开发中经常有池化的思想，如 数据库连接池、Redis连接池等。

预先创建好一些线程，任务提交时直接执行，既可以节约创建线程的时间，又可以控制线程的数量。

线程池的好处

- 降低资源消耗，通过池化思想，减少创建线程和销毁线程的消耗，控制资源
- 提高响应速度，任务到达时，无需创建线程即可运行
- 提供更多更强大的功能，可扩展性高

![](https://i.ibb.co/wSq6Dm5/a-HR0c-HM6-Ly9w-OS1qd-WVqa-W4u-Ynl0-ZWlt-Zy5jb20vd-G9z-LWNu-LWktaz-N1-MWZic-GZjc-C85-ZGFh-MDM2-Nm-Y4.png)

## 线程池的构造方法
```java
public ThreadPoolExecutor(int corePoolSize,
                          int maximumPoolSize,
                          long keepAliveTime,
                          TimeUnit unit,
                          BlockingQueue<Runnable> workQueue,
                          ThreadFactory threadFactory,
                          RejectedExecutionHandler handler) {
 
}
```
构造器参数的意义

| 参数名          | 参数意义                       |
| :-------------- | :----------------------------- |
| corePoolSize    | 核心线程数                     |
| maximumPoolSize | 最大线程数                     |
| keepAliveTime   | 救急线程的空闲时间             |
| unit            | 救急线程的空闲时间单位         |
| workQueue       | 阻塞队列                       |
| threadFactory   | 创建线程的工厂，主要定义线程名 |
| handler         | 拒绝策略                       |



## 线程池案例
下面 我们通过一个实例来理解线程池的参数以及线程池的接收任务的过程

![](https://i.ibb.co/Yhttnmq/a-HR0c-HM6-Ly9w-My1qd-WVqa-W4u-Ynl0-ZWlt-Zy5jb20vd-G9z-LWNu-LWktaz-N1-MWZic-GZjc-C82-Yj-Ux-Nj-M1-OGI.png)

如上图 银行办理业务。

1. 客户到银行时，开启柜台进行办理，柜台相当于线程，客户相当于任务，有两个是常开的柜台，三个是临时柜台。2就是核心线程数，5是最大线程数。即有两个核心线程
2. 当柜台开到第二个后，都还在处理业务。客户再来就到排队大厅排队。排队大厅只有三个座位。
3. 排队大厅坐满时，再来客户就继续开柜台处理，目前最大有三个临时柜台，也就是三个救急线程
4. 此时再来客户，就无法正常为其 提供业务，采用拒绝策略来处理它们
5. 当柜台处理完业务，就会从排队大厅取任务，当柜台隔一段空闲时间都取不到任务时，如果当前线程数大于核心线程数时，就会回收线程。即撤销该柜台。

## 线程池的状态
线程池通过一个int变量的高3位来表示线程池的状态，低29位来存储线程池的数量

| 状态名称  | 高三位 | 接收新任务 | 处理阻塞队列任务 | 说明                                                          |
| :-------- | :----- | :--------- | :--------------- | :------------------------------------------------------------ |
| Running   | 111    | Y          | Y                | 正常接收任务，正常处理任务                                    |
| Shutdown  | 0      | N          | Y                | 不会接收任务,会执行完正在执行的任务,也会处理阻塞队列里的任务  |
| stop      | 1      | N          | N                | 不会接收任务，会中断正在执行的任务,会放弃处理阻塞队列里的任务 |
| Tidying   | 10     | N          | N                | 任务全部执行完毕，当前活动线程是0，即将进入终结               |
| Termitted | 11     | N          | N                | 终结状态                                                      |

```java
// runState is stored in the high-order bits
private static final int RUNNING    = -1 << COUNT_BITS;
private static final int SHUTDOWN   =  0 << COUNT_BITS;
private static final int STOP       =  1 << COUNT_BITS;
private static final int TIDYING    =  2 << COUNT_BITS;
private static final int TERMINATED =  3 << COUNT_BITS;
```

## 线程池的主要流程
线程池创建、接收任务、执行任务、回收线程的步骤

1. 创建线程池后，线程池的状态是Running，该状态下才能有下面的步骤
2. 提交任务时，线程池会创建线程去处理任务
3. 当线程池的工作线程数达到corePoolSize时，继续提交任务会进入阻塞队列
4. 当阻塞队列装满时，继续提交任务，会创建救急线程来处理
5. 当线程池中的工作线程数达到maximumPoolSize时，会执行拒绝策略
6. 当线程取任务的时间达到keepAliveTime还没有取到任务，工作线程数大于corePoolSize时，会回收该线程

注意： 不是刚创建的线程是核心线程，后面创建的线程是非核心线程，线程是没有核心非核心的概念的，这是我长期以来的误解。

拒绝策略

1. 调用者抛出RejectedExecutionException (默认策略)
2. 让调用者运行任务
3. 丢弃此次任务
4. 丢弃阻塞队列中最早的任务，加入该任务

提交任务的方法
```java
// 执行Runnable
public void execute(Runnable command) {
    if (command == null)
        throw new NullPointerException();
    int c = ctl.get();
    if (workerCountOf(c) < corePoolSize) {
        if (addWorker(command, true))
            return;
        c = ctl.get();
    }
    if (isRunning(c) && workQueue.offer(command)) {
        int recheck = ctl.get();
        if (! isRunning(recheck) && remove(command))
            reject(command);
        else if (workerCountOf(recheck) == 0)
            addWorker(null, false);
    }
    else if (!addWorker(command, false))
        reject(command);
}
// 提交Callable
public <T> Future<T> submit(Callable<T> task) {
  if (task == null) throw new NullPointerException();
   // 内部构建FutureTask
  RunnableFuture<T> ftask = newTaskFor(task);
  execute(ftask);
  return ftask;
}
// 提交Runnable,指定返回值
public Future<?> submit(Runnable task) {
  if (task == null) throw new NullPointerException();
  // 内部构建FutureTask
  RunnableFuture<Void> ftask = newTaskFor(task, null);
  execute(ftask);
  return ftask;
} 
//  提交Runnable,指定返回值
public <T> Future<T> submit(Runnable task, T result) {
  if (task == null) throw new NullPointerException();
   // 内部构建FutureTask
  RunnableFuture<T> ftask = newTaskFor(task, result);
  execute(ftask);
  return ftask;
}

protected <T> RunnableFuture<T> newTaskFor(Runnable runnable, T value) {
        return new FutureTask<T>(runnable, value);
}
```

## Execetors创建线程池

>注意： 下面几种方式都不推荐使用
{: .prompt-warning }

### newFixedThreadPool
```java
public static ExecutorService newFixedThreadPool(int nThreads) {
    return new ThreadPoolExecutor(nThreads, nThreads,
                                  0L, TimeUnit.MILLISECONDS,
                                  new LinkedBlockingQueue<Runnable>());
}
```
- 核心线程数 = 最大线程数 没有救急线程
- 阻塞队列无界 可能导致oom
  
### newCachedThreadPool
```java
public static ExecutorService newCachedThreadPool() {
    return new ThreadPoolExecutor(0, Integer.MAX_VALUE,
                                  60L, TimeUnit.SECONDS,
                                  new SynchronousQueue<Runnable>());
}
```
- 核心线程数是0，最大线程数无限制 ，救急线程60秒回收
- 队列采用 SynchronousQueue 实现 没有容量，即放入队列后没有线程来取就放不进去
- 可能导致线程数过多，cpu负担太大

### newSingleThreadExecutor
```java
public static ExecutorService newSingleThreadExecutor() {
    return new FinalizableDelegatedExecutorService
        (new ThreadPoolExecutor(1, 1,
                                0L, TimeUnit.MILLISECONDS,
                                new LinkedBlockingQueue<Runnable>()));
}
```
- 核心线程数和最大线程数都是1，没有救急线程，无界队列 可以不停的接收任务
- 将任务串行化 一个个执行， 使用包装类是为了屏蔽修改线程池的一些参数 比如 corePoolSize
- 如果某线程抛出异常了，会重新创建一个线程继续执行
- 可能造成oom

### newScheduledThreadPool
```java
public static ScheduledExecutorService newScheduledThreadPool(int corePoolSize) {
    return new ScheduledThreadPoolExecutor(corePoolSize);
}
```
- 任务调度的线程池 可以指定延迟时间调用，可以指定隔一段时间调用

## 线程池的关闭

### shutdown()
会让线程池状态为shutdown，不能接收任务，但是会将工作线程和阻塞队列里的任务执行完 相当于优雅关闭
```java
public void shutdown() {
    final ReentrantLock mainLock = this.mainLock;
    mainLock.lock();
    try {
        checkShutdownAccess();
        advanceRunState(SHUTDOWN);
        interruptIdleWorkers();
        onShutdown(); // hook for ScheduledThreadPoolExecutor
    } finally {
        mainLock.unlock();
    }
    tryTerminate();
}
```
### shutdownNow()
会让线程池状态为stop， 不能接收任务，会立即中断执行中的工作线程，并且不会执行阻塞队列里的任务， 会返回阻塞队列的任务列表
```java
public List<Runnable> shutdownNow() {
    List<Runnable> tasks;
    final ReentrantLock mainLock = this.mainLock;
    mainLock.lock();
    try {
        checkShutdownAccess();
        advanceRunState(STOP);
        interruptWorkers();
        tasks = drainQueue();
    } finally {
        mainLock.unlock();
    }
    tryTerminate();
    return tasks;
}
```

## 线程池的正确使用姿势
线程池难就难在参数的配置，有一套理论配置参数

- cpu密集型 : 指的是程序主要发生cpu的运算

  ​核心线程数： CPU核心数+1

- IO密集型: 远程调用RPC，操作数据库等，不需要使用cpu进行大量的运算。 大多数应用的场景

  ​核心线程数=核数*cpu期望利用率 *总时间/cpu运算时间

但是基于以上理论还是很难去配置，因为cpu运算时间不好估算

实际配置大小可参考下表

| cpu密集型  | io密集型        |                           |
| :--------- | :-------------- | :------------------------ |
| 线程数数量 | 核数<=x<=核数\*2 | 核心数\*50<=x<=核心数\*100 |
| 队列长度   | y>=100          | 1<=y<=10                  |

**1.线程池参数通过分布式配置，修改配置无需重启应用**

线程池参数是根据线上的请求数变化而变化的，最好的方式是 核心线程数、最大线程数 队列大小都是可配置的

主要配置 corePoolSize maxPoolSize queueSize

Java提供了可方法覆盖参数，线程池内部会处理好参数 进行平滑的修改

```java
public void setCorePoolSize(int corePoolSize) {
}
```

![](https://i.ibb.co/BwCC9rG/a-HR0c-HM6-Ly9w-MS1qd-WVqa-W4u-Ynl0-ZWlt-Zy5jb20vd-G9z-LWNu-LWktaz-N1-MWZic-GZjc-C9l-Yj-Vk-OGRi-MDJl.png)

**2.增加线程池的监控**

**3.io密集型可调整为先新增任务到最大线程数后再将任务放到阻塞队列**

代码 主要可重写阻塞队列 加入任务的方法

```java
public boolean offer(Runnable runnable) {
    if (executor == null) {
        throw new RejectedExecutionException("The task queue does not have executor!");
    }

    final ReentrantLock lock = this.lock;
    lock.lock();
    try {
        int currentPoolThreadSize = executor.getPoolSize();
       
        // 如果提交任务数小于当前创建的线程数, 说明还有空闲线程,
        if (executor.getTaskCount() < currentPoolThreadSize) {
            // 将任务放入队列中，让线程去处理任务
            return super.offer(runnable);
        }
		// 核心改动
        // 如果当前线程数小于最大线程数，则返回 false ，让线程池去创建新的线程
        if (currentPoolThreadSize < executor.getMaximumPoolSize()) {
            return false;
        }

        // 否则，就将任务放入队列中
        return super.offer(runnable);
    } finally {
        lock.unlock();
    }
}
```

**4.绝策略 建议使用tomcat的拒绝策略(给一次机会)**
```java
// tomcat的源码
@Override
public void execute(Runnable command) {
    if ( executor != null ) {
        try {
            executor.execute(command);
        } catch (RejectedExecutionException rx) {
            // 捕获到异常后 在从队列获取，相当于重试1取不到任务 在执行拒绝任务
            if ( !( (TaskQueue) executor.getQueue()).force(command) ) throw new RejectedExecutionException("Work queue full.");
        }
    } else throw new IllegalStateException("StandardThreadPool not started.");
}
```
建议修改从队列取任务的方式： 增加超时时间，超时1分钟取不到在进行返回
```java
public boolean offer(E e, long timeout, TimeUnit unit){}
```