---
layout: post
title: Portainer 在 VPS 的部署流程
date: 2022-07-23 21:07 +0800
categories: [Tech Projects] 
tags: [Docker, GeekDairy, 安装流程,Nginx]
---

# 介绍
Portainer 是一个轻量级的管理 UI ，可让你轻松管理不同的 Docker 环境（Docker 主机或 Swarm 群集）。它由可在任何 Docker 引擎上运行的单个容器组成

Portainer 由两个元素组成，Portainer Server和Portainer Agent 。这两个元素在 Docker 引擎上作为轻量级 Docker 容器运行。本文档将帮助您在 Linux 环境中安装 Portainer Server 容器。

# 部署Portainer 

## 部署前置条件
最新版本的 Docker 已安装并运行
在要安装 Portainer 的服务器实上启用 sudo 权限
默认情况下，Portainer Server 将通过 port 公开 UI，9443并通过 port 公开 TCP 隧道服务器8000。后者是可选的，仅在计划将边缘计算功能与边缘代理一起使用时才需要。

## 部署流程
首先，创建 Portainer Server 将用于存储其数据库的Docker volume ：

```shell
docker volume create portainer_data
```

然后，拉取并安装 Portainer Server 容器、

```shell
docker run -d -p 8000:8000 -p 9443:9443 --name portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:2.11.1
```

> 默认情况下，Portainer 会生成并使用自签名 SSL 证书来保护 port 9443。或者，您可以在安装期间或在安装完成后通过 Portainer UI提供您自己的 SSL 证书。
{: .prompt-tip }

> If you require HTTP port 9000 open for legacy reasons, add the following to your docker run command: -p 9000:9000
{: .prompt-tip }

Portainer 服务器现已安装完毕。可以通过运行检查 Portainer Server 容器是否已启动 docker ps：

```shell
root@server:~# docker ps
CONTAINER ID   IMAGE                          COMMAND                  CREATED       STATUS      PORTS                                                                                  NAMES             
de5b28eb2fa9   portainer/portainer-ce:2.11.1  "/portainer"             2 weeks ago   Up 9 days   0.0.0.0:8000->8000/tcp, :::8000->8000/tcp, 0.0.0.0:9443->9443/tcp, :::9443->9443/tcp   portainer
```

# 配置Nginx的反向代理

在VPS上部署为了保证服务器安全会选择开放尽可能少的端口到公网，这时通常我们会使用Nginx来做一个服务器托管服务的统一反向代理。

由于我使用了宝塔面板进行服务器管理，所以使用宝塔面板提供的UI建立一个反向代理站点来代理Portainer控制面板，步骤如下
1. 在Cloudflare或者其他DNS服务商注册一共供Portainer面板使用的域名并解析到部署服务器后
2. 在宝塔面板新建一个站点绑定刚刚解析的域名，可以直接打开查看站点是否搭建成功
3. 在宝塔面板->站点选项->反向代理选项卡中选择新建反向代理，目标URL填写 `https://127.0.0.1:9443` ，然后点击确定完成反向代理配置
4. 最后在宝塔面板->站点选项->SSL选项卡对此站点使用Let's Encrypt加密开启HTTPS

这时候就完成了部署的全过程，现在安装已完成，可以通过打开 Web 浏览器并转到解析的域名登录您的 Portainer 服务器实例。