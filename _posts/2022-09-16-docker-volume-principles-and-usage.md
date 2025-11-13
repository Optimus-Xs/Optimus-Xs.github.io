---
layout: post
title: Docker Volume原理及使用
date: 2022-09-16 00:00 +0800
categories: [ServerOperation] 
tags: [Docker,容器]
---
## Docker Volume是什么
想要了解`Docker Volume`，首先我们需要知道`Docker`的文件系统是如何工作的。`Docker`镜像是由多个文件系统（`只读层`）叠加而成。

当我们启动一个容器的时候，`Docker`会加载只读镜像层并在其上（镜像栈顶部）添加一个读写层。如果运行中的容器修改了现有的一个已经存在的文件，那该文件将会从读写层下面的只读层复制到读写层，该文件的只读版本仍然存在，只是已经被读写层中该文件的副本所隐藏。

当删除`Docker`容器，并通过该镜像重新启动时，之前的更改将会丢失。在`Docker`中，只读层及在顶部的读写层的组合被称为`Union File System（联合文件系统）`。

为了能够保存（持久化）数据以及共享容器间的数据，`Docker`提出了`Volume`的概念。简单来说，`Volume`就是目录或者文件，它可以`绕过`默认的联合文件系统，而以正常的文件或者目录的形式存在于宿主机上。

## Docker Volume 实现的原理

> Docker Volume实现的核心原理在于绕过了Docker默认的联合文件系统（Union File System）机制，直接利用宿主机的原生文件系统来管理数据
{: .prompt-tip }

Docker Volume 的实现原理是基于 **Linux 命名空间和文件系统挂载** 的技术，由 Docker Daemon 集中管理宿主机上的特定目录，并通过**卷驱动**将这些目录以一种**持久化、独立于容器生命周期**的方式，映射到容器内部。

### 绕过联合文件系统

**默认容器文件系统的工作方式（被绕过的机制）**

- **分层存储**： 容器镜像是只读层（Read-Only Layers）的叠加。
- **读写层**： 容器启动时，在顶部添加一个读写层（Read-Write Layer）。
- **写时复制 (Copy-on-Write, CoW)**： 任何对容器内现有文件的修改，都会将文件从只读层复制到顶部的读写层，然后在新位置进行修改。
- **缺点**： 容器删除时，顶部的读写层也随之删除，所有修改都会丢失（非持久化）。

**Volume 的如何绕过联合文件系统**

- **特殊挂载点**： 当使用 -v 或 --mount 命令创建一个数据卷时，Docker daemon（守护进程）会在宿主机的特定位置（通常是 /var/lib/docker/volumes/ 下，或者用户指定的目录）创建一个目录或文件。
- **直接映射**： Docker不是让容器将数据写入到联合文件系统的读写层中，而是通过内核的挂载机制（如Linux的 mount 命令）将宿主机上的一个真实目录直接映射（绑定挂载，Bind Mount）到容器内的指定路径。
- **完全独立**： 这种挂载是独立的，它直接在宿主机的文件系统上进行读写操作，不经过联合文件系统和写时复制的开销。

### 挂载宿主机原生文件系统

**持久化 (Persistence)**

- 由于数据卷直接位于宿主机的文件系统上，它的生命周期与宿主机相同，独立于容器的生命周期。
- 即使容器被删除，宿主机上的目录和数据仍然保留，从而实现了数据的持久化。

**高性能 (High Performance)**

- 数据卷直接使用宿主机的文件系统（例如 ext4, xfs, etc.），避免了联合文件系统引入的**写时复制（CoW）**操作开销。
- 数据的读写效率更高，因为它就是宿主机上的本地文件I/O。

**共享 (Sharing)**

- Docker利用宿主机的挂载能力，可以把同一个宿主机目录同时挂载到多个运行中的容器的指定路径下。
- 因为所有容器都在操作宿主机上的同一个物理位置，所以实现了容器之间高效、实时的数据共享。

### Docker Volume的两种实现形式

| Volume 类型                   | 实现机制                                                                                                                                                                 | 挂载命令示例                                   |
| :---------------------------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :--------------------------------------------- |
| 具名数据卷<br/>(Named Volume) | Docker daemon在宿主机特定目录（如 `/var/lib/docker/volumes/`）<br/>创建并管理目录，然后将此目录挂载到容器。<br/>由 Docker 守护进程（Daemon）创建、管理和跟踪。           | `docker run -v my_volume:/app/data ...`        |
| 绑定挂载<br/>(Bind Mount)     | Docker daemon直接将宿主机上用户指定的任意目录挂载到容器。<br/>这种方式用户对数据位置有完全控制权。<br/>Docker 只是简单地将宿主机路径挂载进去，不负责创建或生命周期管理。 | `docker run -v /host/path:/container/path ...` |


