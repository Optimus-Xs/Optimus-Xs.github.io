---
layout: post
title: SpringSecurity 实现方法级别的权限验证
date: 2021-03-10 15:23 +0800
categories: [Software Development] 
tags: [Java, Spring, SpringSecurity, DevDairy]
---

# 背景
在前文[SpringSecurity 使用方法]({% post_url 2021-02-27-spring-security-usage%})中实通过SpringSecurity配置实现了请求路径得用户权限验证，但是只实现了已登录得用户有权限可以访问被保护的资源，但是不同的资源对不同用户的访问权限不一致，例如某个资源是A用户的私有资源，而B应该无权访问，或者R为A共享的资源，B可以访问但不能修改。

而且由于使用Restful风格，对统一资源的CURD操作请求路径一致，而是通过HTTP方法区分，基于路径hasAuthority和hasRole表达式都无法满足需求，因为它们只能判断一个硬编码的权限或者角色字符串。所以我们需要用到自定义表达式来高度自定义权限判断以满足需求。

# SpringSecurity 方法级的安全管控配置
默认情况下, Spring Security 并不启用方法级的安全管控. 启用方法级的管控后, 可以针对不同的方法通过注解设置不同的访问条件.
Spring Security 支持三种方法级注解, 分别是 JSR-205 注解/@Secured 注解/prePostEnabled注解. 这些注解不仅可以直接加 controller 方法上, 也可以注解 Service 或 DAO 类中的方法. 

开启@EnableGlobalMethodSecurity(prePostEnabled = true)注解, 在继承 WebSecurityConfigurerAdapter 这个类的类上面贴上这个注解.并且prePostEnabled设置为true,@PreAuthorize这个注解才能生效,SpringSecurity默认是关闭注解功能的.

```java
@Configuration
@EnableWebSecurity
@EnableGlobalMethodSecurity(prePostEnabled=true)
public class SecurityConfig extends WebSecurityConfigurerAdapter {

}
```

让后就可以在Controller里面添加方法验证注解了
```java
    @PreAuthorize("@ValidService.isUserHasOwnership(#userId, #repoId)")
    @GetMapping("/api/{userId}/{repoId}/notes")
    public List<Note> getNotes(@PathVariable int userId, @PathVariable int repoId) {
        return noteService.getAllNoteOfARepo(repoId);
    }
```
这里主要@PreAuthorize, @PostAuthorize, @Secured这三个注解可以使用。

## @PreAuthorize
Spring的 @PreAuthorize/@PostAuthorize 注解更适合方法级的安全,也支持Spring 表达式语言，提供了基于表达式的访问控制。

当@EnableGlobalMethodSecurity(prePostEnabled=true)的时候，@PreAuthorize可以使用：

```java
@GetMapping("/helloUser")
@PreAuthorize("hasAnyRole('normal','admin')")
public String helloUser() {
    return "hello,user";
}
```
说明：拥有normal或者admin角色的用户都可以方法helloUser()方法。

此时如果我们要求用户必须同时拥有normal和admin的话，那么可以这么编码：
```java

@GetMapping("/helloUser")
@PreAuthorize("hasRole('normal') AND hasRole('admin')") 
public String helloUser() {
    return "hello,user";
}
```
此时如果使用user/123登录的话，就无法访问helloUser()的方法了。

## @PostAuthorize
@PostAuthorize 注解使用并不多，在方法执行后再进行权限验证，适合验证带有返回值的权限，Spring EL 提供 返回对象能够在表达式语言中获取返回的对象returnObject。

当@EnableGlobalMethodSecurity(prePostEnabled=true)的时候，@PostAuthorize可以使用：
```java
@GetMapping("/helloUser")
@PostAuthorize(" returnObject!=null &&  returnObject.username == authentication.name")
public User helloUser() {
        Object pricipal = SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        User user;
        if("anonymousUser".equals(pricipal)) {
            user = null;
        }else {
            user = (User) pricipal;
        }
        return user;
}
```

## @Secured
当@EnableGlobalMethodSecurity(securedEnabled=true)的时候，@Secured可以使用：
```java
@GetMapping("/helloUser")
@Secured({"ROLE_normal","ROLE_admin"})
public String helloUser() {
    return "hello,user";
}
```
说明：拥有normal或者admin角色的用户都可以方法helloUser()方法。另外需要注意的是这里匹配的字符串需要添加前缀“ROLE_“。

