---
layout: post
title: Git clone 时设置临时代理
date: 2024-12-12 13:39 +0800
categories: [Software Development]
tags: [Git, Network]
---

设置 `git clone` 的临时代理有几种常见的方法，具体取决于使用的代理类型（HTTP/HTTPS 或 SOCKS）

## 使用环境变量
这是最简单直接的方法，只需在执行 `git clone` 命令前，设置 当前终端会话 的 `http_proxy` 和 `https_proxy` 环境变量。

```shell
export http_proxy="http://用户名:密码@代理服务器地址:端口"
export https_proxy="http://用户名:密码@代理服务器地址:端口"

# 如果代理不需要用户名和密码：
# export http_proxy="http://代理服务器地址:端口"
# export https_proxy="http://代理服务器地址:端口"

# 对于 SOCKS 代理
# export ALL_PROXY="socks5://代理服务器地址:端口"

# 执行克隆
git clone [仓库地址]
```

**例如**:

```shell
# 配置http代理
export https_proxy="http://127.0.0.1:10809"

# 执行克隆
git clone https://github.com/git/git.git
```

> 环境变量只在当前终端窗口或脚本中有效，终端关闭或新开终端后即失效，实现了临时代理的效果。
{: .prompt-tip }

## 使用Git配置项
可以使用 `git config` 命令，仅对 **本次克隆操作** 或 **特定仓库地址** 临时设置代理。

### 仅对 HTTPS URL 设置代理
使用 `http.proxy` 配置，它会影响所有 HTTPS/HTTP 连接。

```shell
# 设置代理 (仅在当前仓库内有效，但如果在全局设置，则所有仓库都有效)
# 使用 --global 设置后，再用 --unset-global 取消，以确保临时性。

# 临时设置全局代理：
git config --global http.proxy "http://代理服务器地址:端口"
git config --global https.proxy "http://代理服务器地址:端口"

# 执行克隆
git clone [仓库地址]

# 克隆完成后，如果需要, 立即取消代理设置以实现临时效果, 
# git config --global --unset http.proxy
# git config --global --unset https.proxy
```
> 使用 git config 配置的代理在关闭终端会话后不会自动重置, 需要手动重置设置
{: .prompt-tip }

### 对特定主机设置代理
如果你的代理仅用于 GitHub (或其他特定平台)，可以使用 `http.<url>.*` 配置

```shell
# 例如，只对 GitHub 相关的连接走代理
git config --global http.https://github.com.proxy "http://代理服务器地址:端口"

# 执行克隆
git clone [Github仓库地址]

# 克隆完成后，如果不再使用代理, 可取消设置
# git config --global --unset http.https://github.com.proxy
```
> 使用 git config 配置的代理在关闭终端会话后不会自动重置, 需要手动重置设置
{: .prompt-tip }

### 单次请求配置

使用 `git clone -c` 选项可以在单行命令中为本次 `clone` 操作临时设置配置变量，包括代理设置。

这种方式的配置参数不会污染全局或用户级 Git 配置文件，也不会影响当前终端的环境变量。

```shell
git clone -c <配置键>="<配置值>" <仓库URL>
```

**例如**: 

```shell
git clone -c http.proxy="http://127.0.0.1:10809" https://github.com/git/git.git
```

如果代理需要用户名密码验证:

```shell
git clone -c http.proxy="http://username:password@127.0.0.1:10811" https://github.com/git/git.git
```

如果需要设置多个临时配置，可以重复使用 `-c` 选项:

```shell
git clone -c http.proxy="http://127.0.0.1:7890" -c http.sslVerify=false https://github.com/git/git.git
```

# 参考
- [git clone 设置临时代理 \| 纸帆 \| ZevenFang](about:blank)