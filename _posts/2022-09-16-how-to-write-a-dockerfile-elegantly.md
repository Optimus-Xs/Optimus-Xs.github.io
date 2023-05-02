---
layout: post
title: 如何优雅的编写Dockerfile
date: 2022-09-16 20:07 +0800
categories: [Software Development] 
tags: [Docker]
---

容器需要从Dockerfile开始，本文将介绍如何写出一个优雅的Dockerfile文件。

# Docker容器

## 容器的特点
我们都知道容器就是一个标准的软件单元，它有以下特点：

- 随处运行：容器可以将代码与配置文件和相关依赖库进行打包，从而确保在任何环境下的运行都是一致的。
- 高资源利用率：容器提供进程级的隔离，因此可以更加精细地设置CPU和内存的使用率，进而更好地利用服务器的计算资源。
- 快速扩展：每个容器都可作为单独的进程予以运行，并且可以共享底层操作系统的系统资源，这样一来可以加快容器的启动和停止效率。
- 轻量：容器是进程级的资源隔离，而虚拟机是操作系统级的资源隔离，所以Docker容器相对于虚拟机来说可以节省更多的资源开销，因为Docker容器不再需要GuestOS这一层操作系统了。
- 快速：容器的启动和创建无需启动GuestOS，可以实现秒级甚至毫秒级的启动。
- 可移植性：Docker容器技术是将应用及所依赖的库和运行时的环境技术改造包成容器镜像，可以在不同的平台运行。
- 自动化：容器生态中的容器编排工作（如：Kubernetes）可帮助我们实现容器的自动化管理。

## Docker容器
目前市面上的主流容器引擎有Docker、Rocket/rkt、OpenVZ/Odin等等，而独霸一方的容器引擎就是使用最多的Docker容器引擎。

Docker容器是与系统其他部分隔离开的一系列进程，运行这些进程所需的所有文件都由另一个镜像提供，从开发到测试再到生产的整个过程中，Linux 容器都具有可移植性和一致性。相对于依赖重复传统测试环境的开发渠道，容器的运行速度要快得多，并且支持在多种主流云平台（PaaS）和本地系统上部署。Docker容器很好地解决了“开发环境能正常跑，一上线就各种崩”的尴尬。

# Dockerfile
Dockerfile是用来描述文件的构成的文本文档，其中包含了用户可以在使用行调用以组合Image的所有命令，用户还可以使用Docker build实现连续执行多个命令指今行的自动构建。

通过编写Dockerfile生磁镜像，可以为开发、测试团队提供基本一致的环境，从而提升开发、测试团队的效率，不用再为环境不统一而发愁，同时运维也能更加方便地管理我们的镜像。

## Dockerfile语法

### Dockerfile格式
```dockerfile
# Comment
INSTRUCTION arguments
```

虽然Dockerfile并不区分大小写，但还是约定指令使用大写。

Docker按顺序运行Dockerfile中的指令。一个Dockerfile必须以FROM指令开始。这可能是在解析器指令、注释和全局范围的ARG之后。FROM指令指定了你要构建的父镜像。FROM前面只能有一个或多个ARG指令，这些指令声明了Dockerfile中FROM行使用的参数。

Docker将以#开头的行视为注释，除非该行是一个有效的解析指令(parser directives)。一行中其他地方的#标记被视为一个参数。这允许像这样的语句。

```dockerfile
# directive=value1

FROM ImageName
```

解析指令是可选的，虽然不区分大小写，但还是约定使用小写。
解析指令会影响到Dockerfile的解析逻辑，并且不会生成图层，也不会在构建时显示。解析指令只能出现在Dockerfile头部，并且一条解析指令只能出现一次。如果碰到注释、Dockerfile指令或空行，接下来出现的解析指令都无效，被当做注释处理。不支持续行。

目前仅支持 `syntax` `escape` 两个解析器指令

