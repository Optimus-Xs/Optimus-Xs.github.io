---
layout: post
title: 新服务器的SSH配置流程
date: 2022-10-07 19:51 +0800
categories: [ServerOperation] 
tags: [Linux,Network]
---

我们一般使用 SSH 客户端来远程管理 Linux 服务器。但是，一般的密码方式登录，容易有密码被暴力破解的问题。所以，一般我们会将 SSH 的端口设置为默认的 22 以外的端口，或者禁用 root 账户登录。其实，有一个更好的办法来保证安全，而且让你可以放心地用 root 账户从远程登录——那就是通过密钥方式登录。

密钥形式登录的原理是：利用密钥生成器制作一对**非对称密钥**(一只公钥和一只私钥)。将公钥添加到服务器的某个账户上，然后在客户端利用私钥即可完成认证并登录。这样一来，没有私钥，任何人都无法通过 SSH 暴力破解你的密码来远程登录到系统。此外，如果将公钥复制到其他账户甚至主机，利用私钥也可以登录。

## 制作密钥对

首先在服务器上制作密钥对。首先用密码登录到你打算使用密钥登录的账户，然后执行以下命令：

```shell
ssh-keygen
```

然后根据提示操作， 流程如下

```shell
[root@host ~]$ ssh-keygen  <== 建立密钥对
Generating public/private rsa key pair.
Enter file in which to save the key (/root/.ssh/id_rsa): <== 按 Enter 或者指定密钥对文件名
Created directory '/root/.ssh'.
Enter passphrase (empty for no passphrase): <== 输入密钥锁码，或直接按 Enter 留空
Enter same passphrase again: <== 再输入一遍密钥锁码
Your identification has been saved in /root/.ssh/id_rsa. <== 私钥
Your public key has been saved in /root/.ssh/id_rsa.pub. <== 公钥
The key fingerprint is:
0f:d3:e7:1a:1c:bd:5c:03:f1:19:f1:22:df:9b:cc:08 root@host
``` 

> 密钥锁码在使用私钥时必须输入，这样就可以保护私钥不被盗用。当然，也可以留空，实现无密码登录。
{: .prompt-tip }

现在，在 root 用户的家目录中生成了一个 `.ssh` 的隐藏目录，内含两个密钥文件。默认情况下  `id_rsa` 为私钥，`id_rsa.pub` 为公钥。

> 如果已经有创建好的密钥则可以跳过这一步, 并将公钥复制到需要配置的服务器上的 `~/.ssh` 目录进行安装
{: .prompt-tip }


## 在服务器上安装SSH

通常情况下Linux发行版应该预装了 `ssh server`，没有则执行以下命令安装( 这里使用Ubuntu为例子 )

```shell
sudo apt-get update
sudo apt-get install openssh-server
```

其他Linux发行版的安装命令如下:

```shell
# Red Hat/CentOS/Fedora/Rocky Linux
sudo dnf install openssh-server 
# 或者使用 yum 的 CentOS/RHEL
sudo yum install openssh-server

# Arch Linux/Manjaro
sudo pacman -S openssh

# SUSE/openSUSE
sudo zypper install openssh
```

在终端敲入以下命令查看ssh服务状态：

```shell
sudo service ssh status 
```

如果没有自动运行则在终端敲入以下命令手动启动`ssh server`：

```shell
sudo service ssh star
```

ssh 服务的其他管理命令如下：

```shell
#停止服务
sudo service ssh stop

#启动服务
sudo service ssh start

#重启服务
sudo service ssh restart
```

## 在服务器上安装公钥

> 如果需要使用以前生成过的公钥可以把公钥文件提前复制到目标服务器的 `.ssh/` 目录，而不是使用 `ssh-keygen`    手动生成密钥
{: .prompt-tip }

键入以下命令，在服务器上安装公钥

```shell
cd .ssh
cat id_rsa.pub >> authorized_keys
```

如此便完成了公钥的安装。为了确保连接成功，请保证以下文件权限正确：

```shell
chmod 600 authorized_keys
chmod 700 ~/.ssh
```

## 服务器上SSH配置

编辑 `/etc/ssh/sshd_config` 文件，进行如下设置：

```shell
nano /etc/ssh/sshd_config
```

