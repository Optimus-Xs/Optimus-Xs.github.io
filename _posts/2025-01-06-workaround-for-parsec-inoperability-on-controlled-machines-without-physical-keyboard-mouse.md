---
layout: post
title: Parsec 在被控机无硬件键鼠的时候无法操作的解决方案
date: 2025-01-06 21:22 +0800
categories: [Tech Projects]
tags: [Hardware, 远程控制]
---

## 故障表现和原因

在一些没有插入鼠标设备的物理机（或虚拟机）上面，Parsec就无法使用鼠标输入, 同时在移动端的Parsec客户端上不会显示鼠标

这个现象的原因源自于Parsec的设计：

> 如果主机没有物理鼠标，Windows 会显式移除光标，Parsec 也会忠实地重现这一行为。 [Parsec文档 - Mouse and Keyboard Isn't Working Correctly When Connected](https://support.parsec.app/hc/en-us/articles/32381827815188-Mouse-and-Keyboard-Isn-t-Working-Correctly-When-Connected)


## 解决方案
既然Windows在没有鼠标连接的情况下不会渲染鼠标, 那我们的解决方案就是欺骗 Windows 虚拟机，让它认为有一个永久连接的鼠标，或者通过软件强制显示指针。

具体实现有下面3种:

### Parsec 的虚拟鼠标设置
在 Parsec 设置的Host选项卡中启用 `Virtual Mouse` 设置。此设置会创建一个鼠标设备，该设备本身不会移动，但 Windows 可以识别它并恢复光标。此设置需要安装Parsec的虚拟 USB 驱动程序，可以使用[这个链接](https://builds.parsec.app/vud/parsec-vud-0.3.10.0.exe)下载

设置流程如下:

- 进入 Parsec 设置 (Settings)。
- 找到 主机 (Host) 选项卡。
- 找到 虚拟鼠标 (Virtual Mouse) 。
- 启用 (Enable) 此设置。
- 可能需要重启 Parsec 服务以确保设置生效。

![Parsec 虚拟鼠标](https://cdn.jsdelivr.net/gh/Optimus-Xs/Blog-Images/2025-01-06-workaround-for-parsec-inoperability-on-controlled-machines-without-physical-keyboard-mouse%2Fparsec-virtual-mouse.jpg)

### Windows 的鼠标键功能
这是一个 Windows 辅助功能，它能强制操作系统在任何情况下都显示并激活鼠标指针。

设置流程如下:

- 在 Windows 虚拟机内部，按下 `Windows 键 + I` 打开设置 (Settings)。
- 进入 辅助功能或轻松使用。
- 选择 鼠标。
- 找到并启用鼠标键 (Mouse Keys) 选项（通常是：“使用数字键盘移动鼠标指针”）。

![鼠标键设置](https://cdn.jsdelivr.net/gh/Optimus-Xs/Blog-Images/2025-01-06-workaround-for-parsec-inoperability-on-controlled-machines-without-physical-keyboard-mouse%2Fwindows-mouse-key.png)

### 第三方的虚拟鼠标
[MaxKruse/TabletDriver](https://github.com/MaxKruse/TabletDriver) 仓库是一个用于图形输入板（如 Wacom、Huion 等）的低延迟驱动程序，其最初的目的是为了提高这类设备在节奏游戏 (Rhythm Games)，尤其是 `osu!` 中的性能和响应速度。

这个驱动程序能间接解决 Parsec 虚拟机中的鼠标指针不显示/无法输入的问题，是因为它的核心机制是在虚拟机内部创建了一个稳定、可识别的输入设备。

它依赖一个名为 VMulti（Virtual Multi-touch）的驱动程序，在 Windows 操作系统中创建一个虚拟的 HID（Human Interface Device）输入设备, 通过安装这个驱动后，Windows 就会认为有一个功能齐全的、持续活跃的输入设备（即虚拟输入板）连接着。这强制 Windows 维护和显示一个活动的系统指针，并将输入事件（来自 Parsec 客户端的远程输入）映射到这个新创建的虚拟设备上，从而确保 Parsec 能够稳定地捕获和渲染鼠标。

设置流程如下:

- 在[Release页面](https://github.com/MaxKruse/TabletDriver/releases)下载 `TabletDriver.v0.3.1a.zip`
- 解压 `TabletDriver.v0.3.1a.zip` , 然后运行 `TabletDriver\bin\VMulti Installer GUI.exe`
- 根据软件UI提示安装 VMulti 驱动即可

# 参考
- [Parsec 解决无法使用鼠标没有指针无法输入问题](http://halo.naspro.cc/archives/1745893704389)