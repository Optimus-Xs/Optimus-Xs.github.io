---
layout: post
title: 奖任意exe文件注册为Windows服务
date: 2024-09-23 00:00 +0800
categories: [ServerOperation]
tags: [Windows]
---

## 应用场景
在Windows系统中，时长会遇到希望有些软件（比如`软件A`或者一段脚本文件）能够在开机后自动运行的情况，往往可惜的是`软件A`并不具备配置开机自启的功能, 或者脚本文件无法自动执行

通常要实现这个功能的常见方法有下面3种: 

- **任务计划程序**： 处理复杂的脚本和需要后台运行的程序。
- **启动文件夹**： 处理用户登录后需要快速启动且对运行环境要求不高的应用程序。
- **注册为 Windows 服务**： 处理需要系统级、持续运行且不依赖用户登录的程序。

但是:

- 任务计划程序:
  - 配置相对复杂： 相比于启动文件夹，创建任务需要打开工具并经历多个设置步骤。
  - 调试难度： 当任务失败时，需要查看任务历史日志来确定失败原因。
- 启动文件夹:
    - 依赖用户登录： 只有当特定用户登录系统后，程序才会启动。
    - 无法隐藏窗口： 默认情况下，脚本（如 `.bat` 或 `.py`）运行时会弹出命令行窗口。要隐藏窗口，必须依赖额外的 VBScript 或 PowerShell 包装。
    - 权限受限： 只能以当前登录用户的权限运行。

## WinSW简介

> WinSW 将任何应用程序封装并作为 Windows 服务进行管理, 并为其提供了一些额外的功能，如重新启动、日志记录、配置文件管理等。
{: .prompt-info }

