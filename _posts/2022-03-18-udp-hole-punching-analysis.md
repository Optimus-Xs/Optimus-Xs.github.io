---
layout: post
title: UDP 打洞技术解析
date: 2022-03-18 15:20 +0800
categories: [Bottom Layer Knowledge] 
tags: [Network]
---

P2P 通信最大的障碍就是 NAT（网络地址转换），NAT 使得局域网内的设备也可以与公网进行通讯，但是不同 NAT 下的设备之间通讯将会变得很困难。UDP 打洞就是用来使得设备间绕过 NAT 进行通讯的一种技术。


# 简单解释 NAT
NAT 大家应该十分熟悉了，它分为几种。一种就叫做 NAT，它只对 IP 地址进行转换；另一种叫做 NAPT（Network Address/Port Translation），它可以对整个会话的端点（由 IP 地址和端口号组成）做转换，这是一种更加常见的 NAT 变种。

当然了，NAPT 也分为许多种，我们这里就不深入探讨了，大家如果有兴趣可以查阅相关的文献。

下面就简单介绍一下 NAT 的工作原理：

![NAT结构](https://cdn.jsdelivr.net/gh/Optimus-Xs/Blog-Images/2022-03-18-udp-hole-punching-analysis/v2-62cb7ac6f3ef6272314dfe0a822b35a3-720w-jpg.png)

首先，NAT A 网下的设备 1（192.168.1.101）想与某公网 IP 通讯，设备 1 将包发给 NAT A，然后 NAT A 对源 IP 进行转换发给 NAT B（中间可能还会经过多重 NAT）。

这样做的目的是，NAT B 并不知晓 NAT A 下的各个设备，他只能与 NAT A 本身通讯，因此发送给 NAT B 的包源 IP 必须是 NAT A 的公网 IP，不然 NAT B 没有办法进行回复。

接下来 NAT B 将回复包再发回 NAT A，此时就是 NAT 发挥作用的时候了，NAT A 现在要做的就是将包再分发回之前的设备，如何确定要发给谁呢？NAT 中记录了一张表，之前 192.168.1.101 通过 2333 端口与 42.120.241.46 端口 443 通讯了，并且 NAT A 是用 60001 的端口转发出去的，那么这次接受到发往该 NAT 60001 端口的包时就应该再通过 2333 端口转发给 192.168.1.101。经过这样的过程，NAT A 下的设备都可以连接到互联网了！


# UDP 打洞原理及过程
如上图所示，由于 NAT 的存在，当 NAT A 的设备 1 想与 NAT B 下的设备通讯时，必然要将目标 IP 设置为 NAT B 的公网地址，而 NAT B 转发表中并没有记录过 NAT A 与自身网络下设备的通讯记录，因此 NAT B 会将包丢掉。

下面我们来看看 UDP 打洞是怎么解决这个问题的。

![NAT中转结构](https://cdn.jsdelivr.net/gh/Optimus-Xs/Blog-Images/2022-03-18-udp-hole-punching-analysis/v2-52767d1e9ac42d6416025fc5080016d7-720w.png)

为了能够进行 UDP 打洞，我们需要一台公网的服务器作为中转站，它是 NAT A 与 NAT B 之间的信使。

（为了方便起见，我们把地址为 192.168.1.101 的设备称为设备 1，把地址为 192.168.1.2 的设备称为设备 2，信使服务器称为 S）

首先，设备 1 和设备 2 都向 S 注册自己，S 中能记录各个设备此时使用的公网 IP 地址和端口号，例如设备 1 是 123.122.53.20:31000，设备 2 是 42.120.241.46:41000。

然后设备 1 与设备 2 都向 S 获取对方的公网 IP 与之前预留的端口号，就像这样：

![NAT打洞结构](https://cdn.jsdelivr.net/gh/Optimus-Xs/Blog-Images/2022-03-18-udp-hole-punching-analysis/v2-6e2bb16c9c7c4a7ad9e1807a8648e02f-720w.png)

然后就是最关键的一步，打洞。

设备 1 向 42.120.241.46:41000 发一个包，NAT B 自然能接收到这个包，然而它不知道来自 NAT A 的包应该发给谁，因此 NAT B 将这个包舍弃。但是由于设备 1 向 42.120.241.46:41000 发过包，NAT A 会记录：以后来自 42.120.241.46:41000 的包都发给设备1。

设备 2 也做相同的操作，让 NAT B 也知道：以后来自 123.122.53.20:31000 的包都发给设备 2。

至此，NAT A 与 NAT B 都互相为对方保留了端口，就可以愉快地通讯了。

当然了，大致原理是很简单的，实际操作起来情况可能会更复杂，会涉及到丢包、多重 NAT 等问题的处理、

# 参考
- [Peer-to-Peer Communication Across Network Address Translators](https://bford.info/pub/net/p2pnat/)


