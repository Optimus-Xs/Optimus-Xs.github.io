---
layout: post
title: 在 SpringBoot 中集成 Redis
date: 2021-04-15 13:47 +0800
categories: [Software Development] 
tags: [Java, Spring, Redis]
---

# Redis 简介
一个系统在于数据库交互的过程中，内存的速度远远快于硬盘速度，当我们重复地获取相同数据时，我们一次又一次地请求数据库或远程服务，者无疑时性能上地浪费（这会导致大量时间被浪费在数据库查询或者远程方法调用上致使程序性能恶化），于是有了“缓存”。

Redis 是目前业界使用最广泛的内存数据存储。相比 Memcached，Redis 支持更丰富的数据结构，例如 hashes, lists, sets 等，同时支持数据持久化。除此之外，Redis 还提供一些类数据库的特性，比如事务，HA，主从库。

Redis 与其他 key - value 缓存产品有以下三个特点：

- edis支持数据的持久化，可以将内存中的数据保存在磁盘中，重启的时候可以再次加载进行使用。
- edis不仅仅支持简单的key-value类型的数据，同时还提供list，set，zset，hash等数据结构的存储。
- edis支持数据的备份，即master-slave模式的数据备份。

可以说 Redis 兼具了缓存系统和数据库的一些特性，因此有着丰富的应用场景。本文介绍 Redis 在 Spring Boot 中两个典型的应用场景。


# Spring Cache
## SpringCache简介
Spring Cache是Spring框架提供的对缓存使用的抽象类，支持多种缓存，比如Redis、EHCache等，集成很方便。同时提供了多种注解来简化缓存的使用，可对方法进行缓存。
###  关于SpringCache 注解的简单介绍
- @CacheConfig:主要用于配置该类中会用到的一些共用的缓存配置
- @Cacheable:主要方法返回值加入缓存。同时在查询时，会先从缓存中取，若不存在才再发起对数据库的访问。
- @CachePut:配置于函数上，能够根据参数定义条件进行缓存，与@Cacheable不同的是，每次回真实调用函数，所以主要用于数据新增和修改操作上。
- @CacheEvict:配置于函数上，通常用在删除方法上，用来从缓存中移除对应数据
- @Caching:配置于函数上，组合多个Cache注解使用。

## SpringCache 注解
### @CacheConfig
所有的@Cacheable（）里面都有一个value＝“xxx”的属性，这显然如果方法多了，写起来也是挺累的，如果可以一次性声明完 那就省事了， 所以，有了@CacheConfig这个配置，@CacheConfig is a class-level annotation that allows to share the cache names，如果你在你的方法写别的名字，那么依然以方法的名字为准。

@CacheConfig是一个类级别的注解。
```java
/** * 测试服务层 */
@Service
@CacheConfig(value = "taskLog")
public class TaskLogService {
 
    @Autowired  private TaskLogMapper taskLogMapper;
    @Autowired  private net.sf.ehcache.CacheManager cacheManager;
 
    /** * 缓存的key */
    public static final String CACHE_KEY   = "taskLog";
 
    /** * 添加tasklog * @param tasklog * @return */
    @CachePut(key = "#tasklog.id")
    public Tasklog create(Tasklog tasklog){
        System.out.println("CREATE");
        System.err.println (tasklog);
        taskLogMapper.insert(tasklog);
        return tasklog;
    }
 
    /** * 根据ID获取Tasklog * @param id * @return */
    @Cacheable(key = "#id")
    public Tasklog findById(String id){
        System.out.println("FINDBYID");
        System.out.println("ID:"+id);
        return taskLogMapper.selectById(id);
    }
}
```

### @Cacheable
@Cacheable 的作用 主要针对方法配置，能够根据方法的请求参数对其结果进行缓存