[Windows Service Wrapper](https://github.com/winsw/winsw)是一个中间层程序，它的主要功能是充当 Windows 服务控制管理器 (Service Control Manager, SCM) 和要运行的实际应用程序或脚本之间的桥梁。

至于为什么要这种中间层才能把exe可执行文件注册为服务要从Windows的服务机制说起

### windows服务是什么
Windows 服务 (Windows Service) 是 Microsoft Windows 操作系统中的一种核心组件, 它是一种**特殊的应用程序类型**，它可以在没有用户界面的情况下，在后台连续运行。它们是为需要在系统启动时立即启动、不需要用户干预或用户登录即可运行的程序而设计的

**🔑 Windows 服务的核心特点**

1. **独立于用户会话**
    - 无需登录： 服务可以在操作系统启动后立即启动，不需要任何用户登录到 Windows 桌面。这是它与“启动文件夹”和“注册表 Run 键”启动程序的根本区别。
    - 持续运行： 即使所有用户都注销，服务也可以保持运行。
2. **后台运行（无 UI）**
    - 服务通常没有图形用户界面（GUI）。它们设计为静默运行，执行后台处理、监控、服务器功能或设备管理。
    - 它们不能直接与用户桌面环境交互，但可以通过其他机制（如日志、网络接口）间接提供功能。
3. **由服务控制管理器 (SCM) 管理**
    - Windows 服务由一个名为 服务控制管理器 (Service Control Manager, SCM) 的操作系统组件集中管理。
    - SCM 负责服务的启动、停止、暂停、查询状态以及处理错误。可以通过服务管理器 (`services.msc`) 工具来查看和管理所有服务。
4. **高级权限和可靠性**
    - 服务可以配置使用特殊的系统账户（如 Local System 或 Network Service）运行，这些账户拥有比普通用户更高的系统权限。
    - SCM 提供了内置的恢复机制，如果服务意外停止或崩溃，可以配置它自动重启，以提高系统的可靠性。

### 标准exe执行文件和Windows服务的区别
标准的可执行文件（Standard EXE）和 Windows 服务（Windows Service）虽然都是可执行文件（最终都是 `.exe` 格式），但在它们的设计目的、运行环境、生命周期和与操作系统的交互方式上有很大的区别

1. **启动和控制机制（最根本的区别）**
    - 标准 EXE： 它们的生命周期是简单的“`启动-运行-退出`”。它们由用户、任务计划程序或启动文件夹直接启动，并在任务完成后或用户关闭窗口时结束。
    - Windows 服务： 它们不通过标准方式启动。它们由特殊的 服务控制管理器 (SCM) 启动。服务程序必须包含特定的代码（服务 API）来响应 SCM 的命令：
        - `ServiceMain()`: 服务的主入口点。
        - `Handler()`: 接收 SCM 发来的控制命令（如启动、停止、暂停）。
2. **运行环境与会话**
    - 标准 EXE： 运行在当前登录用户的用户会话中。如果用户注销，其会话中的所有程序（包括 EXE）都会终止。
    - Windows 服务： 运行在特殊的 `Session 0` 或其他独立会话中。这意味着它们可以在没有用户登录或用户注销的情况下继续运行，非常适合执行系统维护、网络监控等任务。
3. **权限与安全**
    - 标准 EXE： 权限受到启动该程序的用户账户的限制。
    - Windows 服务： SCM 允许管理员为服务指定专用的系统账户（例如 Local System），该账户拥有对系统资源（如注册表、文件系统）的极高权限，这对于需要底层访问的系统组件至关重要。

### WinSW的实现原理
根据上面的服务对比, 一个标准的 EXE 文件要想被 **Windows 服务控制管理器 (SCM)** 识别并作为服务运行，它必须补充或内置以下几个关键功能，即实现 **Windows 服务 API 规范**

1. **服务的主入口点**
    
    标准的 EXE 使用 `main()` 或 `WinMain()` 作为入口点。服务 EXE 必须提供一个特殊的函数作为服务的主入口点，通常称为 `ServiceMain()` 函数。
    
    当 SCM 启动服务时，它会调用这个函数。`ServiceMain()` 负责初始化服务，并向 SCM 报告服务已经开始运行。

2. **服务状态处理**
    
    服务必须能够实时地向 SCM 报告其当前的状态，这些状态包括：
    
    - `SERVICE_START_PENDING`: 正在启动中。
    - `SERVICE_RUNNING`: 正在正常运行。
    - `SERVICE_STOP_PENDING`: 正在停止中。
    - `SERVICE_STOPPED`: 已停止。
    - `SERVICE_PAUSE_PENDING` / SERVICE_PAUSED: 暂停或正在暂停中（如果服务支持暂停）。
    
    一个关键的 API 函数是 `SetServiceStatus`，服务程序必须定期或在状态变化时调用它来更新 SCM 的视图。

3. **服务控制处理程序**
    
    服务必须注册一个 控制处理函数 (Service Control Handler)，用于接收 SCM 发来的控制命令。
    
    SCM 通过这个处理函数向服务发送指令，例如：

    - `SERVICE_CONTROL_STOP` (停止): 服务必须立即开始清理工作并停止运行。
    - `SERVICE_CONTROL_PAUSE` / `SERVICE_CONTROL_CONTINUE` (暂停/继续): 如果服务支持这些功能，它需要执行相应的操作。
    - `SERVICE_CONTROL_SHUTDOWN` (系统关机): 提醒服务系统即将关机，进行最后的清理工作。

4. **线程管理**
    
    服务的主线程在初始化完成后，必须持续运行。它通常会启动一个或多个工作线程来执行实际的后台任务，而主线程则负责保持与 SCM 的通信。
    
    在 SCM 发出停止指令后，服务必须优雅地关闭所有工作线程，完成清理，然后向 SCM 报告 `SERVICE_STOPPED` 状态。

正因为一个普通的 EXE 缺乏上述四个功能，所以才需要 WinSW：

- WinSW 是一个实现了所有这些 API 的 EXE。
- 当 SCM 启动 WinSW 时，WinSW 接收到 `ServiceMain` 调用和控制指令。
- WinSW 自己不执行任何实际任务，它只是读取配置，然后启动原始 EXE 作为它的子进程。
- 当 WinSW 收到 `停止` 指令时，它不会停止自己，而是将这个 `停止` 指令转换为标准的操作系统信号（例如 `WM_CLOSE` 或进程终止请求）发送给原始 EXE 进程。
- WinSW 监控原始 EXE 进程。如果原始 EXE 崩溃，WinSW 可以向 SCM 报告失败，或自动重启它。

因此，服务包装器 充当了中间层，让普通 EXE 获得了服务的特性，而无需修改原始代码。

## WinSW 配置流程
### 下载WinSW

在 WinSW 的[GitHub Releases](https://github.com/winsw/winsw/releases)下载符合你的设备的exe文件, 并重命名(可选)成`winsw.exe`方便后续使用。

### 编写配置文件

在`winsw.exe`的同级创建一个和winsw同名的`winsw.xml`配置文件，`exe`和`xml`可以修改文件名称，保持同名即可

![winsw目录结构](https://cdn.jsdelivr.net/gh/Optimus-Xs/Blog-Images/2024-09-23-registering-arbitrary-exe-files-as-windows-services%2Fwinsw-folder.png)

然后编辑`winsw.xml`配置文件, 根据下面的模板文件填入你想注册的服务信息, 这是WinSW项目组对于配置文件的[完整说明文档地址](https://github.com/winsw/winsw/blob/v3/docs/xml-config-file.md)

```xml
<service>
	<!-- 该服务的唯一标识 -->
    <id></id>
    <!-- 该服务的名称 -->
    <name></name>
    <!-- 该服务的描述 -->
    <description></description>
    <!-- 要运行的程序路径 -->
    <executable></executable>
    <!-- 携带的参数 -->
    <arguments></arguments>
    <!-- 日志模式 -->
    <logmode></logmode>
    <!-- 指定日志文件目录(相对于executable配置的路径) -->
    <logpath></logpath>
</service>
```

此处以frp客户端为例, 配置文件如下

```xml
<service>
	<!-- 该服务的唯一标识 -->
    <id>frpc</id>
    <!-- 该服务的名称 -->
    <name>frpc_0.43.0-windows-amd64</name>
    <!-- 该服务的描述 -->
    <description>frp内网穿透-客户端</description>
    <!-- 要运行的程序路径 -->
    <executable>D:\frp_0.43.0\frpc.exe</executable>
    <!-- 携带的参数 -->
    <arguments>-c D:\frp_0.43.0\frpc.ini</arguments>
    <!-- 第一次启动失败 60秒重启 -->
    <onfailure action="restart" delay="60 sec"/>
    <!-- 第二次启动失败 120秒后重启 -->
    <onfailure action="restart" delay="120 sec"/>
    <!-- 日志模式 -->
    <logmode>append</logmode>
    <!-- 指定日志文件目录(相对于executable配置的路径) -->
    <logpath>logs</logpath>
</service>
```
### 注册服务

在写完配置文件后就可以使用WinSW提供的命令将程序注册为服务了, 在WinSW的目录启动CMD或者PowerShell

```shell
winsw.exe install # 使用install命令注册一个服务
winsw.exe start # 然后启动服务
```

这样就完成了服务的注册和启动, 其他一些WinSW的常见命令如下:

```shell
winsw.exe uninstall   # //卸载服务
winsw.exe stop    # //停止服务
winsw.exe restart     # //重启服务
winsw.exe status  # //查看服务状态
winsw.exe refresh  # //在不重新注册服务的情况看下更新服务的配置属性
```

# 参考
- [windows将frp或其他应用配置为service服务并开机自启](https://www.cnblogs.com/zhang1f/p/18347387)