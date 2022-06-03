---
layout: post
title: 在 Ubuntu 上安装 Dockers Engine 流程
date: 2022-03-12 23:48 +0800
categories: [Software Development] 
tags: [Docker, 安装流程, Linux]
---

# 先决条件
## 操作系统要求
要安装 Docker Engine，您需要以下 Ubuntu 版本之一的 64 位版本：

- Ubuntu Jammy 22.04 (LTS)
- Ubuntu 小鬼 21.10
- Ubuntu 焦点 20.04 (LTS)
- Ubuntu 仿生 18.04 (LTS)

`x86_64`（或`amd64`)],`armhf`,`arm64`和`s390x`架构支持 Docker 引擎。

## 卸载旧版本
旧版本的 Docker 被称为`docker`,`docker.io`或`docker-engine`. 如果安装了这些，请卸载它们：

`apt-get`如果报告没有安装这些软件包，那也没关系。

`/var/lib/docker/`目录，包括图像、容器、卷和网络，都被保留。如果您不需要保存现有数据，并且想从全新安装开始，请参阅 本页底部的卸载 Docker 引擎部分。

# 安装方法
您可以根据需要以不同的方式安装 Docker Engine：

- 大多数用户 设置 Docker 的存储库并从中安装，以便于安装和升级任务。这是推荐的方法。
- 一些用户下载 DEB 包并 手动安装，完全手动管理升级。这在诸如在无法访问 Internet 的气隙系统上安装 Docker 等情况下很有用。
- 在测试和开发环境中，一些用户选择使用自动化 便利脚本来安装 Docker。

## 使用存储库安装
在新主机上首次安装 Docker Engine 之前，您需要设置 Docker 存储库。之后，您可以从存储库安装和更新 Docker。

### 设置存储库
1. 更新apt包索引并安装包以允许apt通过 HTTPS 使用存储库：
```shell
sudo apt-get update
sudo apt-get install \
  ca-certificates \
  curl \
  gnupg \
  lsb-release
```
2. 添加 Docker 的官方 GPG 密钥：
```shell
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
```
3. 使用以下命令设置存储库：
```shell
echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
$(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

### 安装 Docker 引擎
>运行时收到 GPG 错误`apt-get update`？
>
>您的默认 umask 可能设置不正确，导致无法检测到 repo 的公钥文件。运行以下命令，然后再次尝试更新您的存储库：`sudo chmod a+r /etc/apt/keyrings/docker.gpg`
{: .prompt-tip }
1. 更新apt包索引，安装最新版本的 Docker Engine、containerd 和 Docker Compose，或者进入下一步安装特定版本：
  ```shell
  sudo apt-get update
  sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin
  ```
2. 要安装特定版本的 Docker Engine，请在 repo 中列出可用版本，然后选择并安装：<br>
  a.列出您的存储库中可用的版本：
  ```shell
  apt-cache madison docker-ce
  ```
  b.用第二列中的版本字符串安装特定版本，例如5:20.10.16~3-0~ubuntu-jammy
  ```shell
  sudo apt-get install docker-ce=<VERSION_STRING> docker-ce-cli=<VERSION_STRING> containerd.io docker-compose-plugin
  ```
3. `hello-world` 通过运行映像来验证 Docker 引擎是否已正确安装
  ```shell
  sudo docker run hello-world
  ```
  此命令下载测试映像并在容器中运行它。当容器运行时，它会打印一条消息并退出。

Docker 引擎已安装并正在运行。该`docker组`已创建，但未向其中添加任何用户。您需要使用sudo来运行 Docker 命令。继续Linux 后安装以允许非特权用户运行 Docker 命令和其他可选配置步骤。

### 升级 Docker 引擎
要升级 Docker Engine，首先运行sudo apt-get update，然后按照 [安装说明]({{post_url}}#使用存储库安装)，选择您要安装的新版本。


# 卸载 Docker 引擎
1. 卸载 Docker Engine、CLI、Containerd 和 Docker Compose 软件包：
```shell
sudo apt-get purge docker-ce docker-ce-cli containerd.io docker-compose-plugin
```

2. 主机上的映像、容器、卷或自定义配置文件不会自动删除。要删除所有映像、容器和卷：
```shell
sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd
```

# 参考
- [Install Docker Engine on Ubuntu \| Docker Documentation](https://docs.docker.com/engine/install/ubuntu/)

