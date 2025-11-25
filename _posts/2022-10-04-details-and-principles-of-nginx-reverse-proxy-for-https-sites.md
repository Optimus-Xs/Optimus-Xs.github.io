---
layout: post
title: Nginx反向代理Https站点的细节和原理
date: 2022-10-04 12:38 +0800
categories: [ServerOperation] 
tags: [Nginx]
---

## 反代中配置上游为什么需要SNI

在配置 CDN（内容分发网络）或任何其他反向代理时，需要配置**回源 SNI (Server Name Indication)** 的根本原因是为了正确地与使用 HTTPS/SSL 的源站建立连接，尤其当源站的**同一 IP 地址上托管了多个 HTTPS 域名**时。

如果没有回源 SNI，代理服务器（如 CDN 边缘节点或 Nginx）将无法知道它应该请求哪个域名的证书，从而可能导致安全问题或连接失败。

**💡 为什么需要回源 SNI？**

1. 解决一 IP 多域名 HTTPS 的问题
    
    这是 SNI 诞生的主要原因：

    - **传统 HTTPS 限制**： 在 SNI 出现之前，一次 TLS/SSL 握手是在 HTTP 请求之前发生的。由于当时握手时无法告知服务器客户端要访问哪个域名，服务器只能返回绑定到该 IP 地址的默认证书。这意味着一个 IP 只能高效地托管一个 HTTPS 域名。

    - **SNI 机制**： SNI 是 TLS 协议的一个扩展，允许客户端（在这里是 CDN 节点或反向代理）在发起 TLS 握手的 Client Hello 消息中，明确地带上它想要访问的 目标主机名（即域名）。

    - **回源应用**： 当 CDN 或反向代理向源站发起 HTTPS 连接时，它充当客户端。开启回源 SNI 后，代理会将用户请求的域名（或配置的特定域名）放入 SNI 字段，告知源站：“请给我提供这个域名的证书。”源站就能根据这个名称，从其多个证书中选择正确的那个返回。

2. 保证证书验证成功（安全需求）
    
    开启回源 SNI 是保证证书验证成功的前提：

    - **如果未启用 SNI**： 源站返回的是一个默认证书，这个默认证书很可能与代理要访问的域名不匹配。

    - **如果代理启用了证书验证**： 代理会检查返回证书的主机名（Common Name 或 SANs）是否与目标域名一致。如果不一致，代理会认为证书无效，连接将失败，返回错误（例如 Nginx 的 upstream SSL certificate verify error）。

    - **启用 SNI 的作用**： 启用 SNI 后，代理能拿到正确的证书，证书主机名与目标域名一致，验证才能通过，从而保证了回源链路的 安全性和信任度。

3. CDN 场景下的重要性
    
    - **对于 CDN 来说，回源 SNI 尤为关键**：

    - **源站负载均衡**： 很多大型源站服务商会将不同用户的域名 CNAME 解析到同一个 源站 IP 地址 上。CDN 节点必须通过 SNI 明确区分它要回源的是哪一个域名。

    - **成本效率**： SNI 允许源站服务商在更少的 IP 地址上托管更多的客户，提高了 IP 地址的利用效率，同时也简化了源站架构。

## SNI机制

SNI（Server Name Indication，服务器名称指示）是 TLS（传输层安全协议）的一个扩展功能，它的作用是解决 一个 IP 地址上托管多个使用 HTTPS 的域名 时，服务器无法确定应返回哪个 SSL/TLS 证书的问题

> SNI 的核心作用就是让 **客户端**（浏览器、Nginx 代理、CDN 节点等）能够在 TLS 握手开始时，就明确告诉 **服务器** 它想要连接哪个域名
{: .prompt-tip }

**SNI 的实现原理**

SNI 机制通过将目标域名信息加入到未加密的 `Client Hello` 消息中来解决这个问题

整个流程可以概括为以下 4 个步骤:

1. 发起连接 (**客户端(Nginx/浏览器)**)  

    客户端通过目标 IP 地址(通常是通过 DNS 将域名解析得到 IP)和 443 端口连接服务器。

