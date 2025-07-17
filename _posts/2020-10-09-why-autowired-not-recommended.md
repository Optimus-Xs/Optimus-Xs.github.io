---
layout: post
title: 为什么使用 @Autowired 提示不推荐
date: 2020-10-09 13:09 +0800
categories: [Software Development] 
tags: [Java, Spring, DevDairy]
---

`@Autowired`注解相信每个Spring开发者都不陌生了！

但是当我们使用IDEA写代码的时候，经常会发现@Autowired注解下面是有小黄线的，我们把小鼠标悬停在上面，可以看到这个如下图所示的警告信息：

![](https://cdn.jsdelivr.net/gh/Optimus-Xs/Blog-Images/2020-10-09-why-autowired-not-recommended/bVcVPVz.webp)

那么为什么IDEA会给出Field injection is not recommended这样的警告呢？

下面带着这样的问题，一起来全面的了解下Spring中的三种注入方式以及他们之间在各方面的优劣。

# Spring中的三种依赖注入方式
## Field Injection
`@Autowired`注解的一大使用场景就是Field Injection。

具体形式如下：
```java
@Controller
public class UserController {

    @Autowired
    private UserService userService;

}
```
这种注入方式通过Java的反射机制实现，所以private的成员也可以被注入具体的对象。

## Constructor Injection
Constructor Injection是构造器注入，是我们日常最为推荐的一种使用方式。

具体形式如下：

```java
@Controller
public class UserController {

    private final UserService userService;

    public UserController(UserService userService){
        this.userService = userService;
    }

}
```
这种注入方式很直接，通过对象构建的时候建立关系，所以这种方式对对象创建的顺序会有要求，当然Spring会为你搞定这样的先后顺序，除非你出现循环依赖，然后就会抛出异常。

## Setter Injection
Setter Injection也会用到`@Autowired`注解，但使用方式与Field Injection有所不同，Field Injection是用在成员变量上，而Setter Injection的时候，是用在成员变量的`Setter`函数上。

具体形式如下：

```java
@Controller
public class UserController {

    private UserService userService;

    @Autowired
    public void setUserService(UserService userService){
        this.userService = userService;
    }
}
```
这种注入方式也很好理解，就是通过调用成员变量的set方法来注入想要使用的依赖对象。

# 三种依赖注入的对比
在知道了Spring提供的三种依赖注入方式之后，我们继续回到本文开头说到的问题：IDEA为什么不推荐使用`Field Injection`呢？

我们可以从多个开发测试的考察角度来对比一下它们之间的优劣：

## 可靠性
从对象构建过程和使用过程，看对象在各阶段的使用是否可靠来评判：

- Field Injection：不可靠
- Constructor Injection：可靠
- Setter Injection：不可靠

由于构造函数有严格的构建顺序和不可变性，一旦构建就可用，且不会被更改。

## 可维护性
主要从更容易阅读、分析依赖关系的角度来评判：

- Field Injection：差
- Constructor Injection：好
- Setter Injection：差

还是由于依赖关键的明确，从构造函数中可以显现的分析出依赖关系，对于我们如何去读懂关系和维护关系更友好。

## 可测试性
当在复杂依赖关系的情况下，考察程序是否更容易编写单元测试来评判

- Field Injection：差
- Constructor Injection：好
- Setter Injection：好

Constructor Injection和Setter Injection的方式更容易Mock和注入对象，所以更容易实现单元测试。

## 灵活性
主要根据开发实现时候的编码灵活性来判断：

- Field Injection：很灵活
- Constructor Injection：不灵活
- Setter Injection：很灵活

由于Constructor Injection对Bean的依赖关系设计有严格的顺序要求，所以这种注入方式不太灵活。相反Field Injection和Setter Injection就非常灵活，但也因为灵活带来了局面的混乱，也是一把双刃剑。

## 循环关系的检测
对于Bean之间是否存在循环依赖关系的检测能力：

- Field Injection：不检测
- Constructor Injection：自动检测
- Setter Injection：不检测

## 性能表现
不同的注入方式，对性能的影响

- Field Injection：启动快
- Constructor Injection：启动慢
- Setter Injection：启动快

主要影响就是启动时间，由于Constructor Injection有严格的顺序要求，所以会拉长启动时间。

# 总结

所以，综合上面各方面的比较，可以获得如下表格：

| 注入方式              | 可靠性 | 可维护性 | 可测试性 | 灵活性 | 循环关系的检测 | 性能影响 |
| :-------------------- | :----- | :------- | :------- | :----- | :------------- | :------- |
| Field Injection       | 不可靠 | 低       | 差       | 很灵活 | 不检测         | 启动快   |
| Constructor Injection | 可靠   | 高       | 好       | 不灵活 | 自动检测       | 启动慢   |
| Setter Injection      | 不可靠 | 低       | 好       | 很灵活 | 不检测         | 启动快   |

结果一目了然，`Constructor Injection`在很多方面都是优于其他两种方式的，所以`Constructor Injection`通常都是首选方案！

而Setter Injection比起Field Injection来说，大部分都一样，但因为可测试性更好，所以当你要用`@Autowired`的时候，推荐使用Setter Injection的方式，这样IDEA也不会给出警告了。同时，也侧面也反映了，可测试性的重要地位啊

最后，关于`@Autowired`注入，我们给出两个结论:

- 依赖注入的使用上，`Constructor Injection`是首选。
- 使用@Autowired注解的时候，要使用`Setter Injection`方式，这样代码更容易编写单元测试。




