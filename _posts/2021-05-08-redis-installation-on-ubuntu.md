---
layout: post
title: Ubuntu 安装 Redis 流程
date: 2021-05-08 00:11 +0800
categories: [Software Development] 
tags: [Redis, 安装流程, Linux]
---

Redis 是一个开源的在内存存储键值对数据的存储程序。它可以被用作数据库，缓存，信息暂存，并且支持各种数据结构，例如：字符串，哈希值，列表，集合等等。 Redis 通过 Redis Sentinel 和 Redis 集群中多个 Redis 节点的自动分块处理，提供了高可用性。

这篇文章描述了如何在 Ubuntu 20.04 上安装和配置 Redis。

# 安装 Redis
在 Ubuntu 上安装 Redis 非常简单直接。

Redis 5.0 被包含在默认的 Ubuntu 20.04 软件源中。想要安装它，以 root 或者其他 sudo 身份运行下面的命令：


```shell
sudo apt update
sudo apt install redis-server
```
一旦安装完成，Redis 服务将会自动启动。想要检查服务的状态，输入下面的命令：
```shell
sudo systemctl status redis-server
```
你应该看到下面这些：
```shell
● redis-server.service - Advanced key-value store
     Loaded: loaded (/lib/systemd/system/redis-server.service; enabled; vendor preset: enabled)
     Active: active (running) since Sat 2020-06-06 20:03:08 UTC; 10s ago
...
```

>如果你的服务器上禁用 IPv6，那么 Redis 服务将会启动失败。
{: .prompt-tip }

就这些。你已经在你的 Ubuntu 20.04 上安装并运行了 Redis。


# 配置 Redis 远程访问
默认情况下，Redis 不允许远程连接。你仅仅只能从127.0.0.1（localhost）连接 Redis 服务器 - Redis 服务器正在运行的机器上。

如果你正在使用单机，数据库也同样在这台机器上，你不需要启用远程访问。

想要配置 Redis 来接受远程访问，使用你的文本编辑器打开 Redis 配置文件：

```shell
sudo nano /etc/redis.conf
```
定位到以`bind 127.0.0.1 ::1`开头的一行，并且取消它的注释：

>如果你的服务器有局域网 IP，并且你想要 Redis 从局域网可以访问 Redis，在这一行后面加上服务器局域网 IP 地址。
{: .prompt-tip }

保存这个文件，并且重启 Redis 服务，使应用生效：
```shell
sudo systemctl restart redis-server
```
使用下面的命令来验证 Redis 服务器正在监听端口6379：
```shell
ss -an | grep 6379
```
你应该能看到类似下面的信息：
```
tcp  LISTEN 0   511   0.0.0.0:6379   0.0.0.0:*
tcp  LISTEN 0   511      [::]:6379      [::]:*  
```
下一步，你将需要配置你的防火墙，允许网络流量通过 TCP 端口6379。

通常你想要允许从一个指定 IP 地址或者一个指定 IP 范围来访问 Redis 服务器。例如，想要允许从`192.168.31.10/24`的连接，运行下面的命令：
```shell
sudo ufw allow proto tcp from 192.168.121.0/24 to any port 6379
```

>确保你的防火墙被配置仅仅接受来自受信任 IP 的连接。
{: .prompt-tip }

此时，你应该可以从远程位置通过 TCP 连接到 Redis 的 6379 端口。

想要验证所有设置都设置好了，你可以尝试使用`redis-cli`从你的远程机器上 ping 一下 Redis 服务器。
```shell
redis-cli -h <REDIS_IP_ADDRESS> ping
```
这个命令将会返回一个响应：`PONG`
