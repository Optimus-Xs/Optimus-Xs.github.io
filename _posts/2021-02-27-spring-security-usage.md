---
layout: post
title: SpringSecurity 使用方法
date: 2021-02-27 14:41 +0800
categories: [Software Development] 
tags: [Java, Spring, SpringSecurity, DevDairy]
---

# 简介
Spring Security 是一个相对复杂的安全管理框架，功能比 Shiro 更加强大，权限控制细粒度更高，对 OAuth 2 的支持也更友好。
由于 Spring Security 源自 Spring 家族，因此可以和 Spring 框架无缝整合，特别是 Spring Boot 中提供的自动化配置方案，可以让 Spring Security 的使用更加便捷。

# 依赖配置
```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-security</artifactId>
</dependency>
```

# 基础用法
首先在项目添加一个简单的API接口：
```java
@RestController
public class HelloController {
    @GetMapping("/hello")
    public String hello() {
        return "Welcome to Optimus-Xs.github.io";
    }
}
```
接着启动项目直接访问 /hello 接口则会自动跳转到登录页面，这时所有的API接口都被Spring Security保护了

默认用户名是 user，而登录密码则在每次启动项目时随机生成，我们可以在项目启动日志中找到

# Spring Security 配置文件

## SecurityConfig 

Spring Security的配置类可以继承 WebSecurityConfigurerAdapter 来实现

```java
@Configuration
@EnableWebSecurity
@EnableGlobalMethodSecurity(prePostEnabled=true)
public class SecurityConfig extends WebSecurityConfigurerAdapter {


    @Resource
    CustomEntryPoint customEntryPoint;

    @Resource
    private CustomAccessDeniedHandler customAccessDeniedHandler;


    private UserRepository userRepository;
    @Autowired
    public SecurityConfig( UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @Override
    protected void configure(HttpSecurity http) throws Exception {
        http    .csrf().disable()
                .authorizeRequests()
                .antMatchers(HttpMethod.POST, "/api/login","/api/signUp","/","/api/wxLogin").permitAll()
                .antMatchers(HttpMethod.GET, "/").permitAll()
                .antMatchers(HttpMethod.OPTIONS, "/**").permitAll()
                .anyRequest().hasAuthority("ROLE_USER")
                .and()
                // 添加一个过滤器 所有访问 /login 的请求交给 JWTLoginFilter 来处理 这个类处理所有的JWT相关内容
                .addFilterBefore(new JWTLoginFilter("/api/login", authenticationManager(),userRepository),
                        UsernamePasswordAuthenticationFilter.class)
                // 添加一个过滤器验证其他请求的Token是否合法
                .addFilterBefore(new JWTAuthenticationFilter(),
                        UsernamePasswordAuthenticationFilter.class)
                .exceptionHandling()
                .authenticationEntryPoint(customEntryPoint)
                .accessDeniedHandler(customAccessDeniedHandler);
    }

    @Override
    protected void configure(AuthenticationManagerBuilder auth) {
        // 使用自定义身份验证组件
        auth.authenticationProvider(new CustomAuthenticationProvider());
    }
    @Bean
    public static PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
}
```

此配置文件中包含选型：
- 除/api/login、/api/signUp、/api/wxLogin 所有登录注册相关API开放
- Get访问主页根目录开放
- 所有Option请求开放，保证CORS的预请求能正常访问
- 使用自定义的身份认证组件，不使用SpringSecurity自动生成的简单认证，而让我们可以从数据库读取用户信息认证
- 添加两个Filter JWTLoginFilter 和 JWTAuthenticationFilter来处理JWT的颁发和验证
- 配置用户密码使用BCrypt单向加密算法
- 配置 CustomAccessDeniedHandler 自定义拦截器统一已通过身份验证但无权限的403返回格式（一个用户试图访问其他用户私有资源时）
- 配置 CustomEntryPoint 自定义拦截器统一未登录的403返回格式

# 从数据库读取用户信息登录

