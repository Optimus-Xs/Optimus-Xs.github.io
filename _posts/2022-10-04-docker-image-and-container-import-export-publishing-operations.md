---
layout: post
title: Docker 导入/导出/发布镜像和容器操作
date: 2022-10-04 11:51 +0800
categories: [Software Development] 
tags: [Docker,容器]
---

## 下载镜像
### 直接从Docker hub下载
安装完成 Docker 后直接使用 `pull` 命令即可
```shell
docker pull mysql
```
### 使用代理下载镜像

在 Linux 命令行中，设置代理来执行网络操作（例如 wget）最常用和最灵活的是通过环境变量设置

```shell
export http_proxy="http://[username:password@]proxy_host:proxy_port"
export https_proxy="http://[username:password@]proxy_host:proxy_port"
export ftp_proxy="http://[username:password@]proxy_host:proxy_port"
```

但是对于 `docker pull` 命令来说，直接使用 `export` 配置的环境变量（如 `http_proxy`）通常是无效的

因为 `docker pull` 命令本身是由 Docker Daemon (dockerd) 守护进程执行的，而不是像 `wget` 或 `curl` 那样由你当前的 Shell 直接执行网络请求

当你执行 `export http_proxy=...` 时，你只是设置了你当前 Shell 终端的环境变量。Docker Daemon 是一个独立的系统服务（通常由 systemd 或类似的工具管理），它运行在自己的环境中，不会继承你 Shell 中的环境变量

对于 Docker 而言需要使用 `daemon.json` 配置文件来配置代理信息, 这种方法适用于所有运行 Docker Daemon 的平台，包括 Docker Desktop（Windows/Mac）和一些 Linux 发行版

1. 编辑或创建 Docker 配置文件： 配置文件通常位于 `/etc/docker/daemon.json`

    ```shell
    sudo nano /etc/docker/daemon.json
    ```

2. 添加代理配置： 添加 `proxies` 键到 JSON 文件中，如果文件已存在，请确保保持正确的 JSON 结构
    
    ```json
    {
        "proxies": {
            "default": {
            "httpProxy": "http://YOUR_PROXY_HOST:PORT",
            "httpsProxy": "http://YOUR_PROXY_HOST:PORT",
            "noProxy": "localhost,127.0.0.1"
            }
        }
    }
    ```
    {: file='daemon.json'}

3. 重启 Docker 服务： 在 Linux 上
    ```shell
    sudo systemctl daemon-reload
    sudo systemctl restart docker
    ```
    在 Docker Desktop 上，你通常可以在 **Settings/Preferences -> Resources -> Proxies** 选项卡中直接输入这些设置，然后点击 **Apply & Restart**

配置完成后，就可以像平常一样拉取镜像了

```shell
docker pull mysql
```

### 从第三方镜像服务

#### 配置默认镜像
在 Docker 中，如果你需要从 Docker Hub 的镜像代理站点（也称为 Docker Registry Mirror 或加速器）拉取镜像，你需要配置 Docker Daemon 来使用这个特定的镜像站点，而不是直接连接 Docker Hub。

这样做的好处是，这些代理通常在国内有更快的网络连接，可以显著提高拉取速度。

配置方法是修改 Docker 的配置文件 `daemon.json`

步骤1. 首先，你需要知道你想使用的 Docker 镜像代理的 URL 地址。这些地址通常由云服务提供商或私有加速服务提供。

示例 URL 格式： `https://your-mirror-site.com`

步骤2. 编辑 `daemon.json` 配置文件

Docker 守护进程的配置文件位于 `/etc/docker/daemon.json`

添加 `registry-mirrors` 配置： 在文件中添加 `registry-mirrors` 键，将你获得的代理 URL 放入列表中。如果文件已存在，请确保遵循正确的 JSON 格式

```json
{
  "registry-mirrors": [
    "https://your-mirror-site.com"
  ]
}
```
{: file='daemon.json'}

如果文件已包含其他配置（例如日志、存储驱动等）:

```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m"
  },
  "registry-mirrors": [
    "https://your-mirror-site.com" 
  ]
}
```
{: file='daemon.json'}

步骤3. 重启 Docker 服务
```shell
sudo systemctl daemon-reload
sudo systemctl restart docker
```
对于 Docker Desktop (Windows/Mac)： 通常在 **Settings/Preferences -> Docker Engine** 选项卡中编辑 JSON 配置，然后点击 **Apply & Restart**

如果配置成功，Docker Daemon 在拉取这个镜像时，会首先尝试连接你的镜像代理站点，而不是直接连接 Docker Hub

