---
layout: post
title: OpenWRT overlay 空间扩容
date: 2022-03-13 18:43 +0800
categories: [Tech Projects] 
tags: [OpenWRT, GeekDairy]
---

>安装 OpenWRT 咔咔塞了一大堆插件后，可怜的剩余空间被插件和日志耗尽，不得不对 OpenWRT overlay 进行扩容，本文对此进行了记录
{: .prompt-info }

# 什么是 overlay

`OpenWRT` 一般使用的文件系统是 `SquashFS` ，这个文件系统的特点就是：**只读**。

一个只读的文件系统要怎么做到保存设置和安装软件的呢？这里就是使用 `/overlay` 的分区，`overlay` 顾名思义就是覆盖在上面一层的意思。虽然原来的文件不能修改，但把修改的部分放在 `overlay` 分区上，然后映射到原来的位置，读取的时候就可以读到修改过的文件了。

为什么要用这么复杂的方法呢？ `OpenWRT` 当然也可以使用 `EXT4` 文件系统，但使用 `SquashFS + overlay` 的方式有一定的优点。

- `SquashFS` 是经过压缩的，在路由器这种小型 `ROM` 的设备可以放下更多的东西。
- `OpenWRT` 的恢复出厂设置也要依赖于这个方式。在你重置的时候，它只需要把 `overlay` 分区清空就可以了，一切都回到了刚刷进去的样子。

如果是 `EXT4` 文件系统，就只能够备份每个修改的文件，在恢复出厂设置的时候复制回来，十分复杂。

当然，`SquashFS + overlay` 也有它的缺点：

- 修改文件的时候会占用更多的空间。首先你不能够删除文件，因为删除文件实际上是在 `overlay` 分区中写入一个删除的标识，反而占用更多的空间。
- 另外在修改文件的时候相当于增加了一份文件的副本，占用了双份的空间。

![overlay 示意图](https://i.ibb.co/r00Tj4m/overlay.webp)


# 创建新分区
首先，需要创建一个新的分区，这里使用的是 `cfdisk`

如果此前没有安装，首先使用下列命令进行安装：

```shell
opkg update
opkg install cfdisk
```
然后输入
```shell
cfdisk
```
打开磁盘管理界面：

![磁盘界面](https://i.ibb.co/Ns9qzhP/cfdisk.webp)
_磁盘界面_

这里可以看到，目前一共有两个已有分区，现在新建一个分区：

选中 `Free Space`，再选中 `New`，输入需要的大小，比如 5G。

接着选择 `primary`

![选择主分区](https://i.ibb.co/3CcQ6QH/primary.webp)
_选择主分区_

选择 `Write`

![写入更改](https://i.ibb.co/8nCTcF9/write.webp)
_写入更改_

输入 `yes`，完成新分区的创建

![确认](https://i.ibb.co/2vLMy0K/yes.webp)
_确认_

# 格式化分区
使用命令：
```shell
mkfs.ext4 /dev/sda3
```
格式化分区

![格式化分区](https://i.ibb.co/z86fCcC/format.webp)
_格式化分区_


# 挂载新分区
使用命令：
```shell
mount /dev/sda3 /mnt/sda3
```
挂载分区


# 转移到新分区
然后将原来 `upper` 层中的数据复制到新的分区中：
```shell
cp -r /overlay/* /mnt/sda3
```


# Web 界面配置修改
进入 `OpenWRT` Web 界面的`挂载点`对配置进行修改：

![Web 界面](https://i.ibb.co/hg4XtKP/openwrt.webp)
_Web 界面_

在`挂载点`下方点击`添加`，然后如下配置：

![挂载点配置](https://i.ibb.co/9hQwK3Z/mountpoint.webp)
_挂载点配置_


# 完成
到这一步，只需要重启 `OpenWRT` 即可成功扩容。

重启后到 `系统 -> 软件包` 可以看到变大后的空间容量。


# 自动挂载
分区默认会在 `OpenWRT` 重启后会自动挂载，如果遇到没有挂载的情况，需要编辑 `/etc/rc.local`
```shell
vim /etc/rc.local
```
在 `exit 0` 之前加入一行 `mount /dev/sda3 /overlay` 即可。


# 参考

- [OpenWrt 下把 SD 卡挂载到 /overlay ，扩大软件空间](https://blog.msm.moe/mount-sd-card-to-overlay-on-openwrt/)

- [软路由 LEDE 折腾 overlay 分区扩容之路](https://www.jianshu.com/p/8179b19cfa6d)

- [ESXI 下 OpenWrt 扩容 Overlay,增加安装插件空间](https://www.vediotalk.com/archives/13889)
