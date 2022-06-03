---
layout: post
title: 4种强化域名安全的协议
date: 2022-05-22 20:47 +0800
categories: [Bottom Layer Knowledge] 
tags: [协议解析, Internet Security, Network]
---

# 传统的 DNS 有啥问题
传统的 DNS 是一个【比较古老】的协议。最早的草案可以追溯到1983年。1987年定稿之后，基本上没啥变化。

设计 DNS 的时候，互联网基本上还是个玩具。那年头的互联网协议，压根儿都没考虑安全性，DNS 当然也不例外。所以 DNS 的交互过程全都是【明文】滴，既无法做到“保密性”，也无法实现“完整性”。

缺乏“保密性”就意味着——任何一个能【监视】你上网流量的人，都可以【看到】你查询了哪些域名。直接引发的问题就是隐私风险。

缺乏“完整性”就意味着——任何一个能【修改】你上网流量的人，都可以【篡改】你的查询结果。直接引发的问题就是“DNS 欺骗”（也叫“DNS 污染”或“DNS 缓存投毒”）

为了解决传统 DNS 的这些弊端，后来诞生了好几个网络协议，以强化域名系统的安全性

# DNSSEC
## 历史
这玩意儿是“Domain Name System Security Extensions”的缩写。在今天介绍的4个协议中，DNSSEC 是最早诞生的（1997）。从最先的 [RFC 2065](https://tools.ietf.org/html/rfc2065) 进化为 [RFC 2535](https://tools.ietf.org/html/rfc2535)，再到 [RFC 4033](https://tools.ietf.org/html/rfc4033)、[RFC 4034](https://tools.ietf.org/html/rfc4034)、[RFC 4035](https://tools.ietf.org/html/rfc4035)。

在今天介绍的4个协议中，DNSSEC 也是最早大规模部署的。在2010年的时候，所有根域名服务器都已经部署了 DNSSEC。到了2011年，若干顶级域名（.org 和 .com 和 .net 和 .edu）也部署了 DNSSEC。

## 协议栈
```
--------
 DNSSEC
--------
  UDP
--------
  IP
--------
```

## 安全性的原理
当初设计 DNSSEC 的一个考虑是“尽可能兼容 DNS 协议”。所以 DNSSEC 只是在 DNS 协议的基础上增加了一个【数字签名机制】。

有了数字签名，如果域名查询的结果被人篡改了，DNSSEC 客户端就可以通过【校验签名】，判断查询结果是假的。套用信息安全的行话——DNSSEC 实现了【完整性】（也叫“不可篡改性”）。

由于 DNSSEC 引入了【数字签名】，就需要有【公私钥对】。私钥是保密的，用来生成签名；公钥是公开的，用来验证签名。DNSSEC 客户端可以向 DNSSEC 服务器发出请求，获得一个 DNSKEY 记录，里面含公钥；然后用这个公钥校验每次的查询结果。

## 信任链的实现
有些聪明的老哥会问了：DESSEC 客户端在向服务器请求公钥的过程中，如果被攻击者篡改了，得到一个假的公钥，那该如何是好？

为了解决此问题，DNSSEC 体系要求【上级域】来担保。比如想要证明 optiomus-xs.github.io 这个域名的公钥是否可信，就依靠 github.io 这个域名的公钥来验证。通过层层追溯，最后达到【根域名服务器】。而“根域名服务器的公钥”是事先就部署在客户端的——这玩意儿就是整个信任链的根源，称之为“信任锚”（Trust Anchor）。

## 优点
- 这4个协议中，DNSSEC 应该是最成熟的。除了前面提到的广泛部署，大多数公共的域名服务器也都支持它。在这4个协议中，支持 DNSSEC 的最多。

## 缺点
- 虽然 DNSSEC 最成熟，但它有个天生的缺陷——【没有】考虑到【保密性】。
- DNSSEC 虽然对传输的数据做了数字签名，但是【没有】进行加密。这就意味着——任何能监视你网络流量的人，也可以看到你通过 DNSSEC 查询了哪些域名。
- Chrome 曾经在 14 版本支持过 DNSSEC，后来又【移除】了；而 Firefox 官方从未支持过 DNSSEC 协议。


# DNSCrypt
## 历史
第2个出场的是 DNSCrypt。这个协议是由 Frank Denis 和 Yecheng Fu两人设计的。

这个协议从来【没有】提交过 RFC（征求意见稿），要想看它的协议实现，只能去它的[官网](https://dnscrypt.info/protocol/)

历史上有过两个版本，分别称：Version 1 和 Version 2。如今主要使用“版本2”

## 协议栈
```
----------------
    DNSCrypt
----------------
   TCP or UDP
----------------
       IP
----------------
```

## 安全性的原理
前面提到 DNSSEC 协议强调兼容性。而 DNSCrypt 则完全是另起炉灶搞出来的协议。在这个协议中，域名的“查询请求”与“响应结果”都是加密的。这就是它比 DNSSEC 高级的地方。

换句话说，DNSCrypt 既能做到【完整性】，也能做到【保密性】；相比之下，DNSSEC 只能做到【完整性】。

## 信任链的实现
DNSCrypt 的信任链比较简单——客户端要想使用哪个 DNSCrypt 服务器，就需要预先部署该服务器的公钥。

另外，DNSCrypt 还支持客户端认证（作为可选项）。如果需要的话，可以在服务器上部署客户端的公钥。此时，服务器只接受可信的客户端的查询请求。

## 优点
- 如前所述，DNSCrypt 同时支持【完整性】与【保密性】。在隐私方面完胜 DNSSEC。
- 在下层协议方面，DNSCrypt 同时支持 TCP 和 UDP，显然比 DNSSEC 灵活（DNSSEC 只支持 UDP）。
- 顺便提醒一下：虽然 DNSCrypt 协议默认使用 443 这个端口号，但该协议与 HTTPS 毫无关系。

## 缺点
- DNSCrypt 最大的缺点就是前面提到的：【从未】提交过 RFC。没有 RFC 也就无法通过 IETF（互联网工程任务组）进行标准化。一个无法标准化的协议，其生命力要打很大的折扣。
- 另一个比较小的缺点是——虽然 DNSCrypt 协议是加密的，但可以被识别出来。换句话说：如果有人监控你的流量，可以识别出哪些流量属于 DNSCrypt 协议。
- Google 和 Cloudflare 的公共域名系统【尚未】支持 DNSCrypt

# DNS over TLS
“DNS over TLS”有时也被简称为【DoT】。为了打字省力，本文以下部分用 DoT 来称呼之
## 历史
DoT 已经正式发布了 RFC（参见 [RFC 7858](https://tools.ietf.org/html/rfc7858) 和 [RFC 8310](https://tools.ietf.org/html/rfc8310)）。
从时间上看，RFC7858 是2016年发布的，RFC8310 是今年（2018）发布的；显然，这个协议出现得比较晚（相比前面提到的 DNSSEC 和 DNSCrypt）。

## 协议栈
```
--------
  DoT
--------
  TLS
--------
  TCP
--------
  IP
--------
```

## 安全性的原理
顾名思义，DNS over TLS 就是基于 TLS 隧道之上的域名协议。由于 TLS 本身已经实现了【保密性】与【完整性】，因此 DoT 自然也就具有这两项特性。

## 信任链的实现
DoT 的信任链依赖于 TLS，而 TLS 的信任链靠的是 CA 证书体系

## 优点
- 相比 DNSSEC，DoT 具备了【保密性】；
- 相比 DNSCrypt，DoT 已经标准化。
- 另外，由于 DoT 协议是完全包裹在 TLS 里面，即使有人监视你的上网流量，也无法判断——哪些 TLS 流量是用于域名查询，哪些 TLS 用于网页传输。换句话说，DoT 协议的流量无法被【单独识别】出来。

## 缺点
支持 DoT 的客户端还不够多。尤其是主流的浏览器还没有计划增加 DoT 的支持



# DNS over HTTPS
“DNS over HTTPS”有时也被简称为【DoH】。为了打字省力，本文以下部分用 DoH 来称呼
## 历史
在今天介绍的4个协议中，DoH 是最新的（最晚出现的）。RFC 方面，它已经有了相应的草案，但还【没有】正式发布。截至写本文时，DoH 的草案已经发了 15 个版本（从 00 到 14），[最新版](https://tools.ietf.org/html/draft-ietf-doh-dns-over-https-14)

很多人把 DoH 与 DoT 混为一谈，实际上这是两种不同的协议。你可以对比这两者的协议栈，（只要没有星际玩家）就可看出其中的差别。

## 协议栈
```
--------
  DoH
--------
  HTTP
--------
  TLS
--------
  TCP
--------
  IP
--------
```

## 安全性的原理
顾名思义，DNS over HTTPS 就是基于 HTTPS 隧道之上的域名协议。而 HTTPS 又是“HTTP over TLS”。所以 DoH 相当于是【双重隧道】的协议。

与 DoT 类似，DoH 最终也是依靠 TLS 来实现了【保密性】与【完整性】

## 信任链的实现
DoH 类似于 DoT，最终是靠 TLS 所使用的“CA 证书体系”来实现信任链

## 优点
- 基本上，DoT 具备的优点，DoH 也具备。
- 相比 DoT，DoH 还多了一个优点：
- 由于 DoH 是基于 HTTP 之上。而主流的编程语言都有成熟的 HTTP 协议封装库；再加上 HTTP 协议的使用本身很简单。因此，要想用各种主流编程语言开发一个 DoH 的客户端，是非常容易滴

## 缺点
- 如前所述，DoH 目前还只有 RFC 的草案，尚未正式发布。这算是一个缺点。
- 相比 DoT，DoH 还有一个小缺点——由于 DoH 比 DoT 多了一层（请对比两者的协议栈），所以在性能方面，DoH 会比 DoT 略差。为啥说这是个【小】缺点捏？因为域名的查询并【不】频繁，而且客户端软件可以很容易地对域名的查询结果进行【缓存】（以降低查询次数）。所以 DoH 比 DoT 性能略差，无伤大雅。