如果我们要求，只有同时拥有admin & noremal的用户才能方法helloUser()方法，这时候@Secured就无能为力了。

## SpringSecurity 内置表达式

| Expression                                                           | Description                                                                                                                                                                                                            |
| :------------------------------------------------------------------- | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| hasRole([role])                                                      | 如果当前主体具有指定角色，则返回true。默认情况下，如果提供的角色不是以“ ROLE_”开头，则会添加该角色。可以通过修改DefaultWebSecurityExpressionHandler上的defaultRolePrefix进行自定义。                                   |
| hasAnyRole([role1,role2])                                            | 如果当前主体具有提供的任何角色(以逗号分隔的字符串列表形式)，则返回true。默认情况下，如果提供的角色不是以“ ROLE_”开头，则会添加该角色。可以通过修改DefaultWebSecurityExpressionHandler上的defaultRolePrefix进行自定义。 |
| hasAuthority([authority])                                            | 如果当前主体具有指定的权限，则返回true。                                                                                                                                                                               |
| hasAnyAuthority([authority1,authority2])                             | 如果当前委托人具有提供的任何角色(以逗号分隔的字符串列表形式)，则返回true                                                                                                                                               |
| principal                                                            | 允许直接访问代表当前用户的主体对象                                                                                                                                                                                     |
| authentication                                                       | 允许直接访问从SecurityContext获取的当前Authentication对象                                                                                                                                                              |
| permitAll                                                            | 始终计算为true                                                                                                                                                                                                         |
| denyAll                                                              | 始终计算为false                                                                                                                                                                                                        |
| isAnonymous()                                                        | 如果当前主体是匿名用户，则返回true                                                                                                                                                                                     |
| isRememberMe()                                                       | 如果当前主体是“记住我”用户，则返回true                                                                                                                                                                                 |
| isAuthenticated()                                                    | 如果用户不是匿名用户，则返回true                                                                                                                                                                                       |
| isFullyAuthenticated()                                               | 如果用户不是匿名用户或“记住我”用户，则返回true                                                                                                                                                                         |
| hasPermission(Object target, Object permission)                      | 如果用户有权访问给定目标的给定权限，则返回true。例如hasPermission(domainObject, 'read')                                                                                                                                |
| hasPermission(Object targetId, String targetType, Object permission) | 如果用户有权访问给定目标的给定权限，则返回true。例如hasPermission(1, 'com.example.domain.Message', 'read')                                                                                                             |

# 自定义验证逻辑
当然 除了内建的表达式外，我们也可以自己实现验证逻辑
```java
@Service("ValidService")
public class userOwnershipCheck {
    final UserInfoTool userInfoTool;
    final RepoService repoService;
    final NoteService noteService;

    @Autowired
    public userOwnershipCheck(UserInfoTool userInfoTool, RepoService repoService, NoteService noteService) {
        this.userInfoTool = userInfoTool;
        this.repoService = repoService;
        this.noteService = noteService;
    }

    /*requestUserPath为用户ID*/
    public boolean isUserHasOwnership(int userId) {
        return userInfoTool.currentUser().getId() == userId;
    }

    /*requestUserPath为用户ID*/
    public boolean isUserHasOwnership(int userId, int repoId) {
        Repo repo = repoService.getRepoById(repoId);
        if (repo == null) {
            Asserts.fail(CustomStatusEnum.USER_REPO_NOT_EXIST);
        }
        return  userInfoTool.currentUser().getId() == userId
                && userInfoTool.currentUser().getId() == repo.getUser().getId();
    }
```
只需要将实习逻辑注册为服务，然后在@PreAuthorize(), @PostAuthorize(), @Secured()调用即可
```java
  @PreAuthorize("@ValidService.isUserHasOwnership(#userId, #repoId)")
  @GetMapping("/api/{userId}/{repoId}/notes")
  public List<Note> getNotes(@PathVariable int userId, @PathVariable int repoId) {
      return noteService.getAllNoteOfARepo(repoId);
  }
```
这样在用户以Get方法访问 */api/{userId}/{repoId}/notes* 时 @PreAuthorize 会根据自定义验证逻辑中用户是否对此资源拥有读取权限来确定是否放行请求