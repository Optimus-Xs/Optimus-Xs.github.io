---
layout: post
title: Docker Compose 的网络使用
date: 2022-10-04 00:00 +0800
categories: [Software Development] 
tags: [Docker,容器]
---
## Docker 网络机制简介

Docker 网络机制使用 Linux 的**网络命名空间（network namespace）**和**虚拟网络设备（veth pair）**来实现容器的网络隔离和通信。它支持多种网络模式，如默认的 bridge 模式（为每个容器创建虚拟网桥）；host 模式（容器共享宿主机网络栈）；以及其他模式如 overlay、macvlan、none 等。通过这些机制，Docker 实现了容器之间以及容器与外部网络的灵活通信。 

### 核心原理

网络命名空间（Network Namespace）：为每个容器创建一个独立的网络栈，包括网络接口、IP 地址和路由表，实现了网络隔离。

虚拟网络设备（veth pair）：当一个容器创建时，Docker 会在宿主机上创建一个虚拟网卡对（veth pair）。

  - 一端连接到容器内部（通常是 `eth0`）。
  - 另一端连接到宿主机上的一个虚拟网桥（如 `docker0`）。

虚拟网桥（Virtual Bridge）：

  - `docker0` 是 Docker 默认创建的虚拟网桥，它在宿主机上充当一个虚拟交换机，将所有容器连接到同一个二层网络中。
  - 它提供了一个默认的网关地址给容器，容器间的通信通过这个网桥进行路由转发。
  - Docker 使用 `iptables` 规则来处理容器与宿主机之间的端口映射和网络流量转发。 

### 配置案例分析

默认情况下，Compose会为我们的应用创建一个网络，服务的每个容器都会加入该网络中。这样，容器就可被该网络中的其他容器访问，不仅如此，该容器还能以服务名称作为hostname被其他容器访问。默认情况下，应用程序的网络名称基于Compose的工程名称，而项目名称基于docker-compose.yml所在目录的名称。如需修改工程名称，可使用`--project-name`标识或`COMPOSE_PORJECT_NAME`环境变量。举个例子，假如一个应用程序在名为`myapp`的目录中，并且docker-compose.yml如下所示:


```yml
version: "3"
services:
  web:
    build: .
    ports:
      - "8000:8000"
  db:
    image: postgres
    ports:
      - "8001:5432"
```
{: file='docker-compose.yml'}

当我们运行docker-compose up时，将会执行以下几步：

- 创建一个名为`myapp_default`的网络；
- 使用web服务的配置创建容器，它以“web”这个名称加入网络`myapp_defaul`t；
- 使用db服务的配置创建容器，它以“db”这个名称加入网络`myapp_default`。

容器间可使用Docker DNS机制实现服务名称（`web`或`db`）作为hostname相互访问。例如，`web`这个服务可使用`postgres://db:5432` 访问db容器。

> 使用 docker DNS 有个限制：只能在 user-defined 网络中使用。也就是说，默认的 bridge 网络(启动容器不指定网络的情况下)是无法使用 DNS 的
>
> 但是当使用 `docker-compose up` 运行这个配置时，即使没有明确定义 `networks` 部分，Docker Compose 也会自动为创建一个用户定义的 Bridge 网络。这个网络的名称通常是项目目录名加上 `_default`
>
> 如果是使用 `docker run` 直接启动两个容器则不会自动生成 user-defined 网络, 例如下面的命令
>
> - `docker run -it --name=db postgres`
> - `docker run -it --name=web web`
{: .prompt-warning }

> 上面例子还有一个注意点就是端口号，注意区分`HOST_PORT`和`CONTAINER_PORT`，以上面的db为例：
> 
> - `8001` 是宿主机的端口
> - `5432`（postgres的默认端口） 是容器的端口
> - 当容器之间通讯时 ， 是通过 `CONTAINER_PORT` 来连接的。
> 
> 这里有宿主机端口，那么容器就可以通过宿主机端口和外部应用连接。
{: .prompt-warning }

