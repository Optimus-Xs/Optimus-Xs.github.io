---
layout: post
title: Ubuntu 的 ufw 防火墙使用指南
date: 2023-05-07 00:00 +0800
categories: [ServerOperation]
tags: [Internet Security, Linux, Network]
---

## UFW 简介

UFW 是 Uncomplicated Firewall（不复杂的防火墙） 的简称，是一个用于在 Linux 系统中管理防火墙规则的命令行工具。它是一种用户友好的前端工具，用于简化底层的 iptables 配置，让用户可以更轻松地创建和管理防火墙规则，以限制网络流量并保护服务器。 

主要特点和作用

- **简化 iptables 配置**： UFW 实际上是 Linux 内核内置的 `netfilter` 数据包过滤系统（传统上通过复杂的 `iptables` 命令进行管理）的一个前端。它将复杂的 `iptables` 语法抽象成更简单、更易懂的命令。
- **基于主机的防火墙**： 它主要用于配置基于主机的防火墙（Host-based Firewall），即保护运行 Ubuntu 系统的这台机器本身。
- **默认状态**： 在 Ubuntu 安装后，UFW 默认是安装但**未启用**的。
- **默认策略（启用后）**：
  - 拒绝所有传入（incoming）连接（默认更安全）。
  - 允许所有传出（outgoing）连接。
- **主要功能**：
  - 启用或禁用防火墙。
  - 允许或拒绝特定端口（例如 `22/tcp` 用于 SSH，`80/tcp` 用于 HTTP）的连接。
  - 允许或拒绝特定 IP 地址或子网的连接。
  - 管理应用程序配置文件（可以直接允许或拒绝像 `SSH`、`HTTP` 这样的服务名称）。

工作原理：

- UFW 在底层仍然使用 `iptables` 来实际修改和管理防火墙规则，但它通过提供一个更易于使用的界面来包装 `iptables`。 

## 安装和基础操作
### 安装和启用

安装 UFW, 如果默认没有安装可以手动安装

```shell
sudo apt-get install ufw
```

启用和禁用UFW

```shell
sudo ufw enable  # 启用防火墙规则
sudo ufw disable # 禁用防火墙
```

### 查询运行状态

查看状态

```shell
sudo ufw status # 查看 UFW 的活动状态和已定义的规则
```

## 配置语法

### 语法规则
UFW (Uncomplicated Firewall) 的配置命令语法非常直观且一致。它通常遵循以下基本结构：

```shell
sudo ufw [动作] [规则] [方向/接口] [日志选项]
```

#### 核心动作
这是你告诉 UFW 要执行什么操作的部分。

| 动作    | 描述                                                       |
| :------ | :--------------------------------------------------------- |
| enable  | 启用防火墙。启用前请务必确认 SSH 端口已允许！              |
| disable | 禁用防火墙。                                               |
| status  | 查看当前规则列表和状态。使用 status verbose 查看详细信息。 |
| default | 设置默认策略（例如，`sudo ufw default deny incoming`）。   |
| reset   | 警告： 将 UFW 重置为安装时的状态（删除所有规则）。         |
| show    | 显示配置信息（例如 `sudo ufw show added`）。               |

#### 端口/服务规则
这是最常用的语法，用于允许或拒绝特定端口的连接。

1. 基本允许/拒绝

    | 动作 | 语法示例           | 解释                                                      |
    | :--- | :----------------- |
    | 允许 | sudo ufw allow 22  | 允许所有协议（TCP/UDP）传入端口 22 的连接。               |
    | 拒绝 | sudo ufw deny 80   | 拒绝所有协议传入端口 80 的连接。                          |
    | 限制 | sudo ufw limit ssh | 限制对 SSH 端口（`22/tcp`）的连接尝试，常用于防御暴力破解。 |

