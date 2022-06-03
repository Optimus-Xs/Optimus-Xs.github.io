---
layout: post
title: 同源策略和实现跨域访问的方法
date: 2021-04-07 14:25 +0800
categories: [Software Development] 
tags: [Internet Security]
---

# 同源策略
## 同源策略定义
1995年，同源政策由 Netscape 公司引入浏览器。目前，所有浏览器都实行这个政策。

最初，它的含义是指，A网页设置的 Cookie，B网页不能打开，除非这两个网页"同源"

如果两个 URL 的 protocol、port (en-US) (如果有指定的话)和 host 都相同的话，则这两个 URL 是同源。这个方案也被称为“协议/主机/端口元组”，或者直接是 “元组”。（“元组” 是指一组项目构成的整体，双重/三重/四重/五重/等的通用形式）。

所谓同源是指：域名、协议、端口相同。

同源策略（Same origin policy）是一种约定，它是浏览器最核心也最基本的安全功能，如果缺少了同源策略，则浏览器的正常功能可能都会受到影响。可以说 Web 是构建在同源策略基础之上的，浏览器只是针对同源策略的一种实现。

它的核心就在于它认为自任何站点装载的信赖内容是不安全的。当被浏览器半信半疑的脚本运行在沙箱时，它们应该只被允许访问来自同一站点的资源，而不是那些来自其它站点可能怀有恶意的资源。

下表给出了与 URL http://example.company.com/dir/page.html 的源进行对比的示例:

| URL                                             | 结果 | 原因                             |
| :---------------------------------------------- | :--- | :------------------------------- |
| http://example.company.com/dir2/other.html        | 同源 | 只有路径不同                     |
| http://example.company.com/dir/inner/another.html | 同源 | 只有路径不同                     |
| https://example.company.com/secure.html           | 失败 | 协议不同                         |
| http://example.company.com:81/dir/etc.html        | 失败 | 端口不同 ( http:// 默认端口是80) |
| http://news.company.com/dir/other.html          | 失败 | 主机不同                         |

随着互联网的发展，"同源政策"越来越严格。目前，如果非同源，共有三种行为受到限制。

- Cookie、LocalStorage 和 IndexDB 无法读取。
- DOM 无法获得。
- AJAX 请求不能发送。

## 为什么使用同源策略
因为存在浏览器同源策略，所以才会有跨域问题。那么浏览器是出于何种原因会有跨域的限制呢。其实不难想到，跨域限制主要的目的就是为了用户的上网安全。

如果浏览器没有同源策略，会存在什么样的安全问题呢。下面从 DOM 同源策略和 XMLHttpRequest 同源策略来举例说明：

如果没有 DOM 同源策略，也就是说不同域的 iframe 之间可以相互访问，那么黑客可以这样进行攻击：

- 做一个假网站，里面用 iframe 嵌套一个银行网站 http://mybank.com。
- 把 iframe 宽高啥的调整到页面全部，这样用户进来除了域名，别的部分和银行的网站没有任何差别。
- 这时如果用户输入账号密码，我们的主网站可以跨域访问到 http://mybank.com 的 dom 节点，就可以拿到用户的账户密码了。

如果没有 XMLHttpRequest 同源策略，那么黑客可以进行 CSRF（跨站请求伪造） 攻击：

- 用户登录了自己的银行页面 http://mybank.com，http://mybank.com 向用户的 cookie 中添加用户标识。
- 用户浏览了恶意页面 http://evil.com，执行了页面中的恶意 AJAX 请求代码。
- http://evil.com 向 http://mybank.com 发起 AJAX HTTP 请求，请求会默认把 http://mybank.com 对应 cookie 也同时发送过去。
- 银行页面从发送的 cookie 中提取用户标识，验证用户无误，response 中返回请求数据。此时数据就泄露了。
- 而且由于 Ajax 在后台执行，用户无法感知这一过程。

因此，有了浏览器同源策略，我们才能更安全的上网。

# 跨域访问实现
## CORS
CORS的全称是 Cross-Origin Resource Sharing 跨域资源共享。

是浏览器为 AJAX 请求设置的一种跨域机制，让其可以在服务端允许的情况下进行跨域访问。主要通过 HTTP 响应头来告诉浏览器服务端是否允许当前域的脚本进行跨域访问。

