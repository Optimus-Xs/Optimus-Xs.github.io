---
layout: post
title: Spring AOP 的切点表达式
date: 2021-03-05 19:46 +0800
categories: [Software Development] 
tags: [Java, Spring]
---

PCD(pointcut designators) 就是SpringAOP的切点表达式。SpringAOP的PCD是完全兼容AspectJ的，一共有10种。

SpringAOP 是基于动态代理实现的，以下以目标对象表示被代理bean，代理对象表示AOP构建出来的bean。目标方法表示被代理的方法。

# execution
execution是最常用的PCD。它的匹配式模板如下展示:
```java
execution(modifiers-pattern? ret-type-pattern declaring-type-pattern? name-pattern(param-pattern) throws-pattern?)
execution(修饰符匹配式? 返回类型匹配式 类名匹配式? 方法名匹配式(参数匹配式) 异常匹配式?)
```
代码块中带?符号的匹配式都是可选的，对于execution PCD必不可少的只有三个:

1. 返回值匹配值
2. 方法名匹配式
3. 参数匹配式

举例分析: execution(public * ServiceDemo.*(..)) 匹配public修饰符，返回值是*,即任意返回值类型都行，ServiceDemo是类名匹配式不一定要全路径，只要全局依可见性唯一就行，.*是方法名匹配式，匹配所有方法，..是参数匹配式，匹配任意数量、任意类型参数的方法。

再举一些其他例子:
- execution(* com.xyz.service..*.*(..)): 匹配com.xyz.service及其子包下的任意方法。
- execution(* joke(Object+))):匹配任意名字为joke的方法，且其动态入参是是Object类型或该类的子类。
- execution(* joke(String,..)):匹配任意名字为joke的方法，该方法 一个入参为String(不可以为子类)，后面可以有任意个入参且入参类型不限
- execution(* com..*.*Dao.find*(..)): 匹配指定包下find开头的方法
- execution(* com.baobaotao.Waiter+.*(..)) : 匹配com.baobaotao包下Waiter及其子类的所有方法。

# within
筛选出某包下的所有类，注意要带有*。

- within(com.xyz.service.*)com.xyz.service包下的类，不包括子包
- within(com.xyz.service..*)com.xyz.service包下及其子包下的类

# this
常用于命名绑定模式。对由代理对象的类型进行过滤筛选。

如果目标类是基于接口实现的，则this()中可以填该接口的全路径名，否则非接口实现由于是基于CGLIB实现的，this中可以填写目标类的全路径名。

this(com.xyz.service.AccountService): 代理类是com.xyz.service.AccountService或其子类。

使用@EnableAspectJAutoProxy(proxyTargetClass = true)可以强制使用CGLIB。否则默认首先使用jdk动态代理，jdk代理不了才会用CGLIB。

# target
this作用于代理对象，target作用于目标对象。

target(com.xyz.service.AccountService): 被代理类(目标对象)是com.xyz.service.AccountService或其子类

# args
常用于对目标方法的参数匹配。一般不单独使用，而是配合其他PCD来使用。args可以使用命名绑定模式，如下举例:

