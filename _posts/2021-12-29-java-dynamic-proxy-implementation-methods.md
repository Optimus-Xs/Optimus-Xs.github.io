---
layout: post
title: Java 动态代理实现方法
date: 2021-12-29 15:33 +0800
categories: [Software Development] 
tags: [Java]
---


# 动态代理作用
## 静态代理
要说动态代理，必须先聊聊静态代理。

假设现在项目经理有一个需求：在项目现有所有类的方法前后打印日志。

你如何在**不修改已有代码**的前提下，完成这个需求？

我首先想到的是静态代理。具体做法是：

1.为现有的每一个类都编写一个对应的代理类，并且让它实现和目标类相同的接口（假设都有）

![](https://cdn.jsdelivr.net/gh/Optimus-Xs/Blog-Images/2021-12-29-java-dynamic-proxy-implementation-methods/v2-001c5db900d8785d47c1a5a0c6f32762-720w.png)

2.在创建代理对象时，通过构造器塞入一个目标对象，然后在代理对象的方法内部调用目标对象同名方法，并在调用前后打印日志。也就是说，代理对象 = 增强代码 + 目标对象（原对象）。有了代理对象后，就不用原对象了

![](https://cdn.jsdelivr.net/gh/Optimus-Xs/Blog-Images/2021-12-29-java-dynamic-proxy-implementation-methods/v2-e302487f952bdf8e284afc0d8d6a770b-720w.jpg)

**静态代理的缺陷**

程序员要手动为每一个目标类编写对应的代理类。如果当前系统已经有成百上千个类，工作量太大了，而且不易维护，一旦接口更改，代理类和目标类都需要更改。所以，现在我们的努力方向是：如何少写或者不写代理类，却能完成代理功能？

**对象的创建过程**

创建对象的过程

![](https://cdn.jsdelivr.net/gh/Optimus-Xs/Blog-Images/2021-12-29-java-dynamic-proxy-implementation-methods/v2-9cd31ab516bd967e1b8e68736931f8ba-720w.png)

实际上可以换个角度，也说得通

![](https://cdn.jsdelivr.net/gh/Optimus-Xs/Blog-Images/2021-12-29-java-dynamic-proxy-implementation-methods/v2-eddc430b991c58039dfc79dd6f3139cc-720w.jpg)

所谓的Class对象，是Class类的实例，而Class类是描述所有类的，比如Person类，Student类

![](https://cdn.jsdelivr.net/gh/Optimus-Xs/Blog-Images/2021-12-29-java-dynamic-proxy-implementation-methods/v2-c9bf695b1b9d2a0ae01cf92501492159-720w.jpg)

可以看出，要创建一个实例，最关键的就是得到**对应的Class对象**。只不过对于初学者来说，new这个关键字配合构造方法，实在太好用了，底层隐藏了太多细节，一句 Person p = new Person();直接把对象返回给你了。我自己刚开始学Java时，也没意识到Class对象的存在。

分析到这里，貌似有了思路：

能否不写代理类，而直接得到代理Class对象，然后根据它创建代理实例（反射）。

Class对象包含了一个类的所有信息，比如构造器、方法、字段等。如果我们不写代理类，这些信息从哪获取呢？苦思冥想，突然灵光一现：代理类和目标类理应实现同一组接口。之所以实现相同接口，是为了尽可能保证代理对象的内部结构和目标对象一致，这样我们对代理对象的操作最终都可以转移到目标对象身上，代理对象只需专注于增强代码的编写。还是上面这幅图：

![](https://cdn.jsdelivr.net/gh/Optimus-Xs/Blog-Images/2021-12-29-java-dynamic-proxy-implementation-methods/v2-e302487f952bdf8e284afc0d8d6a770b-720w.jpg)

所以，可以这样说：接口拥有代理对象和目标对象共同的类信息。所以，我们可以从接口那得到理应由代理类提供的信息。但是别忘了，接口是无法创建对象的，怎么办？

当然是让代理类动态的生成啦，也就是动态代理。

## 动态代理

为什么类可以动态的生成？

这就涉及到Java虚拟机的类加载机制了，推荐翻看《深入理解Java虚拟机》7.3节 类加载的过程。

Java虚拟机类加载过程主要分为五个阶段：加载、验证、准备、解析、初始化。其中加载阶段需要完成以下3件事情：

1. 通过一个类的全限定名来获取定义此类的二进制字节流
2. 将这个字节流所代表的静态存储结构转化为方法区的运行时数据结构
3. 在内存中生成一个代表这个类的 `java.lang.Class` 对象，作为方法区这个类的各种数据访问入口

由于JVM规范对这3点要求并不具体，所以实际的实现是非常灵活的，关于第1点，获取类的二进制字节流（class字节码）就有很多途径：

-   从ZIP包获取，这是JAR、EAR、WAR等格式的基础
-   从网络中获取，典型的应用是 Applet
-   运行时计算生成，这种场景使用最多的是动态代理技术，在 java.lang.reflect.Proxy 类中，就是用了 ProxyGenerator.generateProxyClass 来为特定接口生成形式为 *$Proxy 的代理类的二进制字节流
-   由其它文件生成，典型应用是JSP，即由JSP文件生成对应的Class类
-   从数据库中获取等等

所以，动态代理就是想办法，根据接口或目标对象，计算出代理类的字节码，然后再加载到JVM中使用。但是如何计算？如何生成？情况也许比想象的复杂得多，我们需要借助现有的方案。


## 动态代理使用场景
1. AOP—面向切面编程，程序解耦

   简言之当你想要对一些类的内部的一些方法，在执行前和执行后做一些共同的的操作，而在方法中执行个性化操作的时候--用动态代理。在业务量庞大的时候能够降低代码量，增强可维护性。

2. 想要自定义第三放类库中的某些方法
   
   我引用了一个第三方类库，但他的一些方法不满足我的需求，我想自己重写一下那几个方法，或在方法前后加一些特殊的操作--用动态代理。但需要注意的是，这些方法有局限性


# JDK动态代理

>利用反射机制生成一个实现代理接口的匿名类，在调用具体方法前调用InvokeHandler来处理。
{: .prompt-info }

JDK从1.3版本就开始支持动态代理类的创建。主要核心类只有2个：`java.lang.reflect.Proxy`和`java.lang.reflect.InvocationHandler`。

Proxy有个静态方法：getProxyClass(ClassLoader, interfaces)，只要你给它传入类加载器和一组接口，它就给你返回代理Class对象。

用通俗的话说，getProxyClass()这个方法，会从你传入的接口Class中，“拷贝”类结构信息到一个新的Class对象中，但新的Class对象带有构造器，是可以创建对象的。打个比方，一个大内太监（接口Class），空有一身武艺（类信息），但是无法传给后人。现在江湖上有个妙手神医（Proxy类），发明了克隆大法（getProxyClass），不仅能克隆太监的一身武艺，还保留了小DD（构造器）...（这到底是道德の沦丧，还是人性的扭曲，欢迎走进动态代理）

所以，一旦我们明确接口，完全可以通过接口的Class对象，创建一个代理Class，通过代理Class即可创建代理对象。

所以，按我理解，Proxy.getProxyClass()这个方法的本质就是：以Class造Class。

不过实际编程中，一般不用getProxyClass()，而是使用Proxy类的另一个静态方法：Proxy.newProxyInstance()，直接返回代理实例，连中间得到代理Class对象的过程都帮你隐藏：

>代理对象的本质就是：和目标对象实现相同接口的实例。代理Class可以叫任何名字，whatever，只要它实现某个接口，就能成为该接口类型。
{: .prompt-tip }

目标接口类
```java
/**
 * 目标接口类
 */
public interface UserManager {
    void addUser(String username, String password);
    void delUser(String username);
}
```
接口实现类
```java
/**
 * 动态代理：
 *      1. 特点：字节码随用随创建，随用随加载
 *      2. 作用：不修改源码的基础上对方法增强
 *      3. 分类：
 *              1）基于接口的动态代理
 *                      1. 基于接口的动态代理：
 *                              1）涉及的类：Proxy
 *                              2）提供者：JDK官方
 *                              3）如何创建代理对象：
 *                                      使用Proxy类中的newProxyInstance方法
 *                              4）创建代理对象的要求
 *                                      被代理类最少实现一个接口，如果没有则不能使用
 *                              5）newProxyInstance方法的参数：
 *                                      ClassLoader：类加载器，它是用于加载代理对象字节码的。和被代理对象使用相同的类加载器。固定写法。
 *                                      Class[]：字节码数组，它是用于让代理对象和被代理对象有相同方法。固定写法。
 *                                      InvocationHandler：用于提供增强的代码，它是让我们写如何代理。我们一般都是些一个该接口的实现类，通常情况下都是匿名内部类
 *              2）基于子类的动态代理
 */
public class JDKProxy implements InvocationHandler {
    // 用于指向被代理对象
    private Object targetObject;
    public Object newProxy(Object targetObject) {
        // 将被代理对象传入进行代理
        this.targetObject = targetObject;
        // 返回代理对象
        return Proxy.newProxyInstance(this.targetObject.getClass().getClassLoader(),this.targetObject.getClass().getInterfaces(),this);
    }

    /**
     * 被代理对象的任何方法执行时，都会被invoke方法替换，即：代理对象执行被代理对象中的任何方法时，实际上执行的时当前的invoke方法
     * @param proxy（代理对象的引用）
     * @param method（当前执行的方法）
     * @param args（当前执行方法所需的参数）
     * @return（和被代理对象方法有相同的返回值）
     * @throws Throwable
     */
    @Override
    public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
        // 在原来的方法上增加了日志打印功能，增强代码
        printLog();
        Object ret = null;
        // 调用invoke方法（即执行了代理对象调用被调用对象中的某个方法）
        ret = method.invoke(targetObject, args);
        return ret;
    }

    /**
     * 模拟日志打印
     */
    private void printLog() {
        System.out.println("日志打印：printLog()");
    }
}
```
测试类
```java
public class TestJDKProxy {
    public static void main(String[] args) {
        UserManager userManager = new UserManagerImpl();
        JDKProxy jdkProxy = new JDKProxy();
        UserManager userManagerProxy = (UserManager)jdkProxy.newProxy(userManager);
        System.out.println("--------------------没有使用增强过的方法--------------------");
        userManager.addUser("root","root");
        userManager.delUser("root");
        System.out.println("--------------------使用代理对象增强过的方法--------------------");
        userManagerProxy.addUser("scott","tiger");
        userManagerProxy.delUser("scott");
    }
}
```
测试结果
```
--------------------没有使用增强过的方法--------------------
调用了UserManagerImpl.addUser()方法！
调用了UserManagerImpl.delUser()方法！
--------------------使用代理对象增强过的方法--------------------
日志打印：printLog()
调用了UserManagerImpl.addUser()方法！
日志打印：printLog()
调用了UserManagerImpl.delUser()方法！
```


# Cglib动态代理
>利用ASM（开源的Java字节码编辑库，操作字节码）开源包，将代理对象类的class文件加载进来，通过修改其字节码生成子类来处理。
{: .prompt-info }

Spring在5.X之前默认的动态代理实现一直是jdk动态代理。但是从5.X开始，spring就开始默认使用Cglib来作为动态代理实现。并且springboot从2.X开始也转向了Cglib动态代理实现。

是什么导致了spring体系整体转投Cglib呢，jdk动态代理又有什么缺点呢？

那么我们现在就要来说下Cglib的动态代理。

Cglib是一个开源项目，它的底层是字节码处理框架ASM，Cglib提供了比jdk更为强大的动态代理。主要相比jdk动态代理的优势有：

jdk动态代理只能基于接口，代理生成的对象只能赋值给接口变量，而Cglib就不存在这个问题，Cglib是通过生成子类来实现的，代理对象既可以赋值给实现类，又可以赋值给接口。
Cglib速度比jdk动态代理更快，性能更好。

>JDK代理只能对实现接口的类生成代理；CGlib是针对类实现代理，对指定的类生成一个子类，并覆盖其中的方法，这种通过继承类的实现方式，不能代理final修饰的类。
{: .prompt-tip }


```java
/**
 * 动态代理：
 *      1. 特点：字节码随用随创建，随用随加载
 *      2. 作用：不修改源码的基础上对方法增强
 *      3. 分类：
 *              1）基于接口的动态代理
 *              2）基于子类的动态代理
 *                      1. 基于子类的动态代理：
 *                              1）涉及的类：Enhancer
 *                              2）提供者：第三方cglib库
 *                              3）如何创建代理对象：
 *                                      使用Enhancer类中的create方法
 *                              4）创建代理对象的要求
 *                                      被代理类不能是最终类
 *                              5）create方法的参数：
 *                                      Class：字节码，它是用于指定被代理对象的字节码。固定写法。
 *                                      Callback()：用于提供增强的代码，它是让我们写如何代理。我们一般都是些一个该接口的实现类。固定写法。
 */
public class CGLibProxy implements MethodInterceptor {
    // 用于指向被代理对象
    private Object targetObject;

    // 用于创建代理对象
    public Object createProxy(Object targetObject) {
        this.targetObject = targetObject;
        return new Enhancer().create(this.targetObject.getClass(),this);
    }

    /**
     * 
     * @param proxy（代理对象的引用）
     * @param method（当前执行的方法）
     * @param args（当前执行方法所需的参数）
     * @param methodProxy（当前执行方法的代理对象）
     * @return（和被代理对象方法有相同的返回值）
     * @throws Throwable
     */
    @Override
    public Object intercept(Object proxy, Method method, Object[] args, MethodProxy methodProxy) throws Throwable {
        Object ret = null;
        // 过滤方法
        if ("addUser".equals(method.getName())) {
            // 日志打印
            printLog();
        }
        ret = method.invoke(targetObject, args);
        return ret;
    }

    /**
     * 模拟日志打印
     */
    private void printLog() {
        System.out.println("日志打印：printLog()");
    }
}
```
测试类
```java
public class TestCGLibProxy {
    public static void main(String[] args) {
        CGLibProxy cgLibProxy = new CGLibProxy();
        UserManager userManager = new UserManagerImpl();
        UserManager cgLibProxyProxy = (UserManager)cgLibProxy.createProxy(userManager);
        System.out.println("--------------------没有使用增强过的方法--------------------");
        userManager.addUser("root","root");
        userManager.delUser("root");
        System.out.println("--------------------使用代理对象增强过的方法--------------------");
        cgLibProxyProxy.addUser("scott","tiger");
        cgLibProxyProxy.delUser("scott");
    }
}
```
测试结果
```
--------------------没有使用增强过的方法--------------------
调用了UserManagerImpl.addUser()方法！
调用了UserManagerImpl.delUser()方法！
--------------------使用代理对象增强过的方法--------------------
日志打印：printLog()
调用了UserManagerImpl.addUser()方法！
调用了UserManagerImpl.delUser()方法！
```

# javassist动态代理
Javassist是一个开源的分析、编辑和创建Java字节码的类库，可以直接编辑和生成Java生成的字节码。相对于bcel, asm等这些工具，开发者不需要了解虚拟机指令，就能动态改变类的结构，或者动态生成类。

在日常使用中，javassit通常被用来动态修改字节码。它也能用来实现动态代理的功能。

创建JavassitProxy，用作统一代理：

```java
public class JavassitProxy {

    private Object bean;

    public JavassitProxy(Object bean) {
        this.bean = bean;
    }

    public Object getProxy() throws IllegalAccessException, InstantiationException {
        ProxyFactory f = new ProxyFactory();
        f.setSuperclass(bean.getClass());
        f.setFilter(m -> ListUtil.toList("wakeup","sleep").contains(m.getName()));

        Class c = f.createClass();
        MethodHandler mi = (self, method, proceed, args) -> {
            String methodName = method.getName();
            if (methodName.equals("wakeup")){
                System.out.println("早安~~~");
            }else if(methodName.equals("sleep")){
                System.out.println("晚安~~~");
            }
            return method.invoke(bean, args);
        };
        Object proxy = c.newInstance();
        ((Proxy)proxy).setHandler(mi);
        return proxy;
    }
}
```
执行代码：
```java
public static void main(String[] args) throws Exception{
    JavassitProxy proxy = new JavassitProxy(new Student("张三"));
    Student student = (Student) proxy.getProxy();
    student.wakeup();
    student.sleep();

    proxy = new JavassitProxy(new Doctor("王教授"));
    Doctor doctor = (Doctor) proxy.getProxy();
    doctor.wakeup();
    doctor.sleep();

    proxy = new JavassitProxy(new Dog("旺旺"));
    Dog dog = (Dog) proxy.getProxy();
    dog.wakeup();
    dog.sleep();

    proxy = new JavassitProxy(new Cat("咪咪"));
    Cat cat = (Cat) proxy.getProxy();
    cat.wakeup();
    cat.sleep();
}
```
熟悉的配方，熟悉的味道，大致思路也是类似的。同样把原始bean构造传入。可以看到，javassist也是用”凭空“生成子类的方式类来解决，代码的最后也是调用了原始bean的目标方法完成代理。

javaassit比较有特点的是，可以对所需要代理的方法用filter来设定，里面可以像Criteria构造器那样进行构造

# ByteBuddy动态代理
ByteBuddy也是一个大名鼎鼎的开源库，和Cglib一样，也是基于ASM实现。还有一个名气更大的库叫Mockito，相信不少人用过这玩意写过测试用例，其核心就是基于ByteBuddy来实现的，可以动态生成mock类，非常方便。另外ByteBuddy另外一个大的应用就是java agent，其主要作用就是在class被加载之前对其拦截，插入自己的代码。

ByteBuddy非常强大，是一个神器。可以应用在很多场景。但是这里，只介绍用ByteBuddy来做动态代理，关于其他使用方式，可能要专门写一篇来讲述，这里先给自己挖个坑。

来，还是熟悉的例子，熟悉的配方。用ByteBuddy我们再来实现一遍前面的例子

创建ByteBuddyProxy，做统一代理：

```java
public class ByteBuddyProxy {

    private Object bean;

    public ByteBuddyProxy(Object bean) {
        this.bean = bean;
    }

    public Object getProxy() throws Exception{
        Object object = new ByteBuddy().subclass(bean.getClass())
                .method(ElementMatchers.namedOneOf("wakeup","sleep"))
                .intercept(InvocationHandlerAdapter.of(new AopInvocationHandler(bean)))
                .make()
                .load(ByteBuddyProxy.class.getClassLoader())
                .getLoaded()
                .newInstance();
        return object;
    }

    public class AopInvocationHandler implements InvocationHandler {

        private Object bean;

        public AopInvocationHandler(Object bean) {
            this.bean = bean;
        }

        @Override
        public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
            String methodName = method.getName();
            if (methodName.equals("wakeup")){
                System.out.println("早安~~~");
            }else if(methodName.equals("sleep")){
                System.out.println("晚安~~~");
            }
            return method.invoke(bean, args);
        }
    }
}
```
执行代码：
```java
public static void main(String[] args) throws Exception{
    ByteBuddyProxy proxy = new ByteBuddyProxy(new Student("张三"));
    Student student = (Student) proxy.getProxy();
    student.wakeup();
    student.sleep();

    proxy = new ByteBuddyProxy(new Doctor("王教授"));
    Doctor doctor = (Doctor) proxy.getProxy();
    doctor.wakeup();
    doctor.sleep();

    proxy = new ByteBuddyProxy(new Dog("旺旺"));
    Dog dog = (Dog) proxy.getProxy();
    dog.wakeup();
    dog.sleep();

    proxy = new ByteBuddyProxy(new Cat("咪咪"));
    Cat cat = (Cat) proxy.getProxy();
    cat.wakeup();
    cat.sleep();
}
```
思路和之前还是一样，ByteBuddy也是采用了创造子类的方式来实现动态代理


# 各种动态代理的对比

前面介绍了4种动态代理对于同一例子的实现。对于代理的模式可以分为2种：

- JDK动态代理采用接口代理的模式，代理对象只能赋值给接口，允许多个接口
- Cglib，Javassist，ByteBuddy这些都是采用了子类代理的模式，代理对象既可以赋值给接口，又可以复制给具体实现类

Spring5.X，Springboot2.X只有都采用了Cglib作为动态代理的实现，那是不是cglib性能是最好的呢？

## JDK代理和CGLIB代理对比
JDK代理使用的是反射机制实现aop的动态代理，CGLIB代理使用字节码处理框架asm，通过修改字节码生成子类。所以jdk动态代理的方式创建代理对象效率较高，执行效率较低，cglib创建效率较低，执行效率高；

JDK动态代理机制是委托机制，具体说动态实现接口类，在动态生成的实现类里面委托hanlder去调用原始实现类方法，CGLIB则使用的继承机制，具体说被代理类和代理类是继承关系，所以代理类是可以赋值给被代理类的，如果被代理类有接口，那么代理类也可以赋值给接口。

JDK Proxy 的优势：

- 最小化依赖关系，减少依赖意味着简化开发和维护，JDK 本身的支持，可能比 cglib 更加可靠。
- 平滑进行 JDK 版本升级，而字节码类库通常需要进行更新以保证在新版 Java 上能够使用。
- 代码实现简单。

基于类似 cglib 框架的优势：

- 无需实现接口，达到代理类无侵入
- 只操作我们关心的类，而不必为其他相关类增加工作量。
- 高性能

# 参考
- [Java 动态代理作用是什么？](https://www.zhihu.com/question/20794107/answer/658139129)
- [动态代理的两种实现方式](https://segmentfault.com/a/1190000022699975#item-1)
- [动态代理大揭秘，带你彻底弄清楚动态代理！](https://segmentfault.com/a/1190000040680716#item-3)
- [Java 动态代理详解](https://juejin.cn/post/6844903744954433544#heading-3)