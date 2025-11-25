---
layout: post
title: JPA 快速适配多种数据库配置
date: 2022-10-04 12:37 +0800
categories: [Software Development] 
tags: [DataBase,Java,Spring]
math: true
---

## Spring Data JPA 支持多数据库的原理

Spring Data JPA 实现多数据库兼容性的关键在于：

- **JPA 规范**：提供了一套标准的、与数据库无关的持久化 API。
- **ORM 框架（如 Hibernate）**：通过内置的数据库方言将标准的 JPQL（JPA Query Language）或生成的查询转换为特定数据库的 SQL 语法。

当从 MySQL 切换到 PostgreSQL 时，业务代码（Service 层）和数据访问接口（Repository 层）几乎不需要做任何修改，只需更改依赖（添加新的 JDBC 驱动）和配置（更新数据源和方言）

> **Spring Data JPA 是什么？**
> 
> Spring Data JPA 的目标是消除数据访问层的样板代码，让开发者可以专注于定义数据访问的接口，而不是实现细节。它是在 Hibernate（JPA 实现）提供底层持久化和ORM能力的基础上，通过 Spring 框架的高度抽象化能力，实现了极高的开发效率。
>
> 对比其他语言的 ORM 框架:
>   - **ActiveRecord (Ruby/RoR) 和 TypeORM (TypeScript)** 通常是一体化的 ORM 框架，它们将规范、实现和数据访问层面的简洁封装都包含在一个库中
>   - **Spring/Java 生态系统**则采用了分层设计
>     - Hibernate 类似于 ActiveRecord 的实现部分。
>     - JPA 类似于 ActiveRecord 的规范部分。
>     - Spring Data JPA 专门处理 ActiveRecord 中**“自动生成查询方法”和“无需手写数据访问层”**的这部分工作，它极大地减少了数据访问层的样板代码
{: .prompt-tip }

> **Hibernate 是一个完整的ORM框架吗？**
> 
> 主流或经典意义上的 ORM (Object-Relational Mapping) 框架旨在提供一套机制，将面向对象模型 (O-Model) 和关系模型 (R-Model) 进行映射和转换
>
> 一个完整或主流定义的 ORM 框架通常应涵盖以下三个核心部分
>
> 1. **映射和元数据定义 (Mapping & Metadata)**: 定义编程语言类如何映射到数据库表， 关系定义和数据类型转换
> 2. **持久化/会话管理 (Persistence & Session Management)**: 这是 ORM 框架执行操作的运行时环境， 提供基本 CURD ， 身份管理， 查询缓存， 脏检查等能力
> 3. **查询机制 (Query Mechanism)**: ORM 框架如何从数据库检索数据的能力， 包括领域特定查询语言，原生 SQL 支持，事务管理集成等功能
>
> 从功能上讲，Hibernate 是一个完整的、功能强大的 ORM 框架。但从“**封装度**”和“**便利性**”来看，它确实缺乏其他语言 ORM 库所拥有的最高层抽象，而这部分由 Spring Data JPA 补齐了
{: .prompt-tip }

> **Java生态中为什么会出现这个分层架构？**
> 
> 这种分层结构，是因为 Java/JEE 生态更强调规范 (JPA) 与实现 (Hibernate) 的分离，以及框架 (Spring) 与持久化的解耦。这种设计提供了极大的灵活性
>
> 例如：
> 
> - 可以用 Hibernate 实现 JPA 规范，但在 Spring 框架外使用它。
> - 可以用 EclipseLink 来实现 JPA 规范，替换 Hibernate。
> - 可以用 Spring Data JPA 来封装任何 JPA 实现，提供高级抽象。
>
> Java ORM 框架出现分层架构的根本原因在于其历史定位和市场需求：
> 
> - **标准化 (Standardization)**： 在 2000 年代初期，Java 社区需要一个官方标准来结束不同 ORM 框架（如 Hibernate、JDO）的混战，这催生了 JPA 规范。
> - **解耦 (Decoupling)**： JPA 允许企业在不重写业务代码的情况下更换底层持久化供应商，满足了大型项目对可替换性的需求。
> - **抽象化 (Abstraction)**： 尽管 JPA 标准化了核心操作，但仍需要编写大量重复的 Repository 代码。Spring Data JPA 出现，是 Spring 框架的生产力工具，用于解决持久化层的样板代码，完成了与其他语言一体化 ORM 库在开发效率上的对标。
> 
> 因此，Java 的分层架构实际上是用三个组件实现了其他语言**一体化 ORM 框架（如 Ruby on Rails 的 ActiveRecord）**的所有功能：
> 
> $$\text{ActiveRecord} \approx \text{JPA (规范)} + \text{Hibernate (实现)} + \text{Spring Data JPA (抽象)}$$
{: .prompt-tip }

