---
layout: post
title: 在 PVE 虚拟环境中安装 OpenWRT 流程
date: 2022-03-02 00:41 +0800
categories: [Tech Projects] 
tags: [OpenWRT, GeekDairy, PVE]
---

# 前言
前几天捡垃圾￥230淘到一台惠普800G1 SFF 准系统，正好家里缺一台服务器，就直接配了块G3250，先尝试装上PVE实现一波AIO服务器，这篇文章记录下在 pve 环境下折腾 openwrt 的心得，顺便学习下 pve

# 安装 PVE
1. 在官网中下载 [ISO 镜像](https://www.proxmox.com/en/downloads/category/iso-images-pve)
2. 烧录到 U 盘中
3. 使用U盘启动
4. 安装，具体可参考[【纯净安装】Proxmox-VE ISO原版](https://www.cxthhhhh.com/2020/09/21/pure-installation-the-whole-installation-process-of-the-original-proxmox-ve-iso.html) 安装 全过程
5. 登录PVE后台，地址为 https://IP:8006，重点：https，使用 chrome 登录时因为证书不安全的原因会被拦截，选择信任

# 下载 OPENWRT 镜像
我现在使用的是用[Lean大仓库](https://github.com/coolsnowwolf/lede)源码手动编译的版本，编译输出 gz 格式的压缩文件，需要解压为 img 格式的镜像文件

# 分配网卡
路由器最重要的就是将端口的网卡分配成 WAN 口和 LAN 口，这样才能形成一个网络拓扑结构。因为我是在 PVE 中安装虚拟机的方式使用 OPENWRT，所以需要先在 PVE 中将网卡映射到虚拟机中，路由器才能正确分配端口。 

1. 安装 PVE 的过程中，我们已经将 eth0 口(也就是图上的 enp1s0) 虚拟成了 vmbr0
   ![](https://cdn.jsdelivr.net/gh/jiz4oh/backups@master/img/20210206155524.png)
2. 因为我的服务器总共有4个网卡，所以我还需要虚拟3个网卡出来，和硬件口一一对应，比如将 en2s0 虚拟成 vmbr1，以此类推
   ![](https://cdn.jsdelivr.net/gh/jiz4oh/backups@master/img/telegram-cloud-photo-size-5-6123167585387260669-y.jpg)
   最终效果：
   ![](https://cdn.jsdelivr.net/gh/jiz4oh/backups@master/img/2021-02-06-16-02-45.png)
3. 应用配置
   ![](https://cdn.jsdelivr.net/gh/jiz4oh/backups@master/img/2021-02-06-16-04-34.png)
   如果遇到了这个错误，是因为没有 ifupdown2，需要在 shell 中执行 
   ```shell
   apt install -y ifupdown2
   ```
   ![](https://cdn.jsdelivr.net/gh/jiz4oh/backups@master/img/2021-02-06-16-05-23.jpg)


# 创建OPENWRT虚拟机
1. 点击右上角 `创建虚拟机`

2. 一般：输入名称并设置开机自启，点击下一步
我使用的 openwrt，注意 VM ID，这是以后在 PVE 中操作虚拟机的关键
  ![](https://cdn.jsdelivr.net/gh/jiz4oh/backups@master/img/2021-02-06-16-07-58.png)
3. 操作系统：选择不使用任何介质，点击下一步<br>稍后再上传镜像文件，因为需要对磁盘进行一些操
   ![](https://cdn.jsdelivr.net/gh/jiz4oh/backups@master/img/2021-02-06-16-09-07.png)
4. 系统：全部默认，点击下一步
5. 硬盘：全部默认，点击下一步
6. CPU：选择分配给虚拟机的CPU，点击下一步<br>按个人喜好分配 CPU 个数，我分配的 4 个，CPU 权重是在多个虚拟机中竞争 CPU 时，虚拟机的优先级，默认是 1024，可以增加 OPENWET 的权重保证网络通畅
   ![](https://cdn.jsdelivr.net/gh/jiz4oh/backups@master/img/2021-02-06-16-16-55.png)
7. 内存：按照个人喜好分配，如果只是单纯上网，1G足矣
8. 网络：模型选择 VirtIO<br>桥接网卡随便选，后面会将全部网卡添加进来
   ![](https://cdn.jsdelivr.net/gh/jiz4oh/backups@master/img/2021-02-06-16-21-07.png)
9. 确认


# 配置虚拟机
1. 分离创建时选择的硬盘
  ![](https://cdn.jsdelivr.net/gh/jiz4oh/backups@master/img/2021-02-06-16-24-12.png)

2. 删除未使用的磁盘0和CD/DVD驱动器(ide2)
  ![](https://cdn.jsdelivr.net/gh/jiz4oh/backups@master/img/2021-02-06-16-25-38.png)

3. 上传之前下载的 OPENWRT img 文件
  ![](https://cdn.jsdelivr.net/gh/jiz4oh/backups@master/img/2021-02-06-16-29-01.png)

4. 拷贝镜像上传地址
  ![](https://cdn.jsdelivr.net/gh/jiz4oh/backups@master/img/2021-02-06-16-31-56.png)

5. 将 OPENWET 镜像导入磁盘 在 shell 中执行 ：
   ```shell
   qm importdisk 100 /var/lib/vz/template/iso/openwrt-buddha-v2_2021_-x86-64-generic-squashfs-uefi.img local-lvm
   ```
   图中第一个绿框中的 100 为虚拟机的 VM ID，第二个绿框为刚刚上传的镜像地址<br>
  ![](https://cdn.jsdelivr.net/gh/jiz4oh/backups@master/img/2021-02-06-16-34-18.png)

6. 设置磁盘
  ![](https://cdn.jsdelivr.net/gh/jiz4oh/backups@master/img/2021-02-06-16-37-42.png)

7. 调整引导顺序，将 sata0 磁盘启用并调整到第一位
  ![](https://cdn.jsdelivr.net/gh/jiz4oh/backups@master/img/2021-02-06-16-42-15.png)

8. 添加虚拟网卡，将之前虚拟出来的网卡都依次添加进去，还是使用 VirtIO 模型
  ![](https://cdn.jsdelivr.net/gh/jiz4oh/backups@master/img/2021-02-06-16-40-30.png)

9. 启动虚拟机


现在就可以进入 OPENWRT 了

# 参考
- [【纯净安装】Proxmox-VE ISO原版 安装 全过程](https://www.cxthhhhh.com/2020/09/21/pure-installation-the-whole-installation-process-of-the-original-proxmox-ve-iso.html)
- [PVE安装Openwrt/LEDE软路由保姆级图文教程](https://www.10bests.com/install-openwrt-lede-on-pve/)

