---
layout: post
title: HSTS机制详解
date: 2022-03-07 12:09 +0800
categories: [Software Development] 
tags: [HTTP,Network]
---

# HSTS 是什么？

HSTS 是 HTTP 严格传输安全（HTTP Strict Transport Security）。 这是一种网站用来声明他们只能使用安全连接（HTTPS）访问的方法。 如果一个网站声明了 HSTS 策略，浏览器必须拒绝所有的 HTTP 连接并阻止用户接受不安全的 SSL 证书。 目前大多数主流浏览器都支持 HSTS (只有一些移动浏览器无法使用它),  最新的游览器兼容列表查看[此处(CanIUse)](https://caniuse.com/?search=HSTS)

![can i use hsts](https://cdn.jsdelivr.net/gh/Optimus-Xs/Blog-Images/2022-03-07-detailed-explanation-of-the-hsts-mechanism%2Fcan-i-use-hsts.png)

在 2012 年的 [RFC 6797](https://tools.ietf.org/html/rfc6797) 中，HTTP严格传输安全被定义为网络安全标准。 创建这个标准的主要目的，是为了避免用户遭受使用 SSL stripping 的 中间人攻击(`man-in-The-middle`，`MITM`)。 SSL stripping 是一种攻击者强迫浏览器使用 HTTP 协议连接到站点的技术，这样他们就可以嗅探数据包，拦截或修改敏感信息。 另外，HSTS 也是一个很好的保护自己免受 cookie 劫持（cookie hijacking）的方法。

> SSL 剥离(SSL stripping)是一种中间人攻击技术，它利用了 HTTPS 协议向 HTTP 协议降级的过程。攻击者拦截并修改了用户与服务器之间的通信，目的是强制用户浏览器使用不安全的 HTTP 连接，从而窃取敏感信息
>
> 具体攻击流程在下一章节: [HSTS 出现的背景](#hsts-出现的背景)
> 
{: .prompt-info }


# HSTS 出现的背景

## SSL 剥离攻击流程

> 缘起：仅启用HTTPS也不够安全

有不少网站只通过HTTPS对外提供服务，但用户在访问某个网站的时候，在浏览器里却往往直接输入网站域名（例如 `Example Domain`），而不是完整的URL（例如 `https://Example Domain`），不过浏览器依然能正确的使用HTTPS发起请求。这背后多亏了服务器和浏览器的协作，如下图所示。

![游览器URL自动补全](https://cdn.jsdelivr.net/gh/Optimus-Xs/Blog-Images/2022-03-07-detailed-explanation-of-the-hsts-mechanism%2Furl-autocomplete-by-broswer.png)

简单来讲就是，浏览器向网站发起一次HTTP请求，在得到一个重定向响应后，发起一次HTTPS请求并得到最终的响应内容。所有的这一切对用户而言是完全透明的，所以在用户看来，在浏览器里直接输入域名却依然可以用HTTPS协议和网站进行安全的通信，是个不错的用户体验。

一切看上去都是那么的完美，但其实不然，由于在建立起HTTPS连接之前存在一次明文的HTTP请求和重定向（上图中的第1、2步），使得攻击者可以以中间人的方式劫持这次请求，从而进行后续的攻击，例如窃听数据、篡改请求和响应、跳转到钓鱼网站等。

以劫持请求并跳转到钓鱼网站为例，其大致做法如下图所示：

![SSL stripping 攻击流程](https://cdn.jsdelivr.net/gh/Optimus-Xs/Blog-Images/2022-03-07-detailed-explanation-of-the-hsts-mechanism%2Fssl-stripping-demo.png)

1. 浏览器发起一次明文HTTP请求，但实际上会被攻击者拦截下来
2. 攻击者作为代理，把当前请求转发给钓鱼网站
3. 钓鱼网站返回假冒的网页内容
4. 攻击者把假冒的网页内容返回给浏览器

这个攻击的精妙之处在于，攻击者直接劫持了HTTP请求，并返回了内容给浏览器，根本不给浏览器同真实网站建立HTTPS连接的机会，因此浏览器会误以为真实网站通过HTTP对外提供服务，自然也就不会向用户报告当前的连接不安全。于是乎攻击者几乎可以神不知鬼不觉的对请求和响应动手脚。


既然建立HTTPS连接之前的这一次HTTP明文请求和重定向有可能被攻击者劫持，那么解决这一问题的思路自然就变成了如何避免出现这样的HTTP请求。我们期望的浏览器行为是，当用户让浏览器发起HTTP请求的时候，浏览器将其转换为HTTPS请求，直接略过上述的HTTP请求和重定向，从而使得中间人攻击失效，以规避风险。其大致流程如下：

![HSTS 功能需求](https://cdn.jsdelivr.net/gh/Optimus-Xs/Blog-Images/2022-03-07-detailed-explanation-of-the-hsts-mechanism%2Fhsts-require.png)

1. 用户在浏览器地址栏里输入网站域名，浏览器得知该域名应该使用HTTPS进行通信
2. 浏览器直接向网站发起HTTPS请求
3. 网站返回相应的内容

而实现这一套流程的机制就是**HSTS(HTTP Strict-Transport-Security)**


# HSTS 的原理

## 让浏览器直接发起HTTPS请求

通常，当您在 Web 浏览器中输入 URL 时，您会跳过协议部分。 例如，你输入的是 `www.example.com`，而不是 `http://www.example.com`。 在这种情况下，浏览器假设你想使用 HTTP 协议，所以它在这个阶段发出一个 HTTP 请求 到 `www.example.com`，同时，Web Server 会返回 301 状态码将请求重定向到 HTTPS 站点。 接下来浏览器使用 HTTPS 连接到 `www.example.com`。 这时 HSTS 安全策略保护开始使用 HTTP 响应头 `Strict-Transport-Security` 正是它可以让浏览器得知，在接下来的一段时间内，当前域名只能通过HTTPS进行访问，并且在浏览器发现当前连接不安全的情况下，强制拒绝用户的后续访问要求

`Strict-Transport-Security: max-age=31536000; includeSubDomains; preload`

其中：

- **`max-age` 是必选参数**: 是一个以秒为单位的数值，它代表着HSTS Header的过期时间，通常设置为1年，即31536000秒。
- **`includeSubDomains` 是可选参数**: 如果包含它，则意味着当前域名及其子域名均开启HSTS保护。
- **`preload` 是可选参数**: 只有当你申请将自己的域名加入到浏览器内置列表的时候才需要使用到它。关于浏览器内置列表，下文有详细介绍。

响应头的 `Strict-Transport-Security` 给浏览器提供了详细的说明。 从现在开始，每个连接到该网站及其子域的下一年（31536000秒）从这个头被接收的时刻起必须是一个 HTTPS 连接。 HTTP 连接是完全不允许的。 如果浏览器接收到使用 HTTP 加载资源的请求，则必须尝试使用 HTTPS 请求替代。 如果 HTTPS 不可用，则必须直接终止连接。

> 只要是在有效期内，浏览器都将直接强制性的发起HTTPS请求，但是问题又来了，有效期过了怎么办？其实不用为此过多担心，因为HSTS Header存在于每个响应中，随着用户和网站的交互，这个有效时间时刻都在刷新，再加上有效期通常都被设置成了1年，所以只要用户的前后两次请求之间的时间间隔没有超过1年，则基本上不会出现安全风险。更何况，就算超过了有效期，只要用户和网站再进行一次新的交互，用户的浏览器又将开启有效期为1年的HSTS保护。
{: .prompt-tip }

> 此外，如果证书无效，将阻止你建立连接。 通常来说，如果 HTTPS 证书无效（如：过期、自签名、由未知 CA 签名等），浏览器会显示一个可以规避的警告。 但是，如果站点有 HSTS，浏览器就不会让你绕过警告。 若要访问该站点，必须从浏览器内的 HSTS 列表中删除该站点。
{: .prompt-danger }

响应头的 `Strict-Transport-Security` 是针对一个特定的网站发送的，并且覆盖一个特定的域名（domain）。 因此，如果你有 HSTS 的 `www.example.com` ，它不会覆盖 `example.com`，而只覆盖 `www` 子域名。 这就是为什么，为了完全的保护，你的网站应该包含一个对 base domain 的调用（在本例中是 `example.com`） ，并且接收该域名的 `Strict-Transport-Security` 头和 `includeSubDomains` 指令。

完整的HSTS流程如下:

![HSTS 流程](https://cdn.jsdelivr.net/gh/Optimus-Xs/Blog-Images/2022-03-07-detailed-explanation-of-the-hsts-mechanism%2Fhsts-flow.png)


## 强制拒绝不安全的链接

在没有HSTS保护的情况下，当浏览器发现当前网站的证书出现错误，或者浏览器和服务器之间的通信不安全，无法建立HTTPS连接的时候，浏览器通常会警告用户，但是却又允许用户继续不安全的访问。如下图所示，用户可以点击图中红色方框中的链接，继续在不安全的连接下进行访问。

![SSL 错误提示](https://cdn.jsdelivr.net/gh/Optimus-Xs/Blog-Images/2022-03-07-detailed-explanation-of-the-hsts-mechanism%2Fssl-error.jpg)

理论上而言，用户看到这个警告之后就应该提高警惕，意识到自己和网站之间的通信不安全，可能被劫持也可能被窃听，如果访问的恰好是银行、金融类网站的话后果更是不堪设想，理应终止后续操作。然而现实很残酷，就我的实际观察来看，有不少用户在遇到这样的警告之后依然选择了继续访问。

不过随着HSTS的出现，事情有了转机。对于启用了浏览器HSTS保护的网站，如果浏览器发现当前连接不安全，它将仅仅警告用户，而不再给用户提供是否继续访问的选择，从而避免后续安全问题的发生。例如，当访问Google搜索引擎的时候，如果当前通信连接存在安全问题，浏览器将会彻底阻止用户继续访问Google，如下图所示。

![HSTS 错误提示](https://cdn.jsdelivr.net/gh/Optimus-Xs/Blog-Images/2022-03-07-detailed-explanation-of-the-hsts-mechanism%2Fhsts-error.jpg)

# HSTS 安全性分析

## HSTS 是否完全安全？

不幸的是，你第一次访问这个网站，你不受 HSTS 的保护。 如果网站向 HTTP 连接添加 HSTS 头，则该报头将被忽略。 这是因为攻击者可以在中间人攻击（man-in-the-middle attack）中删除或添加头部。 HSTS 报头不可信，除非它是通过 HTTPS 传递的。

你还应该知道，每次您的浏览器读取 header 时，HSTS max-age 都会刷新，最大值为两年。 这意味着保护是永久性的，只要两次访问之间不超过两年。 如果你两年没有访问一个网站，它会被视为一个新网站。 与此同时，如果你提供 max-age 0 的 HSTS header，浏览器将在下一次连接尝试时将该站点视为一个新站点（这对测试非常有用）。

目前唯一可用于绕过 HSTS 的已知方法是基于 NTP(Network Time Protocol) 的攻击。 如果客户端计算机容易受到 **NTP 攻击 (NTP-based attack)**，NTP可能会被欺骗，使 HSTS 策略到期，并使用 HTTP 访问站点一次。

> HSTS（HTTP 严格传输安全）中会指定浏览器在未来的一段时间（max-age）内，这个网站只能通过 HTTPS 访问。即使你下次手动输入 `http://example.com`，浏览器也会自动强制跳转到 HTTPS。
> 
> 这种攻击正是利用了 HSTS 的 max-age 机制：
> 
> - 恶意 NTP 服务器： 攻击者在用户和 NTP 服务器之间建立一个中间人代理。
> - 时间欺骗： 当用户的计算机试图与 NTP 服务器同步时间时，攻击者会拦截这个请求，并伪造一个 NTP 响应，将用户的系统时间设置为一个遥远的未来日期，例如 2050 年。
> - HSTS 策略失效： 用户的浏览器将这个虚假的未来时间作为“当前时间”。当它再次访问 `example.com` 时，浏览器会检查 HSTS 策略。由于其系统时间已经超过了 max-age 的有效期，浏览器会认为该 HSTS 策略已经过期，从而允许不安全的 HTTP 连接。
> - SSL 剥离攻击： 攻击者就可以利用这个不安全的 HTTP 连接，对用户实施 SSL 剥离（SSL stripping）攻击，窃取敏感数据。
> 
> NTP 的攻击通过操纵客户端的系统时钟，来让浏览器误以为 HSTS 策略已失效，从而为后续的 SSL 剥离攻击打开大门。
{: .prompt-tip }

## Preload List机制

你可以使用称为 HSTS 预加载列表（HSTS preload list）的附加保护方法。**Chromium 项目维护一个使用 HSTS 的网站列表，该列表通过浏览器发布**。 如果你把你的网站添加到预加载列表中，浏览器会首先检查内部列表，这样你的网站就永远不会通过 HTTP 访问，甚至在第一次连接尝试时也不会。 这个方法不是 HSTS 标准的一部分，但是它被所有主流浏览器(Chrome、 Firefox、 Safari、 Opera、 IE11 和 Edge)使用。


# HSTS相关配置

## 如何配置HSTS

很多地方都可以进行HSTS的配置，例如反向代理服务器、应用服务器、应用程序框架，以及应用程序中自定义Header。你可以根据实际情况进行选择。
常见的是在代理服务器中进行配置，以Nginx为例，只需在配置文件中加上下面这条指令即可：

```conf
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
```
{: file="nginx.conf" }

> 不过需要特别注意的是，在生产环境下使用HSTS应当特别谨慎，因为一旦浏览器接收到HSTS Header（假如有效期是1年），但是网站的证书又恰好出了问题，那么用户将在接下来的1年时间内都无法访问到你的网站，直到证书错误被修复，或者用户主动清除浏览器缓存。
{: .prompt-danger }

因此，建议在生产环境开启HSTS的时候，先将`max-age`的值设置小一些，例如5分钟，然后检查HSTS是否能正常工作，网站能否正常访问，之后再逐步将时间延长，例如1周、1个月，并在这个时间范围内继续检查HSTS是否正常工作，最后才改到1年。

## 从浏览器的 HSTS 缓存中删除域

在设置 HSTS 并测试它时，可能需要清除浏览器中的 HSTS 缓存。 如果你设置 HSTS 不正确，你可能会访问网站出错，除非你清除数据。 下面是几种常用浏览器的方法。 还要注意，如果你的域在 HSTS 预加载列表中，清除 HSTS 缓存将是无效的，并且无法强制进行 HTTP 连接。

要从 Chrome HSTS 缓存中删除一个域名为案例，请按照以下步骤操作：

- 访问 [chrome://net-internals/#hsts](chrome://net-internals/#hsts)
- 在 Delete domain security policies下的文本框中输入要删除的域
- 点击文本框旁边的 Delete 按钮

![删除HSTS中的域名](https://cdn.jsdelivr.net/gh/Optimus-Xs/Blog-Images/2022-03-07-detailed-explanation-of-the-hsts-mechanism%2Fdelete-domain-in-hsts.png)

之后，你可以检查移除是否成功：

- 在 Query HSTS/PKP domain 下的文本框中输入要验证的域
- 点击文本框旁边的 Query 按钮
- 返回应该是 not found

![验证HSTS域名删除](https://cdn.jsdelivr.net/gh/Optimus-Xs/Blog-Images/2022-03-07-detailed-explanation-of-the-hsts-mechanism%2Fverify-hsts-delete.png)


## 如何加入到HSTS Preload List

根据官方说明，你的网站在具备以下几个条件后，可以提出申请加入到这个列表里。

- 具备一个有效的证书
- 在同一台主机上提供重定向响应，以及接收重定向过来的HTTPS请求
- 所有子域名均使用HTTPS
- 在根域名的HTTP响应头中，加入HSTS Header，并满足下列条件：
  - 过期时间最短不得少于18周(10886400秒), 虽然最低要求是 18 周，但为了确保安全性和成功提交，强烈建议将 max-age 设置为 31536000 秒（1 年）。
  - 必须包含includeSubDomains参数
  - 必须包含preload参数

当你准好这些之后，可以在HSTS Preload List的官网上（[hstspreload.org](https://hstspreload.org)）提交申请，或者了解更多详细的内容。

>为了提高安全性，浏览器不能访问或下载 预加载列表（preload list）。 它作为硬编码资源（hard-coded resource）和新的浏览器版本一起分发。 这意味着结果出现在列表中需要相当长的时间，而域从列表中删除也需要相当长的时间。 如果你希望将你的站点添加到列表中，则必须确保您能够在较长时间内保持对所有资源的完全 HTTPS 访问。 如果不这样做，你的网站可能会完全无法访问。
{: .prompt-danger }

## 如何查询域名是否加入到了Preload List

从提交申请到完成审核，成功加入到内置列表，中间可能需要等待几天到几周不等的时间。可通过官网 [hstspreload.org](https://hstspreload.org) 或在Chrome地址栏里输入 [chrome://net-internals/#hsts](chrome://net-internals/#hsts) 查询状态。

# 参考
- [什么是HSTS，为什么要使用它？](https://www.acunetix.com/blog/articles/what-is-hsts-why-use-it/) / [译文](https://github.com/Pines-Cheng/blog/issues/80)
- [HSTS详解](https://zhuanlan.zhihu.com/p/25537440)