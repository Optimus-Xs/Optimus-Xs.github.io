---
layout: post
title: PVE 开启 IOMMU 功能实现硬件直通
date: 2023-09-11 19:15 +0800
categories: [ServerOperation]
tags: [Hardware, PVE, 操作系统, 虚拟化]
---

## 什么是硬件直通

### 硬件直通概念

硬件直通是一种虚拟化技术，它允许虚拟机（VM）直接访问和独占使用物理主机上的某个硬件设备，而无需通过 hypervisor（虚拟机监控器）进行模拟或中介。

简而言之，它就像是给虚拟机开了一个“专属通道”，让它感觉自己在使用一个真实的、非虚拟化的硬件设备。

**核心原理与作用**

- 绕过 Hypervisor
    
    在传统的虚拟化架构中，所有硬件设备（如网卡、显卡、硬盘控制器等）都是由 hypervisor 模拟或管理后，再分配给虚拟机的。这会带来额外的性能开销和延迟。

    而硬件直通通过使用 IOMMU（Input-Output Memory Management Unit，输入输出内存管理单元）等技术，将设备的 PCI 地址空间和中断信号直接映射给虚拟机，从而：

    - ⚡ 提高性能： 虚拟机可以直接与硬件通信，几乎达到物理机上的原生性能。
    - ⬇️ 降低延迟： 避免了 hypervisor 的干预和多次数据拷贝。

- 独占使用
    
    被直通的硬件设备将完全脱离主机操作系统和 hypervisor 的控制，仅供该特定的虚拟机使用。

- 驱动程序
    
    虚拟机可以直接加载该硬件的原生驱动程序，就像它运行在一台物理机上一样。

> IOMMU 的全称是 Input-Output Memory Management Unit（输入/输出内存管理单元）。它是一种集成在计算机主板芯片组或 CPU 内部的硬件组件。
>
> IOMMU 的主要职责类似于 CPU 中的 MMU（内存管理单元），但它是针对 外围设备（如网卡、显卡、存储控制器等）的
>
> IOMMU 强制所有设备通过它来进行 DMA 访问。它确保设备只能访问 Hypervisor 为其分配的特定的内存区域，从而实现虚拟机之间的内存隔离和保护
>
> 当硬件直通启用时：
> 
> - **直通实现**： Hypervisor 配置 IOMMU，告诉它“将这个 GPU 设备的 I/O 权限，完全映射到 VM A 的虚拟地址空间”。
> - **安全性保证**： IOMMU 确保该 GPU（现在属于 VM A）发出的任何 DMA 请求都只会被转换到属于 VM A 的内存区域内。
> - **结果**： 虚拟机 A 可以直接、独占、高效地使用该 GPU，而不会对系统中的其他组件（包括 Hypervisor 和其他虚拟机）造成安全风险或干扰。
{: .prompt-tip }

### 硬件直通常见的用途
硬件直通主要用于对性能、兼容性或独占性有极高要求的场景：

| 设备类型        | 主要应用场景                                                                                                                           |
| :-------------- | :------------------------------------------------------------------------------------------------------------------------------------- |
| 显卡 (GPU)      | 高性能计算： 机器学习、深度学习训练。<br/>专业图形处理： CAD/CAM、视频渲染。<br/>游戏和桌面虚拟化： 提供接近原生的游戏性能或桌面体验。 |
| 网卡 (NIC)      | 网络功能虚拟化 (NFV)： 如虚拟路由器、防火墙等，对网络I/O性能要求极高。                                                                 |
| 存储控制器      | 允许虚拟机直接访问物理硬盘或 RAID 卡，用于建立存储服务器或存储池。                                                                     |
| USB 控制器/设备 | 允许虚拟机使用特殊的 USB 设备，例如加密狗、工业控制设备等。                                                                            |

### 实现硬件直通的先决条件
要成功实现硬件直通，通常需要满足以下几个条件：

