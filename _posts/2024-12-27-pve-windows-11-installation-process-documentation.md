---
layout: post
title: PVE安装Windows11流程记录
date: 2024-12-27 16:10 +0800
categories: [Tech Projects]
tags: [PVE, Windows, 操作系统, 虚拟化]
---

## 驱动准备
创建虚拟机前先下载以下需要的系统镜像和驱动：

系统镜像和虚拟机文件系统驱动：
- [Windows 11 ISO](https://www.microsoft.com/software-download/windows11)
- [virtio-win驱动ISO](https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso)

> 为什么虚要virtio-win驱动
>
> VirtIO 是一种半虚拟化 (paravirtualization) 驱动标准，专为 KVM、QEMU 等现代虚拟化平台设计。它的核心目的是让虚拟机 (VM) 中的操作系统能够直接且高效地与底层硬件和管理程序 (Hypervisor) 进行通信，而无需通过完全模拟（Full Emulation）传统硬件的方式，从而显著提高性能。
>
> 标准的 Windows 操作系统安装镜像不包含 VirtIO 驱动。它只包含用于传统或模拟硬件的驱动程序
>
> 如果在 PVE 中将虚拟硬盘控制器设置为 VirtIO Block 或 VirtIO SCSI，Windows 虚拟机在没有相应 VirtIO 驱动的情况下无法识别或启动这些高性能虚拟磁盘。
{: .prompt-tip }

显卡硬件驱动：

- [Intel核显驱动](https://downloadmirror.intel.com/813048/gfx_win_101.5085_101.5122.exe)

如果使用独立显卡做显卡直通可以使用下面的驱动：

- [Nvidia核显驱动](https://www.nvidia.cn/geforce/drivers/)
- [AMD核显驱动](https://www.amd.com/zh-cn/support/download/drivers.html)
- [Intel独显驱动](https://www.intel.com/content/www/us/en/download/785597/intel-arc-graphics-windows.html)

## 虚拟机配置

### 操作系统

![Win11 VM 操作系统配置](https://cdn.jsdelivr.net/gh/Optimus-Xs/Blog-Images/2024-12-27-pve-windows-11-installation-process-documentation%2Fwin11-vm-operating-system-configuration.png)

选择ISO镜像，然后选择客户机操作系统类别为：`Microsoft Windows`后，会出现`Add additional drive for Virtio drivers`，选中打勾，选择`virtio-win`的镜像，添加进去。

### 系统

![Win11 VM 系统配置](https://cdn.jsdelivr.net/gh/Optimus-Xs/Blog-Images/2024-12-27-pve-windows-11-installation-process-documentation%2Fwin11-vm-system-configuration.png)

机型选择`q35`，显卡选择`默认`，BIOS选择`OVMF(UEFI)`。安装win11需要`TPM`存储，所以`EFI存储`和`TPM存储`都要。

### 磁盘

![Win11 VM 磁盘配置](https://cdn.jsdelivr.net/gh/Optimus-Xs/Blog-Images/2024-12-27-pve-windows-11-installation-process-documentation%2Fwin11-vm-disk-configuration.png)

总线/设备选择`SCSI`，硬盘大小>=100GB比较合适。

### CPU

![Win11 VM CPU配置](https://cdn.jsdelivr.net/gh/Optimus-Xs/Blog-Images/2024-12-27-pve-windows-11-installation-process-documentation%2Fwin11-vm-cpu-configuration.png)

选择4核心(根据物理机的配置可更换)，类别选择`host`性能和兼容性会更好。

### 内存

![Win11 VM 内存配置](https://cdn.jsdelivr.net/gh/Optimus-Xs/Blog-Images/2024-12-27-pve-windows-11-installation-process-documentation%2Fwin11-vm-memory-configuration.png)

内存至少`4GB`以上。

### 网络

![Win11 VM 网络配置](https://cdn.jsdelivr.net/gh/Optimus-Xs/Blog-Images/2024-12-27-pve-windows-11-installation-process-documentation%2Fwin11-vm-network-configuration.png)

网络模型选择`VirtiO虚拟化`即可。

### 创建虚拟机

点击下一步创建后，选择创建好的虚拟机，打开选项，设置 引导顺序，将`Win11镜像`放在第一个，`virtio-win驱动镜像`放在第二个。启动VM即可。

## 系统安装
### 启动安装程序
Windows安装跟着步骤一步一步走即可。

显示`Press any key to boot from CD or DVD`时，需要按下任意键，才会加载安装光驱。

![进入安装程序](https://cdn.jsdelivr.net/gh/Optimus-Xs/Blog-Images/2024-12-27-pve-windows-11-installation-process-documentation%2Fenter-the-installation-program.png)

### 加载virtio-win驱动

在选择安装硬盘时，会出现没有硬盘可选的时候，只需要选择加载驱动程序，弹出框中选择打开`virtio-win`的镜像，找到`vioscsi/win11/amd64`目录，点击确认安装驱动就可以显示出硬盘了

![安装过程中加载virtio-win驱动](https://cdn.jsdelivr.net/gh/Optimus-Xs/Blog-Images/2024-12-27-pve-windows-11-installation-process-documentation%2Fload-virtio-win-drivers-during-installation.png)

### 绕过Win11网络激活

`shift+F10` 打开CMD，然后运行

```shell
oobe\BypassNRO.cmd
```

即可，Windows会自动重启，重新开始设置Windows。(在最新版本的Win11镜像上可能会无法绕过)

## 硬件配置和驱动安装
### 显卡直通或者GPU虚拟化配置
在初次安装成功后，关闭win11虚拟机，需要重新设置一下显卡配置。

设置PVE自带的虚拟显卡为 `无`

![关闭虚拟显示器](https://cdn.jsdelivr.net/gh/Optimus-Xs/Blog-Images/2024-12-27-pve-windows-11-installation-process-documentation%2Fdisable-virtual-monitors.png)

> 这里PVE自带的虚拟显卡可以选择不修改, 在Win11的虚拟机中会保留一个虚拟屏幕, 让你在PVE控制面板中仍可以连接和调试, 可在硬件显卡驱动或者另外配置的虚拟屏幕故障的情况下调试虚拟机
{: .prompt-tip }

添加`pci`设备，和上面设置SRIOV核显时看到的一致，但是选择时不能选择`0000:00:02.0`，因为这是核显本体，一旦选择了核显本体，(如果是使用独显的显卡直通方案, 直接选择这个显卡本体即可, 记得勾选`全部功能`), 所有虚拟出来的核显都将失效，需要重新重启虚拟核显才行。所以只需要选择虚拟出来的`02.1`，`02.2`，`02.3`其中一个即可。

![添加GPU](https://cdn.jsdelivr.net/gh/Optimus-Xs/Blog-Images/2024-12-27-pve-windows-11-installation-process-documentation%2Fadd-gpu.png)

### 安装virtio-win驱动
在完成系统安装后, 打开资源管理器，找到之前加入的`virtio-win`的镜像ISO，打开后运行`virtio-win-gt-x64.msi`即可安装。

![安装virtio-win驱动](https://cdn.jsdelivr.net/gh/Optimus-Xs/Blog-Images/2024-12-27-pve-windows-11-installation-process-documentation%2Finstall-virtio-win-drivers.png)

安装完成后记得在PVE管理面板的VM的硬件配置中删除已使用过的光驱(`win11镜像`和`virtio-win驱动镜像`)

### 安装显卡驱动
根据实际方案在虚拟机中下载直通的独立显卡驱动或者Intel核显驱动(使用SRIOV显卡虚拟化的情况), 然后安装即可

- [Intel核显驱动下载](https://downloadmirror.intel.com/813048/gfx_win_101.5085_101.5122.exe)
- [Nvidia核显驱动下载](https://www.nvidia.cn/geforce/drivers/)
- [AMD核显驱动下载](https://www.amd.com/zh-cn/support/download/drivers.html)
- [Intel独显驱动下载](https://www.intel.com/content/www/us/en/download/785597/intel-arc-graphics-windows.html)

安装完显卡驱动后, 重新启动win11，pve中的控制台已经无法获取到信号了(关闭了PVE的自带虚拟显示设备的情况下)，我们使用远程桌面进行连接即可。

![GPU验证](https://cdn.jsdelivr.net/gh/Optimus-Xs/Blog-Images/2024-12-27-pve-windows-11-installation-process-documentation%2Fgpu-verification.png)

## 远程软件配置
### RDP配置
开启Windows自带的RDP远程桌面后，可以用另外的设备试一下连接。

![RDP配置](https://cdn.jsdelivr.net/gh/Optimus-Xs/Blog-Images/2024-12-27-pve-windows-11-installation-process-documentation%2Frdp-configuration.png)

### Parsec配置
#### Parsec 安装
Parsec 是一款专为高性能、低延迟交互式串流设计的远程桌面软件。它最初是为远程游戏而开发的，旨在提供类似本地操作的流畅体验，因此在处理对画面刷新率和延迟要求极高的任务（如游戏、图形设计、视频编辑）方面表现出色。

[Parsec 下载地址](https://parsec.app/downloads)

![Parsec 下载](https://cdn.jsdelivr.net/gh/Optimus-Xs/Blog-Images/2024-12-27-pve-windows-11-installation-process-documentation%2Fparsec-download.png)

官网下载`exe`后安装即可

#### 虚拟屏幕配置
在 Proxmox Virtual Environment (PVE) 中的 Windows 虚拟机里，Parsec 等远程桌面软件无法直接捕捉默认虚拟显示器画面，因为PVE默认的虚拟显示器驱动缺乏 Parsec 所需的硬件加速帧缓冲区 (Hardware Accelerated Framebuffer) 和数字输出接口。

这个时候我们可以使用 [Parsec-vdd](https://github.com/nomi-san/parsec-vdd) (Parsec Virtual Display Driver) 的作用就是用来解决上述问题的：

- **创建虚拟适配器**: 它在 Windows 虚拟机中安装一个特殊的虚拟显示驱动。这个驱动程序会在操作系统层面创建一个虚拟的、功能完整的显示适配器。
- **模拟硬件输出**: 这个虚拟显示适配器模拟了一个具有硬件加速能力的输出接口和帧缓冲区。
- **满足 Parsec 需求**: 一旦这个虚拟显示器存在并处于活动状态，Parsec 就能识别并绑定到这个新的虚拟显示输出上，从而成功捕捉画面并进行高性能串流。

> Parsec-vdd 最大的优点是：支持 4K 高刷、可添加多个虚拟屏、 H-Cursor（远程时屏幕无光标，接近原生操作体验）

在[Release页面](https://github.com/nomi-san/parsec-vdd/releases)下载安装包安装后配置虚拟现实器即可, 具体安装步骤也可参考[Parsec的VDD文档](https://support.parsec.app/hc/en-us/articles/32381178803604-VDD-Overview-Prerequisites-and-Installation)

> 如果使用的是独立显卡直通可以使用专门的HDMI/DP欺骗器接入显卡的显示接口模拟常规显示器接入, 这种情况下各种远程软件也能获取到显示画面
{: .prompt-tip }

#### 虚拟键鼠配置
在一些没有插入鼠标设备的物理机（或虚拟机）上面，Parsec就无法使用鼠标输入, 在一些没有插入鼠标设备的物理机（或虚拟机）上面，Parsec就无法使用鼠标输入. 

但是我们的VM不一定保证有单独的USB硬件可以传透到虚拟机上, 这个时候我们可以使用一个开源项目 [TabletDriver](https://github.com/MaxKruse/TabletDriver) 创建一个虚拟鼠标解决这个问题

在[Release页面](https://github.com/MaxKruse/TabletDriver/releases/tag/v0.3.1a) 下载 `TabletDriver.v0.3.1a.zip` 解压后, 运行`TabletDriver\bin\VMulti Installer GUI.exe`

![VMulti 驱动安装](https://cdn.jsdelivr.net/gh/Optimus-Xs/Blog-Images/2024-12-27-pve-windows-11-installation-process-documentation%2Fvmulti-installer.png)

点击`Install`, 安装一个虚拟鼠标的驱动, 然后Parsec就应该能在没有鼠标的情况下也能正常发送指令

# 参考
- [PVE安装Windows11小记](https://willxup.top/archives/pve-install-win11)
- [Parsec 解决无法使用鼠标 没有指针 无法输入 问题](https://www.bilibili.com/opus/637741813906538503)