---
layout: post
title: 使用 SpringBoot 发送邮件
date: 2021-04-27 16:11 +0800
categories: [Software Development] 
tags: [Java, Spring, DevDairy]
---


# 依赖
Java 发送邮件依赖 jakarta 项目（原 javaEE）提供的 jakarta.mail 组件, Maven 坐标：
```xml
   <dependency>
      <groupId>com.sun.mail</groupId>
      <artifactId>jakarta.mail</artifactId>
      <version>1.6.4</version>
      <scope>compile</scope>
    </dependency>
```
Spring 官方 又将其进行进一步封装成开箱即用的 spring-boot-starter-mail 项目：
```xml
 <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-mail</artifactId>
 </dependency>
```
在 Spring Boot 项目中我们引入上面的 spring-boot-starter-mail 依赖即可为你的项目集成邮件功能。接下来我们来对邮件功能进行参数配置。


# 邮箱配置
spring-boot-starter-mail 的配置由 MailProperties 配置类提供。在 application.yml 配置文件中以 spring.mail 为前缀。我们来看看都有哪些配置项。
```yml
#  字符集编码 默认 UTF-8
spring.mail.default-encoding=UTF-8
# SMTP 服务器 host  qq邮箱的为 smtp.qq.com 端口 465 587
spring.mail.host=smtp.qq.com
# SMTP 服务器端口 不同的服务商不一样
spring.mail.port=465
#   SMTP 服务器使用的协议
spring.mail.protocol=smtp
# SMTP服务器需要身份验证 所以 要配置用户密码

# 发送端的用户邮箱名
spring.mail.username=usname@Gmail.com
# 发送端的密码 注意保密
spring.mail.password=oooooxxxxxxxx
# 指定mail会话的jndi名称 优先级较高   一般我们不使用该方式
spring.mail.jndi-name=
# 这个比较重要 针对不同的SMTP服务器 都有自己的一些特色配置该属性 提供了这些配置的 key value 封装方案 例如 Gmail SMTP 服务器超时配置 spring.mail.properties.mail.smtp.timeout= 5000
spring.mail.properties.<key> =
# 指定是否在启动时测试邮件服务器连接，默认为false
spring.mail.test-connection=false
```
针对不同的邮箱有不同的配置，所以我们介绍几种我们常用的邮箱配置，可以直接拿来配置。
>但是请注意很多邮箱需要手动开启 SMTP 功能，请务必确保该功能打开。如果在公有云上部署请避免使用 25 端口
{: .prompt-warning }

## QQ 邮箱
```xml
# 需要开启 smtp
spring.mail.host=smtp.qq.com
spring.mail.port=465
# 发件人的邮箱
spring.mail.username=usname@Gmail.com
# qq 邮箱的第三方授权码 并非个人密码
spring.mail.password=afshgskdbgsdghgwwq
#开启ssl 否则 503 错误
spring.mail.properties.mail.smtp.ssl.enable=true
```

## 163 信箱
```xml
# 需要在设置中开启 smtp
spring.mail.host=smtp.163.com
spring.mail.port=465
# 发件人的邮箱
spring.mail.username=youraccount@163.com
# 邮箱的授权码 并非个人密码
spring.mail.password=afshgskdbgsdghgwwq
spring.mail.properties.mail.smtp.ssl.enable=true
spring.mail.properties.mail.imap.ssl.socketFactory.fallback=false
spring.mail.properties.mail.smtp.ssl.socketFactory.class=javax.net.ssl.SSLSocketFactory
spring.mail.properties.mail.smtp.auth=true
spring.mail.properties.mail.smtp.starttls.enable=true
spring.mail.properties.mail.smtp.starttls.required=true
```

## gmail
```xml
spring.mail.host=smtp.gmail.com
spring.mail.port=587
spring.mail.username=youraccount@gmail.com
# 安全建议使用应用程序密码代替Gmail密码。参见相关文档
spring.mail.password=yourpassword

# 个性配置
spring.mail.properties.mail.debug=true
spring.mail.properties.mail.transport.protocol=smtp
spring.mail.properties.mail.smtp.auth=true
spring.mail.properties.mail.smtp.connectiontimeout=5000
spring.mail.properties.mail.smtp.timeout=5000
spring.mail.properties.mail.smtp.writetimeout=5000

# TLS , port 587
spring.mail.properties.mail.smtp.starttls.enable=true

# SSL, post 465
#spring.mail.properties.mail.smtp.socketFactory.port = 465
#spring.mail.properties.mail.smtp.socketFactory.class = javax.net.ssl.SSLSocketFactory
```