#### 单次拉取
如果你不想修改全局的 `daemon.json` 配置，而只想实现单次或临时从特定镜像站拉取 Docker Hub 的官方镜像, 可以通过完整的镜像路径拉取

这不是使用 Docker Hub 的“镜像站”功能，而是直接将镜像站作为一个独立的私有仓库来使用。许多公共镜像站（如阿里云、网易云等）都允许你通过修改镜像名称的方式来使用它们

步骤1. 确定镜像站地址和命名规则。 假设你的镜像站地址是 `registry.example.com`

步骤2. 修改镜像名称。 对于 Docker Hub 上的官方镜像（例如 `ubuntu:latest` 或 `nginx:latest`），你需要将镜像站地址作为前缀

拉取 `nginx:latest`

```shell
docker pull registry.example.com/nginx:latest
```

拉取非官方镜像（例如 `alpine/git`）

```shell
docker pull registry.example.com/alpine/git:latest
```

> 拉取完成后，镜像在本地的名称会包含前缀（例如 registry.example.com/nginx:latest）。你可能需要使用 `docker tag` 命令将其重命名回 `nginx:latest`，以便后续使用, 
> 
> 或者直接使用镜像站的完整镜像名称, 防止特定网络环境下直接从 docker hub 拉取失败导致的错误或者 CD/CI 流程中断
{: .prompt-tip }

## 重命名镜像
严格来说，`docker tag` 命令不是“重命名”镜像，而是为已存在的镜像添加一个新的标签（`tag`），这个新标签可以包含一个全新的仓库（Repository）名称。原有的镜像和标签仍然存在，直到你手动删除它们

`docker tag` 命令的基本语法如下:

```shell
docker tag SOURCE_IMAGE[:TAG] TARGET_IMAGE[:TAG]
```

步骤 1. 确定要重命名的镜像

首先，使用 `docker images` 命令查看你本地已有的镜像列表，确定要重命名的镜像的 **`Repository` (仓库名) 和 `Tag` (标签)**，或者其唯一的 **IMAGE `ID`**

```shell
docker images
docker image list #或者使用 image list 两者等效
```

示例输出如下

```text
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
my-app              latest              a1b2c3d4e5f6        3 weeks ago         150MB
ubuntu              20.04               f7a9d0e1c8b3        2 months ago        73MB
```
{: file='示例输出'}

假设你想重命名 `my-app:latest`

步骤 2. 执行 `docker tag` 命令

你希望将 `my-app:latest` 重命名为 `new-org/web-service:v1.0.0`

```shell
docker tag my-app:latest new-org/web-service:v1.0.0

docker tag a1b2c3d4e5f6 new-org/web-service:v1.0.0 # 或者使用镜像ID
```

- `my-app:latest`: 源镜像（`SOURCE_IMAGE[:TAG]`）
- `new-org/web-service:v1.0.0`: 目标镜像（`TARGET_IMAGE[:TAG]`），包含新的仓库名称和标签。
- `a1b2c3d4e5f6`: 源镜像`ID`

步骤 3. 验证重命名结果

再次运行 `docker images` 命令，你会看到一个使用新名称的新条目，但它的 IMAGE `ID` 是相同的。这证明这两个标签都指向同一个镜像层。

```text
REPOSITORY              TAG                 IMAGE ID            CREATED             SIZE
my-app                  latest              a1b2c3d4e5f6        3 weeks ago         150MB  <- 原始标签
new-org/web-service     v1.0.0              a1b2c3d4e5f6        3 weeks ago         150MB  <- 新标签
ubuntu                  20.04               f7a9d0e1c8b3        2 months ago        73MB
```
{: file='示例输出'}

步骤 4: （可选）删除旧的名称

如果你确定不再需要旧的名称 (`my-app:latest`)，可以使用 `docker rmi` 命令来删除它

```shell
docker rmi my-app:latest 
docker image rm my-app:latest # 或者使用 image rm 两者是等效的
```

执行删除后再次 `docker images` 查看

```text
REPOSITORY              TAG                 IMAGE ID            CREATED             SIZE
new-org/web-service     v1.0.0              a1b2c3d4e5f6        3 weeks ago         150MB  <- 新标签
ubuntu                  20.04               f7a9d0e1c8b3        2 months ago        73MB
```
{: file='示例输出'}

## 删除镜像

删除镜像可以按照前文所示使用:

```shell
docker rmi my-app:latest 
docker image rm my-app:latest # 或者使用 image rm 两者是等效的
```

