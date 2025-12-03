---
layout: post
title: 使用 Docker 快速部署 MinIO
date: 2024-05-11 21:05 +0800
categories: [ServerOperation]
tags: [Docker, 容器, 对象存储]
---

## 拉取MinIO镜像
MinIO 官方镜像地址  [MinIO-Docker Hub](https://hub.docker.com/r/minio/minio)

```bash
docker pull minio/minio
```

## 创建挂载目录

宿主机与容器挂载映射: 

| 宿主机位置       | 容器内位置     |
| :--------------- | :------------- |
| `/mnt/data/minio` | `/data`        |

为了持久化数据（即使容器被移除），建议在宿主机上创建一个目录用于存储 MinIO 的数据。

```bash
# 例如，在 /mnt/data/minio 目录下
mkdir -p /mnt/data/minio

# 配置挂载文件夹的权限保证MinIO正确启动 
chown -R 1000:1000 /mnt/data/minio
```

> 注意: 一定要把文件夹都先创建好,不然容器启动后容器创建的用户组和权限都会是`root`,而不是`1000`, 目录和MinIO执行用户权限不一致, 导致启动失败, 详情查看[Docker 下 MinIO 启动提示权限不足的解决方案](/posts/resolving-insufficient-permissions-when-starting-minio-in-docker/#故障原因)
{: .prompt-warning }

> 注意: 不同的镜像源可能使用不同的用户ID(例如[Bitnami MinIO 镜像](https://hub.docker.com/r/bitnami/minio)使用1001)来运行MinIO进程, 这里所有示例都假设MinIO会使用`1000`这个用户ID来运行
{: .prompt-tip }

## 启动MinIO服务
### Docker Run 启动
使用 `docker run` 命令来启动 MinIO 容器。需要配置端口映射、数据卷、以及访问密钥。

```bash
docker run -d \
  -p 9000:9000 \
  -p 9001:9001 \
  --name minio \
  -v /mnt/data/minio:/data \
  -e "MINIO_ROOT_USER=minioadmin" \
  -e "MINIO_ROOT_PASSWORD=minioadmin" \
  minio/minio server /data --console-address ":9001"
```

- `-d`: 后台运行容器。
- `-p 9000:9000`: 将宿主机的 9000 端口映射到容器的 9000 端口（MinIO API 端口）。
- `-p 9001:9001`: (如果需要控制台) 将宿主机的 9001 端口映射到容器的 9001 端口（MinIO 控制台/UI 端口）。
    > 注意: 在上面的示例中，使用了简化了命令，直接使用 `/data --console-address ":9001"` 让 MinIO 在容器内部启动 API (9000) 和 Console (9001)。如果你的 `minio/minio` 镜像是新版且支持内嵌控制台，可能只需要映射 9000 端口并通过特定路径访问控制台。
    {: .prompt-info }
- `--name minio`: 给容器命名为 minio。
- `-v /mnt/data/minio:/data`: 将宿主机上的 `/mnt/data/minio` 目录挂载到容器内部的 `/data` 目录，MinIO 会将所有数据存储到这里。
- `-e "MINIO_ROOT_USER=..."`: 设置 MinIO 的根用户的 `Access Key`（访问密钥）。
- `-e "MINIO_ROOT_PASSWORD=..."`: 设置 MinIO 的根用户的 `Secret Key`（密钥）。
- `minio/minio server /data --console-address ":9001"`: 运行 MinIO 镜像，并告诉 MinIO 在 `/data` 目录上启动服务，并将控制台地址设置为 9001 端口。


### Docker Compose 启动
首先，在你的项目目录下创建一个名为 `docker-compose.yml` 的文件。

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
    
    # ⬇️ 手动设置路径用户权限, 修复MinIO使用1000用户和默认Volme使用root的冲突
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

> 这里的`docker-compose.yml`修改了默认的启动命令以处理minio启动的权限冲突文件, 如果不修改启动命令可以:
> 
> - 使用文件目录挂载并手动设置目录权限为`1000`用户所有(等同于前面`docker run`的挂载方案)
> - 继续使用volume, 但是在卷创建后进入容器或对对应的物理机中目录手动修改volume中目录为`1000`用户所有
> - 继续使用volume, 但是通过初始化命令自动修改volume中目录为`1000`用户所有
> - 在容器中直接使用`root`用户权限运行MinIO (不推荐,这会降低安全性)
> 
> 详情查看[Docker 下 MinIO 启动提示权限不足的解决方案](/posts/resolving-insufficient-permissions-when-starting-minio-in-docker/#解决方案)
{: .prompt-warning }

在包含 `docker-compose.yml` 文件的目录下，执行以下命令：

```bash
docker-compose up -d
```

## 验证启动状态
**确认容器正在运行**

```bash
docker ps
```

应该能看到名为 `minio` 的容器处于 Up 状态。

**访问 MinIO 控制台**

在浏览器中访问 MinIO 控制台：

- 如果 MinIO 运行在你本地，访问：`http://localhost:9001` (如果映射了 9001 端口)
- 如果 MinIO 运行在远程服务器上，访问：`http://[服务器IP]:9001` (如果映射了 9001 端口)

使用前面设置的 `Access Key` 和 `Secret Key` (例如 `minioadmin` 和 `minioadmin`) 登录即可开始使用 MinIO。


# 参考
- [『MinIO』在Docker中快速部署MinIO](https://developer.aliyun.com/article/988594)
- [【Docker】Linux中Docker下Minio启动提示权限不足](https://www.yangxj96.com/Docker/DockerMinioPermissionDenied/)
