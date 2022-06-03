---
layout: post
title: 优雅的使用Spring Validation实现业务参数校验
date: 2021-03-03 17:11 +0800
categories: [Software Development] 
tags: [Java, Spring, DevDairy]
---

# 前言

在平时写controller时候，都需要对请求参数进行后端校验，一般写法如下：
``` java
public String add(user user) {
    if(user.getAge() == null){
        return "年龄不能为空";
    }
    if(user.getAge() > 120){
        return "年龄不能超过120";
    }
    if(user.getName().isEmpty()){
        return "用户名不能为空";
    }
    // 省略一堆参数校验...
    return "Done";
}
```
业务代码还没开始写呢，光参数校验就写了一堆判断。这样写虽然没什么错，但是给人的感觉就是：**不优雅**😅,其实SpringBoot提供整合了参数校验解决方案spring-boot-starter-validation

# 依赖配置
第一步就很简单了，直接在 pom.xml 中引入依赖就行：
```xml
<!--校验组件-->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-validation</artifactId>
</dependency>
<!--web组件-->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-web</artifactId>
</dependency>
```
>其中 Springboot-2.3 之前的版本只需要引入 web 依赖就可以了。
{: .prompt-tip }

# Vildation的简单使用

## Spring Validation 内置校验注解

| 注解             | 校验功能                           |
| :--------------- | :--------------------------------- |
| @AssertFalse     | 必须是false                        |
| @AssertTrue      | 必须是true                         |
| @DecimalMax      | 小于等于给定的值                   |
| @DecimalMin      | 大于等于给定的值                   |
| @Digits          | 可设定最大整数位数和最大小数位数   |
| @Email           | 校验是否符合Email格式              |
| @Future          | 必须是将来的时间                   |
| @FutureOrPresent | 当前或将来时间                     |
| @Max             | 最大值                             |
| @Min             | 最小值                             |
| @Negative        | 负数（不包括0）                    |
| @NegativeOrZero  | 负数或0                            |
| @NotBlank        | 不为null并且包含至少一个非空白字符 |
| @NotEmpty        | 不为null并且不为空                 |
| @NotNull         | 不为null                           |
| @Null            | 为null                             |
| @Past            | 必须是过去的时间                   |
| @PastOrPresent   | 必须是过去的时间，包含现在         |
| @Pattern         | 必须满足正则表达式                 |
| @PositiveOrZero  | 正数或0                            |
| @Size            | 校验容器的元素个数                 |

## 单个参数校验
在上面的基础上只需要在对象参数前面加上@Validated注解，然后在需要校验的对象参数的属性上面加上@NotNull，@NotEmpty之类参数校验注解就行了

```java
@Validated
@GetMapping("/home")
public class ProductController {
  public Result index(@NotBlank String name, @Email @NotBlank String email) {
        return ResultResponse.success();
    }
} 
```

## 对象参数校验
在上面的基础上只需要在对象参数前面加上@Validated注解，然后在需要校验的对象参数的属性上面加上
@NotNull，@NotEmpty之类参数校验注解就行了
```java
public class user {
    @NotNull(message = "age 不能为空")    //校验提示信息
    private Integer age;
}
```

## 验证消息返回

### 直接获取验证结果
然后在 Controller 方法中添加 @Validated 和用于接收错误信息的 BindingResult 就可以了，于是有了Ver1：
```java
public String add1(@Validated user user, BindingResult result) {
    List<FieldError> fieldErrors = result.getFieldErrors();
    if(!fieldErrors.isEmpty()){
        return fieldErrors.get(0).getDefaultMessage();
    }
    return "OK";
}
```
通过工具(Postman 或者 IDEA 插件 RestfulToolKit )去请求接口，如果参数不符合规则，会将相应的 message 信息返回
```
age 不能为空
```

