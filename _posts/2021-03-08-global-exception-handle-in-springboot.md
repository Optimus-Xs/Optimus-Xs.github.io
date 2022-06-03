---
layout: post
title: SpringBoot 实现全局异常处理
date: 2021-03-08 12:43 +0800
categories: [Software Development] 
tags: [Java, Spring, DevDairy]
---

将[返回值统一封装]({%post_url 2021-03-07-common-api-result-in-springboot%})时我们没有考虑当接口抛出异常的情况。当接口抛出异常时让用户直接看到服务端的异常肯定是不够友好的，而我们也不可能每一个接口都去try/catch进行处理，此时只需要使用@ExceptionHandler注解即可无感知的全局统一处理异常。

# 前言

## 实现思路

使用全局异常处理来处理校验逻辑的思路很简单，首先我们需要通过@ControllerAdvice注解定义一个全局异常的处理类，然后自定义一个校验异常，当我们在Controller中校验失败时，直接抛出该异常，这样就可以达到校验失败返回错误信息的目的了。

## 使用到的注解

- @ControllerAdvice：类似于@Component注解，可以指定一个组件，这个组件主要用于增强@Controller注解修饰的类的功能，比如说进行全局异常处理。
- @ExceptionHandler：用来修饰全局异常处理的方法，可以指定异常的类型。

# 实现示例代码

## ApiException
首先我们需要自定义一个异常类ApiException，当我们校验失败时抛出该异常
```java
public class ApiException extends RuntimeException {
    private int status;

    public ApiException(int status) {
        this.status = status;
    }

    public ApiException(String message) {
        super(message);
    }

    public ApiException(int status, String message) {
        super(message);
        this.status = status;
    }

    public ApiException(String message, Throwable cause) {
        super(message, cause);
    }

    public int getStatus() {
        return status;
    }
}
```

## Asserts
然后创建一个断言处理类Asserts，用于抛出各种ApiException
```java
public class Asserts {
    public  static void  fail(CustomStatusEnum customStatusEnum){
        throw  new ApiException(customStatusEnum.getStatus(), customStatusEnum.getMessage());
    }
    public static void fail(String message) {
        throw new ApiException(message);
    }

    public static void success(CustomStatusEnum customStatusEnum){
        throw  new ApiException(customStatusEnum.getStatus(), customStatusEnum.getMessage());
    }
}
```

## GlobalExceptionHandler
然后再创建我们的全局异常处理类GlobalExceptionHandler，用于处理全局异常（包括自定义的APIException、SpringVaildtion 和其他组件抛出的异常），并返回封装好的CommonResult对象
```java
@ControllerAdvice
public class GlobalExceptionHandler {

    @ResponseBody
    @ExceptionHandler(value = ApiException.class)
    public CommonResult<?> handleApiException(ApiException e) {
        return new CommonResult<>(e.getStatus(), e.getMessage(), null);
    }

    @ResponseBody
    @ExceptionHandler(value = DataAccessException.class)
    public CommonResult<?> handleException(DataAccessException e) {
        return new CommonResult<>(CustomStatusEnum.DATA_ACCESS_ERROR);
    }

    @ResponseBody
    @ExceptionHandler(value = AccessDeniedException.class)
    public CommonResult<?> handleException(AccessDeniedException e) {
        return new CommonResult<>(CustomStatusEnum.NOT_ALLOWED_TO_ACCESS_OTHER_USER_PATH);
    }

    /* @valid处理 form data方式调用接口校验失败抛出的异常*/
    @ResponseBody
    @ExceptionHandler(BindException.class)
    public CommonResult<?> handleBindException(BindException e) {
        List<FieldError> fieldErrors = e.getBindingResult().getFieldErrors();
        List<String> collect = fieldErrors.stream().map(o -> o.getDefaultMessage()).collect(Collectors.toList());
        List<Map<?,?>> wrappedMessage = wrapParamValidationMessage(collect);
        return new CommonResult<>(CustomStatusEnum.PARAM_VALIDATE_ERROR.getStatus(), CustomStatusEnum.PARAM_VALIDATE_ERROR.getMessage(), wrappedMessage);
    }

    // @valid处理 json 请求体调用接口校验失败抛出的异常
    @ResponseBody
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public CommonResult<?> methodArgumentNotValidExceptionHandler(MethodArgumentNotValidException e) {
        return handleBindException(e);
    }

    // @valid处理单个参数校验失败抛出的异常
    @ResponseBody
    @ExceptionHandler(ConstraintViolationException.class)
    public CommonResult<?> constraintViolationExceptionHandler(ConstraintViolationException e) {
        Set<ConstraintViolation<?>> constraintViolations = e.getConstraintViolations();
        List<String> collect = constraintViolations.stream().map(o -> o.getMessage()).collect(Collectors.toList());
        List<Map<?,?>> wrappedMessage = wrapParamValidationMessage(collect);
        return new CommonResult<>(CustomStatusEnum.PARAM_VALIDATE_ERROR.getStatus(), CustomStatusEnum.PARAM_VALIDATE_ERROR.getMessage(), wrappedMessage);
    }

    /*git相关异常*/
    @ResponseBody
    @ExceptionHandler(GitAPIException.class)
    public CommonResult<?> GitAPIExceptionHandler(GitAPIException e) {
        return new CommonResult<>(CustomStatusEnum.GIT_ERROR);
    }

    /*文件读写异常*/
    @ResponseBody
    @ExceptionHandler(IOException.class)
    public CommonResult<?> IOExceptionHandler(IOException e) {
        return new CommonResult<>(CustomStatusEnum.IO_ERROR);
    }

    /*JWT过期异常*/
    @ResponseBody
    @ExceptionHandler(ExpiredJwtException.class)
    public CommonResult<?> ExpiredJwtExceptionHandler(ExpiredJwtException e) {
        return new CommonResult<>(CustomStatusEnum.JWT_EXPIRED);
    }

    /*JWT过期异常*/
        @ResponseBody
        @ExceptionHandler(IllegalArgumentException.class)
        public CommonResult<?> IllegalArgumentExceptionHandler(IllegalArgumentException e) {
            return new CommonResult<>(CustomStatusEnum.JWT_EXPIRED);
        }


    //其他的异常
    @ResponseBody
    @ExceptionHandler(value = Exception.class)
    public CommonResult<?> handleException(Exception e) {
        return new CommonResult<>(CustomStatusEnum.INTERNAL_ERROR.getStatus(), CustomStatusEnum.INTERNAL_ERROR.getMessage()+e.getClass()+e.getMessage()+e.getCause(), null);
    }

    private List<Map<?,?>>  wrapParamValidationMessage(List<String> collect){
        List<Map<?,?>> wrappedMessage = new ArrayList<>();
        for (String s : collect) {
            Map<String, String> Messages = new HashMap<>();
            Messages.put("validateMessage", s);
            wrappedMessage.add(Messages);
        }
        return wrappedMessage;
    }
}
```