跨域资源共享将 AJAX 请求分成了两类：

- 简单请求
- 非简单请求

### 简单请求
简单请求需要符合以下特征

- 请求方法为 GET、POST、HEAD
- 请求头只能使用下面的字段：

  - Accept 浏览器能够接受的响应内容类型。
  - Accept-Language浏览器能够接受的自然语言列表。
  - Content-Type 请求对应的类型，只限于 text/plain、multipart/form-data、application/x-www-form-urlencoded。
  - Content-Language浏览器希望采用的自然语言。
  - Save-Data浏览器是否希望减少数据传输量。

**简单请求流程如下:**

浏览器发出简单请求的时候，会在请求头部增加一个 Origin 字段，对应的值为当前请求的源信息。

当服务端收到请求后，会根据请求头字段 Origin 做出判断后返回相应的内容。

浏览器收到响应报文后会根据响应头部字段 Access-Control-Allow-Origin 进行判断，这个字段值为服务端允许跨域请求的源，其中通配符 * 表示允许所有跨域请求。如果头部信息没有包含 Access-Control-Allow-Origin 字段或者响应的头部字段 Access-Control-Allow-Origin 不允许当前源的请求，则会抛出错误。

### 非简单请求
只要不符合上述简单请求的特征，会变成非简单请求，浏览器在处理非简单的请求时，浏览器会先发出一个预检请求（Preflight）。这个预检请求为 OPTIONS 方法，并会添加了 1 个请求头部字段 Access-Control-Request-Method，值为跨域请求所使用的请求方法。

在服务端收到预检请求后，除了在响应头部添加 Access-Control-Allow-Origin 字段之外，至少还会添加 Access-Control-Allow-Methods 字段来告诉浏览器服务端允许的请求方法，并返回 204 状态码。

服务端还根据浏览器的 Access-Control-Request-Headers 字段回应了一个 Access-Control-Allow-Headers 字段，来告诉浏览器服务端允许的请求头部字段。

浏览器得到预检请求响应的头部字段之后，会判断当前请求服务端是否在服务端许可范围之内，如果在则继续发送跨域请求，反之则直接报错。

**CORS常用头部字段**

- origin

请求首部字段, Origin 指示了请求来自于哪个站点, 包括协议、域名、端口、不包括路径部分
在不携带凭证的情况下，可以使是一个*，表示接受任意域名的请求

- Access-Control-Allow-Origin

响应头，用来标识允许哪个域的请求

- Access-Control-Allow-Methods

响应头，用来标识允许哪些请求方法被允许

- access-control-allow-headers

响应首部， 用于预检请求中，列出了将会在正式请求的允许携带的请求头信息。

- Access-Control-Expose-Headers

响应头，用来告诉浏览器，服务器可以自定义哪些字段暴露给浏览器

- Access-Control-Allow-Credentials

是否允许携带Credentials,Credentials可以是 cookies, authorization headers 或 TLS client certificates。

- Access-Control-Max-Age

预检请求的缓存时长

### CORS 示例
CORS 示例参考：[SpringBoot 配置 CORS 跨域请求的三种方法]({% post_url 2021-04-07-springboot-cors-config %})


CORS 优点:
- CORS 通信与同源的 AJAX 通信没有差别，代码完全一样，容易维护。
- 支持所有类型的 HTTP 请求。

CORS 缺点:
- 存在兼容性问题，特别是 IE10 以下的浏览器。
- 第一次发送非简单请求时会多一次请求。

## JSONP
JSONP（JSON with Padding）的意思就是用 JSON 数据来填充。

怎么填充呢？

结合它的实现方式可以知道，就是把 JSON 数填充到一个回调函数中。是利用 script 标签跨域引用 js 文件不会受到浏览器同源策略的限制,具有天然跨域性。

假设我们要在 http://www.a.com 中向 http://www.b.com 请求数据。