> 由于 `docker rmi` 只是删除一个标签，只要还有其他标签（例如 `new-org/web-service:v1.0.0`）指向该镜像 ID，镜像的实际数据就不会被删除。只有当所有指向该镜像 ID 的标签都被删除后，镜像数据才会被清理。
{: .prompt-tip }

如果你想彻底删除一个镜像并释放空间，最好的方法是:

- 删除所有指向它的标签。
- 或者，直接使用 IMAGE `ID` 来执行删除操作，它会删除所有相关的标签。

```shell
docker image rm a1b2c3d4e5f6
```

这会删除这个ID关联的所有tag以及镜像本身

## 导入导出镜像和容器

### Save/Load
在 Docker 中，导入（Load）和导出（Save）是管理、迁移和备份**镜像**的常用操作

#### 导出镜像 (`docker save`)

`docker save` 命令用于将一个或多个镜像打包成一个归档文件（通常是 `.tar` 格式），包含所有层和元数据。这个文件可以轻松地在不同机器间传输

**基本语法**

```shell
docker save [OPTIONS] IMAGE [IMAGE...]
```

**导出单个镜像**

将名为 `nginx:latest` 的镜像导出到文件 `nginx_latest.tar`

```shell
docker save -o nginx_latest.tar nginx:latest
```

- `-o`: (Output) 指定输出文件的路径。

**导出多个镜像**

`save`也可以一次性将多个镜像打包到同一个 `.tar` 文件中

```shell
docker save -o all_my_images.tar myapp:v1 myapp:v2 alpine:latest
```

> 如果你使用镜像 `ID` (Image ID) 而不是完整的 `REPOSITORY:TAG` 字符串来执行 `docker save`，那么在 `docker load` 导入时，新镜像的名称和标签很可能会是 `<none>:<none>`
>
> **为什么会这样?**
> 
> - **使用 `REPOSITORY:TAG`**： 当使用完整的名称和标签（如 `redis:5.0.2`）时，Docker 明确知道想要保存哪个标签，因此它会在 `.tar` 文件中包含这个标签的元数据
> - **使用 `IMAGE ID`**： 一个 `IMAGE ID` 可以被本地的多个 `REPOSITORY:TAG` 引用。当只提供 ID 时，Docker 不会自动包含所有或任何关联的标签信息，因为它不知道你想要保留哪一个。因此，导出的 `.tar` 文件中缺少明确的标签元数据
{: .prompt-warning }

#### 导入镜像 (`docker load`)

docker load 命令用于从使用 `docker save` 创建的归档文件（`.tar` 文件）中恢复镜像。导入后，镜像将出现在本地镜像列表中，并保留其原始的标签（`tag`）。

**基本语法**

```shell
docker load [OPTIONS]
```

**从文件导入**

使用 `-i` 或通过管道（pipe）导入导出的 `.tar` 文件

```shell
docker load -i nginx_latest.tar
```

- `-i`: (Input) 指定输入文件的路径。

**通过管道和 `zcat` 导入（适用于压缩文件）**

如果你在导出时使用了 `gzip` 进行了压缩（如 `docker save | gzip > file.tar.gz`），则导入时需要解压

```shell
gzip -dc nginx_latest.tar.gz | docker load
# 或者使用 zcat
zcat nginx_latest.tar.gz | docker load
```

### Export/Import

使用 `docker export` 和 `docker import` 命令可以将一个**容器**的文件系统导出，并在另一台机器上作为一个新的镜像导入

#### 导出容器 (`docker export`)

`docker export` 命令用于导出一个运行中或已停止的容器的文件系统内容，生成一个 `.tar` 文件

首先，确保你的容器存在（运行中或已停止）

然后, 使用容器 `ID` 或名称将容器导出到文件:

```shell
docker export [容器ID或名称] > [文件名].tar
# 示例：
docker export my_web_container > web_container_fs.tar
```
生成一个 `web_container_fs.tar` 文件，其中只包含容器根目录下的所有文件和文件夹

#### 导入文件系统为新镜像 (`docker import`)

将导出的 `.tar` 文件传输到目标机器后，使用 `docker import` 命令将其作为新的镜像导入

执行导入命令： 这时候可以为新镜像指定仓库名和标签

```shell
docker import [文件名].tar [新的仓库名]:[标签]
# 示例：
docker import web_container_fs.tar imported_web_app:latest
```

验证导入结果： 检查本地镜像列表，你会看到一个由导入文件创建的新镜像

```shell
docker images
# 结果可能类似：
# REPOSITORY         TAG          IMAGE ID      CREATED         SIZE
# imported_web_app   latest       a1b2c3d4e5f6  About a minute ago 500MB
```