## CustomStatusEnum
为了抛出异常的代码简洁性和接口状态的解耦，我们还可以使用Java枚举类来定义整个系统中所有的业务异常同时确定接口状态码的含义
```java
public enum CustomStatusEnum {
    //请求正常
    REQUEST_DONE(1000, "请求完成"),
    LOGIN_SUCCESS(1001, "登录成功"),
    SIGN_UP_SUCCESS(1002,"注册成功"),

    // 底层异常
    INTERNAL_ERROR(9999,"内部错误:"),
    DATA_ACCESS_ERROR(10001,"数据访问错误"),
    NO_AUTH_FOR_STORAGE(10002,"文件存取路径无权限访问"),
    IO_ERROR(10003,"文件存取服务异常"),
    GIT_ERROR(10004,"版本控制服务异常"),
    ARGUMENT_ERROR(10005,"请求参数有误"),

    //用户相关异常
    USERNAME_EXIST(20001,"注册失败，用户名已被使用"),
    EMAIL_EXIST(20002,"注册失败，邮箱已被使用"),
    PASSWORD_TO_SIMPLE(20003,"注册失败，密码长度小于8位"),
    LOGIN_FAIL(20010,"登录失败，密码或用户名错误"),
    NOT_LOGIN(20011,"未登录情况下无法访问或访问方法错误"),
    NO_PERMISSION(20012,"当前登录用户无权访问此内容或访问方法错误"),
    NOT_ALLOWED_TO_ACCESS_OTHER_USER_PATH(20013,"无权访问其他用户的内容"),
    JWT_EXPIRED(20014, "登录状态过期"), //JWT登录过期
    WX_NOT_BIND(20015,"微信OpenID未绑定"),
    WX_OPENID_UNREACHABLE(20016,"微信OpenID无法获取"),
    WX_OPENID_ALREADY_BIND(20017,"微信OpenID已有绑定账户，无法绑定多个"),

    //实体属性校验
    PARAM_VALIDATE_ERROR(20020,"参数格式不符合"),

    //仓库相关异常
    REPO_EXIST(30001,"笔记夹已存在"), //仓库已存在
    CHANGE_REPO_NAME_EXIST(30002,"修改的笔记本夹名已被使用"),//要修改仓库名已被使用
    CHANGE_REPO_NAME_NOT_BLANK(30003,"修改的笔记本夹名不能为空白"),
    USER_REPO_NOT_EXIST(30004,"当前用户空间下无此笔记本夹"),
    No_COMMIT_IN_THIS_BRANCH(30004, "当前尚未有文件提交记录"),

    //文档相关异常
    NOTE_NOT_EXIST(40001,"文档不存在"),
    NOTE_EXISTED_IN_REPO(40002,"此文件夹内已有同名笔记"),
    NOTE_RENAME_FAIL(40003,"笔记重命名失败，请稍后再试")
    ;

    private final Integer status;
    private final String message;
    CustomStatusEnum(Integer status, String message) {
        this.status = status;
        this.message = message;
    }

    public Integer getStatus() {
        return status;
    }

    public String getMessage() {
        return message;
    }
}
```
# 异常抛出示例
一下即为验证一个Note资源是否存在的验证方法，当有用户或Note不存在时直接调用 Asserts.fail()方法抛出异常，异常会被自动捕获封装消息后通过API返回
```java
    public boolean isUserHasOwnership(int userId, int repoId, int noteId) throws IOException {
        Repo repo = repoService.getRepoById(repoId);
        Note note = noteService.getANote(noteId);
        if (repo == null) {
            Asserts.fail(CustomStatusEnum.USER_REPO_NOT_EXIST);
        }
        if (note == null) {
            Asserts.fail(CustomStatusEnum.NOTE_NOT_EXIST);
        }
        return userInfoTool.currentUser().getId() == userId
                && userInfoTool.currentUser().getId() == repo.getUser().getId()
                && userInfoTool.currentUser().getId() == note.getUser().getId();
    }
```
若请求Note不存在，这结果如下
```json
{
    "status": 30004,
    "message": "当前用户空间下无此笔记本夹",
    "resultBody": null
}
```