## Docker Volume解决的需求

1. 数据的持久化（Persistence）

    这是 Volume 解决的首要和最核心的需求。

    - **需求痛点**： 容器是短暂（Ephemeral）的。默认情况下，写入容器可写层（Writable Layer）的数据会随着容器被删除而丢失。对于数据库、日志或用户上传的文件等重要数据，这是不可接受的。
    - **Volume 解决方案**： Volume 将数据存储在宿主机（Host）的文件系统上，并且其生命周期独立于容器。即使容器被停止、删除或替换，数据也会安全地保留，等待新的容器重新挂载。

2. 数据共享与跨容器通信

    - **需求痛点**： 多个容器可能需要访问同一份数据，例如，一个容器运行 Web 服务器，另一个容器运行 PHP-FPM 进程，它们都需要访问同一个应用代码库。
    - **Volume 解决方案**： 多个运行中的容器可以同时挂载同一个 Volume。这使得它们可以高效、实时地共享数据，而无需通过网络或复杂的拷贝机制。

3. I/O 性能的提升

    - **需求痛点**： 容器默认使用的 Union File System（如 OverlayFS 或 AUFS）在 I/O 密集型操作中，由于其多层结构，性能通常不如直接在宿主机文件系统上读写。
    - **Volume 解决方案**： Volume 直接将宿主机的文件系统目录挂载到容器中。这意味着所有的数据读写操作都绕过了 Union FS 的开销，**直接作用于宿主机的文件系统**，从而大大提高了数据库等应用的 I/O 性能。

4. 宿主机与容器的解耦（De-coupling）

    - **需求痛点**： 如果数据和容器紧密耦合，应用程序的备份、迁移和升级将非常困难。
    - **Volume 解决方案**： Volume 将“数据”和“容器/应用逻辑”分离开来。可以独立地管理、备份和迁移 Volume 数据，同时独立地升级或更换应用容器，而互不影响。

5. 远程/云存储的集成

    - **需求痛点**： 在分布式、集群或云环境中，容器可能在不同的宿主机上运行，需要访问统一的、高可用的存储。
    - **Volume 解决方案**： 通过使用第三方 Volume 驱动（例如针对 AWS EBS、Google Cloud Persistent Disk、NFS、Ceph 等），Volume 机制允许容器访问和使用网络连接的存储资源，从而实现数据的**跨主机共享和高可用**。

Docker Volume 使容器化应用从“**一次性且无状态**”变为“**持久、高性能且可管理**”，是运行任何需要存储状态信息的应用（如数据库、缓存、日志系统等）不可或缺的基础功能

## Docker Volume 的使用方式
### Docker 数据卷
#### Docker run 语法
在 `docker run` 中，我们主要使用 `-v` 或 `--mount` 标志来挂载 Volume。推荐使用更清晰的 `--mount` 语法。

```bash
# -v 语法
-v <volume_name>:<container_path>

# --mount 语法
--mount source=<volume_name>,target=<container_path>
```

步骤 1: 创建 Volume (可选) 可以提前创建 Volume，也可以让 Docker 在第一次使用时自动创建。

```bash
# 提前创建名为 my_app_data 的 Volume
docker volume create my_app_data
```
步骤 2: 运行容器并挂载 使用 -v 或 --mount 将 Volume 挂载到容器内的指定路径。

```bash
docker run -d -v my_app_data:/var/lib/mysql mysql:latest
# 或者
docker run -d --mount source=my_app_data,target=/var/lib/mysql mysql:latest
```

如果不指定 Volume 名称，Docker 会自动创建一个随机名称的 Volume。

```bash
# Docker 会自动生成一个 UUID 作为 Volume 名称
docker run -d -v /app/logs nginx:latest
```

> 注意： 匿名卷难以管理和查找，不推荐用于重要的持久化数据。
{: .prompt-warning }

#### Docker compose 语法
在 Compose 文件中，需要在两个地方定义 Volume

