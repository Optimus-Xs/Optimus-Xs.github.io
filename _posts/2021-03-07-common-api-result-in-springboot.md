---
layout: post
title: 在 SpringBoot 中实现统一API返回格式
date: 2021-03-07 12:42 +0800
categories: [Software Development] 
tags: [Java, Spring, DevDairy]
---

# 实现思路
在前后端分离大行其道的今天，有一个统一的返回值格式不仅能使我们的接口看起来更漂亮，而且还可以使前端可以统一处理很多东西，避免很多问题的产生。

具体的实现思路为设计设计一个封装类用其一个泛型成员变量对原本返回的数据进行封装，同时提供API对请求的执行状况和消息

# 示例代码

## CommonResult

返回格式封装类

```java
public final class CommonResult<T> {

    private int status;

    private String message;

    private T resultBody;

    public CommonResult() {
    }

    public CommonResult(T resultBody) {
        this.status = CustomStatusEnum.REQUEST_DONE.getStatus();
        this.message = CustomStatusEnum.REQUEST_DONE.getMessage();
        this.resultBody = resultBody;
    }

    public CommonResult(int status, String message, T resultBody) {
        this.status = status;
        this.message = message;
        this.resultBody = resultBody;
    }

    public CommonResult(CustomStatusEnum customStatusEnum) {
        this.status = customStatusEnum.getStatus();
        this.message = customStatusEnum.getMessage();
    }

    //... getters & setters
}
```

假设最原始的接口如下：
```java
    @GetMapping("/test")
    public User test() {
        return new User();
    }
```
当我们需要统一返回值时，可能会使用这样一个办法：
```java
    @GetMapping("/test")
    public Result test() {
        return Result.success(new User());
    }
```
这个方法确实达到了统一接口返回值的目的，但是却有几个新问题诞生了：

- 接口返回值不明显，不能一眼看出来该接口的返回值。
- 每一个接口都需要增加额外的代码量。

## UnifiedReturnConfig

所幸Spring Boot已经为我们提供了更好的解决办法，只需要在项目中加上以下代码，就可以无感知的为我们统一全局返回值。

```java
@EnableWebMvc
@Configuration
public class UnifiedReturnConfig {

    @RestControllerAdvice
    static class ResultResponseAdvice implements ResponseBodyAdvice<Object> {
        @Override
        public boolean supports(MethodParameter methodParameter, Class<? extends HttpMessageConverter<?>> aClass) {
            return true;
        }

        @Override
        public Object beforeBodyWrite(Object body, MethodParameter methodParameter, MediaType mediaType, Class<? extends HttpMessageConverter<?>> aClass, ServerHttpRequest serverHttpRequest, ServerHttpResponse serverHttpResponse) {
            /*文件下载不使用统一Json返回格式*/
            if (serverHttpResponse.getHeaders().get("Content-Disposition") != null){
                return body;
            }
            if (body instanceof CommonResult) {
                return body;
            }
            return new CommonResult<>(body);
        }
    }
}

```

而我们的接口只需要写成最原始的样子就行了。