```conf
RSAAuthentication yes
PubkeyAuthentication yes
```
{: file='sshd_config'}

另外，请留意 root 用户能否通过 SSH 登录：

```conf
PermitRootLogin yes
```
{: file='sshd_config'}

当你完成全部设置，并以密钥方式登录成功后，再禁用密码登录：

```conf
PasswordAuthentication no
```
{: file='sshd_config'}

最后，重启 SSH 服务以应用新的设置：

```shell
service sshd restart
```

## 常见问题
### 客户端连接指令
#### 命令行参数
SSH 连接命令语法

```shell
ssh -p [端口号] -i [密钥文件路径] [用户名]@[服务器IP或域名]
```

假设您的服务器：

- 用户名是 `myuser`
- IP 地址是 `192.168.1.100`
- SSH 端口是 `2222`
- 私钥文件路径是 `~/.ssh/my_key`

连接命令如下：

```shell
ssh -p 2222 -i ~/.ssh/my_key myuser@192.168.1.100
```

#### SSH 配置文件

对于经常连接的服务器，强烈建议使用 SSH 配置文件。这不仅简化了连接命令，还能管理更复杂的连接选项，如自动跳板机等。

打开或创建您的 SSH 配置文件：

```shell
nano ~/.ssh/config
```

假设您要为上一个例子中的服务器创建一个简短的别名 `myserver`：

```conf
Host myserver
    HostName 192.168.1.100
    User myuser
    Port 2222
    IdentityFile ~/.ssh/my_key
```
{: file='~/.ssh/config'}

配置完成后，您只需要使用别名即可连接：

```shell
ssh myserver
```
### Known Host 冲突

有时候,连接Linux服务器时出现`WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED`，会导致这一警告信息是因为，第一次进行SSH连接时，会生成一个认证存储在客户端中的`known_hosts`，但如果服务器重新装过系统或认证信息发生变化。这时候服务器和客户端的信息不匹配时，就会出现错误。解决办法就是将`known_hosts`文件中那个无效的记录删除即可。

完整的警告信息通常如下所示

```text    
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@    WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!     @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
IT IS POSSIBLE THAT SOMEONE IS DOING SOMETHING NASTY!
Someone could be eavesdropping on you right now (man-in-the-middle attack)!
...
Offending key in /home/user/.ssh/known_hosts:N
...
```

其中 **N** 是警告中提到的行号。

SSH 协议将主机的公钥存储在本地的 `known_hosts` 文件中，用于验证您连接的服务器是否是您上次连接的同一台服务器。公钥指纹不匹配，意味着服务器的身份发生了变化

以下是导致这个警告的三个主要原因，按可能性从高到低排列：

1. 服务器重新安装或更换 (最常见原因)
2. 服务器 IP 地址被重新分配给新的机器 (常见原因)
3. 中间人攻击 (Man-in-the-Middle Attack, MITM) (安全风险)

如果确定服务器的身份是安全的（即情况 1 或 2），可以安全地删除本地存储的旧密钥。需要使用命令中提供的行号 **N** 来删除 `known_hosts` 文件中对应的条目。

方法一：使用 `ssh-keygen` 命令（推荐）

这是最安全和最推荐的方法，因为它只删除与特定主机名/IP 相关的密钥，且无需手动编辑文件。

```shell    
ssh-keygen -R [服务器IP或域名]
```

示例： 如果您连接 `192.168.1.100` 时出现警告：

```shell    
ssh-keygen -R 192.168.1.100
```

方法二：使用 `sed` 命令和行号

如果警告中明确给出了行号 **N**（例如，`Offending key in /home/user/.ssh/known_hosts:15`），您可以使用 `sed` 删除该行：

```shell    
sed -i 'Nd' ~/.ssh/known_hosts
```

示例： 如果警告中提到第 15 行：

```shell    
sed -i '15d' ~/.ssh/known_hosts
```

方法三：手动编辑文件

直接打开文件并手动删除出错的那一行

完成以上任一操作后，重新尝试连接 SSH，系统会提示您接受新的主机密钥。

# 参考

- [设置 SSH 通过密钥登录](https://www.runoob.com/w3cnote/set-ssh-login-key.html)
- [REMOTE HOST IDENTIFICATION HAS CHANGED问题解决](https://cloud.tencent.com/developer/article/1790651)