---
layout: post
title: Spring AOP 的使用方法
date: 2021-03-05 18:19 +0800
categories: [Software Development] 
tags: [Java, Spring, DevDairy]
---

# Spring AOP 注解概述
Spring 的 AOP 功能除了在配置文件中配置一大堆的配置，比如切入点、表达式、通知等等以外，使用注解的方式更为方便快捷，特别是 Spring boot 出现以后，基本不再使用原先的 beans.xml 等配置文件了，而都推荐注解编程。

| 注解            | 功能                                                                                                                                                                                                                           |
| :-------------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| @Aspect         | 切面声明，标注在类、接口（包括注解类型）或枚举上。                                                                                                                                                                             |
| @Pointcut       | 切入点声明，即切入到哪些目标类的目标方法。value 属性指定切入点表达式，<br>默认为 ""，用于被通知注解引用，样通知注解只需要关联此切入点声明即可，<br>无需再重复写切入点表达式                                                    |
| @Before         | 前置通知, 在目标方法(切入点)执行之前执行。<br>value 属性绑定通知的切入点表达式，可以关联切入点声明，<br>也可以直接设置切入点表达式注意：如果在此回调方法中抛出异常，<br>则目标方法不会再执行，会继续执行后置通知 -> 异常通知。 |
| @After          | 后置通知, 在目标方法(切入点)执行之后执行                                                                                                                                                                                       |
| @AfterReturning | 返回通知, 在目标方法(切入点)返回结果之后执行，<br>在 @After 的后面执行pointcut 属性绑定通知的切入点表达式，<br>优先级高于 value，默认为 ""                                                                                     |
| @AfterThrowing  | 异常通知, 在方法抛出异常之后执行, <br>意味着跳过返回通知pointcut 属性绑定通知的切入点表达式，<br>优先级高于 value，默认为 ""<br>注意：如果目标方法自己 try-catch 了异常，<br>而没有继续往外抛，则不会进入此回调函数            |
| @Around         | 环绕通知：目标方法执行前后分别执行一些代码，类似拦截器，<br>可以控制目标方法是否继续执行。通常用于统计方法耗时，参数校验等等操作。<br>环绕通知早于前置通知，晚于返回通知。                                                     |

>对于习惯了 Spring 全家桶编程的人来说，并不是需要直接引入 aspectjweaver 依赖，因为 spring-boot-starter-aop 组件默认已经引用了 aspectjweaver 来实现  AOP 功能。换句话说 Spring 的 AOP 功能就是依赖的 aspectjweaver ！
{: .prompt-tip }

```xml
<!-- https://mvnrepository.com/artifact/org.springframework.boot/spring-boot-starter-aop -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-aop</artifactId>
    <version>2.1.4.RELEASE</version>
</dependency>
```
# @Aspect 快速入门
@Aspect 常见用于记录日志、异常集中处理、权限验证、Web 参数校验、事务处理等等

要想把一个类变成切面类，只需3步：

1. 在类上使用 @Aspect 注解使之成为切面类
2. 切面类需要交由 Sprign 容器管理，所以类上还需要有 @Service、@Repository、@Controller、@Component  等注解
2. 在切面类中自定义方法接收通知