- **CPU 支持**： 主机的 CPU 必须支持虚拟化技术中的 I/O 虚拟化功能，例如 Intel 的 VT-d 或 AMD 的 AMD-Vi (或称 AMD-V)。
- **主板/BIOS 支持**： 主板的 BIOS/UEFI 必须启用相应的虚拟化功能（如 VT-d/AMD-Vi）。
- **Hypervisor 支持**： 你使用的虚拟化软件（如 Proxmox, VMware ESXi, KVM/QEMU 等）需要支持硬件直通功能。
- **设备隔离 (IOMMU)**： 硬件设备必须能被 IOMMU 成功隔离到一个独立的 IOMMU 组中，才能安全地直通给虚拟机。

> 虽然功能和作用相同，但不同的 CPU 制造商给 IOMMU 起了不同的商品名：
>
> - Intel： VT-d (Virtualization Technology for Directed I/O)
> - AMD： AMD-Vi (或在较旧的文档中称为 IOMMU)
{: .prompt-tip }

## 硬件兼容性检查

点击进入[Intel Ark官方网站](https://www.intel.cn/content/www/cn/zh/ark.html) 或 [AMD 官方网站](https://www.amd.com/zh-cn/products/specifications.html)，搜索对应处理器型号(例如：[i9-13900K 传送门](https://www.intel.cn/content/www/cn/zh/products/sku/230496/intel-core-i913900k-processor-36m-cache-up-to-5-80-ghz/specifications.html)

如果看到下图内容，则说明CPU支持VT-D技术

![查询 Intel CPU是否支持VT-D](https://cdn.jsdelivr.net/gh/Optimus-Xs/Blog-Images/2023-09-11-enabling-iommu-for-hardware-pass-through-in-pve%2Fcpu-vt-check.jpg)

## 启用IOMMU功能
### Intel 平台

对于Intel CPU，在 Linux 内核引导参数中添加 `intel_iommu=on`，操作如下：

1. Shell 里面输入命令：`nano /etc/default/grub`
    ```bash
    root@pve:~# nano /etc/default/grub
    ```

2. 在里面找到：`GRUB_CMDLINE_LINUX_DEFAULT="quiet"` 然后修改为
    ```
    GRUB_CMDLINE_LINUX_DEFAULT="quiet intel_iommu=on"
    ```
    {: file='/etc/default/grub'}

    编辑完成后，使用快捷键 `Ctrl + O` 回车保存文件，`Ctrl + X` 退出编辑器。

3. 使用命令 `update-grub` 保存更改并更新 GRUB
    ```bash
    root@pve:~# update-grub
    ```

4. 更新完成后，使用命令 `reboot` 重启PVE系统
    ```bash
    root@pve:~# reboot
    ```
    然后运行 
    ```bash
    root@pve:~# dmesg | grep -e DMAR -e IOMMU
    ```
    - 如果没有输出，则说明有问题。
    - 如果有,可基本确认这个过程顺利完成! 接下来就可以为虚拟机正常的添加硬件直通了。


### AMD 平台

对于AMD CPU, 在 Linux 内核引导参数添加 `amd_iommu=on`, 操作如下：

1. Shell 里面输入命令：`nano /etc/default/grub`
    ```bash
    root@pve:~# nano /etc/default/grub
    ```

2. 在里面找到：`GRUB_CMDLINE_LINUX_DEFAULT="quiet"`
    然后修改为
    ```
    GRUB_CMDLINE_LINUX_DEFAULT="quiet amd_iommu=on"
    ```
    {: file='/etc/default/grub'}
    编辑完成后，使用快捷键 `Ctrl + O` 回车保存文件，`Ctrl + X` 退出编辑器。

3. 使用命令 `update-grub` 保存更改并更新GRUB
    ```bash
    root@pve:~# update-grub
    ```
4. 更新完成后，使用命令 `reboot` 重启PVE系统
    ```bash
    root@pve:~# reboot
    ```
    然后运行 
    ```bash
    root@pve:~# dmesg | grep -e DMAR -e IOMMU
    ```
    - 如果没有输出，则说明有问题。
    - 如果有,可基本确认这个过程顺利完成! 接下来就可以为虚拟机正常的添加硬件直通了。

## PVE中配置

在PVE中配置硬件直通需要先按照前面的步骤在BIOS和hypervisor配置综合启用IOMMU

否则在Proxmox VE(Proxmox Virtual Environment)PVE系统操作添加会出现如下错误: 

PCI设备 硬件直通提示：`No IOMMU detected, please activate it.See Documentation for further information.`

如下图所示：

![IOMMU错误提示](https://cdn.jsdelivr.net/gh/Optimus-Xs/Blog-Images/2023-09-11-enabling-iommu-for-hardware-pass-through-in-pve%2Fiommu-error-example.png)

### 启用 VFIO 核心模块

通过修改 `/etc/modules` 文件，你确保了系统在启动时会自动加载以下四个内核模块。这是 **VirtIO Function I/O (VFIO)** 技术栈的核心，是 Proxmox/KVM 实现安全硬件直通的官方和推荐方式。
```bash
root@pve:~# nano /etc/modules
```

添加如下内容:

```
vfio
vfio_iommu_type1
vfio_pci
vfio_virqfd
```
{: file='/etc/modules'}

保存后然后重启系统即可


| 模块名称         | 作用 (在硬件直通中的角色)                                                                                                       |
| :--------------- | :------------------------------------------------------------------------------------------------------------------------------ |
| `vfio`             | VFIO 核心框架。 提供用户空间驱动程序与 I/O 硬件通信的框架，是整个直通机制的基础。                                               |
| `vfio_iommu_type1` | IOMMU 接口。 负责与底层的 IOMMU 硬件进行交互。它根据 Hypervisor 的要求设置 IOMMU 的页表，实现设备到虚拟机内存的地址转换和隔离。 |
| `vfio_pci`         | PCI 设备驱动。 负责将 PCI 设备（如显卡、网卡）从内核驱动程序中解绑，并将其暴露给 VFIO 框架，以便虚拟机可以独占使用这些设备。    |
| `vfio_virqfd`      | 中断处理。 负责处理设备的中断请求，并将这些请求高效地路由给虚拟机。                                                             |

### 验证IOMMU和设备配置

1. 验证 IOMMU： 确认 IOMMU 是否已在内核引导参数中启用。
2. 验证 IOMMU Grouping： 检查你的目标硬件是否已正确分组，可以使用命令 `find /sys/kernel/iommu_groups/ -type l` 来查看。
    ```bash
    find /sys/kernel/iommu_groups/ -type l
    ```

3. 设备解绑/驱动黑名单： 将目标设备的驱动程序列入黑名单（例如，阻止 PVE 的 Linux 内核加载 NVIDIA 显卡驱动），确保 `vfio-pci` 驱动可以接管该设备。
4. 添加到虚拟机： 最后，通过 Proxmox VE 的 Web 界面或配置文件，将该 PCI 设备添加到特定的虚拟机配置中。
    
    ![PVE系统添加PCI设备开启硬件直通界面](https://cdn.jsdelivr.net/gh/Optimus-Xs/Blog-Images/2023-09-11-enabling-iommu-for-hardware-pass-through-in-pve%2Fpve-pci-passthrough-example.png)

> 虚拟机进行直通操作时，建议取消勾选`开机自启动`的选项，这样哪怕直通错误，只需重启一下物理机就可以了，因为虚拟机没有自启的原因就不会直通，不会因为冲突导致物理机无法正常启动。
{: .prompt-tip }

# 参考
- [Proxmox VE(PVE)系统开启IOMMU功能实现硬件直通](https://www.nasge.com/archives/137.html)