1. 全局声明一个用来处理返回值的函数 fn，该函数参数为请求的返回结果。
```js
function fn(result) {
  console.log(result)
}
```
2. 将函数名与其他参数一并写入 URL 中
```js
let url = 'http://www.b.com?callback=fn&params=...';
```
3. 动态创建一个 script 标签，把 URL 赋值给 script 的 src属性。
```js
let script = document.createElement('script');
script.setAttribute("type","text/javascript");
script.src = url;
document.body.appendChild(script);
```
4. 当服务器接收到请求后，解析 URL 参数并进行对应的逻辑处理，得到结果后将其写成回调函数的形式并返回给浏览器。
```js
fn({
  list: [],
  ...
})
```
5. 在浏览器收到请求返回的 js 脚本之后会立即执行文件内容，即可获取到服务端返回的数据。 

JSONP 虽然实现了跨域请求，但也存在以下的几个问题：

- 只能发送 GET 请求，限制了参数大小和类型。
- 请求过程无法终止，导致弱网络下处理超时请求比较麻烦。
- 无法捕获服务端返回的异常信息。

## Websocket
Websocket 是 HTML5 规范提出的一个应用层的全双工协议，适用于浏览器与服务器进行实时通信场景。

全双工通信传输的一个术语，这里的“工”指的是通信方向。

“双工”是指从客户端到服务端，以及从服务端到客户端两个方向都可以通信，“全”指的是通信双方可以同时向对方发送数据。与之相对应的还有半双工和单工，半双工指的是双方可以互相向对方发送数据，但双方不能同时发送，单工则指的是数据只能从一方发送到另一方。

下面是一段简单的示例代码。在 a 网站直接创建一个 WebSocket 连接，连接到 b 网站即可，然后调用 WebScoket 实例 ws 的 send() 函数向服务端发送消息，监听实例 ws 的 onmessage 事件得到响应内容。
```js
let ws = new WebSocket("ws://b.com");
ws.onopen = function(){
  // ws.send(...);
}
ws.onmessage = function(e){
  // console.log(e.data);
}
```

## 请求代理
我们知道浏览器有同源策略的安全限制，但是服务器没有限制，所以我们可以利用服务器进行请求转发。

以 webpack 为例，利用 webpack-dev-server 配置代理, 当浏览器发起前缀为 /api 的请求时都会被转发到 http://localhost:3000 服务器，代理服务器将获取到响应返回给浏览器。对于浏览器而言还是请求当前网站，但实际上已经被服务端转发。

```conf
// webpack.config.js
module.exports = {
  //...
  devServer: {
    proxy: {
      '/api': 'http://localhost:3000'
    }
  }
};

// 使用 Nginx 作为代理服务器
location /api {
    proxy_pass   http://localhost:3000;
}
```

## 图像 Ping 跨域
由于 img 标签不受浏览器同源策略的影响，允许跨域引用资源。因此可以通过 img 标签的 src 属性进行跨域，这也就是图像 Ping 跨域的基本原理。

直接通过下面的例子来说明图像 Ping 实现跨域的流程：

```js
var img = new Image();

// 通过 onload 及 onerror 事件可以知道响应是什么时候接收到的，但是不能获取响应文本
img.onload = img.onerror = function() {
    console.log("Done!");
}

// 请求数据通过查询字符串形式发送
img.src = 'http://www.example.com/test?name=testscript';
```

img标签跨域优点: 
- 用于实现跟踪用户点击页面或动态广告曝光次数有较大的优势。

img标签跨域缺点: 
- 只支持 GET 请求。
- 只能浏览器与服务器的单向通信，因为浏览器不能访问服务器的响应文本。

## 页面跨域解决方案
请求跨域之外，页面之间也会有跨域需求，例如使用 iframe 时父子页面之间进行通信。常用方案如下：

- postMessage
- document.domain
- window.name(不常用)
- location.hash + iframe(不常用)

### postMessage
window.postMessage 是 HTML5 推出一个新的函数，用来实现父子页面之间通信，而且不论这两个页面是否同源。

以 https://test.com 和 https://a.test.com 为例子:
```js
// https://test.com
let child = window.open('https://a.test.com');
child.postMessage('hello', 'https://a.test.com');
```
上面的代码通过 window.open() 函数打开了子页面，然后调用 child.postMessage() 函数发送了字符串数据hello给子页面。