```java

/**
 * 1、@Aspect：声明本类为切面类
 * 2、@Component：将本类交由 Spring 容器管理
 * 3、@Order：指定切入执行顺序，数值越小，切面执行顺序越靠前，默认为 Integer.MAX_VALUE
 */
@Aspect
@Order(value = 999)
@Component
public class AspectHelloWorld {
    private static final Logger LOG = LoggerFactory.getLogger(AspectHelloWorld.class);
 
    /**
     * @Pointcut ：切入点声明，即切入到哪些目标方法。value 属性指定切入点表达式，默认为 ""。
     * 用于被下面的通知注解引用，这样通知注解只需要关联此切入点声明即可，无需再重复写切入点表达式
     * <p>
     * 切入点表达式常用格式举例如下：
     * - * com.wmx.aspect.EmpService.*(..))：表示 com.wmx.aspect.EmpService 类中的任意方法
     * - * com.wmx.aspect.*.*(..))：表示 com.wmx.aspect 包(不含子包)下任意类中的任意方法
     * - * com.wmx.aspect..*.*(..))：表示 com.wmx.aspect 包及其子包下任意类中的任意方法
     * </p>
     * value 的 execution 可以有多个，使用 || 隔开.
     */
    @Pointcut(value =
            "execution(* com.wmx.hb.controller.DeptController.*(..)) " +
                    "|| execution(* com.wmx.hb.controller.EmpController.*(..))")
    private void aspectPointcut() {
 
    }
 
    /**
     * 前置通知：目标方法执行之前执行以下方法体的内容。
     * value：绑定通知的切入点表达式。可以关联切入点声明，也可以直接设置切入点表达式
     * <br/>
     * * @param joinPoint：提供对连接点处可用状态和有关它的静态信息的反射访问<br/> <p>
     * * * Object[] getArgs()：返回此连接点处（目标方法）的参数，目标方法无参数时，返回空数组
     * * * Signature getSignature()：返回连接点处的签名。
     * * * Object getTarget()：返回目标对象
     * * * Object getThis()：返回当前正在执行的对象
     * * * StaticPart getStaticPart()：返回一个封装此连接点的静态部分的对象。
     * * * SourceLocation getSourceLocation()：返回与连接点对应的源位置
     * * * String toLongString()：返回连接点的扩展字符串表示形式。
     * * * String toShortString()：返回连接点的缩写字符串表示形式。
     * * * String getKind()：返回表示连接点类型的字符串
     * * * </p>
     */
    @Before(value = "aspectPointcut()")
    public void aspectBefore(JoinPoint joinPoint) {
        Object[] args = joinPoint.getArgs();
        Signature signature = joinPoint.getSignature();
        Object target = joinPoint.getTarget();
        Object aThis = joinPoint.getThis();
        JoinPoint.StaticPart staticPart = joinPoint.getStaticPart();
        SourceLocation sourceLocation = joinPoint.getSourceLocation();
        String longString = joinPoint.toLongString();
        String shortString = joinPoint.toShortString();
 
        LOG.debug("【前置通知】" +
                        "args={},signature={},target={},aThis={},staticPart={}," +
                        "sourceLocation={},longString={},shortString={}"
                , Arrays.asList(args), signature, target, aThis, staticPart, sourceLocation, longString, shortString);
    }
 
    /**
     * 后置通知：目标方法执行之后执行以下方法体的内容，不管目标方法是否发生异常。
     * value：绑定通知的切入点表达式。可以关联切入点声明，也可以直接设置切入点表达式
     */
    @After(value = "aspectPointcut()")
    public void aspectAfter(JoinPoint joinPoint) {
        LOG.debug("【后置通知】kind={}", joinPoint.getKind());
    }
 
    /**
     * 返回通知：目标方法返回后执行以下代码
     * value 属性：绑定通知的切入点表达式。可以关联切入点声明，也可以直接设置切入点表达式
     * pointcut 属性：绑定通知的切入点表达式，优先级高于 value，默认为 ""
     * returning 属性：通知签名中要将返回值绑定到的参数的名称，默认为 ""
     *
     * @param joinPoint ：提供对连接点处可用状态和有关它的静态信息的反射访问
     * @param result    ：目标方法返回的值，参数名称与 returning 属性值一致。无返回值时，这里 result 会为 null.
     */
    @AfterReturning(pointcut = "aspectPointcut()", returning = "result")
    public void aspectAfterReturning(JoinPoint joinPoint, Object result) {
        LOG.debug("【返回通知】,shortString={},result=", joinPoint.toShortString(), result);
    }
 
    /**
     * 异常通知：目标方法发生异常的时候执行以下代码，此时返回通知不会再触发
     * value 属性：绑定通知的切入点表达式。可以关联切入点声明，也可以直接设置切入点表达式
     * pointcut 属性：绑定通知的切入点表达式，优先级高于 value，默认为 ""
     * throwing 属性：与方法中的异常参数名称一致，
     *
     * @param ex：捕获的异常对象，名称与 throwing 属性值一致
     */
    @AfterThrowing(pointcut = "aspectPointcut()", throwing = "ex")
    public void aspectAfterThrowing(JoinPoint jp, Exception ex) {
        String methodName = jp.getSignature().getName();
        if (ex instanceof ArithmeticException) {
            LOG.error("【异常通知】" + methodName + "方法算术异常（ArithmeticException）：" + ex.getMessage());
        } else {
            LOG.error("【异常通知】" + methodName + "方法异常：" + ex.getMessage());
        }
    }
 
    /**
     * 环绕通知
     * 1、@Around 的 value 属性：绑定通知的切入点表达式。可以关联切入点声明，也可以直接设置切入点表达式
     * 2、Object ProceedingJoinPoint.proceed(Object[] args) 方法：继续下一个通知或目标方法调用，返回处理结果，如果目标方法发生异常，则 proceed 会抛异常.
     * 3、假如目标方法是控制层接口，则本方法的异常捕获与否都不会影响目标方法的事务回滚
     * 4、假如目标方法是控制层接口，本方法 try-catch 了异常后没有继续往外抛，则全局异常处理 @RestControllerAdvice 中不会再触发
     *
     * @param joinPoint
     * @return
     * @throws Throwable
     */
    @Around(value = "aspectPointcut()")
    public Object handleControllerMethod(ProceedingJoinPoint joinPoint) throws Throwable {
        this.checkRequestParam(joinPoint);
 
        StopWatch stopWatch = StopWatch.createStarted();
        LOG.debug("【环绕通知】执行接口开始，方法={}，参数={} ", joinPoint.getSignature(), Arrays.asList(joinPoint.getArgs()).toString());
        //继续下一个通知或目标方法调用，返回处理结果，如果目标方法发生异常，则 proceed 会抛异常.
        //如果在调用目标方法或者下一个切面通知前抛出异常，则不会再继续往后走.
        Object proceed = joinPoint.proceed(joinPoint.getArgs());
 
        stopWatch.stop();
        long watchTime = stopWatch.getTime();
        LOG.debug("【环绕通知】执行接口结束，方法={}, 返回值={},耗时={} (毫秒)", joinPoint.getSignature(), proceed, watchTime);
        return proceed;
    }
 
    /**
     * 参数校验，防止 SQL 注入
     *
     * @param joinPoint
     */
    private void checkRequestParam(ProceedingJoinPoint joinPoint) {
        Object[] args = joinPoint.getArgs();
        if (args == null || args.length <= 0) {
            return;
        }
        String params = Arrays.toString(joinPoint.getArgs()).toUpperCase();
        String[] keywords = {"DELETE ", "UPDATE ", "SELECT ", "INSERT ", "SET ", "SUBSTR(", "COUNT(", "DROP ",
                "TRUNCATE ", "INTO ", "DECLARE ", "EXEC ", "EXECUTE ", " AND ", " OR ", "--"};
        for (String keyword : keywords) {
            if (params.contains(keyword)) {
                LOG.warn("参数存在SQL注入风险，其中包含非法字符 {}.", keyword);
                throw new RuntimeException("参数存在SQL注入风险：params=" + params);
            }
        }
    }
}
```