2. 指定协议和端口

    你可以通过添加 `/tcp` 或 `/udp` 来指定协议。

    | 语法示例                     | 解释                                     |
    | :--------------------------- | :--------------------------------------- |
    | sudo ufw allow 80/tcp        | 仅允许 TCP 协议传入端口 80（HTTP）。     |
    | sudo ufw allow 53/udp        | 仅允许 UDP 协议传入端口 53（DNS 查询）。 |
    | sudo ufw allow 3000:3010/tcp | 允许 TCP 协议传入端口范围 3000 到 3010。 |

3. 使用服务名称

    如果端口有注册的服务名称，你可以直接使用名称，UFW 会自动解析端口。

    | 语法示例             | 解释                            |
    | :------------------- | :------------------------------ |
    | sudo ufw allow ssh   | 等同于 sudo ufw allow 22/tcp。  |
    | sudo ufw allow http  | 等同于 sudo ufw allow 80/tcp。  |
    | sudo ufw allow https | 等同于 sudo ufw allow 443/tcp。 |

#### IP 地址/子网规则

用于根据连接的来源或目的地 IP 地址进行过滤。

| 语法示例                                      | 解释                                              |
| :-------------------------------------------- | :------------------------------------------------ |
| sudo ufw allow from 192.168.1.100             | 允许 IP 地址 192.168.1.100 的所有连接。           |
| sudo ufw deny from 172.16.0.0/12              | 拒绝来自该子网（CIDR 表示法）的所有连接。         |
| sudo ufw allow from 10.0.0.0/8 to any port 22 | 允许来自 10.0.0.0/8 子网的连接访问本机的端口 22。 |

#### 接口规则

用于指定规则应该应用于哪个网络接口（例如 eth0、wlan0）

| 语法示例                                       | 解释                                                |
| :--------------------------------------------- | :-------------------------------------------------- |
| sudo ufw allow in on eth0 to any port 80       | 仅允许通过 eth0 接口传入的 HTTP (`80/tcp`) 连接。     |
| sudo ufw allow out on eth1 to 10.0.0.1 port 53 | 允许从 eth1 接口发出连接到 10.0.0.1 端口 53 (DNS)。 |

#### 删除规则

1. 方法一：按规则内容删除 (推荐)

    直接在原始规则前添加 `delete`

    示例:

    ```shell
    sudo ufw delete allow 80/tcp # 删除允许 80/tcp 的规则
    ```

2. 方法二：按编号删除

    ```shell
    sudo ufw status numbered # 查看带编号的规则列表。
    sudo ufw delete [编号] # 删除列表中的指定编号规则
    ```

### 规则案例

#### 配置默认策略

UFW 的默认配置（Default Policy）案例主要用于定义当没有特定规则匹配时，UFW 如何处理传入和传出连接。

例如下面的配置: 保护本机不受外界网络攻击或未授权连接，同时允许本机自由访问外部网络。

```shell
sudo ufw default deny incoming  # 拒绝所有未被特定规则（如 allow ssh）明确允许的传入连接。
sudo ufw default allow outgoing # 允许本机发起的所有传出连接。这意味着你可以自由浏览网页、更新系统、发送邮件等。
sudo ufw default deny forwarded # 拒绝所有转发的连接。这适用于本机不作为路由器/网关的情况
```

#### 新增规则配置

新增协议配置:

```shell
# 允许所有传入的 SSH 连接:
sudo ufw allow ssh
# 或者
sudo ufw allow 22/tcp # 直接配置端口

# 允许所有传入的 HTTP 连接:
sudo ufw allow http 
#或者
sudo ufw allow 80/tcp # 直接配置端口
```

新增端口规则:

```shell
sudo ufw allow 8080 # 允许8080端口接入
sudo ufw deny 21/tcp # 拒绝传入的 FTP 连接。
```

允许特定来源的ip地址访问:

```shell
sudo ufw allow from 192.168.1.1
```

#### 删除规则

```shell
sudo ufw delete allow 8080 # 删除允许8080端口接入的规则
sudo ufw delete deny 21/tcp # 删除拒绝传入的 FTP 连接的规则
```

# 参考
- [ubuntu的ufw防火墙开放特定端口,查看允许通过防火墙的应用](https://blog.csdn.net/weixin_43944305/article/details/107018131)