- value、cacheNames：两个等同的参数（cacheNames为Spring 4新增，作为value的别名），用于指定缓存存储的集合名。由于Spring 4中新增了@CacheConfig，因此在Spring 3中原本必须有的value属性，也成为非必需项了
- key：缓存对象存储在Map集合中的key值，非必需，缺省按照函数的所有参数组合作为key值，若自己配置需使用SpEL表达式，比如：@Cacheable(key = "#p0")：使用函数第一个参数作为缓存的key值，更多关于SpEL表达式的详细内容可参考官方文档
- condition：缓存对象的条件，非必需，也需使用SpEL表达式，只有满足表达式条件的内容才会被缓存，比如：@Cacheable(key = "#p0", condition = "#p0.length() < 3")，表示只有当第一个参数的长度小于3的时候才会被缓存，若做此配置上面的AAA用户就不会被缓存，读者可自行实验尝试。
- unless：另外一个缓存条件参数，非必需，需使用SpEL表达式。它不同于condition参数的地方在于它的判断时机，该条件是在函数被调用之后才做判断的，所以它可以通过对result进行判断。
- keyGenerator：用于指定key生成器，非必需。若需要指定一个自定义的key生成器，我们需要去实现org.springframework.cache.interceptor.KeyGenerator接口，并使用该参数来指定。需要注意的是：该参数与key是互斥的
- cacheManager：用于指定使用哪个缓存管理器，非必需。只有当有多个时才需要使用
- cacheResolver：用于指定使用那个缓存解析器，非必需。需通过org.springframework.cache.interceptor.CacheResolver接口来实现自己的缓存解析器，并用该参数指定。

作用和配置方法