# execution 切点表达式
@Pointcut 切入点声明注解，以及所有的通知注解都可以通过 value 属性或者 pointcut 属性指定切入点表达式。

2、切入点表达式通过 execution 函数匹配连接点，语法：execution([方法修饰符]  返回类型  包名.类名.方法名(参数类型) [异常类型])

- 访问修饰符可以省略；
- 返回值类型、包名、类名、方法名可以使用星号*代表任意；
- 包名与类名之间一个点.代表当前包下的类，两个点..表示当前包及其子包下的类;
- 参数列表可以使用两个点..表示任意个数，任意类型的参数列表;

3、切入点表达式的写法比较灵活，比如：* 号表示任意一个，.. 表示任意多个，还可以使用 &&、\|\|、! 进行逻辑运算，不过实际开发中通常用不到那么多花里胡哨的，掌握以下几种就基本够用了。

## 切入点表达式常用举例

| execution(* com.wmx.aspect.EmpServiceImpl.findEmpById(Integer))                                                                                                 | 匹配 com.wmx.aspect.EmpService 类中的 findEmpById 方法，且带有一个 Integer 类型参数。 |
| execution(* com.wmx.aspect.EmpServiceImpl.findEmpById(*))                                                                                                       | 匹配 com.wmx.aspect.EmpService 类中的 findEmpById 方法，且带有一个任意类型参数。      |
| execution(* com.wmx.aspect.EmpServiceImpl.findEmpById(..))                                                                                                      | 匹配 com.wmx.aspect.EmpService 类中的 findEmpById 方法，参数不限。                    |
| execution(* grp.basic3.se.service.SEBasAgencyService3.editAgencyInfo(..)) \|\| <br> execution(* grp.basic3.se.service.SEBasAgencyService3.adjustAgencyInfo(..)) | 匹配 editAgencyInfo 方法或者 adjustAgencyInfo 方法                                    |
| execution(* com.wmx.aspect.EmpService.*(..))                                                                                                                    | 匹配 com.wmx.aspect.EmpService 类中的任意方法                                         |
| execution(* com.wmx.aspect.\*.\*(..))                                                                                                                           | 匹配 com.wmx.aspect 包(不含子包)下任意类中的任意方法                                  |
| execution(* com.wmx.aspect..\*.\*(..))                                                                                                                          | 匹配 com.wmx.aspect 包及其子包下任意类中的任意方法                                    |
| execution(* grp.pm..\*Controller.\*(..))                                                                                                                        | 匹配 grp.pm 包下任意子孙包中以 "Controller" 结尾的类中的所有方法                      |

完整 Spring AOP 切点表达式：
[Spring AOP 的切点表达式]({% post_url 2021-03-05-spring-aop-pointcut-designators %})


