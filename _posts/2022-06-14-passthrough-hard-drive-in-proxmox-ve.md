---
layout: post
title: Proxmox VE直通硬盘
date: 2022-06-14 14:37 +0800
categories: [Tech Projects] 
tags: [PVE, GeekDairy]
---

使用PVE有时为了方便，需要将硬盘直通, PVE系统直通硬盘有两种方式，方法一命令操作，直通单块硬盘；方法二添加 PCI设备，直通 SATA Controller(SATA 控制器)。

# 全盘映射
## 查找磁盘ID
进入Proxmox VE(PVE)系统的SSH，或直接进入PVE管理网页Shell

输入命令：

```shell
ls -l /dev/disk/by-id/
```

```
lrwxrwxrwx 1 root root  9 Jun 12 09:36 ata-GALAX_TA1D0240A_305D0********0279966 -> ../../sda
lrwxrwxrwx 1 root root 10 Jun 12 09:36 ata-GALAX_TA1D0240A_305D0********0279966-part1 -> ../../sda1
lrwxrwxrwx 1 root root 10 Jun 12 09:36 ata-GALAX_TA1D0240A_305D0********0279966-part2 -> ../../sda2
lrwxrwxrwx 1 root root 10 Jun 12 09:36 ata-GALAX_TA1D0240A_305D0********0279966-part3 -> ../../sda3
lrwxrwxrwx 1 root root  9 Jun 12 09:58 ata-ST1000DM003-1****2_W********7 -> ../../sdb
lrwxrwxrwx 1 root root 10 Jun 12 09:36 dm-name-pve-root -> ../../dm-1
lrwxrwxrwx 1 root root 10 Jun 12 09:36 dm-name-pve-swap -> ../../dm-0
lrwxrwxrwx 1 root root 10 Jun 12 09:36 dm-name-pve-vm--100--disk--0 -> ../../dm-8
lrwxrwxrwx 1 root root 10 Jun 12 09:36 dm-name-pve-vm--101--disk--0 -> ../../dm-7
lrwxrwxrwx 1 root root 10 Jun 12 09:36 dm-name-pve-vm--105--disk--0 -> ../../dm-6
lrwxrwxrwx 1 root root 10 Jun 12 09:36 dm-name-pve-vm--200--disk--0 -> ../../dm-9
lrwxrwxrwx 1 root root 10 Jun 12 09:36 dm-uuid-LVM-ezreio8tLBAyf5iIBYW5HS*********ZgzGBJxLqknLHZ05EUcCM0h3lWV -> ../../dm-1
lrwxrwxrwx 1 root root 10 Jun 12 09:36 dm-uuid-LVM-ezreio8tLBAyf5iIBYW5HS*********nbQKEmdsTHkKIe8j2Ou0mfRwXNL -> ../../dm-7
lrwxrwxrwx 1 root root 10 Jun 12 09:36 dm-uuid-LVM-ezreio8tLBAyf5iIBYW5HS*********OS0i5zs3870PzzgRxluMPy9qALl -> ../../dm-8
lrwxrwxrwx 1 root root 10 Jun 12 09:36 dm-uuid-LVM-ezreio8tLBAyf5iIBYW5HS*********SUJ1HHzTaROYIrVWHsoN9fZ4XiM -> ../../dm-9
lrwxrwxrwx 1 root root 10 Jun 12 09:36 dm-uuid-LVM-ezreio8tLBAyf5iIBYW5HS*********FE8hXy66BHq4Hf0HjxNMkUgqXnb -> ../../dm-0
lrwxrwxrwx 1 root root 10 Jun 12 09:36 dm-uuid-LVM-ezreio8tLBAyf5iIBYW5HS*********4PcYIkPqUFwmS91bfMSRwlA9vxR -> ../../dm-6
lrwxrwxrwx 1 root root 10 Jun 12 09:36 lvm-pv-uuid-2oucQP-****-****-****-****-****-gm99Po -> ../../sda3
lrwxrwxrwx 1 root root  9 Jun 12 09:58 wwn-0x500********f289 -> ../../sdb
```
这里必需选择的是整个硬盘(物理硬盘)而不是分区，比如sda、sdb、sdc对应的id，而不是(sda1、sda2…)

>注：ata、mmc等…表示接口方式，通常有ATA、SATA、SCS、NVME、eMMC和SASI等类型。IDE和SATA接口一般为“ata”，SCSI及SAS接口一般为”scsi“。
{: .prompt-tip }

## 硬盘映射

将物理磁盘直通给PVE系统下虚拟机中

需要在shell下通过CLI的方式来添加，

使用的工具为qm(Qemu/KVM虚拟机管理器)，通过命令 set 来设置物理磁盘到虚拟机中。

```shell
qm set <vm_id> -<disk_type>[n] /dev/disk/by-id/<type>-$brand-$model_$serial_number
```
注释：

- m_id : 为创建虚拟机时指定的VM ID。

- <disk_type\>\[n\]： 磁盘的总线类型及其编号，总线类型可以选择IDE、SATA、VirtIO Block和SCSI类型，编号从0开始，最大值根据总线接口类型有所不同，IDE为3，SATA为5，VirTIO Block为15，SCSI为13。

- "/dev/disk/by-id/-brand-brand−model_$serial_number" ： 为磁盘ID的具体路径和名称。

按照我硬盘的参数举例：

如上方的硬盘数据 ata-ST1000DM003-1\*\*\*\*2_W\*\*\*\*7 为例，将此硬盘直通给VM ID编号为200的虚拟机下，总线类型接口为sata0（请根据PVE虚拟机下的总线编号设置） 

挂载命令如下：
```shell
qm set 200 -sata0 /dev/disk/by-id/ata-ST1000DM003-1****2_W********7
```
，硬盘直通完成后，返回

```shell
update VM 200: -sata0 /dev/disk/by-id/ata-ST1000DM003-1****2_W********7
```
为直通成功。

## 检查
然后进入PVE虚拟机管理网页,查看是否真的挂载成功。

![](https://i.ibb.co/NmQbKqp/QQ-20220614145816.jpg)

如果看到PVE 200 虚拟机下的硬件设备里有直通的硬盘,就说明成功。如上图中所示，如果有橘黄色字体显示该设置并未生效，请从PVE控制台的重启虚拟机后生效。

# 直通 SATA Controller/PCI-E 阵列卡
Proxmox VE(PVE)系统直通SATA Controller(SATA 控制器)，会把整个sata总线全部直通过去，就是直接将南桥或者直接把北桥连接的sata总线直通，那么有些主板sata接口就会全部被直通。

>注意：如果您的PVE系统是安装在SATA的硬盘中，会导致PVE系统无法启动，所以在直通 SATA Controller(SATA 控制器)，之前请先确认自己的PVE系统安装位置，或者直接将系统安装在 NVMe 硬盘中。
{: .prompt-warning }

>在开始之前开启IOMMU硬件直通功能(需要CPU支持VT-D)，执行下一步添加 SATA Controller（SATA 控制器）/PCI-E 阵列卡操作。
{: .prompt-tip }

选择需要设置的PVE系统，点击 硬件 > 添加 > PCI设备 > 选择 SATA Controller（SATA 控制器），最后点击“添加”把 SATA Controller（SATA 控制器）添加给相应的系统后，完成重启，PVE硬件直通的设置就生效了。

![](https://i.ibb.co/fqT4cdF/QQ-20220614150604.jpg)