- syntax
    语法格式：
    ```Dockerfile
    # syntax = <builder>
    ```
    该指令可以用于选择不同的构建器（Builder），以及切换到不同的语法版本。例如，如果您想要使用BuildKit作为构建器，则可以在Dockerfile中添加以下语句：
    ```Dockerfile
    # syntax = docker/dockerfile:experimental
    ```
    且此功能仅在使用BuildKit 后端时可用，在使用经典构建器后端时将被忽略。
    [Custom Dockerfile syntax](https://docs.docker.com/build/buildkit/dockerfile-frontend/)

- escape
    该escape指令设置用于转义字符的字符 Dockerfile。如果未指定，则默认转义字符为\

    将转义字符设置为 在`上特别有用 Windows，其中\是目录路径分隔符。`与Windows PowerShell一致

    ```Dockerfile
    # escape=`
    ```

    上面的例子将转义字符设置为反引号（`），并且后续的反斜杠将被视为普通字符而不是转义字符。

Dockerfile解析指令可以用于修改Dockerfile的解析方式，从而增强其灵活性和可扩展性

解析指令详细文档参考[Docker文档](https://docs.docker.com/engine/reference/builder/#parser-directives)


### Dockerfile命令集

| 命令        | 说明                                                                                   |
| :---------- | :------------------------------------------------------------------------------------- |
| FROM        | 基于哪个镜像来实现                                                                     |
| MAINTAINER  | 为构建的镜像设置作者信息(已被弃用)                                                                  |
| LABEL       | 给构建的镜像打标签                                                                     |
| ENV         | 声明环境变量                                                                           |
| ARG         | 指定了用户在 `docker build --build-arg` 时可以使用的参数                               |
| RUN         | 执行的命令添加宿主机文件到容器里，有需要解压的文                                       |
| CMD         | run后面跟启动命令会被覆盖掉                                                            |
| ENTRYPOINT  | 与CMD功能相同，但需docker run 不会覆盖，如果需要覆盖可增加参数-entrypoint来覆盖        |
| ADD         | 件会自动解压                                                                           |
| COPY        | 添加宿主机文件到容器里                                                                 |
| WORKDIR     | 工作目录                                                                               |
| EXPOSE      | 容器内应用可使用的端口容器启动后所执行的程序，如果执行docker                           |
| VOLUME      | 将宿主机的目录挂载到容器里                                                             |
| USER        | 为接下来的Dockerfile指令指定用户                                                       |
| ONBUILD     | 向镜像中添加一个触发器，当以该镜像为base image再次构建新的镜像时，会触发执行其中的指令 |
| STOPSIGNAL  | 容器结束时触发系统信号                                                                 |
| HEALTHCHECK | 增加自定义的心跳检测功能                                                               |
| SHELL       | 更改后续的Dockerfile指令中所使用的shell                                                |

#### FROM

构建的镜像继承自某个base image。格式:
```Dockerfile
FROM [--platform=<platform>] <image> [AS <name>]
FROM [--platform=<platform>] <image>[:<tag>] [AS <name>]
FROM [--platform=<platform>] <image>[@<digest>] [AS <name>]
```
FROM指令必须是Dockerfile的第一个指令，可以使用多次来构建多个镜像，以最后一个镜像的ID为输出值。
tag和digest是可选的，如果不提供则使用latest。

该FROM指令初始化一个新的构建阶段并为后续指令设置 基础映像。因此，有效Dockerfile必须以指令开始FROM。该图像可以是任何有效图像——从公共存储库中拉取图像开始特别容易。

`ARG` `FROM`是. 中可能先于的唯一指令Dockerfile。
`FROM`可以在单个中出现多次Dockerfile以创建多个图像或使用一个构建阶段作为另一个构建阶段的依赖项。只需记下每条新指令之前提交输出的最后一个图像 ID FROM。每条FROM指令都会清除之前指令创建的任何状态。
`AS name` 可选，可以通过添加到 指令来为新构建阶段指定名称`FROM`。`FROM`该名称可以在后续和 说明中使用`COPY --from=<name>`，以引用此阶段构建的镜像。
或值是可选`tag`的`digest`。如果您省略其中任何一个，构建器将`latest`默认采用一个标记。如果构建器找不到该`tag`值，则会返回错误。
可选`--platform`标志可用于指定图像的平台，以防`FROM`引用多平台图像。例如，`linux/amd64`、 `linux/arm64`或`windows/amd64`。默认情况下，使用构建请求的目标平台。可以在此标志的值中使用全局构建参数，例如自动平台 `ARG` 允许您将阶段强制为本机构建平台 (`--platform=$BUILDPLATFORM`)，并使用它交叉编译到阶段内的目标平台。


通常情况下，在编写 Dockerfile 时，需要基于一个已经存在的镜像构建。因此，你需要在 FROM 指令中指定你要基于哪个镜像进行构建。

如果你想从零开始创建一个全新的 Docker 镜像，则可以考虑使用一个最小化的基础镜像，例如 `scratch`。这个镜像并不包含任何操作系统组件或应用程序，它只提供了一个空白的文件系统。因此，你可以根据需要添加自己的应用程序和依赖项。

以下是一个简单的例子：
```Dockerfile
FROM scratch

# 添加应用程序二进制文件
COPY myapp /myapp

# 设置容器启动命令
CMD ["/myapp"]
```
在这个例子中，我们首先指定了 FROM scratch，表示我们要从空白镜像开始构建。接着，我们将 myapp 应用程序复制到容器中，并设置容器启动命令为 /myapp。

注意，从零开始构建 Docker 镜像可能需要一些额外的工作和配置，因为你需要自己设置运行环境和依赖项。因此，如果你可以使用现有的基础镜像来构建你的应用程序，那么通常会更加容易和高效。

**ARG 和 FROM 是如何交互的**
FROMinstructions 支持由ARG 在第一条指令之前发生的任何指令声明的变量FROM。

```Dockerfile
ARG  CODE_VERSION=latest
FROM base:${CODE_VERSION}
CMD  /code/run-app

FROM extras:${CODE_VERSION}
CMD  /code/run-extras
```
在`FROM`之前声明的`ARG`位于构建阶段之外，因此无法在`FROM`之后的任何指令中使用。要使用在第一个`FROM`之前声明的`ARG`的默认值，请在构建阶段内使用不带值的ARG指令：`ARG`

```Dockerfile
ARG VERSION=latest
FROM busybox:$VERSION
ARG VERSION
RUN echo $VERSION > image_version
```

#### MAINTAINER (deprecated)
```Dockerfile
MAINTAINER <name>
```
该MAINTAINER指令设置生成图像的作者字段。该LABEL指令是一个更灵活的版本，您应该改用它，因为它可以设置您需要的任何元数据，并且可以轻松查看，例如使用docker inspect. 要设置与您可以使用的字段相对应的标签 MAINTAINER：

```Dockerfile
LABEL org.opencontainers.image.authors="SvenDowideit@home.org.au"
```
这将从docker inspect其他标签中可见。

#### LABEL
LABEL <key>=<value> <key>=<value> <key>=<value> ...
该LABEL指令将元数据添加到图像中。ALABEL是键值对。要在值中包含空格LABEL，请像在命令行解析中一样使用引号和反斜杠。几个使用示例：


LABEL "com.example.vendor"="ACME Incorporated"
LABEL com.example.label-with-value="foo"
LABEL version="1.0"
LABEL description="This text illustrates \
that label-values can span multiple lines."
一张图片可以有多个标签。您可以在一行中指定多个标签。在 Docker 1.10 之前，这会减小最终映像的大小，但现在已不再如此。您仍然可以选择通过以下两种方式之一在一条指令中指定多个标签：


LABEL multi.label1="value1" multi.label2="value2" other="value3"

LABEL multi.label1="value1" \
      multi.label2="value2" \
      other="value3"

>请务必使用双引号而不是单引号。特别是当您使用字符串插值时（例如LABEL example="foo-$ENV_VAR"），单引号将按原样使用字符串而不解包变量的值。
>
>基础图像或父图像（行中的图像FROM）中包含的标签由您的图像继承。如果标签已存在但具有不同的值，则最近应用的值会覆盖任何先前设置的值。
{: .prompt-info }

#### ENV
在构建的镜像中设置环境变量，在后续的Dockerfile指令中可以直接使用，也可以固化在镜像里，在容器运行时仍然有效。格式：

`ENV <key> <value>：`把第一个空格之后的所有值都当做`<key>`的值，无法在一行内设定多个环境变量。

`ENV <key>=<value> ...：`可以设置多个环境变量，如果`<value>`中存在空格，需要转义或用引号"括起来。

docker推荐使用第二种，因为可以在一行中写多个环境变量，减少图层。如下：

```Dockerfile
ENV MY_NAME="John Doe" MY_DOG=Rex\ The\ Dog \
    MY_CAT=fluffy
```

>注意
>
>可以在容器运行时指定环境变量，替换镜像中的已有变量，docker run --env <key>=<value>。
> 
>使用ENV可能会对后续的Dockerfile指令造成影响，如果只需要对一条指令设置环境变量，可以使用这种方式：RUN <key>=<value> <command>
{: .prompt-info }

>ENV当容器从生成的图像运行时，使用的环境变量设置将持续存在。您可以使用 查看值docker inspect，并使用 更改它们docker run --env <key>=<value>。
{: .prompt-info }

如果环境变量只在构建期间需要，而不是在最终图像中，请考虑为单个命令设置一个值：
```Dockerfile
RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y ...
```
或者使用ARG，它不会保留在最终图像中：
```Dockerfile
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y ...
```

#### ARG
指定了用户在 `docker build --build-arg <varname>=<value>` 时可以使用的参数

```Dockerfile
ARG <name>[=<default value>]
```
构建参数在定义的时候生效而不是在使用的时候。如下面第三行开始的user才是用户构建参数传递过来的user：
```Dockerfile
FROM busybox
USER ${user:-some_user}
ARG user
USER $user
```
后续的ENV指令会覆盖同名的构建参数，正常用法如下：
```Dockerfile
FROM ubuntu
ARG CONT_IMG_VER
ENV CONT_IMG_VER ${CONT_IMG_VER:-v1.0.0}
RUN echo $CONT_IMG_VER
```
docker内置了一批构建参数，可以不用在Dockerfile中声明：`HTTP_PROXY`、`http_proxy`、`HTTPS_PROXY`、`https_proxy`、`FTP_PROXY`、`ftp_proxy`、`NO_PROXY`、`no_proxy`

注意
在使用构建参数(而不是在构建参数定义的时候)的指令中，如果构建参数的值发生了变化，会导致该指令发生变化，会重新寻找缓存。

在Dockerfile中，ENV和ARG指令都被用来设置环境变量，但它们之间有一些区别。

- ARG指令是在构建过程中定义一个变量，可以通过--build-arg选项覆盖默认值。这样可以将构建参数传递给Dockerfile，并在构建期间使用它们。ARG变量在构建后不会存在于容器中。

- ENV指令用于在容器中设置环境变量。与ARG不同，ENV指令在运行容器时创建环境变量，并将其持久化到容器中。这意味着在容器运行时可以使用这些环境变量。

总之，ARG指令用于在构建期间定义变量，而ENV指令用于在容器运行时设置环境变量。


#### RUN

在镜像的构建过程中执行特定的命令，并生成一个中间镜像。格式:
```Dockerfile
RUN <command>：shell格式
RUN ["executable", "param1", "param2"]：exec格式
```
RUN指令将在当前镜像的新层中执行任何命令并提交结果。生成的提交镜像将用于Dockerfile中下一步骤。

分层RUN指令和生成提交符合Docker的核心概念，其中提交是廉价的，容器可以从镜像历史记录的任何点创建，就像源代码控制一样。

使用exec形式可以避免shell字符串处理，并使用不包含指定shell可执行文件的基础映像运行命令。

默认情况下，使用shell形式的shell可以使用SHELL命令更改。

在shell形式中，您可以使用\（反斜杠）将单个RUN指令延续到下一行。例如，请考虑以下两行：
```Dockerfile
RUN /bin/bash -c 'source $HOME/.bashrc && \
echo $HOME'
```
它们一起相当于这一行：

```Dockerfile
RUN /bin/bash -c 'source $HOME/.bashrc && echo $HOME'
```
要使用除“/bin/sh”之外的其他 shell，请使用传入所需 shell 的exec形式。例如：

```Dockerfile
RUN ["/bin/bash", "-c", "echo hello"]
```

>exec形式被解析为 JSON 数组，这意味着您必须在单词周围使用双引号 (") 而不是单引号 (') 。
{: .prompt-warning }

与shell形式不同，exec形式不调用命令 shell。这意味着正常的 shell 处理不会发生。例如， `RUN [ "echo", "$HOME" ]`不会对 进行变量替换$HOME。如果您想要 shell 处理，那么要么使用shell形式，要么直接执行 shell，例如：`RUN [ "sh", "-c", "echo $HOME" ].` 当使用exec形式直接执行shell时，如shell形式，是shell在做环境变量扩展，而不是docker。

> 在JSON形式中，需要对反斜杠进行转义。这在反斜杠是路径分隔符的 Windows 上尤为重要。由于不是有效的 JSON，以下行将被视为shell形式，并以意外的方式失败：
> 
> ```Dockerfile
> RUN ["c:\windows\system32\tasklist.exe"]
> ```
> 此示例的正确语法是：
> 
> ```Dockerfile
> RUN ["c:\\windows\\system32\\tasklist.exe"]
> ```
{: .prompt-warning }

指令缓存RUN不会在下一次构建期间自动失效。类似指令的缓存 RUN apt-get dist-upgrade -y将在下一次构建期间重复使用。可以使用标志使指令RUN缓存失效--no-cache ，例如docker build --no-cache。

有关详细信息，请参阅[Dockerfile最佳实践指南](https://docs.docker.com/engine/userguide/eng-image/dockerfile_best-practices/)。

指令的缓存RUN可以由指令ADD和COPY指令使之失效。

#### CMD
该CMD指令具有三种形式：
```Dockerfile
CMD ["executable","param1","param2"]（exec形式，这是首选形式）
CMD ["param1","param2"]（作为ENTRYPOINT 的默认参数）
CMD command param1 param2（外壳形式）
```
CMD一个文件中只能有一条指令Dockerfile。如果您列出多个，CMD 则只有最后一个CMD会生效。

CMD的主要目的是为正在执行的容器提供默认值。这些默认值可以包含可执行文件，也可以省略可执行文件，在这种情况下，您还必须指定一条ENTRYPOINT 指令。

>如果CMD用于为ENTRYPOINT指令提供默认参数，则CMD和ENTRYPOINT指令都应使用 JSON 数组格式指定。
>
>与RUN指令的区别：RUN在构建的时候执行，并生成一个新的镜像，CMD在容器运行的时候执行，在构建时不进行任何操作。
{: .prompt-info }

#### ENTRYPOINT
ENTRYPOINT 有两种形式：

exec形式，这是首选形式：

```Dockerfile
ENTRYPOINT ["executable", "param1", "param2"]
```
外壳形式：

```Dockerfile
ENTRYPOINT command param1 param2
```
将ENTRYPOINT您配置将作为可执行文件运行的容器。

*CMD 和 ENTRYPOINT 是如何交互的*
CMD和指令都ENTRYPOINT定义了运行容器时执行的命令。很少有规则描述他们的合作。

- Dockerfile 应指定至少一个CMD或ENTRYPOINT命令。

- ENTRYPOINT应该在将容器用作可执行文件时定义。

- CMD应该用作为命令定义默认参数ENTRYPOINT或在容器中执行临时命令的一种方式。

- CMD在使用替代参数运行容器时将被覆盖。

下表显示了针对不同ENTRYPOINT/CMD组合执行的命令：

| Company                     | 没有ENTRYPOINT             | 没有ENTRYPOINT exec_entry p1_entry | ENTRYPOINT ["exec_entry","p1_entry"]           |
| :-------------------------- | :------------------------- | :--------------------------------- | :--------------------------------------------- |
| 没有CMD                     | 错误，不允许               | /bin/sh -c exec_entry p1_entry     | exec_entry p1_entry                            |
| CMD ["exec_cmd", "p1_cmd "] | exec_cmd p1_cmd            | /bin/sh -c exec_entry p1_entry     | exec_entry p1_entry exec_cmd p1_cmd            |
| CMD exec_cmd p1_cmd         | /bin/sh -c exec_cmd p1_cmd | /bin/sh -c exec_entry p1_entry     | exec_entry p1_entry /bin/sh -c exec_cmd p1_cmd |

>如果CMD是从基本图像定义的，则设置ENTRYPOINT将重置CMD为空值。在这种情况下，CMD必须在当前图像中定义一个值。
{: .prompt-info }

#### ADD
在构建镜像时，复制上下文中的文件到镜像内，格式：
```Dockerfile
ADD [--chown=<user>:<group>] [--checksum=<checksum>] <src>... <dest>
ADD [--chown=<user>:<group>] ["<src>",... "<dest>"]
```

包含空格的路径需要后一种形式。


>该--chown功能仅在用于构建 Linux 容器的 Dockerfile 上受支持，不适用于 Windows 容器。由于用户和组所有权概念不会在 Linux 和 Windows 之间转换，因此使用和将/>etc/passwd用户/etc/group和组名转换为 ID 限制了此功能仅适用于基于 Linux 操作系统的容器。
{: .prompt-info }

该ADD指令从中复制新文件、目录或远程文件 URL `<src>` ，并将它们添加到路径中图像的文件系统中`<dest>`。

可以指定多个`<src>`资源，但如果它们是文件或目录，则它们的路径被解释为相对于构建上下文的源。

每个都可能包含通配符，匹配将使用 Go 的filepath.Match`<src>`规则完成 。例如：

添加以“hom”开头的所有文件：

```Dockerfile
ADD hom* /mydir/
```
在下面的示例中，?被替换为任何单个字符，例如“home.txt”。

```Dockerfile
ADD hom?.txt /mydir/
```
是`<dest>`绝对路径，或相对于 的路径WORKDIR，源将被复制到目标容器内。

下面的示例使用相对路径，并将“test.txt”添加到`<WORKDIR>`/relativeDir/：

```Dockerfile
ADD test.txt relativeDir/
```
而此示例使用绝对路径，并将“test.txt”添加到/absoluteDir/

```Dockerfile
ADD test.txt /absoluteDir/
```
当添加包含特殊字符（例如[ and ]）的文件或目录时，您需要按照 Golang 规则对这些路径进行转义，以防止它们被视为匹配模式。例如，要添加名为 的文件arr[0].txt，请使用以下命令；

```Dockerfile
ADD arr[[]0].txt /mydir/
```
所有新文件和目录都使用 0 的 UID 和 GID 创建，除非可选标志--chown指定给定的用户名、组名或 UID/GID 组合以请求所添加内容的特定所有权。标志的格式--chown允许用户名和组名字符串或直接整数 UID 和 GID 的任意组合。提供不带组名的用户名或不带 GID 的 UID 将使用与 GID 相同的数字 UID。如果提供了用户名或组名，容器的根文件系统 /etc/passwd和/etc/group文件将分别用于执行从名称到整数 UID 或 GID 的转换。以下示例显示了标志的有效定义--chown：

```Dockerfile 
ADD --chown=55:mygroup files* /somedir/
ADD --chown=bin files* /somedir/
ADD --chown=1 files* /somedir/
ADD --chown=10:11 files* /somedir/
```
如果容器根文件系统不包含/etc/passwd或 /etc/group文件，并且标志中使用了用户名或组名--chown ，则构建操作将失败ADD。使用数字 ID 不需要查找，也不会依赖于容器根文件系统内容。

ADD遵守以下规则：

- 该`<src>`路径必须在构建的上下文中；你不能ADD ../something /something，因为 a 的第一步 docker build是将上下文目录（和子目录）发送到 docker 守护进程。

- 如果`<src>`是一个 URL 并且`<dest>`不以尾部斜杠结尾，则会从该 URL 下载一个文件并将其复制到`<dest>`.

- 如果`<src>`是一个 URL 并且`<dest>`确实以尾部斜杠结尾，那么文件名是从 URL 推断出来的，文件被下载到 `<dest>`/`<filename>`. 例如，ADD `http://example.com/foobar` /将创建文件`/foobar. URL` 必须有一个重要的路径，以便在这种情况下可以发现适当的文件名（`http://example.com` 将不起作用）。

- 如果`<src>`是目录，则复制目录的全部内容，包括文件系统元数据。
    >不复制目录本身，只复制其内容。
    {: .prompt-info }

- 如果`<src>`是采用可识别压缩格式（身份、gzip、bzip2 或 xz）的本地tar 存档，则将其解压缩为目录。来自远程URL 的资源不会被解压缩。复制或解压缩目录时，它具有与 相同的行为tar -x，结果是以下的并集：

- 目标路径上存在的任何内容和源代码树的内容，冲突解决后支持“2”。在逐个文件的基础上。

    >文件是否被识别为可识别的压缩格式完全基于文件的内容，而不是文件的名称。例如，如果一个空文件恰好以此结尾，.tar.gz将不会被识别为压缩文件，也不会生成任何类型的解压缩错误消息，而只是将文件复制到目标位置。
    {: .prompt-info }

- 如果`<src>`是任何其他类型的文件，它将连同其元数据一起单独复制。在这种情况下，如果`<dest>`以尾部斜杠 结尾/，它将被视为一个目录，其内容`<src>`将写入`<dest>`/base(`<src>`).

- 如果`<src>`直接或由于使用通配符指定了多个资源，则`<dest>`必须是目录，并且必须以斜杠结尾/。

- 如果`<dest>`不以尾部斜杠结尾，它将被视为常规文件，其内容`<src>`将写入`<dest>`.

- 如果`<dest>`不存在，则会创建它及其路径中所有缺失的目录。

#### COPY
与ADD类似，只不过ADD是将上下文内的文件复制到镜像内，COPY是在镜像内的复制。格式与ADD一致。

COPY有两种形式：

```Dockerfile
COPY [--chown=<user>:<group>] <src>... <dest>
COPY [--chown=<user>:<group>] ["<src>",... "<dest>"]
```

注意
如果`<dest>`不存在，COPY指令会自动创建所有目录，包括子目录

在 Dockerfile 中，COPY 和 ADD 都用于将文件或目录复制到容器中，但它们有一些区别：

- COPY 只能复制文件或目录到容器中，而 ADD 还支持自动解压缩 URL 和 tar 文件。
- ADD 支持将远程 URL 作为源文件。如果您使用 COPY 命令并指定了 URL，则会出现错误。
- 如果您使用 ADD 命令并且源文件是 tar 文件，它将在复制之前自动解压缩。
- COPY 更加透明，因为它只是简单地将本地文件复制到容器中，而 ADD 具有额外的功能（如自动解压缩），可能会导致意外行为。

总之，如果您只需要复制本地文件到容器中，最好使用 COPY 命令。如果您需要支持更高级的复制功能（如自动解压缩和 URL 支持），则可以使用 ADD 命令。

#### WORKDIR
为接下来的Dockerfile指令指定当前工作目录，可多次使用，如果使用的是相对路径，则相对的是上一个工作目录，类似shell中的cd命令。格式：
```Dockerfile
WORKDIR /path/to/workdir
```
受影响的指令有：RUN、CMD、ENTRYPOINT、COPY和ADD。

该WORKDIR指令可以解析先前使用设置的环境变量 ENV。您只能使用在Dockerfile. 例如：
```Dockerfile
ENV DIRPATH=/path
WORKDIR $DIRPATH/$DIRNAME
RUN pwd
```
pwd最终命令的输出Dockerfile将是 `/path/$DIRNAME`

如果未指定，则默认工作目录为`/. `实际上，如果您不是从头开始构建 Dockerfile ( FROM scratch)，则WORKDIR可能由您使用的基础映像设置。

因此，为避免在未知目录中进行意外操作，最好WORKDIR明确设置您的。

#### EXPOSE

为构建的镜像设置监听端口，使容器在运行时监听。格式：

```Dockerfile
EXPOSE <port> [<port>...]
```

EXPOSE指令并不会让容器监听host的端口，如果需要，需要在`docker run`时使用-p、-P参数来发布容器端口到host的某个端口上。

默认情况下，EXPOSE采用 TCP。您还可以指定 UDP：

```Dockerfile
EXPOSE 80/udp
```
要在 TCP 和 UDP 上公开，请包括两行：

```Dockerfile
EXPOSE 80/tcp
EXPOSE 80/udp
```

在这种情况下，如果您使用`docker run -P` ，端口将为 TCP 公开一次，为 UDP 公开一次。请记住，`-P`在主机上使用临时高阶主机端口，因此 TCP 和 UDP 的端口不会相同。

无论设置如何EXPOSE，您都可以在运行时使用-p标志覆盖它们。例如

```shell
 docker run -p 80:80/tcp -p 80:80/udp ...
```

#### VOLUME
指定镜像内的目录为数据卷。格式：
```Dockerfile
VOLUME ["/var/log"]
VOLUME /var/log /var/db
```
在容器运行的时候，docker会把镜像中的数据卷的内容复制到容器的数据卷中去。
如果在接下来的Dockerfile指令中，修改了数据卷中的内容，则修改无效。

- 请记住以下有关Dockerfile.

- 基于 Windows 的容器上的卷：使用基于 Windows 的容器时，容器内卷的目的地必须是以下之一：

    - 一个不存在的或空的目录
    - 驱动器以外的`C:`

- 从 Dockerfile 中更改卷：如果任何构建步骤在声明卷后更改卷中的数据，这些更改将被丢弃。

- JSON 格式：列表被解析为 JSON 数组。"您必须用双引号 ( ) 而不是单引号 ( )将单词括起来'。

- 主机目录在容器运行时声明：主机目录（挂载点）本质上是依赖于主机的。这是为了保持图像的可移植性，因为不能保证给定的主机目录在所有主机上都可用。因此，您无法从 Dockerfile 中挂载主机目录。该VOLUME指令不支持指定host-dir 参数。您必须在创建或运行容器时指定挂载点。

#### USER
```Dockerfile
USER <user>[:<group>]
```
或者
```Dockerfile
USER <UID>[:<GID>]
```
该USER指令设置用户名（或 UID）和可选的用户组（或 GID）以用作当前阶段剩余部分的默认用户和组。指定的用户用于RUN指令，并在运行时运行相关ENTRYPOINT和CMD命令。

请注意，为用户指定组时，用户将只有指定的组成员资格。任何其他已配置的组成员身份都将被忽略。

当用户没有主要组时，图像（或下一条指令）将与该root组一起运行。

在 Windows 上，如果用户不是内置帐户，则必须先创建它。net user这可以通过作为 Dockerfile 的一部分调用的命令来完成。
```Dockerfile
FROM microsoft/windowsservercore
# Create Windows user in the container
RUN net user /add patrick
# Set it for subsequent commands
USER patrick
```

#### ONBUILD
向镜像中添加一个触发器，当以该镜像为base image再次构建新的镜像时，会触发执行其中的指令。格式：

ONBUILD [INSTRUCTION]
比如我们生成的镜像是用来部署Python代码的，但是因为有多个项目可能会复用该镜像。所以一个合适的方式是：
```Dockerfile
[...]
# 在下一次以此镜像为base image的构建中，执行ADD . /app/src，将项目代目添加到新镜像中去
ONBUILD ADD . /app/src
# 并且build Python代码
ONBUILD RUN /usr/local/bin/python-build --dir /app/src
[...]
```

>ONBUILD只会继承给子节点的镜像，不会再继承给孙子节点。
>ONBUILD ONBUILD或者ONBUILD FROM或者ONBUILD MAINTAINER是不允许的。
{: .prompt-info }

#### STOPSIGNAL
```Dockerfile
STOPSIGNAL signal
```
该STOPSIGNAL指令设置将发送到容器退出的系统调用信号。该信号可以是格式为 的信号名称`SIG<NAME>`，例如`SIGKILL`，或者与内核系统调用表中的位置匹配的无符号数字，例如`9`。SIGTERM如果未定义则为默认值。

`--stop-signal`可以使用标志在`docker run`和覆盖每个容器的图像默认停止信号 `docker create`。

#### HEALTHCHECK
增加自定义的心跳检测功能，多次使用只有最后一次有效。格式：
```Dockerfile
HEALTHCHECK [OPTION] CMD <command>：通过在容器内运行command来检查心跳
HEALTHCHECK NONE：取消从base image继承来的心跳检测
```
可选的OPTION：

`--interval=DURATION`：检测间隔，默认30秒
`--timeout=DURATION`：命令超时时间，默认30秒
`--retries=N`：连续N次失败后标记为不健康，默认3次
`<command>`可以是shell脚本，也可以是exec格式的json数组。
docker以`<command>`的退出状态码来区分容器是否健康，这一点同shell一致：

0：命令返回成功，容器健康
1：命令返回失败，容器不健康
2：保留状态码，不要使用
举例：每5分钟检测本地网页是否可访问，超时设为3秒：
```Shell
HEALTHCHECK --interval=5m --timeout=3s \
    CMD curl -f http://localhost/ || exit 1
```
可以使用docker inspect命令来查看健康状态。

#### SHELL
```Dockerfile
SHELL ["executable", "parameters"]
```
SHELL指令允许覆盖用于命令shell形式的默认shell。在Linux上，默认的shell是`["/bin/sh", "-c"]`，在Windows上是`["cmd", "/S", "/C"]`。在Dockerfile中，SHELL指令必须以JSON格式编写。

在Windows上，SHELL指令特别有用，因为有两个常用且非常不同的本地shell：`cmd`和`powershell`，还有其他可用的shell，例如`sh`。

SHELL指令可以出现多次。每个SHELL指令都会覆盖所有先前的SHELL指令，并影响所有后续指令。例如：
```Dockerfile
FROM microsoft/windowsservercore

# Executed as cmd /S /C echo default
RUN echo default

# Executed as cmd /S /C powershell -command Write-Host default
RUN powershell -command Write-Host default

# Executed as powershell -command Write-Host hello
SHELL ["powershell", "-command"]
RUN Write-Host hello

# Executed as cmd /S /C echo hello
SHELL ["cmd", "/S", "/C"]
RUN echo hello
```
当在Dockerfile中使用它们的shell形式时，以下指令可能会受到SHELL指令的影响：RUN、CMD和ENTRYPOINT。

以下示例是在Windows上常见的模式，可以通过使用SHELL指令来简化：
```Dockerfile
RUN powershell -command Execute-MyCmdlet -param1 "c:\foo.txt"
```
docker 调用的命令将是：
```Shell
cmd /S /C powershell -command Execute-MyCmdlet -param1 "c:\foo.txt"
```
这是低效的，原因有二。首先，调用了一个不必要的 cmd.exe 命令处理器（又名 shell）。其次，shellRUN形式中的每条指令都 需要一个额外的命令前缀。powershell -command

为了提高效率，可以采用两种机制中的一种。一种是使用 RUN 命令的 JSON 形式，例如：

```Dockerfile
RUN ["powershell", "-command", "Execute-MyCmdlet", "-param1 \"c:\\foo.txt\""]
```
虽然 JSON 形式是明确的并且不使用不必要的 cmd.exe，但它确实需要通过双引号和转义来更加冗长。替代机制是使用SHELL指令和shell形式，为 Windows 用户提供更自然的语法，尤其是与escape解析器指令结合使用时：
```Dockerfile
# escape=`

FROM microsoft/nanoserver
SHELL ["powershell","-command"]
RUN New-Item -ItemType Directory C:\Example
ADD Execute-MyCmdlet.ps1 c:\example\
RUN c:\example\Execute-MyCmdlet -sample 'hello world'
```


## 优雅的Dockerfile原则
编写优雅的Dockerfile主要需要注意以下几点：

- Dockerfile文件不宜过长，层级越多最终制作出来的镜像也就越大。
- 构建出来的镜像不要包含不需要的内容，如日志、安装临时文件等。
- 尽量使用运行时的基础镜像，不需要将构建时的过程也放到运行时的Dockerfile里。

以下两个Dockerfile实例进行简单的对比

```dockerfile
FROM ubuntu:16.04
RUN apt-get update
RUN apt-get install -y apt-utils libjpeg-dev \     
python-pip
RUN pip install --upgrade pip
RUN easy_install -U setuptools
RUN apt-get clean
```

```dockerfile
FROM ubuntu:16.04
RUN apt-get update && apt-get install -y apt-utils \
  libjpeg-dev python-pip \
           && pip install --upgrade pip \
      && easy_install -U setuptools \
    && apt-get clean
```

第一个Dockerfile，乍一看条理清晰，结构合理，似乎还不错。再看第二个Dockerfile，紧凑，不易阅读，为什么要这么写？

第一个Dockerfile的好处是：当正在执行的过程某一层出错，对其进行修正后再次Build，前面已经执行完成的层不会再次执行。这样能大大减少下次Build的时间，而它的问题就是会因层级变多了而使镜像占用的空间也变大。

第二个Dockerfile把所有的组件全部在一层解决，这样做能一定程度上减少镜像的占用空间，但在制作基础镜像的时候若其中某个组编译出错，修正后再次Build就相当于重头再来了，前面编译好的组件在一个层里，得全部都重新编译一遍，比较消耗时间。
从下表可以看出两个Dockerfile所编译出来的镜像大小：

```shell
$ docker images | grep ubuntu   
```

| REPOSITORY | TAG     | IMAGE ID     | CREATED    | SIZE  |
| :--------- | :------ | :----------- | :--------- | :---- |
| ubuntu     | 16.04   | 93623e635431 | 1 days ago | 422MB |
| ubuntu     | 16.04-1 | 3g5b329df1a9 | 1 days ago | 412MB |

仅从镜像大小来看好像并没有特别的效果，但若Dockerfile非常长的话可以考虑减少层次，因为Dockerfile最高只能有127层。

## Dockerfile案例

- 使用Java jar包打包镜像

```dockerfile
# FROM ibm-semeru-runtimes:open-11-jre
# 需减少容器内存占用使用ibm-semeru-runtimes
FROM openjdk:11
WORKDIR /home 

COPY *.jar app.jar 
COPY application.yml application.yml 

EXPOSE 8080

ENTRYPOINT ["java","-jar","app.jar","--spring.config.location=application.yml"]
```

- 使用Maven基础镜像完成SpringBoot编译打包镜像
  
```dockerfile
FROM maven:3.3.3

ADD pom.xml /tmp/build/
RUN cd /tmp/build && mvn -q dependency:resolve

ADD src /tmp/build/src
        #构建应用
RUN cd /tmp/build && mvn -q -DskipTests=true package \
        #拷贝编译结果到指定目录
        && mv target/*.jar /app.jar \
        #清理编译痕迹
        && cd / && rm -rf /tmp/build

VOLUME /tmp
EXPOSE 8080
ENTRYPOINT ["java","-Djava.security.egd=file:/dev/./urandom","-jar","/app.jar"]
```


# 使用多阶构

Docker在升级到Docker 17.05之后就能支持多阶构建了，为了使镜像更加小巧，我们采用多阶构建的方式来打包镜像。在多阶构建出现之前我们通常使用一个Dockerfile或多个Dockerfile来构建镜像。

## 单文件构建
在多阶构建出来之前使用单个文件进行构建，单文件就是将所有的构建过程（包括项目的依赖、编译、测试、打包过程）全部包含在一个Dockerfile中之下：

```dockerfile
FROM golang:1.11.4-alpine3.8 AS build-env
ENV GO111MODULE=off
ENV GO15VENDOREXPERIMENT=1
ENV BUILDPATH=github.com/lattecake/hello
RUN mkdir -p /go/src/${BUILDPATH}
COPY ./ /go/src/${BUILDPATH}
RUN cd /go/src/${BUILDPATH} && CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go install –v

CMD [/go/bin/hello]
```

这种的做法会带来一些问题：

- Dockerfile文件会特别长，当需要的东西越来越多的时候可维护性指数级将会下降；
- 镜像层次过多，镜像的体积会逐步增大，部署也会变得越来越慢；
- 代码存在泄漏风险。

以Golang为例，它运行时不依赖任何环境，只需要有一个编译环境，那这个编译环境在实际运行时是没有任务作用的，编译完成后，那些源码和编译器已经没有任务用处了也就没必要留在镜像里。

| REPOSITORY | TAG   | IMAGE ID     | CREATED   | SIZE  |
| :--------- | :---- | :----------- | :-------- | :---- |
| Hello      | 16.04 | 23g3gff98442 | 1 min ago | 312MB |

单文件构建最终占用了312MB的空间

## 多文件构建
在多阶构建出来之前有没有好的解决方案呢？有，比如采用多文件构建或在构建服务器上安装编译器，不过在构建服务器上安装编译器这种方法我们就不推荐了，因为在构建服务器上安装编译器会导致构建服务器变得非常臃肿，需要适配各个语言多个版本、依赖，容易出错，维护成本高。所以这里只介绍多文件构建的方式。

多文件构建，其实就是使用多个Dockerfile，然后通过脚本将它们进行组合。假设有三个文件分别是：Dockerfile.run、Dockerfile.build、build.sh。

- Dockerfile.run就是运行时程序所必须需要的一些组件的Dockerfile，它包含了最精简的库；
- Dockerfile.build只是用来构建，构建完就没用了；
- build.sh的功能就是将Dockerfile.run和Dockerfile.build进行组成，把Dockerfile.build构建好的东西拿出来，然后再执行Dockerfile.run，算是一个调度的角色。

```dockerfile
FROM golang:1.11.4-alpine3.8 AS build-env
ENV GO111MODULE=off
ENV GO15VENDOREXPERIMENT=1
ENV BUILDPATH=github.com/lattecake/hello
RUN mkdir -p /go/src/${BUILDPATH}
COPY ./ /go/src/${BUILDPATH}
RUN cd /go/src/${BUILDPATH} && CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go install –v
```
{: file='Dockerfile.build'}

```dockerfile
FROM alpine:latest
RUN apk –no-cache add ca-certificates
WORKDIR /root
ADD hello .
CMD ["./hello"]
```
{: file='Dockerfile.run'}

```shell
#!/bin/sh
docker build -t –rm hello:build . -f Dockerfile.build
docker create –name extract hello:build
docker cp extract:/go/bin/hello ./hello
docker rm -f extract
docker build –no-cache -t –rm hello:run . -f Dockerfile.run
rm -rf ./hello
```
{: file='Build.sh'}

执行build.sh完成项目的构建。

| REPOSITORY | TAG  | IMAGE ID     | CREATED   | SIZE   |
| :--------- | :--- | :----------- | :-------- | :----- |
| Hello2     | -    | 453je92fo212 | 1 min ago | 7.33MB |
| Hello      | -    | sf39f4i30itf | 1 min ago | 312MB  |

从上表可以看到，多文件构建大大减小了镜像的占用空间，但它有三个文件需要管理，维护成本也更高一些。

## 多阶构建
最后我们来看看万众期待的多阶构建。

完成多阶段构建我们只需要在Dockerfile中多次使用FORM声明，每次FROM指令可以使用不同的基础镜像，并且每次FROM指令都会开始新的构建，我们可以选择将一个阶段的构建结果复制到另一个阶段，在最终的镜像中只会留下最后一次构建的结果，这样就可以很容易地解决前面提到的问题，并且只需要编写一个Dockerfile文件。这里值得注意的是：需要确保Docker的版本在17.05及以上。下面我们来说说具体操作。

在Dockerfile里可以使用as来为某一阶段取一个别名”build-env”：

```dockerfile
FROM golang:1.11.2-alpine3.8 AS build-env
```

然后从上一阶段的镜像中复制文件，也可以复制任意镜像中的文件：

```dockerfile
COPY –from=build-env /go/bin/hello /usr/bin/hello
```

看一个简单的例子：

```dockerfile
FROM golang:1.11.4-alpine3.8 AS build-env
 
ENV GO111MODULE=off
ENV GO15VENDOREXPERIMENT=1
ENV GITPATH=github.com/lattecake/hello
RUN mkdir -p /go/src/${GITPATH}
COPY ./ /go/src/${GITPATH}
RUN cd /go/src/${GITPATH} && CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go install -v
 
FROM alpine:latest
ENV apk –no-cache add ca-certificates
COPY --from=build-env /go/bin/hello /root/hello
WORKDIR /root
CMD ["/root/hello"]
```

执行docker build -t –rm hello3 .后再执行docker images ，然后我们来看镜像的大小：

| REPOSITORY | TAG  | IMAGE ID     | CREATED   | SIZE   |
| :--------- | :--- | :----------- | :-------- | :----- |
| Hello3     | -    | 21ae345mi453 | 1 min ago | 7.2MB  |
| Hello2     | -    | 32mk4sap0ml4 | 1 min ago | 7.23MB |
| Hello      | -    | a32sd23j0154 | 1 min ago | 312MB  |

多阶构建给我们带来很多便利，最大的优势是在保证运行镜像足够小的情况下还减轻了Dockerfile的维护负担，因此极力推荐使用多阶构建来将你的代码打包成Docker 镜像。

# 参考
- [Dockerfile reference](https://docs.docker.com/engine/reference/builder/#run---security)
- [如何编写优雅的Dockerfile](https://zhuanlan.zhihu.com/p/79949030)
- [深入Dockerfile（一）: 语法指南](https://github.com/qianlei90/Blog/issues/35)
- [Dockerfile: ENTRYPOINT和CMD的区别](https://zhuanlan.zhihu.com/p/30555962)