> `links` 关键字（主要存在于 Docker Compose version 1 和 version 2）的设计目的是解决容器间的服务发现问题。它的原理是基于对容器内文件的直接修改。
>
> 当使用 `links: - "db:database"` 时，Docker Compose 会执行两个主要动作：
> 
> - 获取 IP 地址： 查找目标容器 (`db`) 当前在网络上的 IP 地址。
> - 修改 Hosts 文件： 将一个主机名条目写入源容器 (`web`) 的 `/etc/hosts` 文件中
>
> links 机制虽然解决了早期容器间的通信问题，但它存在严重的缺陷和局限性
> 1. 单向通信和复杂性: links 建立的连接是单向的。如果需要双向访问，则需要额外的 links 配置
> 2. 依赖易变的 IP 地址: links 直接在 hosts 文件中硬编码了目标容器的 IP 地址, 如果目标容器 (`db`) 重启或停止导致IP更新, 源容器 (`web`) 的 `/etc/hosts` 文件中的旧 IP 地址就会失效, 除非重新启动源容器
> 3. 现代内置 DNS 服务的出现: 现代 Docker Compose 在创建用户定义的 Bridge 网络时，会内置一个 DNS 服务器, 应用程序直接通过服务名（例如 `db`）解析。即使 `db` 容器重启并获取了新的 IP，DNS 服务器也会实时更新记录
>
> links 是一个**手动、静态、不健**壮的解决方案，已被 Docker 自动服务发现 (内置 DNS) 机制彻底取代
{: .prompt-danger }

## Docker 网络工作模式
### Bridge
这是 Docker 的默认网络模式。它在宿主机上创建一个虚拟交换机 (Linux Bridge)，通常命名为 `docker0`（对于默认 Bridge），或是一个自定义的 Bridge（对于用户定义的网络）。Docker 为每个容器创建一对虚拟网卡 (`veth pair`)，一端在容器内，另一端连接到这个 Bridge。

- 容器间： 同一 Bridge 上的容器可以互相通信。
- 外部访问： 通过宿主机的 NAT (网络地址转换) 和 `iptables` 规则，容器可以访问外部网络，外部世界也可以通过端口映射 (-p 标志) 访问容器。

适用单个宿主机上的多容器应用，以及 Docker Compose 部署。

**配置案例**

```yml
version: "3.8"
services:
  app:
    image: nginx:alpine
    # 容器会被自动连接到默认的用户定义 Bridge 网络
    ports:
      - "8080:80"
  db:
    image: postgres:latest
    environment:
      POSTGRES_PASSWORD: password
    # app 容器可以通过 'db' 名称访问此服务
```
{: file='docker-compose.yml'}

这是默认配置，无需额外的网络定义。Docker Compose 会自动创建一个用户定义的 Bridge 网络

### Host
容器不拥有自己的网络命名空间。它直接共享并使用宿主机的网络堆栈，包括 IP 地址、端口、路由表等

- 性能： 性能最高，因为绕过了 NAT 和 Bridge 转发。
- 端口： 容器内部的进程直接监听宿主机的端口。如果容器内部应用监听 80 端口，那么宿主机上的 80 端口就被占用了，无需端口映射。

适用对网络性能要求极高、或需要访问宿主机网络接口的监控类应用

**配置案例**

```yml
version: "3.8"
services:
  host_app:
    image: nginx:alpine
    # 使用 Host 模式，容器直接占用宿主机端口
    network_mode: host
    # 注意：使用 Host 模式时，ports 映射是无效的！
    # 如果 nginx 监听 80 端口，宿主机 80 端口将被占用。
```
{: file='docker-compose.yml'}

使用 `network_mode: host`，容器直接使用宿主机的网络堆栈

### None
容器拥有自己的网络命名空间，但该命名空间中没有**网络接口**（除了 lo 回环接口）。Docker 不会为其配置 IP 地址、路由和 DNS

- 通信特点： 容器是网络隔离的，无法访问外部或内部网络

适用只需要进行文件处理或计算任务，且需要高度安全隔离的应用，或者网络配置完全由第三方工具接管的情况

**配置案例**

```yml
version: "3.8"
services:
  no_network_worker:
    image: busybox
    # 容器仅有一个 loopback 接口
    network_mode: none
    # 示例命令：休眠 100 秒
    command: sleep 100
```
{: file='docker-compose.yml'}