```yml
version: '3.8'

services:
  db:
    image: postgres:latest
    # 2. 在 service 中使用它
    volumes:
      - db_data:/var/lib/postgresql/data
    environment:
      POSTGRES_PASSWORD: mysecretpassword

# 1. 在顶层定义 Volumes
volumes:
  db_data:
    # 推荐使用 external: true 如果想手动创建 Volume
    # 或者留空让 Compose 自动创建
    driver: local
```
{: file="docker-compose.yml" }

- 在顶层的 `volumes`: 下定义了名为 `db_data` 的 Volume。
- 在 `db service` 下，使用 `db_data:/var/lib/postgresql/data` 将其挂载到数据库容器内的数据路径。

### 宿主机目录挂载

虽然不是严格意义上的 Docker Volume，但它是另一种常用的挂载方式

#### Docker run 语法
```bash
# 语法：-v <host_path>:<container_path>
docker run -d -p 8080:80 -v /home/user/my_html:/usr/share/nginx/html nginx:latest
```

这个案例中： 将宿主机上的 `/home/user/my_html` 目录直接挂载到容器内的 `/usr/share/nginx/html` 目录。

#### Docker compose 语法

在 Compose 中使用绑定挂载非常简单，无需在顶层定义。

```yml
version: '3.8'

services:
  web:
    image: nginx:latest
    ports:
      - "80:80"
    volumes:
      # 语法: <host_path>:<container_path>
      - ./app_code:/usr/share/nginx/html
```
{: file="docker-compose.yml" }

将 Compose 文件所在目录下的 `./app_code` 文件夹（宿主机路径）挂载到 `web` 容器内的 `/usr/share/nginx/html` 路径

### Build 阶段声明 Volume

在构建 Docker 镜像时，可以使用 `VOLUME` 指令在 Dockerfile 中声明 Volume。

`VOLUME` 指令用于在镜像中创建一个或多个指定名称的挂载点，并标记这些挂载点应该从外部 Volume 或 Bind Mount 中获取数据

#### Volume 语法

```dockerfile
# 形式一：JSON 数组，推荐使用
VOLUME ["/data", "/logs"]

# 形式二：纯字符串
VOLUME /data /logs
```
{: file="DockerFile" }


#### DockerFile案例

假设应用会将上传文件存储在 `/usr/src/app/uploads` 目录，可以这样声明：


```dockerfile
# Dockerfile 示例

FROM node:20-slim
WORKDIR /usr/src/app

# 声明一个 Volume 挂载点
# 建议将 uploads 目录标记为 Volume，确保数据不会随容器删除而丢失
VOLUME /usr/src/app/uploads

COPY package*.json ./
RUN npm install
COPY . .

CMD ["npm", "start"]
```
{: file="DockerFile" }


#### VOLUME 指令的真正含义和限制

1. 声明 Volume 的意图（Intention）
    
    `VOLUME` 指令不会在构建镜像时创建任何实际的 Volume，也不会将数据复制到 Volume 中。它的核心作用是：

    - **标记挂载点**： 告诉 Docker，容器运行时，对于镜像中指定的路径（如 `/usr/src/app/uploads`），应该使用外部 Volume 来持久化数据，而不是使用容器的联合文件系统（Union FS）的可写层。
    - **创建匿名卷**： 如果用户在运行容器时没有通过 `-v` 或 `--mount` 明确指定 Volume 或 Bind Mount，Docker 会自动为这个路径创建一个匿名卷 (Anonymous Volume)。

2. 数据复制的限制（关键点）
    
    不能在 `Dockerfile` 中将构建时的数据复制到 `VOLUME` 声明的路径中。

    如果 `Dockerfile` 中包含以下步骤：

    ```dockerfile
    # 步骤 1: 声明一个 Volume
    VOLUME /mydata

    # 步骤 2: 尝试将文件复制到该路径
    COPY initial_data.txt /mydata/
    ```
    {: file="DockerFile" }

    在旧版本的 Docker 中，`COPY` 的数据会丢失或行为不可预测。在现代 Docker 版本中，当容器第一次运行时，如果 Volume 是空的，Docker 会将镜像中 `/mydata` 路径下已存在的内容（如果有）复制到新的 Volume 中。

> 最佳实践： 尽量只用 VOLUME 标记应用运行时需要写入数据的空目录，而不是包含初始数据的目录。如果需要初始数据，应该在应用启动脚本中检查 Volume 是否为空，并手动复制初始文件。
{: .prompt-tip }

