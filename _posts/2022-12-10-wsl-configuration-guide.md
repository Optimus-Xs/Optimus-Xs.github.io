---
layout: post
title: WSL 配置指南
date: 2022-12-10 00:00 +0800
categories: [ServerOperation]
tags: [Linux, Windows, 操作系统]
---

## WSL简介

WSL（Windows Subsystem for Linux）允许开发人员在 Windows 系统上直接运行 Linux 发行版，例如 Ubuntu、Debian、Kali 等，而无需传统虚拟机的复杂配置或双系统设置的开销。

🚀 WSL 的目标是为想要同时利用 Windows 和 Linux 的优势的开发人员提供一个无缝且高效的体验。

- 原生 Linux 环境： 你可以安装和运行各种 Linux 发行版，并直接使用 Linux 应用程序、实用工具和 Bash 命令行工具（如 `grep`、`sed`、`awk`、`vim`、`emacs` 等）。
- 完整的工具链： 可以运行 Bash 脚本和 GNU/Linux 命令行应用程序，支持各种开发语言（如 Python、NodeJS、C/C++、Go 等）和各种服务（如 SSHD、MySQL、Apache、MongoDB）。
- 文件系统互操作性： 可以在 Windows 文件系统中访问 Linux 文件，反之亦然。
- 图形界面支持 (WSL 2)： 最新的 WSL 版本支持直接运行 Linux 图形应用程序，它们可以很好地集成到 Windows 桌面中。
- GPU 加速： 可以利用设备的 GPU 来加速 Linux 上运行的机器学习等工作负载。

### WSL1

WSL 1 是 Windows 子系统技术推出的第一个版本，它提供了一种在 Windows 上运行 Linux 二进制文件的方式，而不使用传统的虚拟机（VM）。

#### 核心工作原理