使用 network_mode: none，容器将没有网络接口

### Joined Container
这不是一个独立的网络驱动，而是一种特殊的容器启动方式。它通过使用 `--network container:<container_name_or_id>` 标志，让新启动的容器共享另一个已存在容器的网络命名空间。

- 共享： 两个容器拥有相同的 IP 地址、相同的 MAC 地址、相同的端口空间。
- 隔离： 它们的文件系统和进程空间仍然是隔离的。

典型的应用是 **Sidecar 模式**，例如，一个容器运行主应用，另一个容器运行一个代理或日志收集器，它们需要使用相同的 IP 地址和网络配置

> Joined Container 这个模式下容器内的进程对应另一个容器内的进程, 在“网络通信”的维度上，它们几乎等效于在同一个未容器化的物理机上运行的两个进程。但在其他方面（如进程可见性和文件系统），它们仍然是隔离的
{: .prompt-tip }

**配置案例**

```yml
version: "3.8"
services:
  # 1. 网络提供者 (例如主应用)
  main_app:
    image: busybox
    command: sleep 3600

  # 2. 共享网络栈的服务 (例如 Sidecar 代理或日志收集器)
  sidecar_proxy:
    image: alpine/git
    # 指定它使用 main_app 服务的网络栈
    network_mode: service:main_app
    # main_app 和 sidecar_proxy 拥有相同的 IP 和端口空间
```
{: file='docker-compose.yml'}

这需要两个服务，一个作为网络提供者，另一个使用 `network_mode: service:provider_service` 共享网络

### Overlay
Overlay 网络用于连接**多个 Docker 宿主机**上的容器。它利用 VXLAN 等隧道技术，在底层物理网络之上创建了一个逻辑、分布式的 L2 网络

- 跨主机通信： 连接到同一 Overlay 网络的容器，无论位于哪个物理宿主机上，都可以直接通过容器名称/IP 地址通信。
- 服务发现： 内置支持跨主机服务发现和负载均衡。

适用 Docker Swarm 或其他集群环境中，实现跨机器的容器通信

**配置案例**

```yml
version: "3.8"
services:
  web_service:
    image: nginx:alpine
    ports:
      - "8081:80"
    networks:
      - global_overlay

networks:
  # 顶级网络定义
  global_overlay:
    driver: overlay
    # 必须指定 attachable: true 才能通过 docker run 手动连接
    attachable: true
```
{: file='docker-compose.yml'}

需要 Docker Swarm 模式启用，并且在 `networks` 块中显式指定 `driver: overlay`。

前提条件： 运行 `docker swarm init` 或 `docker swarm join` 启用 Swarm 模式。

> Docker 原生 Overlay： Docker 原生提供的 `overlay` 网络驱动是专为 Docker Swarm 模式设计的。它依赖 Swarm 模式的 控制平面 (Control Plane) 和 键值存储 (Key-Value Store, 早期是 Swarm 内置的 Raft) 来管理跨主机的网络状态、IP 分配和安全密钥
>
> Docker Engine 内置的 `docker network create --driver overlay` 必须在启用了 Docker Swarm 模式的节点上才能创建和运行
>
> Kubernetes (K8s) 广泛使用 Overlay 网络的概念和技术，但它不使用 Docker 内置的 overlay 驱动。
>
> Kubernetes 将网络功能抽象出来，通过 CNI (Container Network Interface) 规范 交给第三方插件实现。这些 CNI 插件大多使用 Overlay 网络技术来实现跨节点通信（例如 Flannel 或 Calico）
>
> Docker Swarm 使用内置的 Overlay 驱动，而 Kubernetes 使用第三方 CNI 插件来实现相同的 Overlay 网络功能（即跨主机的虚拟 L2/L3 网络）
{: .prompt-tip }

### MacVlan
允许为每个容器分配一个独立的 MAC 地址，并将容器的虚拟网卡直接连接到宿主机的物理网络接口上。在外部网络看来，每个容器就像是一个独立的物理设备