2. 发送 SNI (**客户端(Nginx/浏览器)**)  

    客户端发送 `Client Hello` 消息。这个消息中包含一个名为 `server_name` 的扩展字段，字段值为客户端想要访问的域名，例如：`www.example.com`。

    > 关键： `Client Hello` 消息及其 SNI 字段是未加密的，因此网络上的中间设备（如防火墙、ISP）可以查看到这个域名信息。
    {: .prompt-warning }

3. 返回正确证书 (**服务器(源站/Web Server)**)  

    服务器接收到 Client Hello 消息，读取其中的 SNI 字段（www.example.com）。根据这个域名，服务器从其证书库中准确地找到并返回 www.example.com 对应的 SSL/TLS 证书。


4. 继续握手 (**双方**) 

    客户端验证证书的合法性（CA、有效期、域名匹配），然后双方交换密钥，完成 TLS 握手，开始加密通信。

    > 如果客户端没有启用证书验证（如您的 Nginx 默认配置），这一步只是接受证书，不执行严格的匹配检查。
    {: .prompt-tip }

> 尽管 SNI 极大地解决了多域名 HTTPS 的问题，但它有一个重要的 安全局限性：**SNI 域名是明文传输的**。
>
> 在**步骤 2** 中，由于 TLS 握手尚未完成，加密密钥尚未生成，所以 SNI 字段中的域名是以**明文**形式在网络上传输的。这意味着任何在客户端和服务器之间进行监听的中间人（如 ISP、政府机构、公司网络管理员）都可以看到客户端正在访问的域名，即使后续的数据传输是加密的。
>
> 为了解决这个隐私泄露问题，业界提出了下一代的技术：
> 
> - **ESNI (Encrypted SNI)**： 一种较早的尝试，旨在加密 `Client Hello` 消息中的 SNI 部分。
> - **SEH (Server Hello Extensions)**： 这是 IETF 正在推动的最新标准，用于取代 ESNI，目标是实现加密客户端握手（Encrypted Client Hello, ECH），它不仅加密 SNI，还会加密 `Client Hello` 消息中的其他敏感扩展信息，进一步增强隐私保护
{: .prompt-tip }

## Nginx中的SNI配置

### 配置流程

要在 Nginx 中为上游 HTTPS 连接启用 SNI，必须使用 `proxy_ssl_server_name on`; 指令。同时建议使用 `proxy_ssl_name` 来精确控制发送给上游的域名。

以下是一个典型的，启用 SNI 和证书验证的反向代理配置

```conf
server {
    listen 80;
    server_name www.frontend.com;

    location / {
        # 1. 指定上游服务器地址 (使用 HTTPS)
        proxy_pass https://upstream.example.com;

        # 2. **启用 SNI**：将服务器名称发送给上游
        proxy_ssl_server_name on;
        
        # 3. 【可选】明确指定 SNI 名称（覆盖默认的 $proxy_host）
        #    如果 upstream.example.com 的证书是 example.com 的，可能需要这样设置：
        # proxy_ssl_name example.com; 

        # 4. **启用上游证书验证**（强烈推荐，为了安全）
        proxy_ssl_verify on;
        
        # 5. 指定信任的 CA 证书文件路径
        proxy_ssl_trusted_certificate /etc/nginx/conf/ssl/ca-chain.pem; 
    }
}
``` 
{: file='nginx.conf'}

- `proxy_ssl_server_name on;`: Nginx 会在 `Client Hello` 消息中包含 SNI 字段，以便上游服务器返回正确的证书
- `proxy_ssl_name name;`: 默认为 `$proxy_host`，即 `proxy_pass` URL 中的主机部分。例如：`proxy_pass` `https://backend.example.com`; 则 SNI 默认为 `backend.example.com`。也可以使用变量或字符串显式设置，例如：`proxy_ssl_name $host`;（使用客户端请求头中的 Host）或 `proxy_ssl_name specific-backend.com;`

