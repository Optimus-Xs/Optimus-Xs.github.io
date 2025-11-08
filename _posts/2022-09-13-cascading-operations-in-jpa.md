---
layout: post
title: JPA的级联操作
date: 2022-09-13 23:14 +0800
categories: [Software Development] 
tags: [DataBase,Java,Spring]
---

# JPA 中的级联
> 由于重复性的操作十分烦琐，尤其是在处理多个彼此关联对象情况下，此时我们可以使用级联（Cascade）操作。级联 在关联映射中是个重要的概念，指当主动方对象执行操作时，被关联对象（被动方）是否同步执行同一操作。

## JPA 中关联关系配置

在 JPA (Java Persistence API) 中设置实体的关联关系是核心功能之一。主要通过在实体类中使用**注解（Annotations）**来定义不同实体间的关系

### 一对一关系
用于表示一个实体实例与另一个实体实例一一对应。

- `@OneToOne`: 标记字段是一对一关系。
- `@JoinColumn`: （可选，但推荐使用）定义外键所在的列名。通常在外键持有方使用。
  
**示例**： 一个人 (`Person`) 只有一个护照 (`Passport`)

```java
// Person 实体 (持有外键的一方，通常是关系维护方)
@Entity
public class Person {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // ... 其他字段

    @OneToOne(cascade = CascadeType.ALL) // cascade = ALL 表示对 Person 的所有操作会级联到 Passport
    @JoinColumn(name = "passport_id") // 指定外键列名为 passport_id
    private Passport passport;

    // Getter/Setter...
}

// Passport 实体
@Entity
public class Passport {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // ... 其他字段

    @OneToOne(mappedBy = "passport") // mappedBy 指向 Person 实体中关联 Passport 的字段名
    private Person owner; // 关系非维护方，由 Person 来维护关联关系

    // Getter/Setter...
}
```

### 一对多/多对一关系 

这是最常见的关系类型。通常由**多**的一方来维护外键。

- `@ManyToOne`: 标记字段是多对一关系（在外键持有方使用）。
- `@OneToMany`: 标记字段是一对多关系（在一的一方使用）。
- `@JoinColumn`: （在外键持有方，即 `@ManyToOne` 的字段上使用）定义外键所在的列名。

**示例**： 一个部门 (`Department`) 有多名员工 (`Employee`)。

```java
// Employee 实体 (多方，持有外键，关系维护方)
@Entity
@Table(name = "t_employee")
public class Employee {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // ... 其他字段

    @ManyToOne // 多个 Employee 对应一个 Department
    @JoinColumn(name = "department_id") // 指定外键列名为 department_id
    private Department department;

    // Getter/Setter...
}

// Department 实体 (一方)
@Entity
@Table(name = "t_department")
public class Department {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // ... 其他字段

    @OneToMany(mappedBy = "department", cascade = CascadeType.ALL)
    // mappedBy 指向 Employee 实体中关联 Department 的字段名
    private List<Employee> employees = new ArrayList<>();

    // Getter/Setter...
}
```

### 多对多关系

用于表示一个实体实例可以与多个另一个实体实例关联，反之亦然。通常会生成**中间表（Join Table）**。

- `@ManyToMany`: 标记字段是多对多关系。
- `@JoinTable`: （在外键维护方使用）定义中间表及其外键。

**示例**： 一个学生 (`Student`) 可以选修多门课程 (`Course`)，一门课程可以被多个学生选修。

```java
// Student 实体 (关系维护方，通常是定义 @JoinTable 的一方)
@Entity
public class Student {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // ... 其他字段

    @ManyToMany
    @JoinTable(
        name = "student_course", // 指定中间表的名称
        joinColumns = @JoinColumn(name = "student_id"), // 指定 Student 在中间表中的外键列名
        inverseJoinColumns = @JoinColumn(name = "course_id") // 指定 Course 在中间表中的外键列名
    )
    private Set<Course> courses = new HashSet<>();

    // Getter/Setter...
}

// Course 实体 (关系非维护方)
@Entity
public class Course {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // ... 其他字段

    @ManyToMany(mappedBy = "courses") // mappedBy 指向 Student 实体中关联 Course 的字段名
    private Set<Student> students = new HashSet<>();

    // Getter/Setter...
}
```

### 概念补充

#### 关系维护方（Owning Side）和非维护方（Non-Owning Side）

- **关系维护方**：在数据库中持有外键的一方，负责管理和更新关联关系。在 Java 代码中，维护方通常不会使用 `mappedBy` 属性。
- **关系非维护方**：不持有外键的一方，其关联关系由维护方维护。在 Java 代码中，非维护方必须使用 `mappedBy` 属性来指定维护方实体中关联自己的那个字段名。
- **规则**： `@OneToOne` 和 `@OneToMany` 的另一方，以及 `@ManyToMany` 的任一方，都可以是非维护方。