- 直接： 容器可以直接从物理网络获取 IP 地址，避免了 Bridge 带来的 NAT 转发。
- 兼容性： 对外部网络可见，可以更好地融入传统的 L2/L3 网络环境。

适用场景： 遗留应用，或需要直接暴露给物理网络、不能使用 NAT 映射的情况，例如网络监控或需要高性能二层通信的应用

**配置案例**

```yml
version: "3.8"
services:
  macvlan_app:
    image: busybox
    command: sleep 3600
    networks:
      macvlan_net:
        # 可选：手动指定一个 IP 地址
        ipv4_address: 192.168.1.100

networks:
  macvlan_net:
    driver: macvlan
    driver_opts:
      # !! 必须替换成您的宿主机物理网卡名称 !!
      parent: eth0 
    config:
      # 配置 MacVlan 所属的 IP 子网
      subnet: 192.168.1.0/24
      # MacVlan 使用的网关
      gateway: 192.168.1.1
```
{: file='docker-compose.yml'}

需要在 `networks` 块中显式指定 `driver: macvlan`，并提供宿主机的物理网络接口和子网配置。

注意： `parent` 参数必须替换为 Docker 宿主机上实际的物理网络接口名称（如 `eth0` 或 `enp0s3`）

### IPvlan
IPvlan 模式与 MacVlan 驱动非常相似，两者都旨在解决 Bridge 模式中 NAT 和端口映射带来的复杂性，并允许容器直接接入物理网络

IPvlan 在单个物理网络接口上创建多个虚拟网络接口。与 MacVlan 不同，所有容器共享宿主机的 MAC 地址，但每个容器都有一个独立的 IP 地址。这使得 IPvlan 对 L2 层的网络设备更友好（例如，不会因为 MAC 地址过多而触发安全限制）

当需要在容器直接连接到物理网络，但又想限制 MAC 地址数量时，IPvlan 是比 MacVlan 更具扩展性的选择

```yml
version: "3.8"
services:
  ipvlan_app:
    image: busybox
    command: sleep 3600
    networks:
      ipvlan_net:
        # 可选：手动指定一个 IP 地址
        ipv4_address: 192.168.1.101

networks:
  ipvlan_net:
    driver: ipvlan
    driver_opts:
      # !! 必须替换成您的宿主机物理网卡名称 !!
      parent: eth0
      # 指定为 L2 (Bridge) 模式
      ipvlan_mode: l2 
    config:
      # 配置 IPvlan 所属的 IP 子网
      subnet: 192.168.1.0/24
      # IPvlan 使用的网关
      gateway: 192.168.1.1
```
{: file='docker-compose.yml'}

与 MacVlan 类似，需要在 `networks` 块中指定 `driver: ipvlan`，并设置相应的配置。

注意： `parent` 参数也必须替换为您的宿主机上实际的物理网络接口名称

## 一些常见的 Docker 网络配置案例
### 配置默认网络
```yml
version: '3.8'

services:
  web:
    build: .
    ports:
      - "8000:8000"
    # 服务默认连接到顶级的 default 网络

  db:
    image: postgres:latest
    # 为了演示，添加一个环境变量，方便容器启动
    environment:
      POSTGRES_PASSWORD: your_strong_password
    # web 容器现在可以直接使用服务名称 'db' 访问此数据库

networks:
  # 定义顶级的 networks 块
  default:
    # 使用 driver 关键字来指定网络驱动
    # 注意：在 Docker Compose 3.x 版本中，自定义网络驱动（如 custom-driver-1）
    # 必须是 Docker 环境中已安装或内置的驱动（如 bridge, overlay, macvlan, ipvlan）。
    # 如果该驱动不存在，Compose 会报错。这里我们使用内置的 'bridge' 作为默认驱动。
    driver: bridge
    # 也可以在这里添加 driver_opts 或 ipam 配置
    # driver_opts:
    #   com.docker.network.bridge.host_binding_ipv4: "0.0.0.0"

    # 以下配置允许 web 服务使用自定义别名 'database' 访问 db 服务
    # (类似于 v2 的 links: - "db:database")
    # web 服务通过 service:db 引用这个网络
    # 但是，我们在这里配置 networks 块时，web 和 db 默认都属于 default 网络，
    # 因此不需要在 services 块中显式列出 default 网络，除非想添加别名。
```
{: file='docker-compose.yml'}