WSL 1 的关键在于它不包含一个实际的 Linux 内核。相反，它工作的方式更像是一个兼容层或翻译层(类似于[Wine](https://www.winehq.org/))：

- 翻译系统调用： 当你在 WSL 1 中运行一个 Linux 程序时，该程序会发出 Linux 系统调用（syscalls）。WSL 1 负责实时拦截这些调用，并将它们翻译成 Windows NT 内核可以理解和执行的相应操作。
- 无原生内核： 因为没有真正的 Linux 内核，WSL 1 无法提供 100% 的系统调用兼容性。

#### 主要特点

- 轻量级： 与完整的虚拟机相比，WSL 1 的资源占用非常小，启动速度快。
- 文件系统互通： 对 Windows 文件系统的访问性能较好。
- 兼容性限制： 由于采用翻译层，它无法运行一些需要深度内核交互的应用程序，例如 Docker、特定的网络工具，或要求特定 Linux 内核版本的软件。

#### WSL 1 的主要限制

WSL 1 作为第一代架构，其最大的限制源于它不使用原生的 Linux 内核，而是依赖于系统调用翻译层。这导致了以下几个主要的具体限制：

WSL 1 的主要限制
1. 缺乏完整的系统调用兼容性

    这是 WSL 1 最核心的限制。

    - 无法运行 Docker： Docker 需要完整的 Linux 内核才能运行其容器化组件（例如，依赖于特定内核功能的 `cgroups` 和 `namespaces`）。WSL 1 无法提供这些原生功能。
    - 某些应用程序无法运行： 任何需要深度内核交互、特定文件系统功能或特定网络功能（例如特定的网络套接字或路由操作）的应用程序都可能无法运行，或者行为异常。

2. Linux 文件系统 I/O 性能差

    虽然 WSL 1 访问 Windows 文件系统（即 `/mnt/c/` 下的文件）的速度相对较快，但其自身 Linux 根目录下的文件系统（即 `/home/` 或 `/` 下的文件）的 I/O 性能通常比 WSL 2 慢得多。

    对于需要大量文件读写操作的工作负载，例如 Git 存储库克隆、代码编译、或数据库操作，WSL 1 的性能明显低于原生 Linux 或 WSL 2。


3. 不支持硬件加速或图形应用

      - 无 GPU 加速： WSL 1 无法利用 GPU 来加速计算工作负载，例如机器学习或科学计算（这是 WSL 2 的一个重要功能）。
      - 无 GUI 支持： WSL 1 架构不支持直接运行 Linux 图形应用程序（WSL 2 通过 [WSLg](https://github.com/microsoft/wslg) 提供了出色的 GUI 应用支持）。

### WSL2

WSL 2 对底层架构进行了重大革新，并利用虚拟化技术和 Linux 内核来实现新功能。

#### WSL 2 架构

传统的虚拟机体验启动缓慢、环境封闭、资源消耗大，而且需要花费时间进行管理。WSL 2 则不具备这些问题。

WSL 2 继承了 WSL 1 的所有优点，包括 Windows 和 Linux 之间的无缝集成、快速启动、资源占用少，并且无需配置或管理虚拟机。虽然 WSL 2 也使用虚拟机，但它在后台运行和管理，因此用户体验与 WSL 1 完全相同。

#### 完整的 Linux 内核

WSL 2 中的 Linux 内核由微软基于 kernel.org 提供的源代码，从最新的稳定分支构建而成。该内核针对 WSL 2 进行了专门优化，兼顾了体积和性能，旨在为 Windows 用户提供卓越的 Linux 使用体验。内核将通过 Windows 更新进行维护，这意味着无需自行管理即可获得最新的安全修复和内核改进。

WSL 2 Linux 内核是开源的。

#### 提高文件 I/O 性能

使用 WSL 2，文件密集型操作（如`git clone`、  `npm install`、  `apt update`、 `apt upgrade`等）的速度都明显更快。

实际速度提升取决于运行的应用程序以及它与文件系统的交互方式。WSL 2 的初始版本在解压缩压缩包时比 WSL 1 快 20 倍，在使用各种项目时速度提升约  2-5  倍`git clone`。 `npm install` `cmake`

#### 完全系统调用兼容性

Linux 二进制文件使用系统调用来执行诸如访问文件、请求内存、创建进程等功能。WSL 1 使用的是 WSL 团队构建的转换层，而 WSL 2 则包含了自己的 Linux 内核，并完全兼容系统调用。其优势包括：

可以在 WSL 中运行一系列全新的应用程序，例如Docker等。

Linux 内核的任何更新都可以立即使用（无需等待 WSL 团队实施更新和添加更改）。

### WSL1和2的区别

WSL 1 和 WSL 2 的主要区别在于：

WSL 2 在托管虚拟机 (VM) 内使用真正的 Linux 内核，支持完整的系统调用兼容性，以及在 Linux 和 Windows 操作系统上的卓越性能。WSL 2 是当前安装 Linux 发行版时的默认版本，它采用最新的虚拟化技术，在轻量级实用虚拟机 (VM) 内运行 Linux 内核。WSL 2 将 Linux 发行版作为隔离容器运行在托管 VM 内。

| 特征                                           | WSL 1 | WSL 2 |
| :--------------------------------------------- | :---- | :---- |
| Windows 和 Linux 的集成                        | ✅     | ✅     |
| 启动速度快                                     | ✅     | ✅     |
| 与传统虚拟机相比，资源占用更小                 | ✅     | ✅     |
| 可与最新版本的 VMware 和 VirtualBox 兼容运行。 | ✅     | ❌     |
| 托管虚拟机                                     | ❌     | ✅     |
| 完整的 Linux 内核                              | ❌     | ✅     |
| 完全系统调用兼容性                             | ❌     | ✅     |
| 跨操作系统文件系统的性能                       | ✅     | ❌     |
| systemd 支持                                   | ❌     | ✅     |
| IPv6 支持                                      | ✅     | ✅     |

WSL 2 架构在几个方面都优于 WSL 1，但跨操作系统文件系统的性能除外，这可以通过将项目文件存储在与用于处理项目的工具相同的操作系统上来解决。

WSL 2 仅适用于 Windows 11 或 Windows 10 版本 1903（内部版本 18362 或更高版本）。要查看 Windows 版本，请按Windows 徽标键 + R，输入`winver`，然后单击"确定"（或在 Windows 命令提示符中输入该`ver`命令）。对于低于 14393 的内部版本，WSL 完全不受支持。

> WSL 2 可与VMware 15.5.5及更高版本兼容。虽然VirtualBox 6 及更高版本声称支持 WSL，但实际上仍存在一些重大挑战，导致其无法获得支持
{: .prompt-tip }

**使用 WSL 1 而非 WSL 2 的例外情况**

- 项目文件必须存储在 Windows 文件系统中。WSL 1 可以更快地访问从 Windows 挂载的文件
- 一个需要使用 Windows 和 Linux 工具对同一文件进行交叉编译的项目
- 项目需要访问串口或 USB 设备
- 内存要求非常严格, 目前 WSL 2 尚不会将缓存在内存中的页面释放回 Windows，直到 WSL 实例关闭为止
- 依赖 Linux 发行版来获取与主机位于同一网络中的 IP 地址

## WSL1配置
### 启用 WSL 功能

以管理员身份打开 PowerShell 或 命令提示符，运行以下命令来启用 "适用于 Linux 的 Windows 子系统" 功能：

```shell
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
```

> 仅启用上述功能即可安装 WSL 1。如果你之前运行过 wsl --install，系统可能已经自动启用了所需的其他功能
{: .prompt-info }

> 如果使用的是 Windows 10 版本 2004 及更高版本或 Windows 11，请直接使用 `wsl --install`。这完全取代了手动运行 `dism.exe` 命令的繁琐过程。
{: .prompt-tip }

### 安装 Linux 发行版

前往 Microsoft Store，搜索你想安装的 Linux 发行版（例如 Ubuntu、Debian、Kali Linux 等），然后点击 “获取” 进行安装。

安装完成后，第一次运行它，系统会提示你创建**用户名**和**密码**。

### 检查并指定版本为 WSL 1

在安装完成后，你需要检查当前安装的版本，并将其设置为 WSL 1。

查看已安装的发行版及其版本： 以管理员身份打开 PowerShell，运行：

```shell
wsl --list --verbose
# 简写形式: wsl -l -v
```

输出结果应该如下: 

```shell
STATE     VERSION   NAME
Running   2         Ubuntu-22.04
```

将发行版设置为 WSL 1： 使用以下命令将你的发行版设置为 WSL 1。将 `<DistributionName>` 替换为你列表中显示的名称（如 `Ubuntu-22.04`）：

```shell
wsl --set-version Ubuntu-22.04 1
```

系统将需要几分钟时间进行转换。

验证版本： 转换完成后，再次运行 `wsl -l -v` 进行确认，`VERSION` 栏应该显示 1。

## WSL2配置
### BIOS配置
由于 WSL2 基于 Hyper-V 虚拟技术，所以需要提前在 BIOS 中开启虚拟化支持。

下面是常见主板厂家BIOS启用虚拟化的配置流程

**微星**

1. 开机按`DEL`进入BIOS，按`F7`进入高级模式
2. 进入高级模式，点击打开OC，找到"`CPU Features(CPU特征)`"菜单打开
3. 有一项为`SVM MODE`(AMD芯片组) / `Intel虚拟化技术`(Intel芯片组)，将此选项设置为`允许(Enabled)`，然后F10保存即可

**华硕**

1. 开机按`Del`/`F2`进bios之后，按`F7`切换到BIOS的`Advanced（高级）`模式（ROG系列bios预设进去就是高级模式，不需切换）
2. 按`F7`切换到高级模式
3. 选择`Advanced` - `CPU Configuration`
4. 选项往下拉，就会看到虚拟化的`lntel (VMX) Virtualization Technology`(Intel芯片组) / `SVM MODE`(AMD芯片组)选项了，预设就是`Enabled（开启）`的, 如果没有开启则设置为`Enabled`或者打开启用状态，然后`F10`保存即可

**技嘉**

1. 开机按`DEL`进入BIOS，点击`M.I.T.`选项，打开`ADvaced Frequency settings`
2. 打开`ADvaced CPU Core Setting`s
3. `SVM Mode`(AMD芯片组) / `Intel(R) Virtualization Technology`(Intel芯片组)设置成`Enabled` 状态 然后按`F10`并确认保存即可。

**华擎**

1. 开机屏幕亮起后不断按下`F2`键，进入BIOS页面
2. 进入BIOS页面后，找到`Advanced（高级）`——`CPU Configuration（CPU配置）`——`SVM Mode`(AMD芯片组) / `Intel(R) Virtualization Technology`(Intel芯片组)选项，把`Disabled`都修改为`Enabled`或者禁用修改为启用；
3. 按保存键`F10` 然后`保存并退出 （Save & Exit）`

**七彩虹**

1. 开机按`DEL`进入BIOS  点高级进入高级模式;
2. 在`处理器配置`项找到`SVM Mode`(AMD芯片组) / `Intel(R) Virtualization Technology`(Intel芯片组)，后面设置成`允许（enable）`，在按`F10`保存，接即可;

### WSL2安装

1. 在Windows中以管理员方式运行 PowerShell 或 Windows Terminal
2. 在终端窗口中输入：`wsl --install` 即可自动执行。
    ```shell
    wsl --install
    ```

    安装过程的输出如下:

    ![wsl安装命令输出情况](https://cdn.jsdelivr.net/gh/Optimus-Xs/Blog-Images/2022-12-10-wsl-configuration-guide%2Fwsl2-install-progress.png)

    > 仅当 WSL 还没有安装时，上述命令才有效。
    {: .prompt-tip }

3. 在完成 `已安装 GUI 应用支持` 后， 后重启。
4. 开机后调出终端，输入执行 `wsl --set-default-version 2` 将 WSL 默认版本调整为 WSL2
    ```shell
    wsl --set-default-version 2
    ```

    > 在较新的Windows版本中默认WSL版本为2, 可以跳过此步设置
    {: .prompt-tip }
5. 在 Microsoft Store 中找到对应发行版进行安装即可；也可通过命令行安装。
6. 命令行安装方法：`wsl -l -o`可查看可安装的发行版，记录发行版名称后，执行 `wsl --install --d NAME`即可安装。如： `wsl --install --d ubuntu-20.04` 可安装ubuntu20.04。
    ```shell
    wsl -l -o

    wsl --install --d ubuntu-20.04
    ```

    > 如果安装过程停在 `0.0%`，请先运行 `wsl --install --web-download -d <DistroName>` 下载发行版，然后再进行安装。
    {: .prompt-tip }

7. 安装完毕后，执行：`wsl -l -v`可查看安装的发行版的WSL版本。
    ```shell
    wsl -l -v
    ```

## 卸载WSL
### 卸载特定的 Linux 发行版

如果你只是想移除一个特定的 Linux 系统（例如，不再需要 `Ubuntu 22.04`），这是最简单和最推荐的方法

**方法 A: 通过 Windows 设置/应用管理器 (最简单)**

将 WSL 发行版视为一个普通的 Windows 应用程序进行卸载。

- 打开 Windows 设置。
- 导航到 应用 -> 应用和功能 (或 已安装的应用)。
- 在列表中找到你想要卸载的 Linux 发行版（例如，`Ubuntu 22.04 LTS`）。
- 点击发行版名称旁边的三个点 (...) 或直接点击它。
- 选择卸载。

**方法 B: 通过 wsl 命令行工具（如果发行版未在应用中列出）**

查找发行版的名称： 打开 PowerShell 或命令提示符，运行以下命令查看所有已安装的发行版名称：

```shell
wsl --list --all
```

查找发行版的名称： 打开 PowerShell 或命令提示符，运行以下命令查看所有已安装的发行版名称：

```shell
wsl --unregister <DistributionName>
```

例如，`Ubuntu 22.04 LTS`

```shell
wsl --unregister Ubuntu-22.04
```

### 完全卸载 WSL 平台
如果你希望彻底从系统中移除 WSL 功能，包括 WSL 1 和 WSL 2 的所有底层组件，请执行以下步骤

**步骤 1: 移除所有已安装的发行版**

首先，按照上述 方法 A 或 B 移除所有你通过 Microsoft Store 或 `wsl --import` 安装的 Linux 发行版。

**步骤 2: 禁用 WSL 和虚拟化平台组件**

以管理员身份打开 PowerShell 或 命令提示符，并运行以下 `dism.exe` 命令来禁用相关的 Windows 可选功能：

禁用 WSL 组件：

```shell
dism.exe /online /disable-feature /featurename:Microsoft-Windows-Subsystem-Linux /norestart
```

禁用 Hyper-V 虚拟化平台（如果安装了 WSL 2）：

```shell
dism.exe /online /disable-feature /featurename:VirtualMachinePlatform /norestart
```

禁用 Hyper-V 平台（可选，仅在手动启用了 Hyper-V 管理器时）:

```shell
dism.exe /online /disable-feature /featurename:HypervisorPlatform /norestart
```

**步骤 3: 重启电脑**

# 参考

- [如何使用 WSL 在 Windows 上安装 Linux](https://learn.microsoft.com/zh-cn/windows/wsl/install)
- [Windows 10/11 安装 WSL2 的简单方法](https://www.jianshu.com/p/6e7488440db2)