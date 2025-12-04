---
layout: post
title: PVE 去除订阅弹框
date: 2024-11-14 14:12 +0800
categories: [ServerOperation]
tags: [PVE]
---
## 处理命令
```bash
sed -i_orig "s/data.status === 'Active'/true/g" /usr/share/pve-manager/js/pvemanagerlib.js
sed -i_orig "s/if (res === null || res === undefined || \!res || res/if(/g" /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js
sed -i_orig "s/.data.status.toLowerCase() !== 'active'/false/g" /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js
systemctl restart pveproxy
```

> 执行完成后如果没用生效需要清除游览器缓存或者强制重新加载`Ctrl+F5`让其重新加载PVE UI前端使用的JS资源
{: .prompt-tip }

## 功能分析 
这三个 `sed` 命令都是针对 Proxmox Web 界面的核心 JavaScript 文件进行替换操作，通过修改 Proxmox 管理界面使用的 JavaScript 文件，来改变触发弹窗的逻辑判断, 而最后一个 `systemctl` 命令则是重启 Web 服务使修改生效。

### 修改 pvemanagerlib.js
```bash
sed -i_orig "s/data.status === 'Active'/true/g" /usr/share/pve-manager/js/pvemanagerlib.js
```

- 修改 `/usr/share/pve-manager/js/pvemanagerlib.js` 文件中`data.status === 'Active'`，并将其替换为 `true`
- `sed -i_orig`: `-i` 表示直接修改文件内容，`_orig` 是一个可选后缀，表示在修改前将原始文件备份为 `pvemanagerlib.js_orig`

### 修改 proxmoxlib.js (第一部分)
```bash
sed -i_orig "s/if (res === null || res === undefined || \!res || res/if(/g" /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js
```

替换 `/usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js` 文件中的一个关键的 `if` 语句，用于检查订阅状态并决定是否弹出警告。

### 修改 proxmoxlib.js (第二部分)
```bash
sed -i_orig "s/.data.status.toLowerCase() !== 'active'/false/g" /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js
```

将 `/usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js` 文件中字符串 `.data.status.toLowerCase() !== 'active'`，并将其替换为 `false`, 这条命令就完成了逻辑的修改，使得无论订阅状态如何，导致弹窗的关键条件总是为`false`，从而阻止了警告弹窗的出现

### 重启服务
```bash
systemctl restart pveproxy
```

Proxmox Web 管理界面通过 `pveproxy` 服务运行。由于修改了 Web 界面所使用的 JavaScript 文件，必须重启此服务，才能让 Web 服务器加载新的（被修改后的）JS 文件，使更改生效

> 每次 Proxmox 进行版本更新并升级 `pve-manager` 或 `proxmox-widget-toolkit` 软件包时，这些 JavaScript 文件很可能会被新的、未修改的版本覆盖，导致订阅弹窗重新出现，需要再次执行这些命令
{: .prompt-tip }

# 参考
- [PVE 去除订阅弹框](https://blog.csdn.net/Miss_Mario/article/details/138891690)