在子页面中，只需要监听message事件即可得到父页面的数据。代码如下：
```js
// https://a.test.com
window.addEventListener('message', function(e) {
  console.log(e.data); // hello
},false);
```
子页面发送数据时则要通过 window.opener 对象来调用 postMessage() 函数.
```js
// https://a.test.com
window.opener.postMessage('hello', 'https://test.com');
```

### document.domain
domain 属性可返回下载当前文档的服务器域名。通过修改 document.domain 的值来进行跨域, 这种情况适合主域名相同，子域名不同的页面。

我们以 https://www.test.com/parent.html，在这个页面里面有一个 iframe，其 src 是 http://a.test.com/child.html。

这时只要把 https://www.test.com/parent.html 和 http://a.test.com/child.html 这两个页面的 document.domain 都设成相同的域名，那么父子页面之间就可以进行跨域通信了，同时还可以共享 cookie。

但要注意的是，只能把 document.domain 设置成更高级的父域才有效果，例如在 ·http://a.test.com/child.html 中可以将 document.domain 设置成 test.com

### window.name
name 属性可设置或返回存放窗口的名称的一个字符串，name值在不同的页面（包括域名改变）加载后依旧存在。

我们准备三个页面：

- https://localhost:3000/a.html
- https://localhost:3000/b.html
- https://localhost:4000/c.html
a页面和 b 页面在相同域下，c页面在另一个域下。

我们想a和 c进行通讯，必然涉及到跨域, 通过下面的代码，改变window.name的值来实现跨域。

整体实现思路， b.html其实只是个中间代理页面。

- a.html的 iframe先加载c.html页面，此时c.html设置了 window.name = 'test'。
- 在c.html加载完毕，设置iframe的src为b.html, 由于a.html和b.html在同域，且window.name在域名改变页面从新加载后值不变，实现跨域。

```html
<!-- https://localhost:3000/a.html -->

<!DOCTYPE html>
<html lang="en">
<head></head>
<body>
    <iframe src='https://localhost:4000/c.html' onload="onload()" id="iframe"></iframe>
    <script>
        // iframe 加载完会调用 iframe， 防止src 改变出现死循环。
        let first = true
        function onload() {
            if (first) {
                let iframe = document.getElementById('iframe')
                iframe.src = 'https://localhost:3000/b.html'
                first = false
            } else {
                console.log(iframe.contentWindow.name) // 'test'
            }
        }
    </script>
</body>
</html>
```
{: file='a.html'}

```html
<!-- https://localhost:4000/c.html -->
<!DOCTYPE html>
<html lang="en">
<head></head>
<body>
    <script>
        window.name = 'test'
    </script>
</body>
```
{: file='c.html'}


### location.hash
hash 属性是一个可读可写的字符串，该字符串是 URL 的锚部分（从 # 号开始的部分）。

我们准备三个页面：

- https://localhost:3000/a.html
- https://localhost:3000/b.html
- https://localhost:4000/c.html
a页面和 b 页面在相同域下，c页面在另一个域下。

我们想a和 c进行通讯，必然涉及到跨域, 通过下面的代码，改变window.location.hash的值来实现跨域。


```html
<!DOCTYPE html>
<html lang="en">
<head></head>
<body>
    <!-- 通过 hash 给 c.html 传值 -->
    <iframe src='https://localhost:4000/c.html#test' id="iframe"></iframe>
    <script> 
        //  监听 hash 变化
        window.addEventListener('hashchange',()=>{
            console.log(location.hash)
        })
    </script>
</body>
</html>
```
{: file='a.html'}

```html
<!DOCTYPE html>
<html lang="en">
<head></head>
<body>
    <script>
     // 由于 c 加载的 b 页面，所以，window.parent 是 c 页面
     // c 页面的 parent 是 a 页面，然后设置a页面的 hash 值
      window.parent.parent.location.hash =  location.hash
    </script>
</body>
</html>
```
{: file='b.html'}

```html
<!DOCTYPE html>
<html lang="en">
<head></head>
<body>
    <script>
        console.log(location.hash)
        let iframe = document.createElement('iframe')
        iframe.src = 'https://localhost:3000/b.html#test_one'
        document.append(iframe)
    </script>
</body>
</html>
```
{: file='c.html'}


# 总结

在请求资源进行跨域是，推荐使用 CORS 和 JSONP。

在页面资源跨域时推荐使用postMessage 和 document.domain。
