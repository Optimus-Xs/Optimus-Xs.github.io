---
layout: post
title: Gin 中的 BasicAuth授权认证中间件使用
date: 2022-05-14 20:35 +0800
categories: [Software Development] 
tags: [Go, DevDairy]
---

# 什么是BasicAuth
是一种开放平台认证方式，简单的说就是需要你输入用户名和密码才能继续访问。

# 在单路由中使用
如果需要针对单个路由使用，在要在单路由中注册BasicAuth
中间件即可。
```go 
// 使用BasicAuth中间件
func main(){
 engine := gin.Default()
  // 设置账号和密码，key:代表账号,value:代表密码
 ginAccounts := gin.Accounts{
  "user":"password",
  "abc":"123",
 }
  // 注册路由和中间件
 engine.GET("/test",gin.BasicAuth(ginAccounts), func(context *gin.Context) {
  // 获取中间件BasicAuth
  user := context.MustGet(gin.AuthUserKey).(string)
  fmt.Println(user)
  context.JSON(200,gin.H{"msg":"success"})
 }) 
 _ = engine.Run()
}
```

# 在路由组中使用
绝大部分情况下,我们都是在路由组中使用BasicAuth中间件。

```go
func RunUseBasicAuthWithGroup() {
 engine := gin.Default()
 // 注册路由组和中间件
 userGroup := engine.Group("/user", gin.BasicAuth(gin.Accounts{
  "abc": "123",
 }))
 userGroup.GET("info", func(context *gin.Context) {
  context.JSON(200, gin.H{"msg": "user.info"})
 })
}
```