导入后得到一个新的镜像 (`imported_web_app:latest`)，但它是一个**不带历史、层结构、作者信息、以及最重要的 CMD/ENTRYPOINT 等元数据**的纯文件系统镜像

#### 在另一台机器上启动新镜像

由于导入的镜像是“裸”文件系统，你需要手动指定所有运行参数才能启动它。

运行新导入的镜像时，你必须指定启动容器时要执行的命令 (`CMD`)

```shell
# 示例：假设原容器运行的是 Nginx，命令是 "nginx -g 'daemon off;'"
docker run -d --name new_web_app -p 8080:80 imported_web_app:latest nginx -g 'daemon off;'
```

### Save/Load 与 Export/Import 的区别

`docker save/load` 和 `docker export/import` 最大的区别在于它们操作的对象和保存的内容。

| 特性     | docker save / docker load                                                  | docker export / docker import                  |
| :------- | :------------------------------------------------------------------------- | :--------------------------------------------- |
| 操作对象 | 镜像 (Image)                                                               | 容器 (Container)                               |
| 保存内容 | 完整的 镜像文件系统 + 所有历史层 + 元数据 (如 Tag, CMD, ENV, ENTRYPOINT)。 | 容器的 文件系统 (即运行时状态的快照)。         |
| 导入结果 | 一个完整的、可直接运行的 Image。                                           | 一个纯粹的、无历史、无配置的 Base Image。      |
| 用途     | 迁移镜像，用于在不同 Docker 主机间传输镜像，或在离线环境中使用。           | 迁移容器的文件系统，或用于创建基础镜像。       |
| 最佳实践 | 推荐用于镜像备份和迁移。                                                   | 不推荐用于迁移可运行服务，因为会丢失重要配置。 |

- 当只关心容器中文件的最终状态，并且想将其作为另一个 `Dockerfile` 的起点或创建一个没有历史记录的基础镜像时： 使用 `docker export` / `docker import`, 如果想要运行它，必须手动指定 `CMD` 或 `ENTRYPOINT` 参数
- 当需要将一个完整的、可部署的镜像从一台机器迁移到另一台机器，或者进行镜像备份时： 使用 `docker save` / `docker load`。

### 导出容器到新机器运行的最佳实践流程

如果你希望完整地保留容器示例的配置和状态并在另一台机器上运行，更推荐的方法是：

1. 将容器提交为新的镜像 (`docker commit`)： 这会创建一个包含所有更改和原始元数据的新镜像。

    ```shell
    # 从容器创建一个新的镜像
    docker commit [容器ID或名称] my_image_for_transfer:v1
    ```

2. 导出/导入新的镜像 (`docker save/load`)： 将这个完整的镜像文件传输到目标机器。

    ```shell
    # 导出完整的镜像（包含历史和配置）
    docker save -o my_image.tar my_image_for_transfer:v1
    ```

3. 在目标机器上导入并运行：

    ```shell
    # 导入完整的镜像
    docker load -i my_image.tar

    # 运行新导入的镜像（它会保留原镜像的 CMD/ENTRYPOINT 等配置）
    docker run -d --name final_web_app -p 8080:80 my_image_for_transfer:v1
    ```

> `docker commit` 命令的作用是：将一个运行中或已停止的容器的当前状态（即文件系统的更改）保存为一个新的镜像（Image）
>
> 当你在一个容器内进行了修改（例如，安装了新的软件包、修改了配置文件、创建了新的文件等），这些更改默认只存在于该容器的可写层中。
> 
> 使用 `docker commit`，你可以将这个可写层以及容器的配置（如 `ENV 变量`、`CMD` 等）打包成一个新的镜像层，从而生成一个新的、永久存储在本地的 Docker 镜像。
>
> 如果你在容器内进行了复杂的调试或配置，并且希望保留这些更改以便下次直接启动，或者将其分享给其他人，`docker commit` 是最快的保存方法
>
> 但在生产环境中，它通常被认为是**不推荐**的构建镜像方法。由于过程不透明，其他人无法知道镜像内进行了哪些更改，难以维护, 且处理过程中可能因为各种自动依赖和冗余包导致镜像体积过大
>
> 正式生产或团队协作：**始终使用 Dockerfile 来构建镜像**，以确保构建过程是清晰和可追溯的。
{: .prompt-tip }

# 参考

- [docker镜像导入导出(windows)](https://blog.csdn.net/qq_22211217/article/details/93936363)
- [Docker load 之后镜像名字为none问题解决](https://blog.csdn.net/Alavn_/article/details/103799826)