`proxy_ssl_server_name` 的[官方说明文档](https://nginx.org/en/docs/http/ngx_http_proxy_module.html#proxy_ssl_server_name)如下

```
Syntax:	proxy_ssl_server_name on | off;
Default:	
proxy_ssl_server_name off;
Context:	http, server, location
This directive appeared in version 1.7.0.

Enables or disables passing of the server name through TLS Server Name Indication extension (SNI, RFC 6066) when establishing a connection with the proxied HTTPS server.
``` 
{: file='Nginx Doc'}

`proxy_ssl_name` 的[官方说明文档](https://nginx.org/en/docs/http/ngx_http_proxy_module.html#proxy_ssl_name)如下

```
Syntax:	proxy_ssl_name name;
Default:	
proxy_ssl_name $proxy_host;
Context:	http, server, location
This directive appeared in version 1.7.0.

Allows overriding the server name used to verify the certificate of the proxied HTTPS server and to be passed through SNI when establishing a connection with the proxied HTTPS server.

By default, the host part of the proxy_pass URL is used.
```
{: file='Nginx Doc'}

### 配置 SNI 后的证书验证行为

默认情况下，Nginx 在代理 HTTPS 上游服务器时，不会验证上游证书的合法性，也不会比对证书的 CommonName（或 SANs）。

> CommonName（通用名称）是证书的 Subject (主体) 字段的一部分，它通常包含证书所保护的 **完全限定域名 (FQDN)**，例如 `www.example.com`
>
> 虽然 CommonName 过去是主要标识，但在现代证书标准中，它已经逐渐被 Subject Alternative Names (SANs) 所取代
>
> - **CommonName 的局限性**： CommonName 只能包含一个域名。如果要保护多个域名（如 `www.example.com` 和 `blog.example.com`），或者同时保护顶级域名和泛域名，CommonName 就无法满足要求。
> - **SANs (主体备用名称)**： SANs 是证书中的一个扩展字段，可以包含多个域名（包括域名、IP 地址、电子邮件地址等）。现代浏览器和服务器（包括Nginx）在进行证书校验时，会优先检查 SANs 字段。如果 SANs 中找不到匹配的域名，才会退而求其次检查 CommonName
{: .prompt-tip }

这个默认行为由以下指令控制：

`proxy_ssl_verify` 其默认值为 `off` 

- **默认不验证**: Nginx 即使收到无效、过期或自签名的证书，也会继续连接。
- **默认不比对**: 因为总体的验证是关闭的，所以它不会检查证书上的域名是否与请求的域名匹配。

`proxy_ssl_verify` 的[官方说明文档](https://nginx.org/en/docs/http/ngx_http_proxy_module.html#proxy_ssl_verify)如下

```
Syntax:	proxy_ssl_verify on | off;
Default:	
proxy_ssl_verify off;
Context:	http, server, location
This directive appeared in version 1.7.0.

Enables or disables verification of the proxied HTTPS server certificate.
```
{: file='Nginx Doc'}

**为什么要默认关闭证书验证？**

这个默认设置通常是为了最大限度的兼容性，尤其在以下场景：

- **内部网络**： 在完全受控的内部网络或微服务架构中，开发者可能使用了自签名证书，或者证书配置不规范，关闭验证可以简化部署。
- **回源兼容性**： 默认关闭可以避免因为上游服务器证书链不完整或 CommonName 设置不准确而导致 Nginx 连接中断。

### Nginx的行为总结

Nginx作用反向代理与上游服务器使用HTTPS建连时，

- 默认不启用SNI，使用`proxy_ssl_server_name on;`参数启用；
- 默认不验证上游服务器返回的证书，使用`proxy_ssl_verify on;`
- 开启上游证书验证后Nginx会使用配置文件中指定的`CA`验证上游服务器返回证书的合法性，同时也会比对证书中的`CommonName`信息。

## Nginx反代Https的最佳实践

综上所述，配置一个安全、高效且可靠的 Nginx 反向代理（特别是针对 HTTPS 上游）的最佳实践案例，主要涉及以下几个关键方面。

最佳实践就是要确保 客**户端连接安全**、**回源连接安全**，以及 **性能优化**。

- 基础配置与性能优化

| 配置目标   | 关键配置项                      | 说明                                                                              |
| :--------- | :------------------------------ | :-------------------------------------------------------------------------------- |
| 持久连接   | keepalive                       | 在 upstream 块中配置，允许 Nginx 重复使用与上游服务器的连接，显著提升回源性能。   |
| HTTP 版本  | proxy_http_version 1.1;         | 必须设置，以启用连接重用和更好的数据传输效率。                                    |
| 清除连接头 | proxy_set_header Connection ""; | 必须与 keepalive 配合使用，清除客户端可能传入的 Connection 头，防止干扰持久连接。 |
| 超时设置   | proxy_connect_timeout 5s;       | 设置合理的连接超时时间，防止因上游无响应而长时间阻塞。                            |

- 回源安全配置（SNI 与证书验证）

| 配置目标     | 关键配置项                                                   | 说明                                                                                                                                                   |
| :----------- | :----------------------------------------------------------- | :----------------------------------------------------------------------------------------------------------------------------------------------------- |
| 启用 SNI     | proxy_ssl_server_name on;                                    | 【重要】 确保 Nginx 在 TLS 握手时发送目标域名，使上游返回正确的证书。                                                                                  |
| 名称指定     | proxy_ssl_name $host;                                        | 【推荐】 确保 SNI 名称与客户端请求的 Host 头一致，适用于多域名代理到同一源站的场景。 (如果回源目标是固定的内部服务器，可使用 $proxy_host 或固定字符串) |
| 启用证书验证 | proxy_ssl_verify on;                                         | 【安全】 开启严格的证书验证，防止中间人攻击和连接到错误服务器。                                                                                        |
| 信任链       | proxy_ssl_trusted_certificate /etc/ssl/certs/trusted_ca.pem; | 【安全】 指定用于验证上游证书合法性的 CA 文件路径。                                                                                                    |
| 代理证书     | proxy_ssl_certificate 和 proxy_ssl_certificate_key           | 【双向验证（可选）】 如果上游服务器也要求 Nginx 提供客户端证书进行身份验证（双向 TLS），则需要配置这些项。                                             |

- 请求头透传配置
   
| 配置目标 | 关键配置项                                                   | 说明                                       |
| :------- | :----------------------------------------------------------- | :----------------------------------------- |
| 真实IP   | proxy_set_header X-Real-IP $remote_addr;                     | 透传用户的真实 IP 地址。                   |
| 代理链   | proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for; | 记录经过的所有代理 IP 地址，确保日志准确。 |
| 协议透传 | proxy_set_header X-Forwarded-Proto $scheme;                  | 告诉上游客户端使用的是 HTTP 还是 HTTPS。   |
| 主机名   | proxy_set_header Host $host;                                 | 转发客户端请求的原始 Host 域名。           |

**Nginx 反向代理最佳实践配置模板**

```conf
http {
    # 启用上游连接池，提升性能
    upstream backend_pool {
        # 后端服务器列表（假设后端使用HTTPS）
        server 192.168.1.100:443; 
        keepalive 32; # 启用连接重用，保持32个空闲连接
    }

    server {
        listen 443 ssl;
        server_name api.example.com;
        
        # ... SSL证书配置（这里是前端面向客户端的证书） ...

        location / {
            # 1. 基础配置与性能优化
            proxy_pass https://backend_pool;
            proxy_http_version 1.1;
            proxy_set_header Connection ""; # 清除连接头，配合 keepalive

            # 2. 安全配置（回源 HTTPS）
            proxy_ssl_verify on;                       # 开启证书验证
            proxy_ssl_trusted_certificate /etc/ssl/certs/trusted_ca.pem; # 指定信任CA
            proxy_ssl_server_name on;                  # 启用 SNI 
            proxy_ssl_name $host;                      # SNI名称和证书验证名称使用客户端请求的Host

            # 3. 请求头透传
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
}
``` 
{: file='nginx.conf'}

# 参考

- [Nginx反向代理，当后端为Https时的一些细节和原理](https://blog.dianduidian.com/post/nginx%E5%8F%8D%E5%90%91%E4%BB%A3%E7%90%86%E5%BD%93%E5%90%8E%E7%AB%AF%E4%B8%BAhttps%E6%97%B6%E7%9A%84%E4%B8%80%E4%BA%9B%E7%BB%86%E8%8A%82%E5%92%8C%E5%8E%9F%E7%90%86/)