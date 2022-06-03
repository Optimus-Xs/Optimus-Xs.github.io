---
layout: post
title: SpringBoot 配置 CORS 跨域请求的三种方法
date: 2021-04-07 13:56 +0800
categories: [Software Development] 
tags: [Java, Spring, DevDairy]
---

# 前言
Springboot跨域问题，是当前主流web开发人员都绕不开的难题。但我们首先要明确以下几点

- 跨域只存在于浏览器端，不存在于安卓/ios/Node.js/python/ java等其它环境
- 跨域请求能发出去，服务端能收到请求并正常返回结果，只是结果被浏览器拦截了。
- 之所以会跨域，是因为受到了同源策略的限制，同源策略要求源相同才能正常进行通信，即协议、域名、端口号都完全一致。

浏览器出于安全的考虑，使用 XMLHttpRequest对象发起 HTTP请求时必须遵守同源策略，否则就是跨域的HTTP请求，默认情况下是被禁止的。换句话说，浏览器安全的基石是同源策略。

同源策略限制了从同一个源加载的文档或脚本如何与来自另一个源的资源进行交互。这是一个用于隔离潜在恶意文件的重要安全机制。

# 一、什么是CORS？
先给出一个熟悉的报错信息，让你找到家的感觉~

> Access to XMLHttpRequest at 'http://192.168.1.1:8080/app/easypoi/importExcelFile' from origin 'http://localhost:8080' has been blocked by CORS policy: No 'Access-Control-Allow-Origin' header is present on the requested resource.
{: .prompt-danger }

CORS是一个W3C标准，全称是”跨域资源共享”（Cross-origin resource sharing），允许浏览器向跨源服务器，发出XMLHttpRequest请求，从而克服了AJAX只能同源使用的限制。

它通过服务器增加一个特殊的Header[Access-Control-Allow-Origin]来告诉客户端跨域的限制，如果浏览器支持CORS、并且判断Origin通过的话，就会允许XMLHttpRequest发起跨域请求。

## CORS Header
- Access-Control-Allow-Origin: http://www.xxx.com
- Access-Control-Max-Age：86400
- Access-Control-Allow-Methods：GET, POST, OPTIONS, PUT, DELETE
- Access-Control-Allow-Headers: content-type
- Access-Control-Allow-Credentials: true

| CORS Header属性                  | 解释                                                           |
| :------------------------------- | :------------------------------------------------------------- |
| Access-Control-Allow-Origin      | 允许http://www.xxx.com域（自行设置，这里只做示例）发起跨域请求 |
| Access-Control-Max-Age           | 设置在86400秒不需要再发送预校验请求                            |
| Access-Control-Allow-Methods     | 设置允许跨域请求的方法                                         |
| Access-Control-Allow-Headers     | 允许跨域请求包含content-type                                   |
| Access-Control-Allow-Credentials | 设置允许Cookie                                                 |


# 二、SpringBoot跨域请求处理方式

## 方法一、直接采用SpringBoot的注解@CrossOrigin（也支持SpringMVC）
简单粗暴的方式，Controller层在需要跨域的类或者方法上加上该注解即可
```java
@RestController
@CrossOrigin
@RequestMapping("/situation")
public class SituationController extends PublicUtilController {
 
    @Autowired
    private SituationService situationService;
    // log日志信息
    private static Logger LOGGER = Logger.getLogger(SituationController.class);
} 
```
但每个Controller都得加，太麻烦了，怎么办呢，加在Controller公共父类（PublicUtilController）中，所有Controller继承即可。
```java
@CrossOrigin
public class PublicUtilController {
    /**
     * 公共分页参数整理接口
     *
     * @param currentPage
     * @param pageSize
     * @return
     */
    public PageInfoUtil proccedPageInfo(String currentPage, String pageSize) {
 
        /* 分页 */
        PageInfoUtil pageInfoUtil = new PageInfoUtil();
        try {
            /*
             * 将字符串转换成整数,有风险, 字符串为a,转换不成整数
             */
            pageInfoUtil.setCurrentPage(Integer.valueOf(currentPage));
            pageInfoUtil.setPageSize(Integer.valueOf(pageSize));
        } catch (NumberFormatException e) {
        }
        return pageInfoUtil;
    }
}
```
当然，这里虽然指SpringBoot，SpringMVC也是同样的，但要求在Spring4.2及以上的版本

> SpringMVC使用@CrossOrigin使用场景要求
>  - jdk1.8+
>  - Spring4.2+
{: .prompt-tip }

## 方法二、处理跨域请求的Configuration
增加一个配置类，CrossOriginConfig.java。继承WebMvcConfigurerAdapter或者实现WebMvcConfigurer接口，其他都不用管，项目启动时，会自动读取配置。
```java
@Configuration
public class CorsConfig extends WebMvcConfigurerAdapter {
    static final String ORIGINS[] = new String[] { "GET", "POST", "PUT", "DELETE" };
    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/**").allowedOrigins("*").allowCredentials(true).allowedMethods(ORIGINS).maxAge(3600);
    }
```

## 方法三、采用过滤器（filter）的方式
同方法二加配置类，增加一个CORSFilter 类，并实现Filter接口即可，其他都不用管，接口调用时，会过滤跨域的拦截。
```java
@Component
@Order(Integer.MIN_VALUE)
@WebFilter(urlPatterns = "/**", filterName = "CorsConfigFilter")
public class CorsConfigFilter implements Filter {

    static final String METHODS = "GET, POST, PUT, DELETE, OPTIONS";
    static final String HEADERS = "Content-Type,X-CAF-Authorization-Token,sessionToken,Authorization";

    private CustomApplicationConfig customApplicationConfig;

    @Autowired
    public CorsConfigFilter(CustomApplicationConfig customApplicationConfig) {
        this.customApplicationConfig = customApplicationConfig;
    }

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {
        String ORIGINS = customApplicationConfig.getCorsAllowed();
        request.setCharacterEncoding("utf-8");
        response.setCharacterEncoding("utf-8");
        HttpServletResponse res = (HttpServletResponse) response;
        res.addHeader("Access-Control-Allow-Credentials", "false");
        res.addHeader("Access-Control-Allow-Origin", ORIGINS);
        res.addHeader("Access-Control-Allow-Methods", METHODS);
        res.addHeader("Access-Control-Allow-Headers", HEADERS);
        res.addHeader("Access-Control-Expose-Headers", "Content-Disposition");

        if (((HttpServletRequest) request).getMethod().equals("OPTIONS")) {
            response.getWriter().println("Preflight Done");
            return;
        }
        chain.doFilter(request, response);
    }
}
```
