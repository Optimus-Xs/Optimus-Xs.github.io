---
layout: post
title: Docker 下 MinIO 启动提示权限不足的解决方案
date: 2024-09-08 21:08 +0800
categories: [ServerOperation]
tags: [Docker, 容器, 对象存储]
---

## 故障原因

这个错误信息 `ERROR Unable to initialize backend: mkdir /data/.minio.sys: permission denied` 意味着 MinIO 进程在尝试创建其系统配置目录（`.minio.sys`）时，没有权限写入你挂载到容器内部 `/data` 的目录。

这是因为 MinIO 容器内的进程通常以非 root 用户（例如 ID 为 `1000` 或其他特定 UID）运行，而你宿主机上用于**持久化数据的目录权限**或者使用**Volume管理的数据卷内目录**归属于 root 或不同的用户。

> - **[官方 MinIO 镜像](https://hub.docker.com/r/minio/minio)**: 默认使用 root 用户运行。为了安全起见，通常建议在生产环境中以非 root 用户身份运行容器。你可以使用 `docker run` 命令的 `--user` 参数指定一个不同的用户（例如 `--user $(id -u):$(id -g)`）。
> - **[Bitnami MinIO 镜像](https://hub.docker.com/r/bitnami/minio)**: 这些镜像默认设计为使用非 root 用户（通常是 UID 1001）运行。在使用 Bitnami 镜像时，需要确保挂载的数据目录具有正确的权限（chown -R 1001:1001），否则可能会遇到权限问题。 
{: .prompt-tip }

### 挂载目录的情况
这种情况下宿主机上用于持久化数据的目录权限可能归属于 root 或其他用户, 而非MinIO运行使用的用户

当你将一个宿主机目录（比如 `/mnt/data/minio`）挂载到容器的 `/data` 目录时，Docker 会保留宿主机目录原有的权限信息：

- 如果你的 `/mnt/data/minio` 目录是由宿主机的 `root` 用户创建的，它的所有者就是 root (UID `0`)。
- 当容器内部的用户（UID `1000`）尝试在 `/data`（即宿主机上的 `/mnt/data/minio`）中创建文件或目录时，它发现自己不是所有者，也没有写入权限，因此抛出：`permission denied`。

### 使用Docker Volume的情况
当在 `docker-compose.yml` 中定义并使用一个命名卷（例如 `minio_data`）时，Docker 守护进程（通常以 `root` 身份运行）会在宿主机上的特定位置（通常是 `/var/lib/docker/volumes/` 下）自动创建该卷。

1. **首次创建时的 UID/GID**
    在 Docker 首次创建这个命名卷的底层目录时：

    **默认情况下**，该目录通常会被 Docker 守护进程创建为 `root:root` (UID 0: GID 0) 所有。这是因为 Docker 守护进程负责文件系统的操作，而它通常以 `root` 权限运行。

2. **容器首次写入时的“隐式”权限变更**
    
    当你启动一个使用这个命名卷的容器，并且容器内的程序（例如 MinIO）**首次尝试向这个空卷写入数据**时，会发生关键的交互：
    
    - 如果容器以非 `root` 用户运行 (UID 1000)： 容器内的 MinIO 进程尝试写入 `root:root` 所属的空卷。此时就会触发 `permission denied` 错误。
    - 如果容器以 `root` 用户运行 (UID 0)： 容器内的 `root` 进程可以成功写入，并且创建的文件和目录将以 `root:root` 身份存储在卷中。

> 对于命名卷，无法像绑定挂载那样，在 `docker-compose.yml` 之外通过简单的 `sudo chown 1000:1000 /path/to/data` 来预先解决权限问题，因为无法不知道卷的具体宿主机路径，或者希望 Docker 自己管理
{: .prompt-info }

## 解决方案
虽然 MinIO 的默认非 Root 用户 ID 可能因镜像版本而异，但常见的是 `1000`。为了安全起见，这里所示例的所有方案均假设MinIO的执行用户ID是 `1000`。

### 手动修改挂载目录权限
以 Docker [运行示例](/posts/quickly-deploying-minio-with-docker/#创建挂载目录) `/mnt/data/minio` 为例，运行以下命令更改宿主机目录的所有权，使其与容器内的 MinIO 用户匹配：

```bash
# 假设 MinIO 容器内的用户 ID 是 1000
sudo chown -R 1000:1000 /mnt/data/minio
```

然后再重新启动容器即可:

```bash
# 如果是 docker run 方式
docker restart minio

# 如果是 docker-compose 方式
docker-compose down && docker-compose up -d
```

### 手动修改Volume内目录权限
如果你的数据卷是通过 `volumes:` 定义的命名卷 (`minio_data`)，[例如这个案例](http://localhost:4000/posts/quickly-deploying-minio-with-docker/#docker-compose-%E5%90%AF%E5%8A%A8), 你需要进入宿主机 Docker 卷存储路径（通常是 `/var/lib/docker/volumes/minio_data/_data/`）去修改权限

```bash
# 假设 MinIO 容器内的用户 ID 是 1000
sudo chown -R 1000:1000 /var/lib/docker/volumes/minio_data/_data/
```

修改权限后，重新启动 MinIO 容器：
```bash
# 如果是 docker run 方式
docker restart minio

# 如果是 docker-compose 方式
docker-compose down && docker-compose up -d
```


### 在初始化配置中修改Volume权限
要使用命名卷并避免权限错误，同时不使用 `root` 用户运行，你需要在**容器启动 MinIO 之前**，让容器内部的进程执行一次权限修正。

最佳实践是使用 `init` 脚本或在 `docker-compose.yml` 中使用 `entrypoint` 或 `command` 来实现这一逻辑：

使用 `command` 或 `entrypoint` (最常用的 Compose 技巧)

你可以在 `docker-compose.yml` 中定义一个命令序列，让容器首先以 `root` 身份对卷执行 `chown`，然后切换到非 `root` 用户启动 MinIO。

> 注意： 这需要容器的 `entrypoint` 脚本支持执行 `root` 命令。MinIO 官方镜像的 `entrypoint` 默认不支持这种复杂操作，所以我们通常需要覆盖整个启动命令，并使用 `sh -c` 来串联命令, 以便全部的执行都能在容器中正确识别和执行
{: .prompt-info }

```yml
version: '3.8'

services:
  minio:
    image: minio/minio
    container_name: minio_server
    
    environment:
      MINIO_ROOT_USER: minioadmin
      MINIO_ROOT_PASSWORD: minioadmin
    
    ports:
      - "9000:9000"
      - "9001:9001"
    
    # ⬇️ 使用命名卷 (Named Volume)
    volumes:
      - minio_data:/data 
    
    # ⬇️ 核心修复：组合命令
    command: >
      sh -c "chown -R 1000:1000 /data && 
             exec minio server /data --console-address ':9001'"

    # ⚠️ 注意: 
    # 1. chown 必须是第一条命令。
    # 2. chown 操作会以 entrypoint 的用户权限运行 (通常是 root)。
    # 3. MinIO 官方镜像的 entrypoint 会在 chown 之后切换到非 root 用户 (UID 1000) 执行 minio server。
    
    restart: always

# 定义命名卷
volumes:
  minio_data:
```
{: file='docker-compose.yml'}

对于命名卷，你不能在外部设置权限，而需要在容器内部通过 `chown` 命令在服务启动前“校正”卷的权限。

在这个解决方案中：

- `sh -c "..."` 启动一个 shell 进程，它通常继承了 `entrypoint` 或默认的用户（通常是 `root`）。
- `chown -R 1000:1000 /data`：这条命令以 root 权限执行，将命名卷 `/data` 目录及其内容的所有权更改为 
- `exec minio server ...`：Docker 的 `entrypoint` 脚本看到这条命令，确保后续的 MinIO 服务器进程会以 MinIO 镜像中定义的 非 root 用户（UID `1000`）启动。
- 由于卷现在属于 `1000:1000`，MinIO 进程可以成功写入，并且服务成功启动。

### 指定使用 root 运行 MinIO
如果使用的是 Docker Compose，在不修改持久化目录的情况下，还可以修改 `docker-compose.yml` 文件，明确告诉 Docker 以 `root` 用户身份运行 MinIO 进程，从而绕过权限问题。

> 这会降低安全性，因为它允许容器内部的进程以宿主机上的高权限用户身份运行。
{: .prompt-danger }

```yml
version: '3.8'

services:
  minio:
    image: minio/minio
    container_name: minio_server
    # ⬇️ 添加这一行 
    user: "0" # 0 代表 root 用户
    # ⬆️ 添加这一行
    environment:
      MINIO_ROOT_USER: minioadmin
      MINIO_ROOT_PASSWORD: minioadmin
    # ... (其他配置保持不变)
```
{: file='docker-compose.yml'}

保存文件后，运行:

```bash
docker-compose up -d 
```

重新启动服务。


# 参考
- [【Docker】Linux中Docker下Minio启动提示权限不足](https://www.yangxj96.com/Docker/DockerMinioPermissionDenied/)