## outlook
```xml
spring.mail.host=smtp-mail.outlook.com
spring.mail.port=587
spring.mail.username=youraccount@outlook.com
spring.mail.password=yourpassword

spring.mail.properties.mail.protocol=smtp
spring.mail.properties.mail.tls=true

spring.mail.properties.mail.smtp.auth=true
spring.mail.properties.mail.smtp.starttls.enable=true
spring.mail.properties.mail.smtp.ssl.trust=smtp-mail.outlook.com
```


# 邮件发送服务
配置完毕后我们就可以构建我们自己的邮件发送服务了

## 纯文本邮件
最简单的就是发送纯文本邮件了，完整代码如下：
```java
@Component
public class EmailService {
    @Resource
    private JavaMailSender javaMailSender;
    @Value("${spring.mail.username}")
    private String from;

    /**
     * 发送纯文本邮件.
     *
     * @param to      目标email 地址
     * @param subject 邮件主题
     * @param text    纯文本内容
     */
    public void sendMail(String to, String subject, String text) {
        SimpleMailMessage message = new SimpleMailMessage();

        message.setFrom(from);
        message.setTo(to);
        message.setSubject(subject);
        message.setText(text);
        javaMailSender.send(message);
    }
}
```

## 带附件的邮件
有时候我们需要在邮件中携带附件。我们就需要发送 Mime 信息了，代码如下:
```java
    /**
     * 发送邮件并携带附件.
     * 请注意 from 、 to 邮件服务器是否限制邮件大小
     *
     * @param to       目标email 地址
     * @param subject  邮件主题
     * @param text     纯文本内容
     * @param filePath 附件的路径 当然你可以改写传入文件
     */
    public void sendMailWithAttachment(String to, String subject, String text, String filePath) throws   MessagingException {

        File attachment = new File(filePath);
        MimeMessage mimeMessage = javaMailSender.createMimeMessage();
        MimeMessageHelper helper=new MimeMessageHelper(mimeMessage,true);
        helper.setFrom(from);
        helper.setTo(to);
        helper.setSubject(subject);
        helper.setText(text);
        helper.addAttachment(attachment.getName(),attachment);
        javaMailSender.send(mimeMessage);
    }
```

> 这里需要注意的是 from 、 to 邮件服务器是否限制邮件大小，避免邮件超出限定大小。
{: .prompt-warning }

## 富文本邮件
现在很多的场景是通过电子邮件发送宣传营销的富文本，甚至图文并茂带链接。所以这个功能非常实用。可以通过前端编写适配邮件的 html 模板。将数据动态化注入模板即可。我们先来写一个 html :
```html
<html lang="en">
<head>
    <meta http-equiv="content-type" content="text/html" charset="UTF-8">
    <title></title>
</head>
<body>
<h2>你好，朋友</h2>
</body>
</html>
```
上面大致上跟我们平时的 html 基本一致，区别在于如果有内嵌的图片元素比如 img 标签 ，其 src 中需要使用占位符，规则为 cid:后紧接着一个你自己定义的标记。比如 qr 。后面会在代码中体现这个 qr。
如果使用占位符则必须指定 <meta http-equiv="content-type" content="text/html" charset="UTF-8"> 否则图片无法显示！ 当然你也可以直接把图片的 url 链接写入模板，就像下面:
```html
<html lang="en">
<body>
  <h2>你好，朋友</h2>
</body>
</html>
```
然后我们编写 Java 代码 如下：
```java
    /**
     * 发送富文本邮件.
     *
     * @param to       目标email 地址
     * @param subject  邮件主题
     * @param text     纯文本内容
     * @param filePath 附件的路径 当然你可以改写传入文件
     */
    public void sendRichMail(String to, String subject, String text, String filePath) throws   MessagingException {

        MimeMessage mimeMessage = javaMailSender.createMimeMessage();
        MimeMessageHelper helper=new MimeMessageHelper(mimeMessage,true);
        helper.setFrom(from);
        helper.setTo(to);
        helper.setSubject(subject);

        helper.setText(text,true);
        // 图片占位写法  如果图片链接写入模板 注释下面这一行
        helper.addInline("qr",new FileSystemResource(filePath));
        javaMailSender.send(mimeMessage);

    }
```

> 如果你采用类似上面第二个 HTML 模板，图片逻辑就不需要了，注释掉 helper.addInline() 方法即可
{: .prompt-tip }