> VOLUME 是一个元数据标记，用于告诉 Docker 运行时环境：
> 
> “**这个目录包含重要或易变的数据，请务必将其持久化到容器外部的 Volume 中**。”
> 
> 它并不能像 RUN 或 COPY 那样执行构建时的文件操作。
{: .prompt-warning }


### 多容器共享

多容器共享 Volume 是 Docker 容器化应用中的常见需求，特别是在微服务架构中，例如 Web 服务器和应用服务器需要共享同一套静态文件或代码库。

Volume 共享配置非常简单，核心操作是让多个容器都挂载同一个**命名卷（Named Volume）**

下面分别介绍使用 `docker run` 和 `Docker Compose` 配置多容器共享 Volume 的方法，并以一个 Web 服务和日志分析服务共享日志文件的案例进行解释

**案例：Web 服务与日志分析服务**

假设我们有两个服务：

- **web-app 容器**： 运行 Nginx，负责生成访问日志到 /var/log/nginx/ 路径。
- **log-analyzer 容器**： 运行一个日志处理工具，需要实时读取 /var/log/nginx/ 中的日志文件。

它们需要共享一个名为 `log_data` 的 Volume

#### Docker run 语法

在使用 `docker run` 时，只需要确保两个容器都在 `-v` 或 `--mount` 标志中指定同一个 Volume 名称即可

**步骤 1**: 创建命名卷

首先，创建用于共享的命名卷：
```bash
docker volume create log_data
```

**步骤 2**: 运行第一个容器（Web App）
让 Web App 容器将日志写入共享 Volume:
```bash
# 运行 Nginx 容器，并将内部的日志目录挂载到 log_data Volume
docker run -d \
    --name web-app \
    --mount source=log_data,target=/var/log/nginx \
    nginx:latest
```

**步骤 3**: 运行第二个容器（Log Analyzer）
让 Log Analyzer 容器挂载同一个 Volume 来读取日志：
```bash
# 运行一个临时的容器（例如 Alpine），挂载 log_data Volume，并读取其中的 access.log 文件
docker run --rm \
    --name log-analyzer \
    --mount source=log_data,target=/logs \
    alpine:latest \
    tail -f /logs/access.log
```

两个容器都使用了 `log_data` 这个 Volume。`web-app` 写入 `/var/log/nginx`，`log-analyzer` 从 `/logs` 读取，由于两者都指向宿主机上的同一块存储，因此实现了数据共享

#### Docker compose 语法

在多容器场景下，Docker Compose 是更清晰、更推荐的方法。只需在顶层定义一次 Volume，然后在需要共享的 Service 中引用即可

```yml
version: '3.8'

services:
  # 1. Web 应用服务
  web-app:
    image: nginx:latest
    ports:
      - "8080:80"
    volumes:
      # 挂载共享 Volume。Nginx 将日志写入到容器内的 /var/log/nginx
      - log_data:/var/log/nginx

  # 2. 日志分析服务
  log-analyzer:
    image: alpine/git:latest # 假设这是一个基于 Alpine 的日志处理镜像
    command: sh -c "echo 'Starting log analyzer...' && tail -f /shared_logs/access.log"
    volumes:
      # 挂载同一个共享 Volume。分析器从容器内的 /shared_logs 读取
      - log_data:/shared_logs
    # 确保 log-analyzer 在 web-app 启动后运行
    depends_on:
      - web-app

# 顶层 Volume 定义：声明一个命名卷
volumes:
  log_data:
    # 默认使用 local driver，实现宿主机本地共享存储
    driver: local
```
{: file="docker-compose.yml" }

使用 Compose 启动服务：

```bash
docker-compose up -d
```

**执行流程：**

- Docker Compose 首先创建了名为 `log_data `的命名卷。
- `web-app` 容器启动，将其内部的 `/var/log/nginx` 挂载到 `log_data`。
- `log-analyzer` 容器启动，将其内部的 `/shared_logs` 挂载到同一个 `log_data`。
- 当用户访问 `web-app` (通过 8080 端口) 时，Nginx 将访问日志写入 `/var/log/nginx`，这些数据会立即同步到 `log_data` Volume 中。
- `log-analyzer` 容器可以立即从其挂载点 `/shared_logs` 下的 `access.log` 文件中读取到这些新的日志条目，实现了实时共享。

# 参考

- [Docker最全教程——数据库容器化之持久保存数据（十一）](https://www.cnblogs.com/codelove/p/10270233.html)
- [Docker Volume原理](https://blog.csdn.net/lijingjingchn/article/details/118154601)