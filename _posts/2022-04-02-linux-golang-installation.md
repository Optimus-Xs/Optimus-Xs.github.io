---
layout: post
title: Linux Golang 安装流程
date: 2022-04-02 23:32 +0800
categories: [Software Development] 
tags: [Go, 安装流程, Linux]
---
Go，通常被称为 golang，它是一门由 Google 创建的现代化的开源编程语言，它允许你构建实时并且高效的应用。

很多流行的应用程序，例如 Kubernetes，Docker，Prometheus 和 Terraform，都是使用 Go 来编写的。

这篇教程讲解如何在 Ubuntu 20.04 上下载和安装 Go。

# 下载 Go 压缩包
在写这篇文章的时候，Go 的最新版为 1.18.1。在我们下载安装包时，请浏览Go 官方下载页面,并且检查一下是否有新的版本可用。

以 root 或者其他 sudo 用户身份运行下面的命令，下载并且解压 Go 二进制文件到`/usr/local`目录：

```shell
wget -c https://dl.google.com/go/go1.18.1.linux-amd64.tar.gz -O - | sudo tar -xz -C /usr/local
```

# 调整环境变量
通过将 Go 目录添加到`$PATH`环境变量，系统将会知道在哪里可以找到 Go 可执行文件。

这个可以通过添加下面的行到`/etc/profile`文件（系统范围内安装）或者`$HOME/.profile`文件（当前用户安装）：

```shell
export PATH=$PATH:/usr/local/go/bin
```
保存文件，并且重新加载新的PATH 环境变量到当前的 shell 会话：
```shell
source ~/.profile
```

# 验证 Go 安装过
通过打印 Go 版本号，验证安装过程。
```shell
go version
```

```shell
go version go1.14.2 linux/amd64
```

# 测试
想要测试 Go 安装过程，我们将会创建一个工作区，并且构建一个简单的程序，用来打印经典的"Hello World"信息。

1. 默认情况下，`GOPATH`变量，指定为工作区的位置，设置为`  `。想要创建工作区目录，输入：
  ```shell
  mkdir ~/go
  ```
2. 在工作区内，创建一个新的目录`src/hello`：
  ```shell
  mkdir -p ~/go/src/hello
  ```
  在那个目录下，创建一个新文件，名称为hello.go
  ```go
  package main
  import "fmt"
  func main() {
      fmt.Printf("Hello, World\n")
  }
  ```
3. 浏览到`~/go/src/hello`目录，并且运行go build构建程序：
  ```shell
  cd ~/go/src/hello
  go build
  ```
  上面的这个命令将会构建一个名为hello的可执行文件。
4. 你可以通过简单执行下面的命令，运行这个可执行文件：
  ```shell
  ./hello
  ```
  输出应该像下面这样：
  ```
  Hello, World
  ```

现在你已经在你的 Ubuntu 系统上下载并安装了 Go，你可以开始开发你的 Go 项目了。