### 规范返回值
待校验参数多了之后我们希望一次返回所有校验失败信息，方便接口调用方进行调整，这就需要统一返回格式，常见的就是封装一个结果类
```java
public class ResultInfo<T>{
    private Integer status;
    private String message;
    private T response;
    // 省略其他代码...
}
```
改造一下 Controller 方法，Ver2
```java
public ResultInfo add2(@Validated user user, BindingResult result) {
    List<FieldError> fieldErrors = result.getFieldErrors();
    List<String> collect = fieldErrors.stream()
            .map(o -> o.getDefaultMessage())
            .collect(Collectors.toList());
    return new ResultInfo<>().success(400,"请求参数错误",collect);
}
```
请求该方法时，所有的错误参数就都返回了：
```json
{
    "status": 400,
    "message": "请求参数错误",
    "response": [
        "年龄必须在[1,120]之间",
        "bg 字段的整数位最多为3位，小数位最多为1位",
        "name 不能为空",
        "email 格式错误"
    ]
}
```

# 全局异常处理
每个 Controller 方法中如果都写一遍 BindingResult 信息的处理，使用起来还是很繁琐。可以通过全局异常处理的方式统一处理校验异常。

当我们写了 @validated 注解，不写 BindingResult 的时候，Spring 就会抛出异常。由此，可以写一个全局异常处理类来统一处理这种校验异常，从而免去重复组织异常信息的代码。

全局异常处理类只需要在类上标注 @RestControllerAdvice，并在处理相应异常的方法上使用 @ExceptionHandler 注解，写明处理哪个异常即可

```java
@RestControllerAdvice
public class GlobalControllerAdvice {
    private static final String BAD_REQUEST_MSG = "客户端请求参数错误";
    // <1> 处理 form data方式调用接口校验失败抛出的异常 
    @ExceptionHandler(BindException.class)
    public ResultInfo bindExceptionHandler(BindException e) {
        List<FieldError> fieldErrors = e.getBindingResult().getFieldErrors();
        List<String> collect = fieldErrors.stream()
                .map(o -> o.getDefaultMessage())
                .collect(Collectors.toList());
        return new ResultInfo().success(HttpStatus.BAD_REQUEST.value(), BAD_REQUEST_MSG, collect);
    }
    // <2> 处理 json 请求体调用接口校验失败抛出的异常 
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResultInfo methodArgumentNotValidExceptionHandler(MethodArgumentNotValidException e) {
        List<FieldError> fieldErrors = e.getBindingResult().getFieldErrors();
        List<String> collect = fieldErrors.stream()
                .map(o -> o.getDefaultMessage())
                .collect(Collectors.toList());
        return new ResultInfo().success(HttpStatus.BAD_REQUEST.value(), BAD_REQUEST_MSG, collect);
    }
    // <3> 处理单个参数校验失败抛出的异常
    @ExceptionHandler(ConstraintViolationException.class)
    public ResultInfo constraintViolationExceptionHandler(ConstraintViolationException e) {
        Set<ConstraintViolation<?>> constraintViolations = e.getConstraintViolations();
        List<String> collect = constraintViolations.stream()
                .map(o -> o.getMessage())
                .collect(Collectors.toList());
        return new ResultInfo().success(HttpStatus.BAD_REQUEST.value(), BAD_REQUEST_MSG, collect);
    }
}
```

事实上，在全局异常处理类中，我们可以写多个异常处理方法，这里总结了三种参数校验时可能引发的异常：

- 使用 form data 方式调用接口，校验异常抛出 BindException
- 使用 json 请求体调用接口，校验异常抛出 MethodArgumentNotValidException
- 单个参数校验异常抛出 ConstraintViolationException

> 注：单个参数校验需要在参数上增加校验注解，并在类上标注@Validated
{: .prompt-warning }

全局异常处理类可以添加各种需要处理的异常，比如添加一个对 Exception.class 的异常处理，当所有 ExceptionHandler 都无法处理时，由其记录异常信息，并返回友好提示

# 分组校验
如果同一个参数，需要在不同场景下应用不同的校验规则，就需要用到分组校验了。比如：新注册用户还没起名字，我们允许 name 字段为空，但是不允许将名字更新为空字符。

分组校验有三个步骤：
1. 定义一个分组类（或接口）
2. 在校验注解上添加groups属性指定分组
3. Controller 方法的 @Validated 注解添加分组类

```java
public interface Update extends Default{
}
```

```java
public class user {
    @NotBlank(message = "name 不能为空",groups = Update.class)
    private String name;
    // 省略其他代码...
}
```

