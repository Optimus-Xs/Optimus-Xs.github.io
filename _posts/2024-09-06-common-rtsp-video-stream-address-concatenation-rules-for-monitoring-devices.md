---
layout: post
title: 常见监控设备的 RTSP 视频流地址拼接规则
date: 2024-09-06 16:17 +0800
categories: [Software Development]
tags: [Hardware, 协议解析]
---

## 海康
**直播RTSP接口格式**

```
rtsp://[username]:[password]@[ip]:554/Streaming/Channels/[channel][stream]
```
{: file="单播RTSP直播格式" }

```
rtsp://[username]:[password]@[ip]:554/Streaming/Channels/[channel][stream]?transportmode=multicast
```
{: file="多播RTSP直播格式" }

**回放RTSP接口格式**

```
rtsp://[username]:[password]@[ip]:554/Streaming/tracks/[channel][stream]?starttime=[start_time]&endtime=[end_time]
```
{: file="回放RTSP格式" }

说明:

- `username`: 用户名。例如 `admin`
- `password`: 密码。例如 `admin`
- `ip`: 为设备IP。例如 `192.168.1.101`
- `channel`: 通道号, 例如通道2，则为`2`
- `stream`: 主码流为`01`，辅码流为`02`
- `start_time`: 回访开始时间, 例如 `20240716t154020z`
- `end_time`: 回访结束时间, 例如 `20240716t184020z`

channel规则:

- 32路包含32路以下的NVRchannel从33开始，也就是说从海康NVR中获取的channel就是从33开始的，自己拼接RTSP的时候要用这个channel减32才是真正的channel
- 64路包含64路以上的NVRchannel是从1开始的，也就是说从海康NVR中获取的channel就是从1开始的，自己拼接RTSP的时候可以直接使用

```
// 取NVR通道1的主码流
rtsp://admin:admin@192.168.2.205:554/Streaming/Channels/101

// 取NVR通道1的子码流
rtsp://admin:admin@192.168.2.205:554/Streaming/Channels/102
```
{: file="RTSP 案例" }

```
// NVR通道1的主码流录像回放RTSP地址
rtsp://admin:admin@192.168.2.205:554/Streaming/tracks/101?starttime=20240716t154020z&endtime=20240716t184020z
```
{: file="RTSP 案例" }

## 大华
大华摄像机RTSP地址规则为：

```
rtsp://[username]:[password]@[ip]:[port]/cam/realmonitor?channel=[channel]&subtype=[subtype]
```
{: file="RTSP直播格式" }

说明：

- `username`: 用户名。例如`admin`
- `password`: 密码。例如`admin123`
- `ip`: 为设备IP。例如 `192.168.1.101`
- `port`: 端口号默认为`554`，若为默认可不填写
- `channel`: 通道号，起始为1。例如通道2，值为`2`, 则为`channel=2`
- `subtype`: 流类型，主码流为`0`（即`subtype=0`），辅码流为`1`（即`subtype=1`）

```
rtsp://admin:admin123@192.168.1.101/cam/realmonitor?channel=1&subtype=1
```
{: file="RTSP 案例" }

## 宇视
```
rtsp://[username]:[password]@[ip]:[port]/media/[video]
```
{: file="RTSP直播格式" }

说明：

- `username`: 用户名。例如`admin`
- `password`: 密码。例如`admin123`
- `ip`: 为设备IP。例如 `192.168.1.107`
- `port`: 端口号默认为`554`，若为默认可不填写
- `video`: `video1`代表主码流、`video2`辅码流、`video3`第三码流

```
rtsp://admin:admin123@192.168.1.107/media/video2
```
{: file="RTSP 案例" }

## TP-Link

```
rtsp://[username]:[password]@[ip]:[port]/[stream]&channel=[channel]
```
{: file="RTSP直播格式" }

说明：

- `username`: 用户名，如`admin`
- `password`: 密码，如`123456`
- `ip`: 设备IP，如`192.168.1.60`
- `port`: RTSP端口，默认为`554`，若为默认可不填
- `stream`: stream，主码流为`stream1`，子码流为`stream2`
- `channel`: channel, 可选值 `1`,`2`,`3` ....

```
rtsp://admin:123456@192.168.1.60:554/stream1&channel=1
```
{: file="RTSP 案例" }

# 参考
- [海康NVR的实时视频与录像回放RTSP流地址拼接格式](https://blog.csdn.net/q276250281/article/details/134600474)