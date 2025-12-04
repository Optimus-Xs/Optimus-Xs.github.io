---
layout: post
title: HSTS 缓存(307 跳转) 的处理
date: 2024-10-15 23:21 +0800
categories: [Software Development]
tags: [HTTP, Internet Security, Network, 协议解析]
---

## 背景
最近遇到使用HTTP访问自托管的Harbor某个域名时Chrome自动返回307，并重定向到HTTPS, 但是由于证书过期导致无法访问, 错误提示类似下图: 

![错误示例](https://cdn.jsdelivr.net/gh/Optimus-Xs/Blog-Images/2024-10-15-handling-hsts-cache-307-redirect%2Ferror-example.png)

表现行为:

- 无法通过访问HTTP访问, 指定协议也会跳转到HTTPS
- 同时提示证书错误,导致页面无法加载
- 更换游览器或者使用无痕模式能使用HTTP访问, 且正常(在服务允许HTTP访问的情况下)

## 原理分析
这个特性是由现代浏览器和服务器的 HSTS(HTTP Strict Transport Security) 功能导致

即自动将不安全的 HTTP 请求使用 307 Internal Redirect 跳转到 HTTPS 请求。这是由Chrome内部HSTS缓存导致的。**首次访问**一个设置了HSTS的网站，浏览器会接收并在当前隐身会话期间记住这个HSTS策略, 也就是说HSTS只要在理论上的**第一次访问**后，后来就不经网页服务器返回，浏览器会查询本地数据，直接使用 HSTS 307 跳转到安全的 HTTPS，以此来加强网络访问的安全性。

> HSTS机制详情参考 [HSTS机制详解](/posts/detailed-explanation-of-the-hsts-mechanism/)
{: .prompt-tip }

在安全层面这的确是个很先进的功能，但对开发环境耐受就带来了麻烦，一旦网页服务器设置了 HSTS，且在理论上的第一次无意或有意访问过，这就被浏览器缓存住了。此后，浏览器自行决定将不会再访问该域的 HTTP了，哪怕服务端已经修改了相关配置。

> 在HTTP/1.1中，新增了303 See Other、307 Temporary Redirect这两个状态码，这两个状态码和301、302状态码有什么区别呢？
>    
> 1. 对于`301`、`302`的`location`中包含的重定向url，如果请求`method`不是`GET`或者`HEAD`，那么浏览器是禁止自动重定向的，除非得到用户的确认，因为`POST`、`PUT`等请求是非冥等的（也就是再次请求时服务器的资源可能已经发生了变化）。
> 2. 虽然rfc明确了上述的规定，但是很多的浏览器不遵守这条规定，无论原来的请求方法是什么都会自动用GET方法重定向到`location`指定的url。就是说现存的很多浏览器在遇到`POST`请求返回`301`、`302`状态码的时候自动用GET请求`location`中的url，无需用户确认。
> 3. HTTP 1.1中新增了`303`、`307`状态码，用来明确服务器期待客户端进行何种反应。
> 4. `303`状态码其实就是上面`301`、`302`状态码的”不合法”动作，指示客户端可以自动用`GET`方法重定向请求`location`中的url，无需用户确认。也就是把前面`301`、`302`状态码的处理动作”合法化”了。
> 5. `307`状态码就是`301`、`302`原本需要遵守的规定，除`GET`、`HEAD`方法外，其他的请求方法必须等客户确认才能跳转。
> 6. `303`、`307`其实就是把原来`301`、`302`不”合法”的处理动作给”合法化”，因为发现大家都不太遵守，所以干脆就增加一条规定。
>
> MDN Web 文档:
> - [303 See Other](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Status/303)
> - [307 Temporary Redirect](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Status/307)
{: .prompt-info }

## 解决方案

在Chrome地址栏打开, 手动清除HSTS缓存即可

```
chrome://net-internals/#hsts
```

如果是Edge游览器访问: 

```
edge://net-internals/#hsts
```

![chrome HSTS 管理](https://cdn.jsdelivr.net/gh/Optimus-Xs/Blog-Images/2024-10-15-handling-hsts-cache-307-redirect%2Fchrome-hsts-management.png)

在 `Domain Security Policy` -> `Delete domain security policies` 选型中数量要清除HSTS缓存的域名, 点击`Delete`删除即可


> 如果一个网站被列入了Chrome的HSTS Preload List，那么无论是正常模式还是隐身模式，浏览器在首次访问该网站时都会直接使用HTTPS，因为这个策略是硬编码在浏览器内部的，不依赖于本地缓存。
{: .prompt-info }

# 参考
- [记一次HTTP Status 307缓存的处理](https://www.cnblogs.com/Don/p/12192420.html)