## CustomAuthenticationProvider
CustomAuthenticationProvider 是自定义身份认证验证组件，使SpringSecurity通过读取数据库的用户信息验证
```java
@Component
public class CustomAuthenticationProvider implements AuthenticationProvider {

    private NoteHubUserDetailsService noteHubUserDetailsService;
    private BCryptPasswordEncoder bCryptPasswordEncoder;

    private static CustomAuthenticationProvider customAuthenticationProvider;

    @PostConstruct //通过@PostConstruct实现初始化bean之前进行的操作
    public void init() {
        customAuthenticationProvider = this;
        // 初使化时将已静态化的testService实例化
    }

    @Autowired
    public void setNoteHubUserDetailsService(NoteHubUserDetailsService noteHubUserDetailsService, BCryptPasswordEncoder bCryptPasswordEncoder) {
        this.noteHubUserDetailsService = noteHubUserDetailsService;
        this.bCryptPasswordEncoder = bCryptPasswordEncoder;
    }

    @Override
    public Authentication authenticate(Authentication authentication) throws AuthenticationException {
        // 获取认证的用户名 & 密码
        String name = authentication.getName();
        String password = authentication.getCredentials().toString();
        UserDetails userDetails = customAuthenticationProvider.noteHubUserDetailsService.loadUserByUsername(name);

        // 认证逻辑
        if (customAuthenticationProvider.bCryptPasswordEncoder.matches(password,userDetails.getPassword())) {

            // 这里设置权限和角色
            ArrayList<GrantedAuthority> authorities = new ArrayList<>();
            authorities.add(new GrantedAuthorityImpl("ROLE_USER"));
            authorities.add(new GrantedAuthorityImpl("AUTH_WRITE"));
            // 生成令牌
            return new UsernamePasswordAuthenticationToken(name, password, authorities);
        } else {
            throw new BadCredentialsException("密码错误~");
        }
    }

    // 是否可以提供输入类型的认证服务
    @Override
    public boolean supports(Class<?> authentication) {
        return authentication.equals(UsernamePasswordAuthenticationToken.class);
    }
}
```
## NoteHubUserDetailsService
NoteHubUserDetailsService 用于从调用Service层的接口从数据库读取用户数据供CustomAuthenticationProvider使用
```java
@Service
@Configuration
public class NoteHubUserDetailsService implements UserDetailsService {
    private final UserService userService;

    @Autowired
    public NoteHubUserDetailsService(UserService userService) {
        this.userService = userService;
    }

    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        ml.notehub.core.model.entity.User user = userService.getUserByUsername(username);
        if (user == null) {
            throw new UsernameNotFoundException("用户不存在");
        }
        List<SimpleGrantedAuthority> authorities = new ArrayList<>();
        authorities.add(new SimpleGrantedAuthority("ROLE_USER" ));
        return new User(user.getUsername(), user.getPassword(),authorities);
    }
}
```

# 无权限的返回拦截器

## CustomAccessDeniedHandler
设置自定义拦截器统一已通过身份验证但无权限的403返回格式
```java
@Component
public class CustomAccessDeniedHandler implements AccessDeniedHandler {

    @Override
    public void handle(HttpServletRequest request, HttpServletResponse response, AccessDeniedException accessDeniedException) throws IOException {
        request.setCharacterEncoding("utf-8");
        response.setCharacterEncoding("utf-8");
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);
        response.setStatus(HttpStatus.FORBIDDEN.value());
        response.getWriter().write(new ObjectMapper().writeValueAsString(new CommonResult<>(CustomStatusEnum.NO_PERMISSION)));
    }
}
```

## CustomEntryPoint
设置自定义拦截器统一未登录的403返回格式
```java
@Component
public class CustomEntryPoint implements AuthenticationEntryPoint {

    @Override
    public void commence(HttpServletRequest request, HttpServletResponse response, AuthenticationException authException) throws IOException {
        response.setStatus(HttpServletResponse.SC_FORBIDDEN);
        response.setCharacterEncoding("UTF-8");
        response.setContentType("application/json; charset=utf-8");
        PrintWriter out = response.getWriter();

        ObjectMapper objectMapper = new ObjectMapper();
        String errorMsg = objectMapper.writeValueAsString(new CommonResult<>(CustomStatusEnum.NOT_LOGIN));
        out.write(errorMsg);
        out.flush();
        out.close();
    }
}
```

# JWT 相关处理

JWT 认证实现主要通过

- JWTLoginFilter 实现读取 /login 请求中的用户信息进行验证，通过后发放JWT
- JWTAuthenticationFilter 拦截所有使用JWT认证的请求，同时获取请求头中的JWT并解析验证，根据结果放行请求
- TokenAuthenticationService 为以上两个Filter提供服务

具体实现参考: [SpringSecurity 集成JWT权限验证]({% post_url 2021-03-01-spring-integrate-jwt-auth%})