```java
@Aspect // 切面声明
@Component // 注入IOC
@Slf4j
class AspectDemo {
    @Around("within(per.aop.*) && args(str)") // 在per.aop包下，且被代理方法的只有一个参数，参数类型是String或者其子类
    @SneakyThrows
    public Object logAspect(ProceedingJoinPoint pjp, String str) { 
        String signature = pjp.getSignature().toString();
        log.info("{} start,param={}", signature, pjp.getArgs());
        Object res = pjp.proceed();
        log.info("{} end", signature);
        return res;
    }
}
```
- 如果args中是参数名，则配合切面(advice)方法的使用来确定要匹配的方法参数类型。
- 如果args中是类型，例如@Around("within(per.aop.*) && args(String)”)，则可以不必使用切面方法来确定类型，但此时也不能使用参数绑定了见下文了。
- 虽然args()支持+符号，但本省args()就支持子类通配。

和带参数匹配execution区别

举个例子: args(com.xgj.Waiter)等价于 execution(* *(com.xgj.Waiter+))。而且execution不能支持带参数的advice。

# @target
使用场景举例: 当一个Service有多个子类时, 某些子类需要打日志，某些子类不需要打日志时可以如下处理(配合java多态):

筛选出具有给定注解的被代理对象是对象不是类，@target是动态的。如下自定义一个注解LogAble:
```java
//全限定名: annotation.LogAble
@Target({ElementType.TYPE,ElementType.PARAMETER}) // 支持在方法参数、类上注
@Retention(RetentionPolicy.RUNTIME)
public @interface LogAble {
}
```
假如需要“注上了这个注解的所有类的的public方法“都打日志的话日志逻辑要自定义，可以如下这么写PCD，当然对应方法的bean要注入到SpringIOC容器中:
```java
@Around("@target(annotation.LogAble) && execution(public * *.*(..))")
// 自定义日志逻辑
```

# @args
对于目标方法参数的运行时类型要有@args指定的注解。是方法参数的类型上有指定注解，不是方法参数上带注解。

使用场景: 假如参数类型有多个子类，只有某个子类才可以匹配该PCD。
- @args(com.ms.aop.jargs.demo1.Anno1): 匹配1个参数，且第1个参数运行时需要有Anno1注解
- @args(com.ms.aop.jargs.demo1.Anno1,..)匹配一个或多个参数，第一个参数运行时需要带上Anno1注解。
- @args(com.ms.aop.jargs.demo1.Anno1,com.ms.aop.jargs.demo1.Anno2): 一参匹配Anno1，二参匹配Annno2 。

# @within
非运行时类型的的@target。@target关注的是被调用的对象，@within关注的是调用的方法所在的类。
@target 和 @within 的不同点:
- @target(注解A)：判断被调用的目标对象中是否声明了注解A，如果有，会被拦截
- @within(注解A)： 判断被调用的方法所属的类中是否声明了注解A，如果有，会被拦截

# @annotation
匹配有指定注解的方法（注解作用在方法上面）

# bean
根据beanNam来匹配。支持*通配符。
```java
bean(*Service) // 匹配所有Service结尾的Service
```

# 组合使用
PCD之间支持，&& \|\| !三种运算符。上文示例中就使用了&& 运算符。\|\|表示或(不是短路或)。!表示非。

# 命名绑定模式
上文中的@Around("within(per.aop.*) && args(str)")示例就是使用了命名绑定模式，在PCD中写上变量名，在方法上对变量名的类型进行限定。
```java
@Around("within(per.aop.*) && args(str)")
public Object logAspect(ProceedingJoinPoint pjp, String str) { ...}
```
如上举例，str要是String类型或其子类，且方法入参只能有一个。
>命名绑定模式只支持target、this、args三种PCD。
{: .prompt-tip }

# argNames
观察源码可以发现，所有的Advice注解都带有argNames字段，例如@Around:
```java
@Retention(RetentionPolicy.RUNTIME)
@Target({ElementType.METHOD})
public @interface Around {
    String value();
    String argNames() default "";
}
```
什么情况下会使用这个属性呢，如下举例解释:
```java
@Around(value = "execution(* TestBean.paramArgs(..))  && args(decimal,str,..)&& target(bean)", argNames = "pjp,str,decimal,bean")
@SneakyThrows // proceed会抛受检异常
Object aroundArgs(ProceedingJoinPoint pjp,/*使用命名绑定模式*/ String str, BigDecimal decimal, Object bean) {
    // 在方法执行前做一些操作
	return  pjp.proceed();
}
```
argnames 必须要和args、target、this标签一起使用。虽然实际操作中可以不带，但官方建议所有带参数的都带，原因如下:

因此如果‘ argernames’属性没有指定，那么 Spring AOP 将查看类的调试信息，并尝试从局部变量表中确定参数名。只要使用调试信息(至少是‘-g: vars’)编译了类，就会出现此信息。使用这个标志编译的结果是:

- 你的代码将会更容易被反向工程
- 类文件大小将会非常大(通常是无关紧要的)
- 删除未使用的局部变量的优化将不会被编译器应用。

此外，如果编译的代码没有必要的调试信息，那么 Spring AOP 将尝试推断绑定变量与参数的配对。如果变量的绑定在可用信息下是不明确的，那么一个 AmbiguousBindingException 就会被抛出。如果上面的策略都失败了，那么就会抛出一个 IllegalArgumentException。

>建议所有的advice注解里都带argNames，反正idea也会提醒。
{: .prompt-tip }