```java
@PostMapping("update")
public ResultInfo update(@Validated({Update.class}) user user) {
    return new ResultInfo().success(user);
}
```

细心的小伙伴可能已经注意到，自定义的 Update 分组接口继承了 Default 接口。校验注解(如：@NotBlank)和 @Validated 默认都属于 Default.class 分组，这一点在 javax.validation.groups.Default 注释中有说明

```java
/**
 * Default Jakarta Bean Validation group.
 * <p>
 * Unless a list of groups is explicitly defined:
 * <ul>
 *     <li>constraints belong to the {@code Default} group</li>
 *     <li>validation applies to the {@code Default} group</li>
 * </ul>
 * Most structural constraints should belong to the default group.
 *
 * @author Emmanuel Bernard
 */
public interface Default {
}
```
在编写 Update 分组接口时，如果继承了 Default，下面两个写法就是等效的：
- @Validated()
- @Validated({Update.class,Default.class})

请求一下 /update 接口可以看到，不仅校验了 name 字段，也校验了其他默认属于 Default.class 分组的字段
```json
{
    "status": 400,
    "message": "客户端请求参数错误",
    "response": [
        "name 不能为空",
        "age 不能为空",
        "email 不能为空"
    ]
}
```
如果 Update 不继承 Default，@Validated({Update.class}) 就只会校验属于 Update.class 分组的参数字段，修改后再次请求该接口得到如下结果，可以看到， 其他字段没有参与校验
```json
{
    "status": 400,
    "message": "客户端请求参数错误",
    "response": [
        "name 不能为空"
    ]
}
```

# 递归校验
如果 user 类中增加一个 OrderVO 类的属性，而 OrderVO 中的属性也需要校验，就用到递归校验了，只要在相应属性上增加 @Valid 注解即可实现（对于集合同样适用）

OrderVO 类如下
```java
public class OrderVO {
    @NotNull
    private Long id;
    @NotBlank(message = "itemName 不能为空")
    private String itemName;
    // 省略其他代码...
}
```
在 user 类中增加一个 OrderVO 类型的属性
```java
public class user {
    @NotBlank(message = "name 不能为空",groups = Update.class)
    private String name;
    //需要递归校验的OrderVO
    @Valid
    private OrderVO orderVO;
    // 省略其他代码...
}   
```
```
http://localhost:8080/user/addorderV0.id=1 &orderVO.itemName&age=1 &email=1@1
```
```json
{
    "status": 400,
    "message": "客户端请求参数错误",
    "response": [
        "itemName 不能为空"
    ]
}
```

# 自定义校验
Spring 的 Validation 为我们提供了这么多特性，几乎可以满足日常开发中绝大多数参数校验场景了。但是，一个好的框架一定是方便扩展的。有了扩展能力，就能应对更多复杂的业务场景，毕竟在开发过程中，如果需求没变那一定是需求变了。

Spring Validation 允许用户自定义校验，实现很简单，分两步：
- 自定义校验注解
- 编写校验者类
```java
@Target({METHOD, FIELD, ANNOTATION_TYPE, CONSTRUCTOR, PARAMETER})
@Retention(RUNTIME)
@Documented
@Constraint(validatedBy = {HaveNoBlankValidator.class})// 标明由哪个类执行校验逻辑
public @interface HaveNoBlank {
 
    // 校验出错时默认返回的消息
    String message() default "字符串中不能含有空格";

    Class<?>[] groups() default { };

    Class<? extends Payload>[] payload() default { };

    /**
     * 同一个元素上指定多个该注解时使用
     */
    @Target({ METHOD, FIELD, ANNOTATION_TYPE, CONSTRUCTOR, PARAMETER, TYPE_USE })
    @Retention(RUNTIME)
    @Documented
    public @interface List {
        NotBlank[] value();
    }
}
```
```java
public class HaveNoBlankValidator implements ConstraintValidator<HaveNoBlank, String> {
    @Override
    public boolean isValid(String value, ConstraintValidatorContext context) {
        // null 不做检验
        if (value == null) {
            return true;
        }
        if (value.contains(" ")) {
            // 校验失败
            return false;
        }
        // 校验成功
        return true;
    }
}
```
自定义校验注解使用起来和内置注解无异，在需要的字段上添加相应注解即可