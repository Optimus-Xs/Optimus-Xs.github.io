---
layout: post
title: SpringSecurity 集成JWT权限验证
date: 2021-03-01 22:46 +0800
categories: [Software Development] 
tags: [Java, Spring, SpringSecurity, DevDairy]
---

一般来讲，对于RESTful API都会有认证(Authentication)和授权(Authorization)过程，保证API的安全性。

Authentication指的是确定这个用户的身份，Authorization是确定该用户拥有什么操作权限。

认证方式一般有三种

- Basic Authentication

这种方式是直接将用户名和密码放到Header中，使用Authorization: Basic ，使用最简单但是最不安全。

- TOKEN认证

这种方式也是再HTTP头中，使用Authorization: Bearer <token>，使用最广泛的TOKEN是JWT，通过签名过的TOKEN。

- OAuth2.0

这种方式安全等级最高，但是也是最复杂的。如果不是大型API平台或者需要给第三方APP使用的，没必要整这么复杂。

一般项目中的RESTful API使用JWT来做认证就足够了。

简要的说明下为什么用JWT，因为要实现完全的前后端分离以及多客户端平台的认证，所以不可能使用session，cookie的方式进行鉴权， 所以JWT就被派上了用场，可以通过一个加密密钥来进行前后端的鉴权。

程序逻辑:

1. 我们POST用户名与密码到/login进行登入，如果成功返回一个加密token，失败的话直接返回401错误。
2. 之后用户访问每一个需要权限的网址请求必须在header中添加Authorization字段，例如Authorization: token，token为密钥。
3. 后端对每个请求会进行token的校验，如果不通过直接返回401。

## SecurityConfig
Spring Security 配置文件, 设置需要被保护的API，同时添加JWTFilter到Spring Security的认证链
```java
@Configuration
@EnableWebSecurity
public class SecurityConfig extends WebSecurityConfigurerAdapter {


    @Resource
    CustomEntryPoint customEntryPoint;

    @Resource
    private CustomAccessDeniedHandler customAccessDeniedHandler;


    @Override
    protected void configure(HttpSecurity http) throws Exception {
        http    .csrf().disable()
                .authorizeRequests()
                .antMatchers(HttpMethod.POST, "/api/login","/api/signUp","/").permitAll()
                .antMatchers(HttpMethod.GET, "/").permitAll()
                .anyRequest().hasAuthority("ROLE_USER")
                .and()
                // 添加一个过滤器 所有访问 /login 的请求交给 JWTLoginFilter 来处理 这个类处理所有的JWT相关内容
                .addFilterBefore(new JWTLoginFilter("/api/login", authenticationManager()),
                        UsernamePasswordAuthenticationFilter.class)
                // 添加一个过滤器验证其他请求的Token是否合法
                .addFilterBefore(new JWTAuthenticationFilter(),
                        UsernamePasswordAuthenticationFilter.class)
                .exceptionHandling()
                .authenticationEntryPoint(customEntryPoint)
                .accessDeniedHandler(customAccessDeniedHandler);
    }

    @Override
    protected void configure(AuthenticationManagerBuilder auth) throws Exception {
        // 使用自定义身份验证组件
        auth.authenticationProvider(new CustomAuthenticationProvider());
    }
    @Bean
    public static PasswordEncoder passwordEncoder() {
        return NoOpPasswordEncoder.getInstance();
    }
}
```

## JWTLoginFilter

验证登录请求并发放JWT Token

```java
class JWTLoginFilter extends AbstractAuthenticationProcessingFilter {

    public JWTLoginFilter(String url, AuthenticationManager authManager) {
        super(new AntPathRequestMatcher(url));
        setAuthenticationManager(authManager);
    }

    @Override
    public Authentication attemptAuthentication(HttpServletRequest req, HttpServletResponse res) throws AuthenticationException, IOException, ServletException {
        // JSON反序列化成 User
        User user = new ObjectMapper().readValue(req.getInputStream(), User.class);

        // 返回一个验证令牌
        return getAuthenticationManager().authenticate(
                new UsernamePasswordAuthenticationToken(
                        user.getUsername(),
                        user.getPassword()
                )
        );
    }

    @Override
    protected void successfulAuthentication(
            HttpServletRequest req,
            HttpServletResponse res, FilterChain chain,
            Authentication auth) throws IOException, ServletException {

        TokenAuthenticationService.addAuthentication(res, auth.getName());
    }


    @Override
    protected void unsuccessfulAuthentication(HttpServletRequest request, HttpServletResponse response, AuthenticationException failed) throws IOException, ServletException {
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);
        response.setStatus(HttpStatus.OK.value());
        response.setCharacterEncoding("UTF-8");
        response.getWriter().write(new ObjectMapper().writeValueAsString(new CommonResult<>(CustomStatusEnum.LOGIN_FAIL)));
    }
}
```

## JWTAuthenticationFilter
拦截分发所有和使用JWT认证的请求，同时调用TokenAuthenticationService.getAuthentication()方法进行认证
```java
public class JWTAuthenticationFilter extends GenericFilterBean {

    @Override
    public void doFilter(ServletRequest request,
                         ServletResponse response,
                         FilterChain filterChain)
            throws IOException, ServletException {
        Authentication authentication = TokenAuthenticationService
                .getAuthentication((HttpServletRequest) request);

        SecurityContextHolder.getContext()
                .setAuthentication(authentication);
        filterChain.doFilter(request, response);
    }
}

```

## TokenAuthenticationService
用于生成和验证JWT，为两个Filter提供服务
```java
class TokenAuthenticationService {
    static final long EXPIRATION_TIME = 432_000_000;     // 5天
    static final String SECRET = "*****";            // JWT密码
    static final String TOKEN_PREFIX = "Bearer";        // Token前缀
    static final String HEADER_STRING = "Authorization";// 存放Token的Header Key

    // JWT生成方法
    static void addAuthentication(HttpServletResponse response, String username) {

        // 生成JWT
        String JWT = Jwts.builder()
                // 保存权限（角色）
                .claim("authorities", "ROLE_USER,AUTH_WRITE")
                // 用户名写入标题
                .setSubject(username)
                // 有效期设置
                .setExpiration(new Date(System.currentTimeMillis() + EXPIRATION_TIME))
                // 签名设置
                .signWith(SignatureAlgorithm.HS512, SECRET)
                .compact();

        // 将 JWT 写入 body
        try {
            response.setContentType(MediaType.APPLICATION_JSON_VALUE);
            response.setStatus(HttpStatus.OK.value());
            response.setCharacterEncoding("UTF-8");
            response.getWriter().write(new ObjectMapper().writeValueAsString(new CommonResult<>(CustomStatusEnum.LOGIN_SUCCESS.getStatus(), CustomStatusEnum.LOGIN_SUCCESS.getMessage(), JWT)));
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    // JWT验证方法
    static Authentication getAuthentication(HttpServletRequest request) {
        // 从Header中拿到token
        String token = request.getHeader(HEADER_STRING);

        if (token != null) {
            // 解析 Token
            Claims claims = Jwts.parser()
                    // 验签
                    .setSigningKey(SECRET)
                    // 去掉 Bearer
                    .parseClaimsJws(token.replace(TOKEN_PREFIX, ""))
                    .getBody();

            // 拿用户名
            String user = claims.getSubject();

            // 得到 权限（角色）
            List<GrantedAuthority> authorities =  AuthorityUtils.commaSeparatedStringToAuthorityList((String) claims.get("authorities"));

            // 返回验证令牌
            return user != null ?
                    new UsernamePasswordAuthenticationToken(user, null, authorities) :
                    null;
        }
        return null;
    }
}
```