## Spring Data JPA 切换数据库的配置流程

由于 Spring Data JPA 提供了高度抽象，切换数据库通常是一个配置和数据迁移的过程，而不是大规模代码重构。

以下是详细的步骤，主要分为 **配置切换** 和 **数据迁移** 两个阶段：

### Spring Boot 配置切换

这个阶段的目标是让你的 Spring Boot 应用连接到新的数据库。

**步骤 1**: 引入新的 JDBC 驱动依赖

首先，你需要将新数据库的 JDBC 驱动添加到你的 `pom.xml`（Maven）或 `build.gradle`（Gradle）中。

例如，从 MySQL 迁移到 PostgreSQL：

```xml
<dependency>
    <groupId>org.postgresql</groupId>
    <artifactId>postgresql</artifactId>
</dependency>
```
{: file="pom.xml" }

**步骤 2**: 更新 `application.properties/yml` 配置

修改你的数据源配置以指向新的数据库实例，并指定正确的 Hibernate 方言。

假设从 MySQL 切换到 PostgreSQL:

```yaml
# application.yml 配置示例
spring:
  datasource:
    # 1. 更改 JDBC URL、用户名和密码
    url: jdbc:postgresql://localhost:5432/new_db_name
    username: new_user
    password: new_password
    driver-class-name: org.postgresql.Driver
  jpa:
    # 2. 更改 Hibernate 方言
    # 确保 Hibernate 知道如何生成 PostgreSQL 特有的 SQL
    properties:
      hibernate:
        # 使用 PostgreSQL 的方言
        dialect: org.hibernate.dialect.PostgreSQLDialect
    # 3. 保持 DDL 策略不变 (或设置为 validate/none)
    hibernate:
      ddl-auto: validate # 在迁移阶段，通常设置为 validate 或 none 更安全
```
{: file="application.yml" }

> 注意 `ddl-auto`： 在生产环境中，推荐将 `ddl-auto` 设置为 `validate` 或 `none`，避免应用启动时意外修改或删除表结构。
{: .prompt-warning }


### 数据迁移和结构同步

即使配置切换了，你还需要将旧数据库中的数据和结构移动到新数据库中

**步骤 3**: 初始化新的数据库结构（DDL）

你有两种主流方式来创建新数据库的表结构：

- 使用 Hibernate 自动生成 (开发环境)：
  - 临时将 `spring.jpa.hibernate.ddl-auto` 设置为 `create` 或 `create-drop`。
  - 启动应用一次，让 Hibernate 根据你的 JPA 实体生成并创建新的表结构。
  - 完成后立即改回 `validate` 或 `none`。

- 使用专业的 Schema 迁移工具（推荐用于生产环境）：
  - Flyway 或 Liquibase 是主流选择。它们允许你用 SQL 脚本或 XML/YAML 文件管理数据库的版本控制。
  - 在新的数据库上执行这些工具的脚本，以创建稳定且经过版本控制的表结构。

**步骤 4**: 迁移旧数据（Data Migration）

这是最关键的一步，你需要将旧数据库（如 MySQL）中的现有数据导入到新数据库（如 PostgreSQL）中。

