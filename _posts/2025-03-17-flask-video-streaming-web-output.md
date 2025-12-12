---
layout: post
title: Flask 输出视频流Web
date: 2025-03-17 15:51 +0800
categories: [Software Development]
tags: [Flask, Python, 流媒体]
---

## 需求
将普通的视频文件以视频流的方式输出到web API没有任何意义，因在web端可以直接使用播放器通过HLS或者WebRTC这些音视频通信协议高效点播视频文件。

但是在一些特殊情况下，视频内容可能实时生成的, 例如:

- 本地监控系统的 Web 预览画面。
- 机器人或无人机的实时调试反馈画面。
- 基于 Flask/Django 这种web框架的实时图像处理结果展示系统。

在这种情况下，就需要采用视频流的方式，将实时生成的图像输出的web端形成视频效果。

## 实现方案
我们可以使用 `yield` 关键字: 让API接口返回一个生成器。它不是一次性返回所有数据，而是逐帧持续返回。这使得 Flask 能够持续发送数据，形成视频流。

具体文件如下:

- `index.html` (Web 客户端)

    ```html
    <html>
      <head>
        <title>Video Streaming Demonstration</title>
      </head>
      <body>
        <h1>Video Streaming Demonstration</h1>
        <img src="{{ url_for('video_feed') }}" height="500">
      </body>
    </html>
    ```

- `app.py` (Flask 服务器端)

    ```python
    import cv2
    from flask import Flask, render_template, Response

    app = Flask(__name__)

    @app.route('/')
    def index():
        return render_template('index.html')

    def gen():
        video_path = 'E:/GraduationProject/dataset/video/video1.mp4'
        vid = cv2.VideoCapture(video_path)
        while True:
            return_value, frame = vid.read()
            image = cv2.imencode('.jpg', frame)[1].tobytes()
            yield (b'--frame\r\n'
                  b'Content-Type: image/jpeg\r\n\r\n' + image + b'\r\n')

    @app.route('/video_feed')
    def video_feed():
        return Response(gen(), mimetype='multipart/x-mixed-replace; boundary=frame')

    if __name__ == '__main__':
        app.run()
    ```

当访问 `127:.0.0.1:8080/` 的时候, `index.html` 中的 `<img>` 标签，它的 src 属性指向一个 Flask 路由 `/video_feed`，浏览器期望从 `/video_feed` 获取一张图片。然而，这个路由返回的是一个不断更新的多部分响应 (Multipart Response)。浏览器会持续接收和刷新这个 `<img>` 标签的内容，从而显示连续的帧。实现视频流的显示效果

## 原理分析
这个方案背后的原理是实现了基于 HTTP 的 M-JPEG (Motion JPEG) 流，这是 Flask 实现实时视频流最简单和常见的方法之一。

> **HTTP 的 M-JPEG (Motion JPEG) 流**是一种利用标准 HTTP 协议来传输连续图像流的技术，让浏览器把一系列图片看作一个不断更新的视频
>
> 当 Web 服务器返回一个响应时，它通常只返回一个文件（如一个 HTML 页面、一张图片或一个 JSON 对象）
>
> M-JPEG 流则不同：
>
> - 多部分: 响应体由多个部分组成，每个部分都是一张独立的 JPEG 图像（一帧视频）
> - 混合替换: 浏览器接收到第一个部分（第一帧）后会显示它。当服务器发送第二个部分（第二帧）时，浏览器会立即替换掉前一帧。
> - 持续性: 服务器不会关闭连接，而是不断地发送新帧。浏览器持续替换显示，高速连续的帧就形成了“视频”效果
>
> M-JPEG 流虽然不是最高效的视频流技术（相比于 H.264/H.265 等编码），但它因其 实现简单 和 低延迟 的特性，成为 局域网或低负载 实时应用的首选
{: .prompt-tip }

**连续返回帧的实现**:

在视频流生成器中: 

```python
def gen():
    # ... 省略文件读取部分 ...
    while True:
        # 1. 读取帧
        return_value, frame = vid.read() 
        # 2. 将OpenCV帧编码为JPEG格式
        image = cv2.imencode('.jpg', frame)[1].tobytes()
        # 3. 构造M-JPEG流所需的响应体
        yield (b'--frame\r\n'
               b'Content-Type: image/jpeg\r\n\r\n' + image + b'\r\n')
```

配置关键点:

- 使用 `cv2.imencode('.jpg', frame)` 将 OpenCV 读取的原始帧数据（NumPy 数组）转换为 JPEG 格式的二进制数据。使其符合 M-JPEG 流要求的格式。
- `yield` 关键字: 让 `gen()` 方法的返回值是一个 `生成器 (Generator)`。它不是一次性返回所有数据，而是逐帧返回。这使得 Flask 能够持续发送数据，形成流。
- M-JPEG 格式: `yield` 语句构造了 M-JPEG 规范要求的帧分隔符：
    - `--frame\r\n`: 分隔符，必须与 MIME-Type 中的 boundary 匹配。
    - `Content-Type`: `image/jpeg\r\n\r\n`: 声明下一部分是 JPEG 图像。
    - `image`: 实际的 JPEG 二进制数据。

在路由配置中:

```python
@app.route('/video_feed')
def video_feed():
    return Response(gen(), mimetype='multipart/x-mixed-replace; boundary=frame')
```

- `Response()`: Flask 用它来返回一个响应。在这里，它将 生成器 `gen()` 作为数据源。
- `mimetype` (MIME 类型): 这是 最关键 的一行，它告诉浏览器这不是一个普通的响应，而是一个 **多部分响应** (Multipart Response)：
    - `multipart/x-mixed-replace`: 表示这是一个由多个部分（帧）组成、并且每个新部分都会替换前一个部分的流。
    - `boundary=frame`: 声明了用于分隔每个部分的字符串（即 `gen()` 中使用的 `--frame`）。

# 参考

- [【Flask】以视频流的方式将视频输出到Web端](https://blog.csdn.net/See_Star/article/details/106215938)