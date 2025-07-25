---
layout: post
title: DNS报文格式
date: 2022-04-18 19:17 +0800
categories: [Bottom Layer Knowledge] 
tags: [Network, 协议解析]
---

我们知道查询一个域名，需要与 DNS 服务器进行通信。那么，DNS 通信过程大概是怎样的呢？

DNS 是一个典型的 Client-Server 应用，客户端发起域名查询请求，服务端对请求进行应答：

![](https://cdn.jsdelivr.net/gh/Optimus-Xs/Blog-Images/2022-04-18-dns-message-format/ba987b1fa1b0168df88331eee7bfa7e058a4cfb6.png)

DNS 一般采用 UDP 作为传输层协议（ TCP 亦可），端口号是 53 。请求报文和应答报文均作为数据，搭载在 UDP 数据报中进行传输：

![](https://cdn.jsdelivr.net/gh/Optimus-Xs/Blog-Images/2022-04-18-dns-message-format/4e9f63a16c60af3fc49a951154a2f3d2c0f21f98.png)

很显然，DNS 请求报文和应答报文均需要满足一定的格式，才能被通信双方所理解。这就是 DNS 协议负责的范畴，它位于传输层之上，属于 应用层 协议。


# 报文格式
DNS 报文分为 请求 和 应答 两种，结构是类似的，大致分为五部分：

- 头部（ header ），描述报文类型，以及其下 4 个小节的情况；
- 问题节（ question ），保存查询问题；
- 答案节（ answer ），保存问题答案，也就是查询结果；
- 授权信息节（ authority ），保存授权信息；
- 附加信息节（ additional ），保存附加信息；

>也有不少文献将 DNS 请求称为 DNS 查询（ query ），两者是一个意思。
{: .prompt-tip }

![](https://cdn.jsdelivr.net/gh/Optimus-Xs/Blog-Images/2022-04-18-dns-message-format/bb5146dfd61519aebc02722d4e62acaa1aba94e0.png)

其中，头部是固定的，共 12 字节；其他节不固定，记录数可多可少，数目保存在头部中。头部分为 6 个字段：

- 标识（ identifier ），一个 16 位的 ID ，在应答中原样返回，以此匹配请求和应答；
- 标志（ flags ），一些标志位，共 16 位；
- 问题记录数（ question count ），一个 16 位整数，表示问题节中的记录个数；
- 答案记录数（ answer count ），一个 16 位整数，表示答案节中的记录个数；
- 授权信息记录数（ authority record count ），一个 16 位整数，表示授权信息节中的记录个数；
- 附加信息记录数（ additional record count ），一个 16 位整数，表示附加信息节中的记录个数；

最后，我们来解释一下标志字段中的各个标志位：

- QR 位标记报文是一个查询请求，还是查询应答；
  - 0 表示查询请求；
  - 1 表示查询应答；
- 操作码（ opcode ）占 4 位，表示操作类型：
  - 0 代表标准查询；
  - 1 代表反向查询；
  - 2 代表服务器状态请求；
- AA 位表示 权威回答（ authoritative answer ），意味着当前查询结果是由域名的权威服务器给出的；
- TC 位表示 截短（ truncated ），使用 UDP 时，如果应答超过 512 字节，只返回前 512 个字节；
- RD 位表示 期望递归 （ recursion desired ），在请求中设置，并在应答中返回；
  - 该位为 1 时，服务器必须处理这个请求：如果服务器没有授权回答，它必须替客户端请求其他 DNS 服务器，这也是所谓的 递归查询 ；
  - 该位为 0 时，如果服务器没有授权回答，它就返回一个能够处理该查询的服务器列表给客户端，由客户端自己进行 迭代查询 ；
- RA 位表示可递归（ recursion available ），如果服务器支持递归查询，就会在应答中设置该位，以告知客户端；
- 保留位，这 3 位目前未用，留作未来扩展；
- 响应码（ response code ）占 4 位，表示请求结果，常见的值包括：
  - 0 表示没有差错；
  - 3 表示名字差错，该差错由权威服务器返回，表示待查询的域名不存在；


# 问题记录
客户端查询域名时，需要向服务端发送请求报文；待查询域名作为问题记录，保存在问题节中。

![](https://cdn.jsdelivr.net/gh/Optimus-Xs/Blog-Images/2022-04-18-dns-message-format/4e3499436f3827644b71c9e392e2e5462cad6402.png)

问题节支持保存多条问题记录，记录条数则保存在 DNS 头部中的问题记录数字段。这意味着，DNS 协议单个请求能够同时查询多个域名，虽然通常只查询一个。

一个问题记录由 3 个字段组成：

- 待查询域名（ Name ），这个字段长度不固定，由具体域名决定；
- 查询类型（ Type ），域名除了关联 IP 地址，还可以关联其他信息，常见类型包括（下节详细介绍）：
  - 1 表示 A 记录，即 IP 地址；
  - 28 表示 AAAA 记录，即 IPv6 地址；
  - etc
- 类 （ Class ）通常为 1 ，表示 TCP/IP 互联网地址；

最后，我们回过头来考察域名字段，它的长度是不固定的。域名按 . 切分成若干部分，再依次保存。每个部分由一个前导计数字节开头，记录当前部分的字符数。

以域名 example.com. 为例，以 . 切分成 3 example 、com 以及空字符串 。请注意，空字符串 代表根域。因此，待查询域名字段依次为：

- 一个前导字节保存整数 8 ，然后 8 个字节保存 example 部分（二级域）；
- 一个前导字节保存整数 3 ，然后 3 个字节保存 com 部分（一级域）；
- 一个前导字节保存整数 0 ，然后 0 个字节保存 部分（根域）；

由此可见，每一级域名的长度理论上可以支持多达 255 个字符。

| 查询类型 | 名称代码 | 描述         |
| :------- | :------- | :----------- |
| 1        | A        | IPv4地址     |
| 2        | NS       | 名称服务器   |
| 5        | CNAME    | 规范名称     |
| 15       | MX       | 电子邮件交互 |
| 16       | TXT      | 文本信息     |
| 28       | AAAA     | IPv6地址     |



# 资源记录
服务端处理查询请求后，需要向客户端发送应答报文；域名查询结果作为资源记录，保存在答案以及其后两节中。

![](https://cdn.jsdelivr.net/gh/Optimus-Xs/Blog-Images/2022-04-18-dns-message-format/d9cdce4af72ec74a5795f1215be063c59253b883.png)

答案节、授权信息节和附加信息节均由一条或多条资源记录组成，记录数目保存在头部中的对应字段，不再赘述。

资源记录结构和问题记录非常相似，它总共有 6 个字段，前 3 个和问题记录完全一样：

- 被查询域名（ Name ），与问题记录相同；
- 查询类型（ Type ），与问题记录相同；
- 类 （ Class ），与问题记录相同；
- 有效期（ TTL ），域名记录一般不会频繁改动，所以在有效期内可以将结果缓存起来，降低请求频率；
- 数据长度（ Resource Data Length ），即查询结果的长度；
- 数据（ Resource Data ），即查询结果；

如果查询类型是 A 记录，那查询结果就是一个 IP 地址，保存于资源记录中的数据字段；而数据长度字段值为 4 ，因为 IP 地址的长度为 32 位，折合 4 字节。


# 域名压缩
我们注意到，应答报文中，会将请求报文中的问题记录原样返回。由于问题记录和资源记录都会保存域名，这意味着域名会被重复保存，而报文尺寸是有限的！

为了节约报文空间，有必要解决域名重复保存问题，这也是所谓的信息压缩。具体做法如下：

域名在报文中第二次出现时，只用两个字节来保存。第一个字节最高两位都是 1 ，余下部分和第二个字节组合在一起，表示域名第一次出现时在报文中的偏移量。通过这个偏移量，就可以找到对应的域名。

由此一来，原来需要 21 个字节来保存的域名，现在只需区区两个字节即可搞定，数据量大大降低！

实际上，域名压缩机制还可以针对域名的某个部分进行。举个例子，假设一个请求报文同时查询两个域名：

- example.com
- test.example.com

请求报文中包含两个问题记录，分别对应域名 example.com 和 test.example.com 。这两个域名都有一个公共后缀 example.com ，无须重复保存。

第二个域名只需保存 test 部分，然后接两个字节特殊的压缩字节`1100 0000B`，指向第一个问题记录中的 example.com 。如果两条问题记录顺序颠倒，结果也是类似的