现代 Docker Compose（version 3）配置默认网络的两种方式

1. 自动默认网络 (Implicit Default Network)
  
    没有在 `networks`: 顶级块中定义任何网络时，Docker Compose 会为创建一个名为 `<projectname>_default` 的 Bridge 网络，并将所有服务连接到它。

2. 显式配置默认网络 (Explicit Default Network)
  
    就像上面的示例所示，如果想自定义这个默认网络的行为（例如更改驱动、添加 IP 地址管理策略），可以在 `networks` 顶级块中添加一个名为 `default` 的网络配置：

```yml
networks:
  default:
    # 显式指定驱动。如果留空，则默认为 'bridge'。
    driver: bridge 
    # 添加高级配置，例如 IP 地址管理 (IPAM)
    ipam:
      driver: default
      config:
        - subnet: 172.28.0.0/16
```
{: file='docker-compose.yml'}

**配置说明：**

- **`networks` (顶级键)：** 专门用于定义 Compose 文件中可用的网络资源。
- **`default` (网络名称)：** 当在服务中不指定任何网络时，服务将自动连接到这个名为 `default` 的网络。
- **`driver`：** 用于指定 Docker 网络的驱动程序。您原配置中的 `custom-driver-1` 需要是 Docker 环境中已安装或内置的有效驱动（如 `bridge`, `overlay`, `macvlan` 等）。如果指定了一个不存在的驱动，`docker-compose up` 将会失败。

通过这种方式，`web` 和 `db` 服务将自动连接到您自定义配置的 `default` 网络中，并可以通过彼此的服务名称 (`web` 和 `db`) 进行访问。

### 使用已存在的网络

一些场景下，我们并不需要创建新的网络，而只需加入已存在的网络，此时可使用`external`选项。示例:

```yml
networks:
  default:
    external:
      name: my-pre-existing-network
```
{: file='docker-compose.yml'}

### 指定自定义网络
一些场景下，默认的网络配置满足不了我们的需求，此时我们可使用`networks`命令自定义网络。`networks`命令允许我们创建更加复杂的网络拓扑并指定自定义网络驱动和选项。不仅如此，我们还可使用`networks`将服务连接到不是由Compose管理的、外部创建的网络

```yml
version: '3.8'

services:
  proxy:
    build: ./proxy
    # 服务通过 networks 关键字指定连接到哪些自定义网络
    networks:
      - front

  app:
    build: ./app
    networks:
      - front
      - back

  db:
    image: postgres:latest
    environment:
      POSTGRES_PASSWORD: mysecretpassword # 推荐为数据库设置密码
    networks:
      - back

networks:
  # 1. 前端网络定义 (front)
  front:
    # 在 v3 中，driver 关键字保持不变，用于指定 Docker 网络驱动
    driver: custom-driver-1
    # 注意：custom-driver-1 必须在您的 Docker 环境中存在

  # 2. 后端网络定义 (back)
  back:
    driver: custom-driver-2
    # driver_opts 关键字在 v3 中继续使用，用于将配置传递给驱动程序
    driver_opts:
      foo: "1"
      bar: "2"
```
{: file='docker-compose.yml'}

**这个配置文件实现的效果如下**

隔离性 (Isolation)：服务通过 networks 列表连接到指定的网络。

- `app` 服务连接到 `front` 和 `back`，所以它可以访问 `proxy` 和 `db`。
- `proxy` 只连接到 `front`，它无法直接访问 `db`。
- `db` 只连接到 `back`，它无法直接访问 `proxy`。

服务发现 (Service Discovery)：

- 在 `app` 容器中，访问 `proxy` 时使用主机名 `proxy`；访问 `db` 时使用主机名 `db`。

> Docker 内置 DNS 的功能，与网络驱动类型无关，只要它们连接在同一个用户定义网络中即可。
{: .prompt-tip }

**自定义网络和驱动配置说明:**