推荐使用专业的迁移工具：

- **数据库内置工具**： 许多数据库（如 PostgreSQL）提供了工具（如 pg_dump 和 psql）来导入和导出数据。
- **第三方工具**： 使用 Navicat, DBeaver 等数据库管理工具，它们通常提供跨数据库的数据同步/迁移功能。
- **脚本工具**： 编写 Python/Java 脚本，使用 JDBC 连接新旧数据库，逐表读取旧数据并写入新数据。

> 数据类型兼容性： 迁移时要特别注意数据类型的差异（例如，MySQL 的 DATETIME 和 PostgreSQL 的 TIMESTAMP），以及自增主键（ID）的兼容性。
{: .prompt-warning }

### 测试与验证

**步骤 5**: 全面测试应用

在新的数据库上运行所有单元测试和集成测试。重点检查：

- **CURD 操作**： 确保基础的保存、查找、更新、删除功能正常。
- **复杂查询**： 检查所有使用了复杂查询（尤其是原生 SQL 或特定 JPQL）的方法，因为不同方言可能导致细微差异。
- **事务行为**： 确保 @Transactional 注解在新的数据库环境下仍然按预期工作。

## 不同数据的项目配置示例
### Hibernate 官方支持的数据库方言

你应当总是为你的数据库将 `hibernate.dialect `属性设置成正确的 `org.hibernate.dialect.Dialect` 子类。如果你指定一种方言，Hibernate 将为上面列出的一些属性使用合理的默认值，这样你就不用手工指定它们。