| 参数      | 解释                                                                                                   | example                                                                       |
| :-------- | :----------------------------------------------------------------------------------------------------- | :---------------------------------------------------------------------------- |
| value     | 缓存的名称，在 spring 配置文件中定义，必须指定至少一个                                                 | 例如: @Cacheable(value=”mycache”)  <br>  @Cacheable(value={”cache1”,”cache2”} |
| key       | 缓存的 key，可以为空，如果指定要按照 SpEL 表达式编写，<br>如果不指定，则缺省按照方法的所有参数进行组合 | @Cacheable(value=”testcache”,key=”#userName”)                                 |
| condition | 缓存的条件，可以为空，使用 SpEL 编写，<br>返回 true 或者 false，只有为 true 才进行缓存                 | @Cacheable(value=”testcache”,condition=”#userName.length()>2”)                |

```java
    /** * 根据ID获取Tasklog * @param id * @return */
    @Cacheable(value = CACHE_KEY, key = "#id",condition = "#result != null")
    public Tasklog findById(String id){
        System.out.println("FINDBYID");
        System.out.println("ID:"+id);
        return taskLogMapper.selectById(id);
    }
```

### @CachePut
@CachePut 的作用 主要针对方法配置，能够根据方法的请求参数对其结果进行缓存，和 @Cacheable 不同的是，它每次都会触发真实方法的调用

作用和配置方法

| 参数      | 解释                                                                                               | example                                                       |
| :-------- | :------------------------------------------------------------------------------------------------- | :------------------------------------------------------------ |
| value     | 缓存的名称，在 spring 配置文件中定义，必须指定至少一个                                             | @CachePut(value=”my cache”)                                   |
| key       | 缓存的 key，可以为空，如果指定要按照 SpEL 表达式编写，如果不指定，则缺省按照方法的所有参数进行组合 | @CachePut(value=”testcache”,key=”#userName”)                  |
| condition | 缓存的条件，可以为空，使用 SpEL 编写，返回 true 或者 false，只有为 true 才进行缓存                 | @CachePut(value=”testcache”,condition=”#userName.length()>2”) |

```java
    /** * 添加tasklog * @param tasklog * @return */
    @CachePut(value = CACHE_KEY, key = "#tasklog.id")
    public Tasklog create(Tasklog tasklog){
        System.out.println("CREATE");
        System.err.println (tasklog);
        taskLogMapper.insert(tasklog);
        return tasklog;
    }
```

### @CacheEvict
@CachEvict 的作用 主要针对方法配置，能够根据一定的条件对缓存进行清空

作用和配置方法

| 参数             | 解释                                                                                                                                        | example                                                         |
| :--------------- | :------------------------------------------------------------------------------------------------------------------------------------------ | :-------------------------------------------------------------- |
| value            | 缓存的名称，在 spring 配置文件中定义，必须指定至少一个                                                                                      | @CacheEvict(value=”my cache”)                                   |
| key              | 缓存的 key，可以为空，如果指定要按照 SpEL 表达式编写，如果不指定，则缺省按照方法的所有参数进行组合                                          | @CacheEvict(value=”testcache”,key=”#userName”)                  |
| condition        | 缓存的条件，可以为空，使用 SpEL 编写，返回 true 或者 false，只有为 true 才进行缓存                                                          | @CacheEvict(value=”testcache”,condition=”#userName.length()>2”) |
| allEntries       | 是否清空所有缓存内容，缺省为 false，如果指定为 true，则方法调用后将立即清空所有缓存                                                         | @CachEvict(value=”testcache”,allEntries=true)                   |
| beforeInvocation | 是否在方法执行前就清空，缺省为 false，如果指定为 true，则在方法还没有执行的时候就清空缓存，缺省情况下，如果方法执行抛出异常，则不会清空缓存 | @CachEvict(value=”testcache”，beforeInvocation=true)            |

```java
    /** * 根据ID删除Tasklog * @param id */
    @CacheEvict(value = CACHE_KEY, key = "#id")
    public void delete(String id){
        System.out.println("DELETE");
        System.out.println("ID:"+id);
        taskLogMapper.deleteById(id);
    }
```

### @Caching
有时候我们可能组合多个Cache注解使用；比如用户新增成功后，我们要添加id–>user；username—>user；email—>user的缓存；此时就需要@Caching组合多个注解标签了。 
```java
@Caching(put = {
@CachePut(value = "user", key = "#user.id"),
@CachePut(value = "user", key = "#user.username"),
@CachePut(value = "user", key = "#user.email")
})
public User save(User user) {
}
```

### 自定义缓存注解
比如之前的那个@Caching组合，会让方法上的注解显得整个代码比较乱，此时可以使用自定义注解把这些注解组合到一个注解中，如：
```java
@Caching(put = {
    @CachePut(value = "user", key = "#user.id"),
    @CachePut(value = "user", key = "#user.username"),
    @CachePut(value = "user", key = "#user.email")
})
@Target({ElementType.METHOD, ElementType.TYPE})
@Retention(RetentionPolicy.RUNTIME)
@Inherited
public @interface UserSaveCache {
}
```
这样我们在方法上使用如下代码即可，整个代码显得比较干净。
```java
@UserSaveCache
public User save(User user){}
```

### Spring Cache提供的SpEL上下文数据

| 名字          | 位置       | 描述                                                                                                | 示例                 |
| :------------ | :--------- | :-------------------------------------------------------------------------------------------------- |
| methodName    | root对象   | 当前被调用的方法名                                                                                  | #root.methodName     |
| method        | root对象   | 当前被调用的方法                                                                                    | #root.method.name    |
| target        | root对象   | 当前被调用的目标对象                                                                                | #root.target         |
| targetClass   | root对象   | 当前被调用的目标对象类                                                                              | #root.targetClass    |
| args          | root对象   | 当前被调用的方法的参数列表                                                                          | #root.args[0]        |
| caches        | root对象   | 当前方法调用使用的缓存列表（如@Cacheable(value={"cache1", "cache2"})），则有两个cache               | #root.caches[0].name |
| argument name | 执行上下文 | 当前被调用的方法的参数，如findById(Long id)，我们可以通过#id拿到参数                                | #user.id             |
| result        | 执行上下文 | 方法执行后的返回值（仅当方法执行之后的判断有效，如‘unless’，'cache evict'的beforeInvocation=false） | #result              |

## SpringCache和Redis集成过程
### 操作步骤
我们要把一个查询函数加入缓存功能，大致需要三步。

1. 在函数执行前，我们需要先检查缓存中是否存在数据，如果存在则返回缓存数据。
2. 如果不存在，就需要在数据库的数据查询出来。
3. 最后把数据存放在缓存中，当下次调用此函数时，就可以直接使用缓存数据，减轻了数据库压力。

### Spring Cacahe 运行流程
1. 首先执行@CacheEvict（如果beforeInvocation=true且condition 通过），如果allEntries=true，则清空所有  
2. 接着收集@Cacheable（如果condition 通过，且key对应的数据不在缓存），放入cachePutRequests（也就是说如果cachePutRequests为空，则数据在缓存中）  
3. 如果cachePutRequests为空且没有@CachePut操作，那么将查找@Cacheable的缓存，否则result=缓存数据（也就是说只要当没有cache put请求时才会查找缓存）  
4. 如果没有找到缓存，那么调用实际的API，把结果放入result  
5. 如果有@CachePut操作(如果condition 通过)，那么放入cachePutRequests  
6. 执行cachePutRequests，将数据写入缓存（unless为空或者unless解析结果为false）；  
7. 执行@CacheEvict（如果beforeInvocation=false 且 condition 通过），如果allEntries=true，则清空所有

> 流程中需要注意的就是2/3/4步：
>
>如果有@CachePut操作，即使有@Cacheable也不会从缓存中读取；问题很明显，如果要混合多个注解使用，不能组合使用@CachePut和@Cacheable；
>
>官方说应该避免这样使用（解释是如果带条件的注解相互排除的场景）；不过个人感觉还是不要考虑这个好，让用户来决定如何使用，否则一会介绍的场景不能满足。
{: .prompt-tip }

### 具体操作
添加依赖
```xml
<!-- springboot redis依赖-->
        <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-data-redis</artifactId>
        </dependency>
```
> 注: 其实我们从官方文档可以看到spring-boot-starter-data-redis 已经包含了jedis客户端，我们在使用jedis连接池的时候不必再添加jedis依赖。
{: .prompt-tip }

配置SpringCache，Redis连接等信息

```java
@Configuration
@EnableCaching
public class RedisConfig {

    /**
     * 申明缓存管理器，会创建一个切面（aspect）并触发Spring缓存注解的切点（pointcut）
     * 根据类或者方法所使用的注解以及缓存的状态，这个切面会从缓存中获取数据，将数据添加到缓存之中或者从缓存中移除某个值

     * @return
     */
    @Bean
    public RedisCacheManager cacheManager(RedisConnectionFactory redisConnectionFactory) {
        return RedisCacheManager.create(redisConnectionFactory);
    }

    @Bean
    public RedisTemplate redisTemplate(RedisConnectionFactory factory) {
        // 创建一个模板类
        RedisTemplate<String, Object> template = new RedisTemplate<String, Object>();
        // 将刚才的redis连接工厂设置到模板类中
        template.setConnectionFactory(factory);
        // 设置key的序列化器
        template.setKeySerializer(new StringRedisSerializer());
        // 设置value的序列化器
        //使用Jackson 2，将对象序列化为JSON
        Jackson2JsonRedisSerializer jackson2JsonRedisSerializer = new Jackson2JsonRedisSerializer(Object.class);
        //json转对象类，不设置默认的会将json转成hashmap
        ObjectMapper om = new ObjectMapper();
        om.setVisibility(PropertyAccessor.ALL, JsonAutoDetect.Visibility.ANY);
        om.enableDefaultTyping(ObjectMapper.DefaultTyping.NON_FINAL);
        jackson2JsonRedisSerializer.setObjectMapper(om);
        template.setValueSerializer(jackson2JsonRedisSerializer);

        return template;
    } 
} 
```
{: file='RedisConfig.java'}

redis配置
```yml
spring:
  # redis相关配置
  redis:
    database: 0
    host: localhost
    port: 6379
    password: ******
    jedis:
      pool:
        # 连接池最大连接数（使用负值表示没有限制）
        max-active: 8
        # 连接池最大阻塞等待时间（使用负值表示没有限制）
        max-wait: -1ms
        # 连接池中的最大空闲连接
        max-idle: 8
        # 连接池中的最小空闲连接
        min-idle: 0
    # 连接超时时间（毫秒）默认是2000ms
    timeout: 2000ms
  cache:
    redis:
      ## Entry expiration in milliseconds. By default the entries never expire.
      time-to-live: 1d
      #写入redis时是否使用键前缀。
      use-key-prefix: true
```
{: file='application.yml'}

启动类

cache相关注解必须在spring所管理的bean容器中，这样才能使缓存生效

启动类中要加入@EnableCaching注解支持缓存
```java
@SpringBootApplication
@EnableCaching
public class CoreApplication {

    public static void main(String[] args) {
        SpringApplication.run(CoreApplication.class, args);
    }
}
```

编写实体类
```java
@Data
//lombok依赖，可省略get set方法
public class User implements Serializable {

    private int userId;

    private String userName;

    private String userPassword;

    public User(int userId, String userName, String userPassword) {
        this.userId = userId;
        this.userName = userName;
        this.userPassword = userPassword;
    }
}
```

service简单操作
```java
@Service
public class UserDao {

    public User getUser(int userId) {
        System.out.println("执行此方法，说明没有缓存，如果没有走到这里，就说明缓存成功了");
        User user = new User(userId, "没有缓存_"+userId, "password_"+userId);
        return user;
    }

    public User getUser2(int userId) {
        System.out.println("执行此方法，说明没有缓存，如果没有走到这里，就说明缓存成功了");
        User user = new User(userId, "name_nocache"+userId, "nocache");
        return user;
    }
}
```

控制层

在方法上添加相应的方法即可操作缓存了，SpringCache 对象可以对redis自行操作，减少了很多工作啊，还是那个开箱即用的Spring
```java
@RestController
public class testController {
    @Resource
    private UserDao userDao;

    /**
     * 查询出一条数据并且添加到缓存
     *
     * @param userId
     * @return
     */
    @RequestMapping("/getUser")
    @Cacheable("userCache")
    public User getPrud(@RequestParam(required = true) String userId) {
        System.out.println("如果没有缓存，就会调用下面方法，如果有缓存，则直接输出，不会输出此段话");
        return userDao.getUser(Integer.parseInt(userId));
    }

    /**
     * 删除一个缓存
     *
     * @param userId
     * @return
     */
    @RequestMapping(value = "/deleteUser")
    @CacheEvict("userCache")
    public String deleteUser(@RequestParam(required = true) String userId) {
        return "删除成功";
    }

    /**
     * 添加一条保存的数据到缓存，缓存的key是当前user的id
     *
     * @param user
     * @return
     */
    @RequestMapping("/saveUser")
    @CachePut(value = "userCache", key = "#result.userId +''")
    public User saveUser(User user) {
        return user;
    }

    /**
     * 返回结果userPassword中含有nocache字符串就不缓存
     *
     * @param userId
     * @return
     */
    @RequestMapping("/getUser2")
    @CachePut(value = "userCache", unless = "#result.userPassword.contains('nocache')")
    public User getUser2(@RequestParam(required = true) String userId) {
        System.out.println("如果走到这里说明，说明缓存没有生效！");
        User user = new User(Integer.parseInt(userId), "name_nocache" + userId, "nocache");
        return user;
    }


    @RequestMapping("/getUser3")
    @Cacheable(value = "userCache", key = "#root.targetClass.getName() + #root.methodName + #userId")
    public User getUser3(@RequestParam(required = true) String userId) {
        System.out.println("如果第二次没有走到这里说明缓存被添加了");
        return userDao.getUser(Integer.parseInt(userId));
    }
}
```


# Spring Data Redis
## 引入依赖
```xml
<dependencies>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-data-redis</artifactId>
    </dependency>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-web</artifactId>
    </dependency>
</dependencies>
<dependency>
    <groupId>org.apache.commons</groupId>
    <artifactId>commons-pool2</artifactId>
</dependency>
```
这里主要就是引入了 Spring Data Redis + 连接池。

## 配置 Redis 信息
```yml
spring:
  # redis相关配置
  redis:
    database: 0
    host: localhost
    port: 6379
    password: ******
    jedis:
      pool:
        # 连接池最大连接数（使用负值表示没有限制）
        max-active: 8
        # 连接池最大阻塞等待时间（使用负值表示没有限制）
        max-wait: -1ms
        # 连接池中的最大空闲连接
        max-idle: 8
        # 连接池中的最小空闲连接
        min-idle: 0
    # 连接超时时间（毫秒）默认是2000ms
    timeout: 2000ms
```
{: file='application.yml'}

## 自动配置
当开发者在项目中引入了 Spring Data Redis ，并且配置了 Redis 的基本信息，此时，自动化配置就会生效。

我们从 Spring Boot 中 Redis 的自动化配置类中就可以看出端倪：
```java
@Configuration
@ConditionalOnClass(RedisOperations.class)
@EnableConfigurationProperties(RedisProperties.class)
@Import({ LettuceConnectionConfiguration.class, JedisConnectionConfiguration.class })
public class RedisAutoConfiguration {
        @Bean
        @ConditionalOnMissingBean(name = "redisTemplate")
        public RedisTemplate<Object, Object> redisTemplate(
                        RedisConnectionFactory redisConnectionFactory) throws UnknownHostException {
                RedisTemplate<Object, Object> template = new RedisTemplate<>();
                template.setConnectionFactory(redisConnectionFactory);
                return template;
        }
        @Bean
        @ConditionalOnMissingBean
        public StringRedisTemplate stringRedisTemplate(
                        RedisConnectionFactory redisConnectionFactory) throws UnknownHostException {
                StringRedisTemplate template = new StringRedisTemplate();
                template.setConnectionFactory(redisConnectionFactory);
                return template;
        }
}
```
这个自动化配置类很好理解：

- 首先标记这个是一个配置类，同时该配置在 RedisOperations 存在的情况下才会生效(即项目中引入了 Spring Data Redis)
- 然后导入在 application.properties 中配置的属性
- 然后再导入连接池信息（如果存在的话）
- 最后，提供了两个 Bean ，RedisTemplate 和 StringRedisTemplate ，其中 StringRedisTemplate 是 RedisTemplate 的子类，两个的方法基本一致，不同之处主要体现在操作的数据类型不同，RedisTemplate 中的两个泛型都是 Object ，意味者存储的 key 和 value 都可以是一个对象，而 StringRedisTemplate 的 两个泛型都是 String ，意味者 StringRedisTemplate 的 key 和 value 都只能是字符串。如果开发者没有提供相关的 Bean ，这两个配置就会生效，否则不会生效。

## 使用
接下来，可以直接在 Service 中注入 StringRedisTemplate 或者 RedisTemplate 来使用：
```java
@Service
public class HelloService {
    @Autowired
    RedisTemplate redisTemplate;
    public void hello() {
        ValueOperations ops = redisTemplate.opsForValue();
        ops.set("k1", "v1");
        Object k1 = ops.get("k1");
        System.out.println(k1);
    }
}
```
Redis 中的数据操作，大体上来说，可以分为两种：

- 针对 key 的操作，相关的方法就在 RedisTemplate 中
- 针对具体数据类型的操作，相关的方法需要首先获取对应的数据类型，获取相应数据类型的操作方法是 opsForXXX

RedisTemplate 中，key 默认的序列化方案是 JdkSerializationRedisSerializer 。

而在 StringRedisTemplate 中，key 默认的序列化方案是 StringRedisSerializer ，因此，如果使用 StringRedisTemplate ，默认情况下 key 前面不会有前缀。

不过开发者也可以自行修改 RedisTemplate 中的序列化方案，如下:
```java
@Service
public class HelloService {
    @Autowired
    RedisTemplate redisTemplate;
    public void hello() {
        redisTemplate.setKeySerializer(new StringRedisSerializer());
        ValueOperations ops = redisTemplate.opsForValue();
        ops.set("k1", "v1");
        Object k1 = ops.get("k1");
        System.out.println(k1);
    }
}
```
当然也可以直接使用 StringRedisTemplate：
```java
@Service
public class HelloService {
    @Autowired
    StringRedisTemplate stringRedisTemplate;
    public void hello2() {
        ValueOperations ops = stringRedisTemplate.opsForValue();
        ops.set("k2", "v2");
        Object k1 = ops.get("k2");
        System.out.println(k1);
    }
}
```
另外需要注意 ，Spring Boot 的自动化配置，只能配置单机的 Redis ，如果是 Redis 集群，则所有的东西都需要自己手动配置


# Spring Session
## 引入依赖
pom 需要引入 redis 和 session 的依赖
```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-redis</artifactId>
</dependency>
<dependency>
    <groupId>org.springframework.session</groupId>
    <artifactId>spring-session-data-redis</artifactId>
</dependency>
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-web</artifactId>
</dependency>
```
## 配置
```properties
spring.redis.host=localhost
spring.redis.port=6379
spring.redis.password=Redis.127
# session存储类型使用redis
spring.session.store-type=redis
```
{: file='application.properties'}

启动类添加 @EnableRedisHttpSession 注解
```java
@SpringBootApplication
@EnableRedisHttpSession
public class CoreApplication {

    public static void main(String[] args) {
        SpringApplication.run(CoreApplication.class, args);
    }
}
```

## 测试
1. 启动两个或以上服务，端口分别为8080，8081……
2. 分别调用：http://127.0.0.1:8080/getSessionId,http://127.0.0.1:8081/getSessionId

若sessionId是一样的，redis里也存在同样的session信息，以上，说明session共享已完成。


# 直接使用 Redis 客户端
## Lettuce 集成 Redis 服务
### 依赖和配置
> 由于 Spring Boot 2.X 默认集成了 Lettuce ，所以无需导入依赖。
{: .prompt-tip }

```properties
################ Redis 基础配置 ##############
# Redis数据库索引（默认为0）
spring.redis.database=0  
# Redis服务器地址
spring.redis.host=127.0.0.1
# Redis服务器连接端口
spring.redis.port=6379  
# Redis服务器连接密码（默认为空）
spring.redis.password=*********
# 链接超时时间 单位 ms（毫秒）
spring.redis.timeout=3000
################ Redis 线程池设置 ##############
# 连接池最大连接数（使用负值表示没有限制） 默认 8
spring.redis.lettuce.pool.max-active=8
# 连接池最大阻塞等待时间（使用负值表示没有限制） 默认 -1
spring.redis.lettuce.pool.max-wait=-1
# 连接池中的最大空闲连接 默认 8
spring.redis.lettuce.pool.max-idle=8
# 连接池中的最小空闲连接 默认 0
spring.redis.lettuce.pool.min-idle=0
```
{: file='application.properties'}

### 自定义 RedisTemplate
默认情况下的模板只能支持 RedisTemplate<String,String>，只能存入字符串，很多时候，我们需要自定义 RedisTemplate ，设置序列化器，这样我们可以很方便的操作实例对象。如下所示：

```java
@Configuration
public class LettuceRedisConfig {

	@Bean
	public RedisTemplate<String, Serializable> redisTemplate(LettuceConnectionFactory connectionFactory) {
		RedisTemplate<String, Serializable> redisTemplate = new RedisTemplate<>();
		redisTemplate.setKeySerializer(new StringRedisSerializer());
		redisTemplate.setValueSerializer(new GenericJackson2JsonRedisSerializer());
		redisTemplate.setConnectionFactory(connectionFactory);
		return redisTemplate;
	}
}
```

### 序列化实体类
```java
public class UserEntity implements Serializable {
	private static final long serialVersionUID = 6455431221321343103305078L;
	
	private Long id;
	private String userName;
	private String userSex;
	public Long getId() {
		return id;
	}
	public void setId(Long id) {
		this.id = id;
	}
	public String getUserName() {
		return userName;
	}
	public void setUserName(String userName) {
		this.userName = userName;
	}
	public String getUserSex() {
		return userSex;
	}
}
```

### 测试
```java
@RunWith(SpringRunner.class)
@SpringBootTest
public class SpringBootRedisApplicationTests {

	@Autowired
	private RedisTemplate<String, String> strRedisTemplate;
	@Autowired
	private RedisTemplate<String, Serializable> serializableRedisTemplate;
	
	@Test
	public void testString() {
		strRedisTemplate.opsForValue().set("strKey", "Opt");
		System.out.println(strRedisTemplate.opsForValue().get("strKey"));
	}
	
	@Test
	public void testSerializable() {
		UserEntity user=new UserEntity();
		user.setId(1L);
		user.setUserName("Optimus");
		user.setUserSex("男");		
		serializableRedisTemplate.opsForValue().set("user", user);		
		UserEntity user2 = (UserEntity) serializableRedisTemplate.opsForValue().get("user");
		System.out.println("user:"+user2.getId()+","+user2.getUserName()+","+user2.getUserSex());
	}
}
```

## Jedis 集成 Redis 服务

### 导入依赖和配置
```xml
<dependency>
			<groupId>org.springframework.boot</groupId>
			<artifactId>spring-boot-starter-data-redis</artifactId>
			<exclusions>
				<!-- 排除lettuce包 -->
				<exclusion>
					<groupId>io.lettuce</groupId>
					<artifactId>lettuce-core</artifactId>
				</exclusion>
			</exclusions>
		</dependency>
		<!-- 添加jedis客户端 -->
		<dependency>
			<groupId>redis.clients</groupId>
			<artifactId>jedis</artifactId>
		</dependency>
```

```properties
################ Redis 基础配置 ##############
# Redis数据库索引（默认为0）
spring.redis.database=0  
# Redis服务器地址
spring.redis.host=127.0.0.1
# Redis服务器连接端口
spring.redis.port=6379  
# Redis服务器连接密码（默认为空）
spring.redis.password=**********
# 链接超时时间 单位 ms（毫秒）
spring.redis.timeout=3000
################ Redis 线程池设置 ##############
# 连接池最大连接数（使用负值表示没有限制） 默认 8
spring.redis.lettuce.pool.max-active=8
# 连接池最大阻塞等待时间（使用负值表示没有限制） 默认 -1
spring.redis.lettuce.pool.max-wait=-1
# 连接池中的最大空闲连接 默认 8
spring.redis.lettuce.pool.max-idle=8
# 连接池中的最小空闲连接 默认 0
spring.redis.lettuce.pool.min-idle=0
```
{: file='application.properties'}

### JedisRedisConfig
```java
@Configuration
public class JedisRedisConfig {

	@Value("${spring.redis.database}")
	private int database;
	@Value("${spring.redis.host}")
	private String host;
	@Value("${spring.redis.port}")
	private int port;
	@Value("${spring.redis.password}")
	private String password;
	@Value("${spring.redis.timeout}")
	private int timeout;
	@Value("${spring.redis.jedis.pool.max-active}")
	private int maxActive;
	@Value("${spring.redis.jedis.pool.max-wait}")
	private long maxWaitMillis;
	@Value("${spring.redis.jedis.pool.max-idle}")
	private int maxIdle;
	@Value("${spring.redis.jedis.pool.min-idle}")
	private int minIdle;

	/**
	 * 连接池配置信息
	 */

	@Bean
	public JedisPoolConfig jedisPoolConfig() {
		JedisPoolConfig jedisPoolConfig = new JedisPoolConfig();
		// 最大连接数
		jedisPoolConfig.setMaxTotal(maxActive);
		// 当池内没有可用连接时，最大等待时间
		jedisPoolConfig.setMaxWaitMillis(maxWaitMillis);
		// 最大空闲连接数
		jedisPoolConfig.setMinIdle(maxIdle);
		// 最小空闲连接数
		jedisPoolConfig.setMinIdle(minIdle);
		// 其他属性可以自行添加
		return jedisPoolConfig;
	}

	/**
	 * Jedis 连接
	 * 
	 * @param jedisPoolConfig
	 * @return
	 */
	@Bean
	public JedisConnectionFactory jedisConnectionFactory(JedisPoolConfig jedisPoolConfig) {
		JedisClientConfiguration jedisClientConfiguration = JedisClientConfiguration.builder().usePooling()
				.poolConfig(jedisPoolConfig).and().readTimeout(Duration.ofMillis(timeout)).build();
		RedisStandaloneConfiguration redisStandaloneConfiguration = new RedisStandaloneConfiguration();
		redisStandaloneConfiguration.setHostName(host);
		redisStandaloneConfiguration.setPort(port);
		redisStandaloneConfiguration.setPassword(RedisPassword.of(password));
		return new JedisConnectionFactory(redisStandaloneConfiguration, jedisClientConfiguration);
	}

	/**
	 * 缓存管理器
	 * 
	 * @param connectionFactory
	 * @return
	 */
	@Bean
	public RedisCacheManager cacheManager(RedisConnectionFactory connectionFactory) {
		return RedisCacheManager.create(connectionFactory);
	}

	@Bean
	public RedisTemplate<String, Serializable> redisTemplate(JedisConnectionFactory connectionFactory) {
		RedisTemplate<String, Serializable> redisTemplate = new RedisTemplate<>();
		redisTemplate.setKeySerializer(new StringRedisSerializer());
		redisTemplate.setValueSerializer(new GenericJackson2JsonRedisSerializer());
		redisTemplate.setConnectionFactory(jedisConnectionFactory(jedisPoolConfig()));
		return redisTemplate;
	}
}
```

### 测试
```java
@RunWith(SpringRunner.class)
@SpringBootTest
public class SpringBootRedisApplicationTests {

	@Autowired
	private RedisTemplate<String, String> strRedisTemplate;
	@Autowired
	private RedisTemplate<String, Serializable> serializableRedisTemplate;
	
	@Test
	public void testString() {
		strRedisTemplate.opsForValue().set("strKey", "Opt");
		System.out.println(strRedisTemplate.opsForValue().get("strKey"));
	}
	
	@Test
	public void testSerializable() {
		UserEntity user=new UserEntity();
		user.setId(1L);
		user.setUserName("Optimus");
		user.setUserSex("男");		
		serializableRedisTemplate.opsForValue().set("user", user);		
		UserEntity user2 = (UserEntity) serializableRedisTemplate.opsForValue().get("user");
		System.out.println("user:"+user2.getId()+","+user2.getUserName()+","+user2.getUserSex());
	}
}
```