> `mappedBy` 的作用是纯粹的JPA/对象层面的定义。它用于指定非维护方（Non-Owning Side），并指出该关系的维护权在对面的哪个字段上。
> 
> **它不做任何数据库操作。**它告诉 JPA 容器(根据[上面提到的案例](#一对多多对一关系)而言)：“我已经知道这个关系了，请去查看对面的 `Employee` 实体中的 `department` 字段，它才是真正负责管理这个关系的。”
> 
> 它只用于关系中的非维护方（Non-Owning Side），并且只能用于 `@OneToOne`, `@OneToMany`, 和 `@ManyToMany` 注解中。
{: .prompt-tip }

#### mappedBy 属性值的规则:

JPA 规范的目的是在 Java 对象模型和关系数据库模型之间建立映射。[例如](#一对多多对一关系)当你在 `Department` 实体中使用 `@OneToMany` 时：

- JPA 已经知道关联的类型： 它知道 `List<Employee> employees` 关联到的是 `Employee` 实体。
- JPA 已经知道关联的方向： `@OneToMany` 已经明确地定义了这是一对多关系。

因此，当你写 `mappedBy = "department"` 时，JPA 并不需要完整的写为 `Employee.department`，因为它已经上下文关联地知道这个 "`department`" 字段一定存在于关联的那个实体 (`Employee`) 中。

> 对于初学者而言, `mappedBy = "department"` 很容易让人误解为： “这个关系是由 `Department` 类（或表）来维护的。”
>
> 在 JPA 中，判断**关系维护方（Owning Side）**的关键在于以下两点，而不是 `mappedBy` 的值：
> 
> - `mappedBy` 的存在：
>   - 如果一个关联注解中存在 `mappedBy`: 那么该实体就是非维护方。它明确放弃了维护权。
>   - 如果一个关联注解中没有`mappedBy`: 那么该实体就是维护方（JPA 会默认创建一个联结表或者额外外键来维护）。
> - `@JoinColumn` 的位置：
>   - 谁使用了 `@JoinColumn`，谁就持有外键，谁就是维护方。 在[上面的例子](#一对多多对一关系)中，`Employee` 使用了 `@JoinColumn(name = "department_id")`，所以 `Employee` 才是维护方。
>
> **要理解 mappedBy 的含义，应该将其翻译为：**
>
> `@OneToMany(mappedBy = "department")`: 我（`Department`）有一个 `Employee` 列表，但**我的关联关系是映射（代理）**给 `Employee` 实体中的那个名叫 `department` 的字段来维护的。
> 
> 同时对于数据库层面而言: `t_department` 表中没有外键。外键在 `t_employee` 表中。
{: .prompt-warning }


#### 为什么需要 mappedBy

在双向关联中，两个实体类都知道对方的存在。如果不使用 `mappedBy`，JPA 会认为两边都需要维护这个关系，这会导致：

- 数据库中出现重复的外键 (如果两边都尝试创建 `JoinColumn`)。
- 数据不一致：当你更新关系时，如果两个实体表的外键绑定的对象不一致，JPA 不知道是应该以哪一个实体的外键字段为准。

mappedBy 的存在，就是为了明确宣布：“我只是提供了一个反向导航的视图，我没有维护权，请以我的伙伴（mappedBy 指向的那个字段）为准。”

**Fetch 策略**

- **`fetch = FetchType.LAZY`（延迟加载）**：默认策略（`@OneToMany` 和 `@ManyToMany`）。只有在实际访问关联对象时才加载数据，效率高，推荐使用。
- **`fetch = FetchType.EAGER`（即时加载）**：默认策略（`@OneToOne` 和 `@ManyToOne`）。在加载主实体时，立即加载关联对象，可能导致性能问题。

#### 双向关联和单向关联

双向关联和单向关联描述了实体（Entity）之间导航关系的方式。本质上，它是在 Java 代码层面，一个对象能否直接访问到它关联的另一个对象

- **单向关联 (Unidirectional Association)**: 关系只能从一个实体导航到另一个实体，反之则不行
- **双向关联 (Bidirectional Association)**: 关系可以从任何一个实体导航到另一个实体。两个实体都包含对对方的引用

下面是两种关联方式的实体配置示例, 这里我们的 `Group` 和 `Customer` 是一个一对多的关系

**单向关联**

```java
@Entity
@Table(name = "t_group")
@Data
public class Group { 
    @Id
    @SequenceGenerator(name = "group_seq_generator", sequenceName = "group_seq", allocationSize = 1)
    @GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "group_seq_generator")
    private Long id; 
    
    private String name; 
    
    // ⚠️ 注意：Group 类中没有 List<Customer> 字段
}

@Entity
@Table(name = "t_customer")
@Data
public class Customer {
    @Id
    @SequenceGenerator(name = "customer_seq_generator", sequenceName = "customer_seq", allocationSize = 1)
    @GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "customer_seq_generator")
    private Long id;
    
    private String name;
    
    // ⭐ ManyToOne 是默认的拥有方，不需要 mappedBy
    @ManyToOne 
    @JoinColumn(name = "group_id") // 明确指定外键列名
    private Group group; 
}
```
{: file="单向关联的案例实体配置" }

关系仅从 `Customer` 导航到 `Group`。`Customer` 知道它属于哪个 `Group`，但 `Group` 实体中没有维护客户列表。

只需要设置 customer.setGroup(group)，然后保存 customer 或 group (如果配置了级联)

**双向关联**

```java
@Entity
@Table(name = "t_group")
@Data
public class Group { 
    @Id
    @SequenceGenerator(name = "group_seq_generator", sequenceName = "group_seq", allocationSize = 1)
    @GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "group_seq_generator")
    private Long id; 
    
    private String name; 
    
    // ⭐ OneToMany 是反转方：
    // 1. 使用 mappedBy="group"，指定外键由 Customer 实体中的 "group" 字段维护。
    // 2. CascadeType.ALL 允许级联操作。
    @OneToMany(cascade = CascadeType.ALL, mappedBy = "group", orphanRemoval = true)
    private List<Customer> customerList = new ArrayList<>();
    
    // 辅助方法：确保双向关系同步
    public void addCustomer(Customer customer) {
        this.customerList.add(customer);
        customer.setGroup(this); // 关键：设置拥有方
    }
}

@Entity
@Table(name = "t_customer")
@Data
public class Customer {
    @Id
    @SequenceGenerator(name = "customer_seq_generator", sequenceName = "customer_seq", allocationSize = 1)
    @GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "customer_seq_generator")
    private Long id;
    
    private String name;
    
    // ⭐ ManyToOne 是拥有方：
    // 1. 没有 mappedBy。
    // 2. 数据库中的 group_id 外键由此字段维护。
    @ManyToOne 
    @JoinColumn(name = "group_id") // 明确指定外键列名
    private Group group; 
}
```
{: file="双向关联的案例实体配置" }

关系可以在两个方向上导航：Customer 知道 Group，同时 Group 也知道所有关联的 Customer

> 双向关联必须维护双向同步，同时为两个实体关联属性配置值
{: .prompt-danger }

在此案例中必须通过 `group.addCustomer(customer)` 辅助方法来建立关系(或者手动配置`customer`的`group`属性和`group`的`customerList`属性)，然后调用 `groupRepository.save(group)` 才能正常级联保存, 否则会出现`can not insert null into t_customer.group_id` 错误

> **最佳实践**
>
> 优先使用单向关联。只在业务逻辑真正需要双向导航时，才使用双向关联，并且必须使用辅助方法或者手动处理同步关系
{: .prompt-tip }

#### JPA/Hibernate 中实体生命周期最核心的三个状态

- **瞬时（Transient）**: 实体对象只是一个普通的 Java 对象，它存在于内存中，但 JPA 框架完全不知道它的存在，数据库中也没有对应的记录, 对象还没有 ID，对该对象的任何修改都不会对数据库造成影响。
- **托管（Managed）**: 实体对象被 持久化上下文 (Persistence Context) 追踪和管理。持久化上下文是一个内存缓存和同步机制。托管状态下，对对象属性的任何修改（在事务内）都会被 JPA/Hibernate 自动监测到。在事务提交时，JPA 会自动生成 UPDATE 语句将其同步到数据库，无需您手动调用 `update()` 或 `save()` 方法
- **分离（Detached）**: 这是实体对象脱离 JPA 管理后的状态，实体对象曾经是托管的（在数据库中有记录和 ID），但它现在已经离开了持久化上下文的“看管”， 对象仍然存在于内存中，并且拥有 ID， 您对该对象的任何修改将不再自动同步到数据库（如果没有通过@Transactional配置事务， 在`save()`完成返回后对象会变成分离状态）

## 级联简介和基础操作

> JPA的级联操作允许在对一个实体对象进行操作时，自动地对其关联的实体对象进行相同的操作。级联操作可以简化数据操作的管理，确保关联数据的一致性。
{: .prompt-tip }

这里试图使用一个新的的例子来说明JPA级联操作的配置具体区别。

我们使用一个订单和订单项的例子。该例子在网络上那些介绍JPA CascadeType用法的文章中广为流传。

```java
/** 订单 */
@Entity
@Table(name = "t_order")
public class Order {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;
    @Column
    private String name;
    @OneToMany(mappedBy = "order", targetEntity = Item.class, fetch = FetchType.LAZY)
    private List<Item> items;
}

/** 订单物品 */
@Entity
@Table(name = "t_item")
public class Item {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;
    @Column
    private String name;
    @ManyToOne(fetch = FetchType.LAZY, targetEntity = Order.class)
    @JoinColumn(name = "order_id")
    private Order order;
}

/** Order Repository */
public interface OrderRepository extends JpaRepository<Order, Integer>,
    JpaSpecificationExecutor<Order> {
}

/** Item Repository */
public interface ItemRepository extends JpaRepository<Item, Integer>,
    JpaSpecificationExecutor<Item> {
}
```
{: file="订单和物品实体的基本配置配置" }

通过jpa自动建表，这时候item表中有一个字段`order_id`，是order表的`id`，这是一个外键约束，记住这一点，很重要

但是我们现在还没有配置完成 JPA 的级联配置, 还需要单独在`Order`类的`items`属性上的`@ManyToOne`关联注解加上`cascade` 属性

### 新增数据
客户每次下完订单后，需要保存Order，但是订单里含有Item，因此，在保存Order时候，Order相关联的Item也需要保存。采用上面的模型，使用如下的测试代码：

```java
@Test
public void addTest(){
    // 准备数据
    Order order = new Order();
    order.setName("order1");

    Item item1 = new Item();
    item1.setName("item1_order1");
    item1.setOrder(order);

    Item item2 = new Item();
    item2.setName("item2_order1");
    item2.setOrder(order);

    List<Item> items = new ArrayList<Item>();
    items.add(item1);
    items.add(item2);
    order.setItems(items);

    //保存Order测试
    orderRepository.save(order);
    Assert.assertEquals(1,orderRepository.count());
    Assert.assertEquals(2,itemRepository.count());

    //保存Item测试
    itemRepository.save(items);
    Assert.assertEquals(1,orderRepository.count());
    Assert.assertEquals(2,itemRepository.count());
}
```
{: file="级联新增数据的流程" }

这时候我们针对 Order 和 Item 两个类的 CascadeType 的配置有以下4种情况

```java
// Order 实体（非维护方）
@OneToMany(mappedBy = "order") 
private List<Item> items; 

// Item 实体（维护方）
@ManyToOne
@JoinColumn(name = "order_id")
private Order order;
```
{: file="不使用CascadeType" }

- **保存Order测试**: `Order` 是非维护方，保存 `Order` 不会自动保存关联的 `Item`。当事务提交时，JPA 尝试保存 `Item` 时失败（根本没有尝试）。
- **保存Item测试**: `Item` 是维护方，它在保存时会尝试插入 `order_id`。此时 `order` 对象是持久化状态，但它关联的 `Order` 尚未被持久化，导致数据库外键约束失败（`order_id` 找不到对应的 `Order` 记录）。

```java
// Order 实体（非维护方）
@OneToMany(mappedBy = "order", cascade = CascadeType.PERSIST) // Order 加上 CascadeType.PERSIST
private List<Item> items; 

// Item 实体（维护方）
@ManyToOne
@JoinColumn(name = "order_id")
private Order order;
```
{: file="单独在Order类的items属性上加入CascadeType.PERSIST" }

- **保存Order测试**: `Order` 上的级联生效。保存 `Order` 时，JPA 级联保存了 `items` 列表中的两个 `Item` 对象。因为 `Item` 是维护方，它在保存时会写入外键 `order_id`，而此时 `order` 已经被持久化，所以成功。
- **保存Item测试**: 级联是单向的，它不影响反向操作。保存 `Item` 时，JPA 不会去查看 `Order` 上的级联设置，且 `Item` 上没有级联，所以不会保存 `Order`，导致外键约束失败。

```java
// Order 实体（非维护方）
@OneToMany(mappedBy = "order") 
private List<Item> items; 

// Item 实体（维护方）
@ManyToOne(cascade = CascadeType.PERSIST) // Item 加上 CascadeType.PERSIST
@JoinColumn(name = "order_id")
private Order order;
```
{: file="单独在Item类的order属性上加入CascadeType.PERSIST" }

- **保存Order测试**: `Order` 是非维护方，保存 `Order` 时不会级联到 `Item`。
- **保存Item测试**: 级联生效。保存 `Item` 时，JPA 发现 `Item.order` 上有级联，于是先持久化 `Order` 对象。`Order` 对象持久化成功后，`Item` 再持久化，写入外键 `order_id`，成功。

```java
// Order 实体（非维护方）
@OneToMany(mappedBy = "order", cascade = CascadeType.PERSIST) // 都加上 CascadeType.PERSIST
private List<Item> items; 

// Item 实体（维护方）
@ManyToOne(cascade = CascadeType.PERSIST) // 都加上 CascadeType.PERSIST
@JoinColumn(name = "order_id")
private Order order;
```
{: file="在Order和Item类中都使用CascadeType.PERSIST" }

- **保存Order测试**: 与情况 2 相同，`Order` 级联保存 `Item` 成功。
- **保存Item测试**: 与情况 3 相同，`Item` 级联保存 `Order` 成功。结论： 无论从哪一方开始保存，只要该字段配置了 `CascadeType.PERSIST`，关联的对象都会被持久化，从而避免外键约束失败。

**CascadeType 配置位置总结**

| CascadeType的用法                | 保存Order测试结果<br/>`orderRepository.save(order);` | 保存Item测试<br/>`itemRepository.save(items);` |
| :------------------------------- | :--------------------------------------------------- | :--------------------------------------------- |
| 不使用Cascade配置                | order可以保存到数据库，item不能                      | 报错，因为外键使用的order_id不存在             |
| Order类items属性增加Cascade配置  | order和items都可以保存到数据库                       | 报错，同上                                     |
| Item类order属性增加Cascade配置   | order可以保存到数据库，item不能                      | order和items都可以保存到数据库                 |
| Order和Item类中都使用Cascade配置 | order和items都可以保存到数据库                       | order和items都可以保存到数据库                 |


**级联是单向的 (Cascade is Unidirectional)**

- `ascadeType.PERSIST` 总是从使用它的那个实体出发，沿着字段方向传播持久化操作。
  - `Order` 上配置级联，只影响 `Order` 存入时对 `Item` 的操作。
  - `Item` 上配置级联，只影响 `Item` 存入时对 `Order` 的操作。
- `保存Order测试`结果成功的条件：`Order.items` 上有 `PERSIST`。
- `保存Item测试`成功的条件：`Item.order` 上有 `PERSIST`。

**失败的原因永远是外键约束 (Foreign Key Constraint)**

- 在所有失败的案例中，错误的原因都是相同的：尝试保存维护方 (`Item`) 时，它需要将一个有效的外键值 (`order_id`) 写入数据库，但此时关联的 `Order` 记录尚未存在。
- **非维护方 (`Order`) 的保存操作永远不能级联保存另一个方向上的对象**，除非该对象自身也支持级联（情况 3 的 `保存Order测试` 失败就是例证）。

### 删除数据

现在有这样的场景，客户需要删除一个订单,那么订单中的订单项也需要一并删除，为了可以实现级连删除的效果，我们使用以下测试代码：

```java
@Test
public void testDelete(){
    //Order删除测试
    orderRepository.delete(order);
    Assert.assertEquals(0, orderRepository.count());
    Assert.assertEquals(0, orderRepository.count());

    //Item删除测试
    itemRepository.delete(items);
    Assert.assertEquals(0, orderRepository.count());
    Assert.assertEquals(0, itemRepository.count());
}
```
{: file="级联删除数据的流程" }

在该场景中，这时候我们针对 Order 和 Item 两个类的 CascadeType 的配置依然还是有以下4种情况:

- 不使用CascadeType
- 在Order类的items属性上使用CascadeType.REMOVE
- 在Item类的order属性上使用CascadeType.REMOVE
- 在Order和Item中都使用CascadeType.REMOVE

**这些不同配置的执行结果如下:**

| CascadeType的用法                | Order删除测试<br/>`orderRepository.delete(order);` | Item删除测试<br/>`itemRepository.delete(items);`       |
| :------------------------------- | :------------------------------------------------- | :----------------------------------------------------- |
| 不使用Cascade配置                | 报错，被item的order_id外键约束                     | 删除item，不能删除order                                |
| Order类items属性增加Cascade配置  | 级连删除成功；先删除items，然后再删除order         | 可以删除item，不能删除order                            |
| Item类order属性增加Cascade配置   | 报错，被item的order_id外键约束                     | 可以删除items及其级联的order对象，但是不能删除单个Item |
| Order和Item类中都使用Cascade配置 | order和items都被删除                               | order和items都被删除；如果只删除部分item，报错         |




> **最佳实践建议**
> 
> 在一对多的双向关联中，推荐的级联配置是：
> 
> - 在“一”方 (`Order`) 的 `@OneToMany` 字段上使用 `CascadeType.PERSIST`, `CascadeType.REMOVE`：确保你保存或删除 `Order` 时，JPA 会级联处理 `Item` 列表。
> - 在“多”方 (`Item`) 的 `@ManyToOne` 字段上通常不使用级联：因为如果删除一个 `Item` 级联删除了 `Order`，可能会导致其他 `Item` 失去关联，这通常不是我们希望的行为。
{: .prompt-tip }


### 更新数据

在业务上，经常会有这样一种类似的需要：查找到了一个业务实体后，要更新该实体，同时也需要更新该实体所关联的其他业务实体。在我们的例子中就是，同时需要更新Order和其所关联的Item。我们使用如下测试代码：

```java
@Test
public void testUpdate(){
    order.setName("order1_updated");

    items.get(0).setName("item1_order1_updated");
    items.get(1).setName("item2_order1_updated");

    // Order 发起更新保存
    orderRepository.save(order);
    Assert.assertEquals(1, orderRepository.count(new Specification<Order>(){
        public Predicate toPredicate(Root<Order> root, CriteriaQuery<?> cq, CriteriaBuilder cb) {
            return cb.equal(root.get("name").as(String.class), "order1_updated");
        }
    }));
    Assert.assertEquals(1, itemRepository.count(new Specification<Item>() {

        public Predicate toPredicate(Root<Item> root,CriteriaQuery<?> cq, CriteriaBuilder cb) {
            return cb.equal(root.get("name").as(String.class), "item1_order1_updated");
        }
    }));

    //  items 发起更新保存
    itemRepository.save(items);
    Assert.assertEquals(1, itemRepository.count(new Specification<Item>() {
        public Predicate toPredicate(Root<Item> root,CriteriaQuery<?> cq, CriteriaBuilder cb) {
            return cb.equal(root.get("name").as(String.class), "item1_order1_updated");
        }
    }));
    Assert.assertEquals(1, orderRepository.count(new Specification<Order>(){
        public Predicate toPredicate(Root<Order> root, CriteriaQuery<?> cq, CriteriaBuilder cb) {
            return cb.equal(root.get("name").as(String.class), "order1_updated");
        }
    }));
}
```
{: file="级联更新数据的流程" }

**在该场景中，我们分别测试如下情况：**

| CascadeType的用法                             | Order 发起保存<br/>`orderRepository.save(order);` | items 发起更新保存<br/>`itemRepository.save(items);` |
| :-------------------------------------------- | :------------------------------------------------ | :--------------------------------------------------- |
| 不CascadeType.MERGE                           | 更新Order成功，不会级连更新items                  | 更新items成功，不会级联更新items所关联的order对象    |
| 单独在Order的items属性上使用CascadeType.MERGE | 更新order成功，并且级连更新items                  | 更新items成功，不会级联更新order                     |
| 单独在Item的属性order上使用CascadeType.MERGE  | 更新order成功，不会级联更新items                  | 更新items成功，可以级连更新其关联的order对象         |
| 在Order和Item中都使用CascadeType.MERGE        | 更新order成功，并且级连更新items                  | 更新items成功，可以级连更新其关联的order对象         |

这两个代码段的区别在于谁发起了 `save` 操作，以及实体关系中配置的 JPA 级联（CascadeType） 策略。


## 级联类型

在 JPA 中，级联（CascadeType） 定义了父实体上执行的持久化操作（如保存、删除、更新等）是否应该自动传播到它所关联的子实体上。

- ALL
- PERSIST
- MERGE
- REMOVE
- REFRESH
- DETACH

这六种（包括 ALL）是 JPA 规范中定义的所有标准级联类型，它们对应了 EntityManager 的几种核心操作。

### ALL

ALL类型包括所有的jpa级联类型和Hibernate的级联类型。

当子实体的生命周期完全依赖于父实体时。例如，`Order` 和 `OrderLine`（订单项）。删除订单，订单项也应该删除。

> 过度使用 `ALL`，尤其是在双向关联中，可能会导致意外的数据删除或更新（例如，删除一个用户意外删除了不应删除的共享地址）。
{: .prompt-danger }

具体的使用方法，就是在实体的关联注解上使用`@OneToMany(cascade = CascadeType.ALL)`级联类型:

```java
@Entity
@Table(name = "ORDERS") // 使用 ORDERS 避免与 SQL 关键字冲突
public class Order {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // 核心配置：使用 CascadeType.ALL
    // mappedBy = "order" 表示 OrderLine 是关系的所有者，Order 只是映射方
    // 此外，建议搭配 orphanRemoval = true 来处理“孤儿”实体，使其管理更完善。
    @OneToMany(
        mappedBy = "order",
        cascade = CascadeType.ALL, // <--- 关键：将所有操作传播给 OrderLine
        orphanRemoval = true       // <--- 推荐：如果从集合中移除 OrderLine，它将从数据库中删除
    )
    private List<OrderLine> orderLines = new ArrayList<>();
}

@Entity
@Table(name = "ORDER_LINES")
public class OrderLine {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // 关系的所有者：不配置 cascade
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "order_id", nullable = false)
    private Order order; // 关联回 Order 实体
}
```

### PERSIST

当你在父实体上执行 持久化 (Persist) 操作时，`CascadeType.PERSIST` 会确保这个操作自动传播到所有关联的**新的（瞬态，Transient）**子实体上。

简单来说：

当你调用 `EntityManager.persist(parent)` 或 `parentRepository.save(parent)` 并且 parent 包含新的子实体时，JPA 会自动将这些新的子实体也插入到数据库中，而无需你手动对每个子实体调用 `persist()` 或 `save()`。

> **使用场景**
> 
> `CascadeType.PERSIST` 最常用且最适合 以下场景：
> 
> - 创建实体图时：当您创建一个包含其他新实体的复杂父实体时。
> - 子实体的生命周期起始依赖于父实体
> - 确保原子性：它保证了父实体和所有子实体作为一个整体被保存，避免了遗漏保存子实体导致的数据不一致问题。
{: .prompt-tip }

**实际场景示例**

假设你有以下关联配置：

```java
// 在 Order 实体中
@OneToMany(mappedBy = "order", cascade = CascadeType.PERSIST) 
private List<OrderLine> orderLines;
```

操作流程如下：

```java
Order newOrder = new Order("Laptop Order");
OrderLine line1 = new OrderLine("Dell XPS 13"); // 新建，瞬态
OrderLine line2 = new OrderLine("Mouse");       // 新建，瞬态

newOrder.addOrderLine(line1); // 自动设置双向关联
newOrder.addOrderLine(line2);


orderRepository.save(newOrder); // 或 entityManager.persist(newOrder);
```

由于 `CascadeType.PERSIST`，JPA 会在事务提交时执行以下操作：

- INSERT INTO ORDERS (插入 `newOrder`)
- INSERT INTO ORDER_LINES (插入 `line1`)
- INSERT INTO ORDER_LINES (插入 `line2`)

对应sql如下:

```sql
INSERT INTO ORDERS (id, name, ...) VALUES (DEFAULT, 'Laptop Order', ...) -- 数据库生成并返回一个新的 id（例如：100）这个 ID 被回填到 newOrder 对象中，并且 JPA 内部持久化上下文记录了该 ID
INSERT INTO ORDER_LINES (id, order_id, name, ...) VALUES (DEFAULT, 100, 'Dell XPS 13', ...) -- 语句中使用的 order_id 100 就是上一步插入 Order 时生成的 ID。
INSERT INTO ORDER_LINES (id, order_id, name, ...) VALUES (DEFAULT, 100, 'Mouse', ...)
```

如果没有配置 `CascadeType.PERSIST`，你将不得不手动保存每个订单项，否则 JPA 会抛出异常，告诉你不能在父实体中使用未持久化的子实体。


> PERSIST 只针对处于[**瞬态（Transient）**](#jpahibernate-中实体生命周期最核心的三个状态)状态的实体对象起作用。
> 
> - 瞬态实体： 刚刚通过 `new` 关键字创建，但还没有被持久化上下文管理，也没有 ID。
> - 托管实体（Managed）： 已经从数据库加载，或已经被持久化到数据库中。PERSIST 对这些实体不起作用。
>
> 当你使用 `CascadeType.PERSIST` 时，它就是用来帮你解决一个特定问题：**批量保存**。
>
> 它保证了在保存父对象的同时，所有作为其新关联的子对象也会被自动保存。它严格遵守了 JPA 的设计原则：`persist` 是为新增数据设计的，而 `merge` 是为更新或重新连接数据设计的。
>
> 如果加载了一个在数据库中已有的 `Order`，修改了它的一个 `OrderLine`，然后调用 `orderRepository.save(order)`，PERSIST 这里根据 "PERSIST 只针对处于**瞬态（Transient）**状态的实体" 的原则, 不会导致 `OrderLine` 被更新。要实现更新的级联，需要使用 `CascadeType.MERGE` (或 `CascadeType.ALL`)。
{: .prompt-warning }

### MERGE

MERGE 的设计目标是：将一个分离（Detached）或瞬时（Transient）的实体对象的状态，重新同步回持久化上下文（Persistence Context），并应用到数据库中的对应记录上。

它解决了 “我修改了一个从数据库取出来但现在脱离了 JPA 管理的对象，如何把这些修改持久化回数据库？” 的问题。

**实际场景示例**

假设已经在 Order 的 `@OneToMany` 关系上配置了 `cascade = CascadeType.MERGE`

```java
@OneToMany(
    mappedBy = "order",
    cascade = CascadeType.MERGE // <-- 关键配置
)
private List<OrderLine> orderLines = new ArrayList<>();
```

场景1. 更新已存在的订单的流程

```java
// 事务 A：查询 Order (ID=100) 和它的 OrderLines
Order orderToEdit = orderRepository.findById(100L).get(); // Managed
// ... 事务 A 结束，orderToEdit 变为 Detached

// 在业务层修改 Detached 对象
orderToEdit.setCustomerName("Updated Customer");
OrderLine lineToModify = orderToEdit.getOrderLines().get(0);
lineToModify.setPrice(999.00);

// 事务 B：调用 merge
Order managedOrder = entityManager.merge(orderToEdit);
// 事务 B 提交：JPA 自动生成 UPDATE 语句更新 Order 和 OrderLine 的数据。

```

对应的SQL为

```sql
SELECT * FROM ORDERS WHERE id = 100;
SELECT * FROM ORDER_LINES WHERE order_id = 100;

UPDATE ORDERS SET customerName = 'Updated Customer' WHERE id = 100;
UPDATE ORDER_LINES SET price = 999.00 WHERE id = <lineToModify_ID>;
```

场景2. 在 Detached 集合中添加新的子项

从数据库中取出一个 Detached `Order`，并向其 `orderLines` 集合中添加一个新的 Transient `OrderLine`

当 `merge(detachedOrder)` 时

- JPA 识别到这个新的 `OrderLine` 是 Transient 的。
- `MERGE` 级联会负责将其作为一条新的记录插入到 `ORDER_LINES` 表中(类似于 PERSIST 的行为)

> **`CascadeType.MERGE` 的核心是 “[应用状态](#jpahibernate-中实体生命周期最核心的三个状态)变化”**
> 
> - 分离实体: 重新纳入托管：保存 Detached 对象的修改，将其转为 Managed。
> - 瞬时实体: 插入：如果遇到新的 Transient 关联实体，它会将其持久化。
{: .prompt-tip }

### REMOVE

`CascadeType.REMOVE` 意味着：当您删除父实体时，关联的子实体也会被级联删除

**实际场景示例**

如果您在 `Order` 实体上配置了 `REMOVE` 级联：

```java
@OneToMany(
    mappedBy = "order",
    cascade = CascadeType.REMOVE // <-- 关键配置
)
private List<OrderLine> orderLines = new ArrayList<>();
```

执行以下删除流程

```java
// 事务开始
Order existingOrder = entityManager.find(Order.class, 100L); 
entityManager.remove(existingOrder);
// 事务提交
```

生成的 SQL：

```sql
DELETE FROM ORDER_LINES WHERE order_id = 100; -- 先删子对象记录
DELETE FROM ORDERS WHERE id = 100; -- 后删父对象记录, JPA 必须先删除子实体，以避免外键约束错误
```

> **使用场景**
>
> 只有在子实体的生命周期完全且绝对地依赖于父实体，并且子实体在没有父实体的情况下毫无意义时，才应该使用 `CascadeType.REMOVE`
>
> - **一对一（OneToOne）关系中的从属实体**： 例如，`Person` 实体和其 `PassportDetails` 实体。如果一个人被删除，其护照信息当然也应该被删除
> - **组合关系（Composition）**： 例如，案例中的 Order 和 OrderLine 关系。通常一个订单项离开了它所属的订单就没有了意义
>
> [更好的替代方案：orphanRemoval = true](#orphanremoval)
> 
> 在 `OneToMany` 和 `OneToOne` 关系中，JPA 推荐使用 `orphanRemoval = true` 作为 `CascadeType.REMOVE` 的更精细、更安全的替代方案。
{: .prompt-warning }

> 不推荐使用/应避免的场景
>
> - 子实体可以被其他父实体引用（共享实体）： 如果 `OrderLine` 实体理论上可以被另一个 `Order` 引用（虽然在您的模型中不可能），或如果它是一个共享的目录项。在这种情况下，删除父实体不应导致子实体的删除。
> - 任何可能导致意外数据丢失的场景： `REMOVE` 是一个全有或全无的操作。一旦您删除父实体，所有关联的子实体都会被删除。
{: .prompt-danger }

### REFRESH

配置`CascadeType.REFRESH`后, 当对父实体执行刷新操作时，关联的子实体也会被级联刷新

`refresh()` 操作会强制 JPA 重新从数据库中加载该实体及其所有关联数据，并覆盖该实体在持久化上下文中的当前状态

**为什么需要 REFRESH？**

1. 撤销未提交的本地修改（Undo Changes）
    
    如果在一个事务中修改了一个托管实体，但后来决定不保存这些修改，而是想恢复到数据库中的原始值，您可以使用 `refresh()`。

    - 在一个事务中，查询并修改 `Order` 对象。
    - 对 `Order` 调用 `entityManager.refresh(order)`。
    - JPA 立即执行 `SELECT` 语句，从数据库中读取原始值，并覆盖 `Order` 对象在内存中的所有修改。
    - 如果配置了 `CascadeType.REFRESH`，`OrderLine` 的任何本地修改也会被对应的数据库值覆盖。

2. 同步外部修改（Sync External Changes）
    
    在并发环境中，如果同一个数据库记录被另一个事务修改并提交了，当前的事务中的托管对象可能会“过时”

    虽然 JPA 默认使用隔离级别来处理并发问题，但在某些特定场景下，可能需要明确知道当前数据库的最新状态。

    - 事务 A 查询 `Order`。
    - 事务 B 提交 对同一条 `Order` 记录的修改。
    - 在事务 A 中，调用 `entityManager.refresh(order)`。
    - JPA 从数据库获取事务 B 提交后的最新值，并更新事务 A 中的 `Order` 对象。

**实际场景示例**

假设您在 `Order` 实体上配置了 `cascade = CascadeType.REFRESH`

```java
@OneToMany(
    mappedBy = "order",
    cascade = CascadeType.REFRESH // <-- 关键配置
)
private List<OrderLine> orderLines = new ArrayList<>();
```

```java
// 事务开始
Order order = entityManager.find(Order.class, 100L); // Managed (当前数据库值为 OldName)

// 1. 本地修改 (仅在内存中)
order.setName("Temporary Name");
OrderLine line = order.getOrderLines().get(0);
line.setQuantity(999); // 仅在内存中

// 2. 决定撤销修改，并级联刷新关联的 OrderLine
entityManager.refresh(order); 

// 此时：
// order.getName() 恢复到数据库的 OldName。
// line.getQuantity() 恢复到数据库中的原始值。
// 事务结束，没有 UPDATE/INSERT 语句生成。
```

当调用 `refresh(order)` 时，JPA 会立即执行两条 `SELECT` 语句

```sql
SELECT * FROM ORDERS WHERE id = 100;
SELECT * FROM ORDER_LINES WHERE order_id = 100;
```

> CascadeType.REFRESH 的作用是从数据库同步到内存，它是一种读操作的级联，用于确保实体及其关联的数据状态与数据库中的最新状态保持一致
{: .prompt-tip }

### DETACH

配置 `CascadeType.DETACH` 后：当您将父实体从持久化上下文中分离时，关联的子实体也会被级联分离

**使用场景**

DETACH 级联的使用场景，主要是为了精确控制哪些对象需要停止被持久化上下文监控，通常用于以下情况：

1. 优化和缩小持久化上下文范围

    在长时间运行的事务中，持久化上下文可能会积累大量的托管对象，占用内存。

    在批处理或数据导入过程中，可能需要处理数千个实体。一旦一个实体处理完毕，您不再需要它保持托管状态。
    
    对父实体调用 `detach()` 并级联到子实体，可以安全地将这些对象从持久化上下文中移除，释放内存，并避免后续对它们进行不必要的脏检查，从而提高性能。

2. 将对象转换为只读状态（Read-Only）

    需要在事务内读取数据并在内存中对其进行操作，但不希望这些操作被持久化

    查询了一批数据用于生成报告或进行复杂的计算。计算过程中对对象的修改不应写入数据库, 查询后立即对父实体调用` detach()`，可以确保其及其关联的子实体脱离管理，避免任何意外的数据更新

3. 准备跨事务传输（例如，将对象传递给非 JPA 维护的层）
   
    虽然事务提交或 EntityManager 关闭后所有对象都会自动分离，但有时需要提前在事务结束前明确地分离对象。

    希望在事务中获取数据，并在将其返回给表示层或 REST API 之前立即分离它，以明确表明此对象已脱离数据库同步

**实际场景示例**

假设您在 `Order` 实体上配置了 `cascade = CascadeType.DETACH`

```java
@OneToMany(
    mappedBy = "order",
    cascade = CascadeType.DETACH // <-- 关键配置
)
private List<OrderLine> orderLines = new ArrayList<>();
```

```java
// 事务开始
Order order = entityManager.find(Order.class, 100L); // Managed
OrderLine line = order.getOrderLines().get(0); // Managed

// 执行分离操作
entityManager.detach(order); 

// 此时：
// order 状态变为 Detached
// line 状态也变为 Detached (由于级联)

// 尝试修改 Detached 对象
order.setName("New Name"); // 修改不会被追踪
line.setQuantity(5);      // 子对象的修改也不会被追踪

// 事务提交时，不会生成任何 UPDATE 语句
```

> `CascadeType.DETACH` 的作用是将整个对象图（父实体及其关联子实体）从托管状态批量地、显式地转变为分离状态，从而停止 JPA 的管理和监控
{: .prompt-tip }

### OrphanRemoval

`orphanRemoval` 字面意思是“孤儿移除”

- **配置位置**： 只能在关系的非所有者端（通常是父实体端，如 @OneToMany 和 @OneToOne 的映射）进行配置。
- **核心作用**： 当一个子实体对象（Child Entity）从其父实体（Parent Entity）的关联集合（例如 List 或 Set）中移除后，它会被视为一个“孤儿”并自动从数据库中删除。

**实际场景示例**

如果您在 `Order` 实体上配置 `orphanRemoval = true`：

```java
@OneToMany(
    mappedBy = "order",
    orphanRemoval = true // <-- 关键配置
)
private List<OrderLine> orderLines = new ArrayList<>();
```
触发删除的场景：


```java
Order existingOrder = entityManager.find(Order.class, 100L);
OrderLine lineToRemove = existingOrder.getOrderLines().get(0);

// 这一行代码标记 lineToRemove 为“孤儿”, 这里是操作的Java对象, orphanRemoval会将这个集合的变更同步到数据库
existingOrder.getOrderLines().remove(lineToRemove);
// 事务提交时，JPA 会自动生成 DELETE 语句删除 lineToRemove

// 删除父实体 (与 REMOVE 相同)
Order existingOrder = entityManager.find(Order.class, 100L);
entityManager.remove(existingOrder);
// 事务提交时，所有关联的 OrderLine 都会被删除
```

> `orphanRemoval`和直接调用子类的`remove()`的区别
>
> 在上面的例子中,分别使用: 
> 
> - `existingOrder.getOrderLines().remove(lineToRemove);`
> - `entityManager.remove(lineToRemove);` 
> 
> 这两种操作最终对数据库的影响（即删除 OrderLine 记录）是相同的，但它们的机制和使用前提是不同的。
>
> - **orphanRemoval的机制**: 从 托管（Managed） 父实体 (`existingOrder`) 的关联集合中移除了一个子实体 (`lineToRemove`), JPA 的持久化上下文检测到这个子实体不再被任何父实体引用，将其标记为“孤儿”在事务提交时，JPA 会自动生成 `DELETE FROM ORDER_LINES WHERE id = <lineToRemove ID>`, 这种方式是 **声明式** 的。操作的是 Java 集合，JPA 负责将这种关系变化同步到数据库
> - **直接操作生命周期**: 直接告诉 EntityManager ：“请将这个实体 (`lineToRemove`) 从数据库中移除。” `lineToRemove` 对象的状态立即变为 `Removed`, 在事务提交时，JPA 会生成 `DELETE FROM ORDER_LINES WHERE id = <lineToRemove ID>`, 这种方式是 **命令式** 的。
>   
>   直接告诉 JPA 要对这个对象进行删除操作, 但是这种操作需要确保手动或通过辅助方法将 `lineToRemove.order` 设为 `null` (解除关系所有者端引用)，否则可能会导致数据库外键约束冲突或意外行为。这略微绕过了建立的集合关系。理论上可能会导致集合状态与数据库状态不一致
{: .prompt-warning }


**为什么说 `orphanRemoval` 它是 `CascadeType.REMOVE` 的更优替代?**

| 特性                 | `CascadeType.REMOVE`                                     | `orphanRemoval = true`                       | 优势原因                                                          |
| :------------------- | :------------------------------------------------------- | :------------------------------------------- | :---------------------------------------------------------------- |
| 删除父实体时         | 会级联删除子实体。                                       | 会级联删除子实体。                           | 相同                                                              |
| 从集合中移除子实体时 | 不会自动删除。子实体只是“断开”了关系，但仍存在于数据库。 | 会自动删除（视为孤儿）。                     | 更符合业务逻辑： 订单项不再属于订单，就应该被移除。               |
| 目的语义             | 传播 `remove()` 操作。                                   | 保证子实体的生命周期严格绑定到父实体。       | 更清晰的意图： 强制实施“子实体不能独立存在”的组合关系。           |
| 意外删除风险         | 相对较高。                                               | 相对较低，删除只发生在托管实例的集合操作中。 | 更安全： 防止分离对象（Detached）的误操作，只作用于被管理的集合。 |

> `orphanRemoval`优势：
> 
> - 语义更清晰： `orphanRemoval = true` 明确地告诉 JPA：“如果这个子实体从父实体关联的集合中移除，它就是无主孤儿，必须被清除。” 这正是许多强组合关系（如订单/订单项）所需的生命周期管理。
> - 操作更精细： 它可以处理在应用程序中将子实体从集合中移除这一常见的业务操作。使用 REMOVE，您在从集合中移除后，必须手动调用 `entityManager.remove(lineToRemove)`，否则数据库中会残留这条记录。`orphanRemoval` 避免了这种手动操作的遗漏。
> 
> 因此，对于强生命周期依赖的 `OneToMany` 关系，最佳实践是使用 `orphanRemoval = true` 来管理删除行为，而不是单独使用 `CascadeType.REMOVE`。
{: .prompt-tip }

## JPA 级联实现原理

JPA 中的级联（Cascading）功能并非通过 SQL 语句的级联操作（如数据库外键约束的 `ON DELETE CASCADE`）实现的，而是完全由 **JPA 运行时环境（如 Hibernate 或 EclipseLink）** 在 内存和持久化上下文 中进行管理和控制的。


下面是 JPA 级联功能实现的核心步骤和机制：

### 内存中的对象图遍历

级联功能的起点是操作一个**托管（Managed）**实体。

- **配置读取**： 当您对一个实体执行操作（例如 `entityManager.persist(order)`）时，JPA 提供者会检查该实体类定义中的所有关联字段（如 `@OneToMany`, `@ManyToOne`）上是否配置了 `cascade` 属性。
- **递归遍历**： 如果发现 `cascade` 属性包含当前操作类型（例如 `PERSIST`），JPA 提供者会递归地遍历整个关联的对象图，从父实体开始，一直向下查找所有配置了相应级联的子实体。

### 持久化上下文的状态管理
   
持久化上下文（Persistence Context）是实现级联的核心，它是一个内存缓存，负责跟踪托管实体的状态。

#### 状态转换

在遍历过程中，JPA 提供者会根据级联类型，将关联子实体从一个状态转换到另一个状态：

- `PERSIST`： 如果子实体是 **Transient**，JPA 会对其调用内部的 `persist()` 逻辑，将其转为 **Managed** 状态，并将其添加到持久化上下文中。
- `MERGE`： JPA 会查找或加载子实体的托管实例，然后将 Detached 子实体的新状态复制到托管实例上。
- `REMOVE`： JPA 会对子实体调用内部的 `remove()` 逻辑，将其标记为 **Removed** 状态。

#### 脏检查

对于 `MERGE` 操作，JPA 会将合并后的子实体纳入脏检查的范围。

脏检查是 Hibernate（或任何 JPA 实现）的一项强大功能，它允许在不调用显式 update() 方法的情况下自动更新数据库。它主要通过以下机制实现:

1. 快照机制 (The Snapshot Mechanism)
    
    当一个实体对象被 `EntityManager.find()` 或 `EntityManager.persist()` 首次加载或纳入持久化上下文时，JPA 提供者会在内存中创建一个该**对象原始状态的快照（Snapshot）**。

2. 事务同步时的比较（The Comparison at Flush Time）
    
    当事务即将提交（Flush 阶段）时，JPA 提供者会启动脏检查流程

    1. **遍历**： JPA 遍历持久化上下文中所有当前的 Managed 实体。
    2. **比较**: 对于每一个 Managed 实体，JPA 逐一比较它的当前内存状态和存储的快照状态。
    3. **识别脏实体**： 如果某个实体的任何属性与快照中的对应属性不一致，则该实体被标记为“脏”（Dirty）。
   
3. 生成和执行 `UPDATE` SQL
    
    **对于所有被标记为“脏”的实体**: JPA 提供者会根据差异，动态地生成必要的 `UPDATE` SQL 语句，只更新实际发生改变的字段。然后，这些 `UPDATE` 语句会在事务提交之前被执行到数据库中

> **如何检测子对象的属性变化?**
> 
> 在级联更新 (MERGE) 中，子对象的属性变化检测遵循同样的原理：
> 
> - 级联传播： 当对父实体执行 `MERGE` 时，如果配置了 `CascadeType.MERGE`，JPA 会将 `MERGE` 操作传播给所有关联的子实体。
> - 子对象托管化： 确保所有关联的对象也进入 **Managed** 状态，并对它们创建快照（如果之前没有）。
> - 独立脏检查： 在 Flush 阶段，JPA 分别对父实体和所有子实体执行脏检查。
> - 生成 SQL： 如果对象的属性发生变化，JPA 就会为该对象独立生成一个 `UPDATE` SQL 语句。
{: .prompt-info }

### 在事务同步时生成 SQL

级联操作本身通常不会立即触发数据库操作。实际的 SQL 语句生成和执行，发生在 **事务同步（Flush）** 阶段。

**Flush 时机**： 当事务提交时，或在执行某些查询操作之前，JPA 会执行 Flush 操作，将内存中的状态变化同步到数据库。

**SQL 生成**：

- JPA 收集所有被标记为 **Managed**（需要 `INSERT` 或 `UPDATE`）或 **Removed**（需要 `DELETE`）的实体。
- 对于级联操作产生的状态变化，JPA 会根据事务的顺序性和外键约束要求，智能地调整 SQL 语句的生成顺序。例如，`PERSIST` 级联通常会先插入父实体以获取 ID，再插入子实体；`REMOVE` 级联必须先删除子实体，再删除父实体，以避免外键约束错误。
- `orphanRemoval` 也是在 `Flush` 阶段，JPA 发现某个子实体对象虽然没有被显式 `remove()`，但已从父实体的集合中移除，便自动生成其 `DELETE` 语句。 

> JPA 级联功能的实现，是基于面向对象的方法，而不是依赖数据库的级联约束。
> 
> - 内存管理： 通过在内存中遍历对象图。
> - 状态控制： 通过持久化上下文对实体状态（`Transient`, `Managed`, `Removed`, `Detached`）进行精确转换。
> - 同步机制： 在事务提交或 Flush 阶段，将这些内存中的状态变化转化为有序的 SQL 语句。
> 
> 这种方式的优势在于：它与具体的数据库类型无关，并允许开发者在应用层对实体的生命周期进行细粒度的控制。
{: .prompt-info }

# 参考

- [JPA的CascadeType的解释](https://www.jianshu.com/p/ae07c9f147bc)
- [jpa级联(Cascade)操作](https://segmentfault.com/a/1190000021752690)
- [Jpa/Hibernate之级联保存的坑](https://codeantenna.com/a/u4RwgJ5cot)