这是 Hibernate [官方支持的 SQL 方言 (`hibernate.dialect`) 列表](https://hibernate.net.cn/docs/281.html)

| RDBMS                | 方言                                          |
| :------------------- | :-------------------------------------------- |
| DB2                  | `org.hibernate.dialect.DB2Dialect`            |
| DB2 AS/400           | `org.hibernate.dialect.DB2400Dialect`         |
| DB2 OS390            | `org.hibernate.dialect.DB2390Dialect`         |
| PostgreSQL           | `org.hibernate.dialect.PostgreSQLDialect`     |
| MySQL                | `org.hibernate.dialect.MySQLDialect`          |
| MySQL with InnoDB    | `org.hibernate.dialect.MySQLInnoDBDialect`    |
| MySQL with MyISAM    | `org.hibernate.dialect.MySQLMyISAMDialect`    |
| Oracle (any version) | `org.hibernate.dialect.OracleDialect`         |
| Oracle 9i/10g        | `org.hibernate.dialect.Oracle9Dialect`        |
| Sybase               | `org.hibernate.dialect.SybaseDialect`         |
| Sybase Anywhere      | `org.hibernate.dialect.SybaseAnywhereDialect` |
| Microsoft SQL Server | `org.hibernate.dialect.SQLServerDialect`      |
| SAP DB               | `org.hibernate.dialect.SAPDBDialect`          |
| Informix             | `org.hibernate.dialect.InformixDialect`       |
| HypersonicSQL        | `org.hibernate.dialect.HSQLDialect`           |
| Ingres               | `org.hibernate.dialect.IngresDialect`         |
| Progress             | `org.hibernate.dialect.ProgressDialect`       |
| Mckoi SQL            | `org.hibernate.dialect.MckoiDialect`          |
| Interbase            | `org.hibernate.dialect.InterbaseDialect`      |
| Pointbase            | `org.hibernate.dialect.PointbaseDialect`      |
| FrontBase            | `org.hibernate.dialect.FrontbaseDialect`      |
| Firebird             | `org.hibernate.dialect.FirebirdDialect`       |

下面是一些常见数据库的项目配置示例文件

请注意：

- 这里的示例使用常见的默认端口和本地主机 (localhost)。请根据实际环境替换这些值。
- 对于 Hibernate 方言，这里案例使用旧版名称，但在注释中会提及现代推荐的方言（如果适用）。
- 需要确保已经在项目中添加了相应的 JDBC 驱动依赖。

#### IBM DB2 系列

```yml
# DB2 (通用) 配置示例
spring:
  datasource:
    url: jdbc:db2://localhost:50000/testdb
    username: db2user
    password: password
    driver-class-name: com.ibm.db2.jcc.DB2Driver
  jpa:
    properties:
      hibernate:
        dialect: org.hibernate.dialect.DB2Dialect
```
{: file="application.yml" }

#### PostgreSQL

```yml
# PostgreSQL 配置示例
spring:
  datasource:
    url: jdbc:postgresql://localhost:5432/testdb
    username: pguser
    password: password
    driver-class-name: org.postgresql.Driver
  jpa:
    properties:
      hibernate:
        # 现代推荐使用 org.hibernate.dialect.PostgreSQLDialect
        dialect: org.hibernate.dialect.PostgreSQLDialect
```
{: file="application.yml" }

#### MySQL 系列

```yml
# MySQL (推荐 InnoDB/现代版本) 配置示例
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/testdb?serverTimezone=UTC
    username: myuser
    password: password
    driver-class-name: com.mysql.cj.jdbc.Driver
  jpa:
    properties:
      hibernate:
        # 推荐使用 MySQL8Dialect 或 MySQLInnoDBDialect
        dialect: org.hibernate.dialect.MySQLInnoDBDialect
```
{: file="application.yml" }

#### Oracle 系列

```yml
# Oracle 配置示例
spring:
  datasource:
    url: jdbc:oracle:thin:@localhost:1521:XE # 替换为实际的 Service Name/SID
    username: orauser
    password: password
    driver-class-name: oracle.jdbc.OracleDriver
  jpa:
    properties:
      hibernate:
        # 现代推荐使用 Oracle12cDialect 或更高版本
        dialect: org.hibernate.dialect.Oracle9Dialect
```
{: file="application.yml" }

#### Microsoft SQL Server

```yml
# Microsoft SQL Server 配置示例
spring:
  datasource:
    url: jdbc:sqlserver://localhost:1433;databaseName=testdb
    username: sqluser
    password: password
    driver-class-name: com.microsoft.sqlserver.jdbc.SQLServerDriver
  jpa:
    properties:
      hibernate:
        # 现代推荐使用 SQLServer2012Dialect 或更高版本
        dialect: org.hibernate.dialect.SQLServerDialect
```
{: file="application.yml" }

#### 其他主流/特定数据库

| 数据库                 | 驱动类                                   | 方言                                          | URL 格式 (示例)                                                      |
| :--------------------- | :--------------------------------------- | :-------------------------------------------- | :------------------------------------------------------------------- |
| Sybase                 | `com.sybase.jdbc4.jdbc.SybDriver`        | `org.hibernate.dialect.SybaseDialect`         | `jdbc:sybase:Tds:localhost:5000/testdb`                              |
| Sybase Anywhere        | `com.sybase.jdbc4.jdbc.SybDriver`        | `org.hibernate.dialect.SybaseAnywhereDialect` | `jdbc:sybase:Tds:localhost:2638/testdb`                              |
| SAP DB                 | `com.sap.dbtech.jdbc.Driver`             | `org.hibernate.dialect.SAPDBDialect`          | `jdbc:sapdb://server_name/testdb`                                    |
| Informix               | `com.informix.jdbc.IfxDriver`            | `org.hibernate.dialect.InformixDialect`       | `jdbc:informix-sqli://localhost:9088/testdb:INFORMIXSERVER=myserver` |
| HypersonicSQL (HSQLDB) | `org.hsqldb.jdbcDriver`                  | `org.hibernate.dialect.HSQLDialect`           | `jdbc:hsqldb:file:/data/testdb`                                      |
| Ingres                 | `com.ingres.jdbc.IngresDriver`           | `org.hibernate.dialect.IngresDialect`         | `jdbc:ingres://localhost:II7/testdb`                                 |
| Progress               | `com.ddtek.jdbc.progress.ProgressDriver` | `org.hibernate.dialect.ProgressDialect`       | `jdbc:datadirect:progress://localhost:20000;databaseName=testdb`     |
| Interbase              | `interbase.interclient.Driver`           | `org.hibernate.dialect.InterbaseDialect`      | `jdbc:interbase://localhost/testdb`                                  |
| Firebird               | `org.firebirdsql.jdbc.FBDriver`          | `org.hibernate.dialect.FirebirdDialect`       | `jdbc:firebirdsql://localhost:3050/testdb`                           |

> 对于 Mckoi SQL, Pointbase, 和 FrontBase 这类相对不那么主流的数据库，驱动类和 URL 格式可能因版本和厂商而异，使用前务必查阅其官方文档来确定准确的 `driver-class-name` 和 `url` 格式
{: .prompt-warning }

### 社区支持的数据库方言
#### SQLite

最常用的 SQLite JDBC 驱动是 Xerial SQLite JDBC Driver。

```xml
<dependency>
    <groupId>org.xerial</groupId>
    <artifactId>sqlite-jdbc</artifactId>
</dependency>
```
{: file="pom.xml" }

连接 SQLite 最大的特殊点 Hibernate 方言。Hibernate 官方在早期版本中并没有直接提供 `SQLiteDialect`，但社区贡献了一个非常成熟的方言实现。

为了让 Hibernate 能够支持 SQLite 的分页、类型转换等，你需要：

**引入 SQLite 社区方言**： 在 `pom.xml` 中引入一个包含社区方言的库。

- 推荐使用 `com.github.gwenn.jpa-hibernate:sqlite-dialect` 这样的第三方库（这是一个社区维护的适配器）。
- 如果你的 Spring Boot 版本比较新，可以直接在 Maven/Gradle 配置中添加以下依赖：

```yml
# Microsoft SQL Server 配置示例
spring:
  datasource:
    # 1. JDBC URL: 指向你的 SQLite 文件路径
    # 如果文件不存在，驱动会自动创建它
    url: jdbc:sqlite:./data/app.db
    # SQLite 不需要用户名和密码
    username: 
    password: 
    # 2. 驱动类名
    driver-class-name: org.sqlite.JDBC
  jpa:
    properties:
      hibernate:
        # 3. 方言：使用社区提供的方言类
        dialect: com.github.gwenn.sqlite.SQLiteDialect 
        # 确保 ddl-auto 可以自动创建表
        # ddl-auto: update
```
{: file="application.yml" }

#### MariaDB

MariaDB 是 MySQL 的一个分支，因此它的驱动和方言与 MySQL 高度兼容。

驱动则可以直接使用 MariaDB 官方的 JDBC 驱动

```xml
<dependency>
    <groupId>org.mariadb.jdbc</groupId>
    <artifactId>mariadb-java-client</artifactId>
</dependency>
```
{: file="pom.xml" }

在配置中，使用 MariaDB 的驱动类和 URL，方言可以沿用 MySQL 的，或者使用 MariaDB 专用的方言（如果需要使用 MariaDB 特有功能）

```yml
spring:
  datasource:
    # 1. JDBC URL: MariaDB 默认端口和 MySQL 一致 (3306)
    url: jdbc:mariadb://localhost:3306/your_mariadb_name
    username: mariadb_user
    password: mariadb_password
    # 2. 驱动类名
    driver-class-name: org.mariadb.jdbc.Driver
  jpa:
    properties:
      hibernate:
        # 3. Hibernate 方言：可以使用 MySQL 的方言，或者使用 MariaDB 专用的
        # 推荐使用 MariaDBDialect 或 MariaDB103Dialect 等特定版本方言
        dialect: org.hibernate.dialect.MariaDBDialect
        # 或：dialect: org.hibernate.dialect.MySQL8Dialect （因为兼容性高）
```
{: file="application.yml" }

#### H2

H2 数据库是 Spring Boot 项目中最常用的内存或文件级数据库，通常用于开发、测试和原型设计阶段，因为它启动快、配置简单，并且可以与应用一起打包。

H2 数据库主要有三种运行模式：内存模式、文件模式和服务器模式。

驱动安装如下:

```xml
<dependency>
    <groupId>com.h2database</groupId>
    <artifactId>h2</artifactId>
    <scope>runtime</scope>
</dependency>
```
{: file="pom.xml" }

**内存模式 (推荐用于测试)**

数据存储在 JVM 内存中。应用停止或 JVM 退出时，数据会丢失。这是最快、最简单的模式。

```yml
# application.yml
spring:
  datasource:
    # 1. JDBC URL: 使用 jdbc:h2:mem: 即可，:testdb 是数据库名称，可任意命名
    url: jdbc:h2:mem:testdb 
    username: sa # H2 默认用户名
    password:     # H2 默认密码为空
    driver-class-name: org.h2.Driver
  jpa:
    # 2. Hibernate 方言：Spring Boot 通常会自动配置为 H2Dialect
    properties:
      hibernate:
        dialect: org.hibernate.dialect.H2Dialect

# 3. 启用 H2 Web 控制台（可选，但强烈推荐）
spring:
  h2:
    console:
      enabled: true
      path: /h2-console # 控制台访问路径，浏览器访问 http://localhost:8080/h2-console
```
{: file="application.yml" }

> 注意： 启用控制台后，登录时使用的 JDBC URL 必须与 `spring.datasource.url` 中的值保持一致 (`jdbc:h2:mem:testdb`)。
{: .prompt-warning }

**文件模式 (推荐用于原型/轻量级应用)**

数据存储在硬盘文件系统中。应用重启后数据不会丢失。

```yml
# application.yml
spring:
  datasource:
    # 1. JDBC URL: 使用 jdbc:h2:file:，后面是文件路径
    # 路径 ./data/testdb 表示在应用根目录下的 data 文件夹中创建 testdb.mv.db 文件
    url: jdbc:h2:file:./data/testdb 
    username: sa
    password: 
    driver-class-name: org.h2.Driver
  jpa:
    properties:
      hibernate:
        dialect: org.hibernate.dialect.H2Dialect
```
{: file="application.yml" }

**保持连接存活 (内存模式扩展)**

如果你的应用使用内存数据库 (模式 A)，并在程序中途关闭了所有的连接池连接，H2 可能会认为没有应用在使用它，从而关闭数据库并删除数据。

为了防止这种情况，可以在 URL 中添加 `;DB_CLOSE_DELAY=-1`，强制 H2 在 JVM 退出前保持活跃：

```yml
spring:
  datasource:
    # 保持数据库打开，直到 JVM 退出
    url: jdbc:h2:mem:testdb;DB_CLOSE_DELAY=-1
```
{: file="application.yml" }

## 可迁移数据查询架构设计原则
### 持久化架构与 ORM 特性

- **1. 坚持 JPA 规范（核心）**	

    严格使用标准的 JPA 注解和 API，避免直接调用底层 Hibernate/EclipseLink 的专有方法或特性。	

    避免使用如 Hibernate Session、Criteria API 的非标准部分，专注于 `@Entity`, `@Id`, `@OneToMany` 等标准 JPA 注解。

- **2. 抽象 Repository 实现**	

    仅依赖 `JpaRepository` 接口提供的 CURD 和方法名查询能力。不要为 `Repository` 接口编写实现类。	

    避免在代码中手动管理 `EntityManager` 的生命周期，让 Spring Data JPA 自动实现 `Repository` 接口。

- **3. 标准化主键生成策略**	

    避免依赖数据库特有的自增机制。选择适用于大多数数据库的策略。	

    倾向于使用 `GenerationType.SEQUENC`E（配合 Sequence 表）或 `GenerationType.AUTO`，让 Hibernate 方言处理底层差异。避免过度依赖 MySQL 的 `IDENTITY（AUTO_INCREMENT）`。

- **4. 谨慎使用二级缓存**	

    二级缓存的配置和实现（例如 Ehcache, Redis）通常依赖于 ORM 框架和数据库连接特性。	

    如果需要跨应用重启的数据缓存，优先使用外部独立的缓存系统（如 Redis），而不是依赖 ORM 框架的二级缓存。

### 查询机制与 SQL 兼容性

- **5. 优先使用 JPQL/方法名查询**

    使用面向对象的 JPQL (Java Persistence Query Language) 或 Spring Data 的方法名查询约定来编写查询逻辑。	
    
    避免在 JPQL 中使用数据库特有的函数。只在极少数性能敏感或复杂报表场景下才考虑使用原生 SQL。 请保证**语法相对可移植，能适配不同数据库**。

- **6. 注意命名和定义冲突**
    
    在为实体或字段起名时，**避免使用到相关数据库的关键字和保留关键字**，可以通过加限制前缀来避免。

    - [Mysql 相关关键字链接](https://dev.mysql.com/doc/refman/8.0/en/keywords.html)
    - [Oracle 相关关键字链接](https://docs.oracle.com/cd/B19306_01/em.102/b40103/app_oracle_reserved_words.htm)
    - [Mssql 相关关键字链接](https://docs.microsoft.com/en-us/sql/odbc/reference/appendixes/reserved-keywords?view=sql-server-ver15)

    同时**注意实体, 关联关系, 索引的命名长度限制**, 如果长度超过特定数据库支持的字符长度，JPA则会将其截断

- **7. 抽象分页/排序语法**

    充分利用 Spring Data JPA 提供的 `Pageable` 和 `Sort` 接口，让 ORM 框架处理不同数据库的分页（`LIMIT/OFFSET` 或 `ROWNUM`）和排序语法。	
    
    避免手动拼接分页 SQL。

- **8. 事务隔离级别标准化**

    避免依赖数据库特有的事务隔离级别。只使用标准的四个级别（`Read` `Committed`, `Repeatable` `Read` 等）。	
    
    在 `@Transactional` 中，只使用 `Isolation.READ_COMMITTED` 等 Java 标准枚举。避免使用数据库默认级别，因为它可能因数据库而异。

### 查询机制与 SQL 兼容性

- **9. 外部化配置**

    将所有与数据库连接相关的配置（URL, 方言, 驱动）完全从代码中分离，放在外部配置文件或环境变量中。	
    
    确保 `spring.datasource.*` 和 `spring.jpa.properties.hibernate.dialect` 等配置可以轻松通过环境变量或外部 `application.yml` 文件覆盖。

- **10. 使用数据库版本控制工具**

    使用工具来管理 DDL (数据定义语言)，而不是依赖 ORM 的 `ddl-auto`。	
    
    强制使用 **Flyway** 或 **Liquibase**。这可以确保每个数据库（无论新旧）的 Schema 都是通过版本控制的 SQL 脚本创建的，可以手动调整以适应特定数据库的语法。

    在用 Liquibase 创建表字段时，选择合适的类型，**不要使用特定于数据库的数据类型**。

- **11. 自动化兼容性测试**

    建立 CI/CD 流水线，针对至少两种不同的数据库运行全套集成测试。
    
    使用 Testcontainers 或 Docker 容器在 CI 流程中启动一个 MySQL 实例和一个 PostgreSQL 实例，并对这两个数据库执行相同的测试套件，验证兼容性。

# 参考

- [JPA 适配多种数据库 \| Zeral's Blog](https://zeral.cn/persistence/jpa-%E5%BF%AB%E9%80%9F%E9%80%82%E9%85%8D%E5%A4%9A%E7%A7%8D%E6%95%B0%E6%8D%AE%E5%BA%93/)
- [Hibernate 是否完全支持 SQLite? - StackOverflow](https://stackoverflow.com/questions/17587753/does-hibernate-fully-support-sqlite)