- **`networks` 顶级块**： 用于定义 `proxy`, `app`, `db` 服务所引用的网络。
- **`driver` 关键字**： 用于指定 Docker 必须使用的网络驱动。
    - `driver: custom-driver-1` 和 `driver: custom-driver-2` 保持不变。如果这些驱动不是 Docker 内置的（如 `bridge`, `overlay`），它们必须是已安装的第三方网络驱动或 CNI 插件。如果这些驱动不存在，docker-compose up 将会失败。
- **`driver_opts` 关键字**： 用于将特定的选项作为键值对传递给指定的网络驱动程序。
    - 示例中，`custom-driver-2` 将接收到参数 `foo=1` 和 `bar=2`，用于配置该网络的底层实现（例如，设置 VXLAN ID、VLAN 标签等）。

### 多项目的容器之间的链接
在Docker中，容器之间的链接是一种很常见的操作：它提供了访问其中的某个容器的网络服务而不需要将所需的端口暴露给Docker Host主机的功能。Docker Compose中对该特性的支持同样是很方便的。

然而，如果需要链接的容器没有定义在同一个`docker-compose.yml`中的时候，这个时候就稍微麻烦复杂了点

当需要让两个不同的 Compose 文件（代表两个独立的项目或服务组）中的容器互相通信时，它们不能依赖彼此的默认网络。需要让它们都连接到一个**共享的、预先创建**的网络。

步骤 1: 创建一个共享的外部网络

首先，需要手动创建一个 Bridge 网络。这个网络将作为连接所有独立项目的"主干线"

```shell
docker network create shared_backend
```

步骤 2: 配置第一个 Compose 文件 (`docker-compose-app.yml`)

第一个文件定义了前端应用 `web` 和 API 网关 `api`。它们需要连接到 `shared_backend` 才能访问数据库。

```yml
version: '3.8'

services:
  web:
    image: myapp/frontend
    ports:
      - "80:80"
    networks:
      - shared_network # 连接到共享网络

  api:
    image: myapp/gateway
    networks:
      - shared_network # 连接到共享网络
    # 现在 API 可以通过主机名 'db' 访问数据库服务

networks:
  # 在 networks 顶级块中声明 'shared_network' 是一个外部网络
  shared_network:
    external: true
    name: shared_backend # 必须匹配步骤 1 中创建的 Docker 网络名称
```
{: file='docker-compose-app.yml'}

步骤 3: 配置第二个 Compose 文件 (`docker-compose-db.yml`)

第二个文件只定义了数据库服务 `db`。它也必须连接到同一个 `shared_backend `网络

```yml
version: '3.8'

services:
  db:
    image: postgres:latest
    environment:
      POSTGRES_PASSWORD: mysecretpassword
    networks:
      - shared_network # 连接到共享网络

networks:
  # 同样在这里声明 'shared_network' 是外部网络
  shared_network:
    external: true
    name: shared_backend # 必须匹配步骤 1 中创建的 Docker 网络名称
```
{: file='docker-compose-db.yml'}

步骤 4: 分别启动服务

```shell
docker-compose -f docker-compose-db.yml up -d

docker-compose -f docker-compose-app.yml up -d
```

**工作原理:**

- 当 Docker Compose 看到 `external: true` 时，它不会尝试创建该网络，而是去查找 Docker 环境中是否已经存在一个名为 `shared_backend` 的网络。
- 如果找到，它会将当前 Compose 文件中定义的所有服务（如 `api` 和 `db`）都挂载到这个现有的共享网络上。
- 由于 `api` 和 `db` 现在位于同一个用户定义的网络 `shared_backend` 中，Docker 的内置 DNS 服务将它们的服务名注册为主机名。
- 因此，`api` 容器就可以通过主机名 `db` 来访问 PostgreSQL 数据库，即使它们是在不同的 `docker-compose.yml` 文件中启动的。


# 参考

- [Docker Compose 网络设置](https://juejin.cn/post/6844903976534540296)
- [docker-compose配置networks](https://www.jianshu.com/p/3004fbce4d37)
- [docker 网络模式 和 端口映射](https://www.cnblogs.com/chenpython123/p/10823879.html)