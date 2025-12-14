---
layout: post
title: Docker Engine 网络受影响的情况下的本地部署的配置流程
date: 2025-06-09 22:00 +0800
categories: [ServerOperation]
tags: [Docker, Hardware, Linux, Network, Windows]
---

在某些网络访问受限的情况下, 例如不能访问 Docker hub, Docker Apt 源, Nvidia Apt 源, 或者设备与自建/公共的镜像托管服务网络连接不稳定等情况, 仍然需要安装 Docker 并运行GPU应用, 可以参考以下方案:

## 网络受限的情况下安装Docker Engine的方案

1. 卸载旧版docker和删除残留

    ```bash
    sudo apt remove docker docker-engine docker.io containerd runc
    ```

2. 安装安装所需依赖工具

    ```bash
    sudo apt -y install ca-certificates curl gnupg lsb-release
    ```

3. 添加阿里云镜像的公钥

    ```bash
    curl -fsSL http://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | sudo apt-key add -
    ```

    打印返回（返回OK即为成功）

4. 添加Docker软件源
    
    注意 `arch=amd64` 这里的CPU架构需要根据安装的机器架构更改

    ```bash
    sudo add-apt-repository "deb [arch=amd64] http://mirrors.aliyun.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable"
    ```

5. 安装docker       

    ```bash
    apt -y install docker-ce docker-ce-cli containerd.io
    ```
6. 将当前用户添加到docker组

    避免每次使用Docker时都需要使用sudo（默认情况下，只有root用户和docker组的用户才能运行Docker命令）

    ```bash
    sudo usermod -aG docker $USER
    ```

7. 重启docker服务

    ```bash
    service docker restart
    ```

8. 查看docker状态

    ```bash
    systemctl status docker
    ```


## Docker Pull 低质量网络环境下EOF异常解决方案

`/etc/docker/deamon.json` 中配置以下内容

```json
{
   "max-concurrent-downloads": 1,
   "max-concurrent-uploads": 1,
   "max-download-attempts": 50,
   "features": {"containerd-snapshotter": true}
}
```
{: file="daemon.json" }

在低质量网络连接下启用，防止镜像Pull失败

- 限制镜像Pull并发数
- 限制镜像Push并发数
- 增加重试次数
- 启用containerd作为运行时， 以启用镜像pull的断点重传

## 在无法访问官方储存库的情况下安装NVIDIA Container Toolkit的方案

> 能直接访问 `nvidia.github.io` 的情况下优先使用的官方安装方案 [Installing the NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html)
{: .prompt-tip }

如果无法访问 `nvidia.github.io` 按照以下步骤操作

1. 单独下载 [nvidia.github.io/libnvidia-container/gpgkey](https://nvidia.github.io/libnvidia-container/gpgkey) 公钥文件，并复制到目标服务器上

2. 导入公钥

    ```bash
    sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg ./gpgkey
    ```
    其中 `./gpgkey` 是复制到服务器上对的公钥文件的路径

    `sudo gpg --dearmor`: 將 gpgkey 文件（通常是 ASCII armored 格式）转换为 APT 所需的二進制格式。

3. 配置 [mirrors.ustc.edu.cn](https://mirrors.ustc.edu.cn/help/libnvidia-container.html) 的鏡像源

    创建或编辑APT软件源列表文件：
    
    打开终端并使用sudo权限进行创建或编辑。 `/etc/apt/sources.list.d/nvidia-container-toolkit.list` 文件

    ```bash
    sudo nano /etc/apt/sources.list.d/nvidia-container-toolkit.list
    ```

    將以下內容粘贴到 `nvidia-container-toolkit.list` 中 

    ```bash
    deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://mirrors.ustc.edu.cn/libnvidia-container/stable/deb/amd64/ ./
    ```

    注意 `signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg` 公钥文件的路径需要和上一步导入公钥的时候设置的 `gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg` 路径的对应

    `/amd64/` 这里需要根据安装服务器的CPU架构指定, 查询支持的架构可以访问 [libnvidia-container/stable/deb/](https://mirrors.ustc.edu.cn/libnvidia-container/stable/deb/) 查看

4. 更新包索引并安装 NVIDIA Container Toolkit
    
    ```bash
    sudo apt update && sudo apt install nvidia-container-toolkit
    ```

5. 配置 Docker 运行时
        
    ```bash
    sudo nvidia-ctk runtime configure --runtime=docker
    ```

    重启 docker
        
    ```bash
    sudo systemctl restart docker
    ```

## 配置第三方Docker Hub镜像加速

在 `/etc/docker/daemon.json` 中写入如下内容（如果文件不存在请新建该文件）

```json
{
  "registry-mirrors": [
    "https://mirrors-example.com"
  ]
}
```
{: file="daemon.json" }

> 如果使用的镜像加速站点没有使用Https或者是内网的自建Register服务, 没有Https可以配置 `--insecure-registry` 来使用, 默认情况下Docker 会拒绝从没有启用Https的镜像站拉取镜像
{: .prompt-tip }

要配置`--insecure-registry`, 也需要打开`/etc/docker/daemon.json` 中写入如下内容

```json
{
  "insecure-registries": ["http://mirrors-example.com"]
}
```
{: file="daemon.json" }

之后重新启动Docker服务

```bash
sudo systemctl daemon-reload
sudo systemctl restart docker
```

重启后可以使用 `info` 命令查询配置的信息是否生效

```bash
docekr info
```

如果Docker配置正确，则命令的输出中应该包含之前添加的镜像站或者不安全镜像仓库的URL

如果是配置了上面所有配置项的 `/etc/docker/daemon.json` 最终看起来应该像:

```json
{
  "max-concurrent-downloads": 1,
  "max-concurrent-uploads": 1,
  "max-download-attempts": 50,
  "features": {"containerd-snapshotter": true},
  "registry-mirrors": [
    "https://mirrors-example.com"
  ],
  "insecure-registries": [
    "http://mirrors-example.com"
  ],
  "default-runtime": "nvidia",
  "runtimes": {
    "nvidia": {
      "path": "nvidia-container-runtime",
      "runtimeArgs": []
    }
  }
}
```
{: file="daemon.json" }


# 参考

- [在Ubuntu中安装docker最新的docker（被墙）](https://www.cnblogs.com/lrzy/p/18293457)
- [Ubuntu 22.04离线安装Docker和NVIDIA Container Toolkit](https://zhuanlan.zhihu.com/p/15194336245)
- [如何解决非root用户没有权限运行docker命令的问题？](https://developer.aliyun.com/article/773605)
- [【docker】添加用户到docker组](https://www.cnblogs.com/fireblackman/p/16054371.html)
- [docker客户端拉包逻辑及优化思路](https://blog.csdn.net/u013565163/article/details/120334785)
- [docker pull的断点续传](https://blog.csdn.net/weixin_40465062/article/details/138290828)
- [修改Docke上传/下载并发线程数（解决docker: unexpected EOF.)](https://blog.csdn.net/qq_35395195/article/details/128378573)
- [Windows docker --insecure-registry](https://blog.51cto.com/u_16213408/7148862)
- [镜像加速器](https://yeasy.gitbook.io/docker_practice/install/mirror)
