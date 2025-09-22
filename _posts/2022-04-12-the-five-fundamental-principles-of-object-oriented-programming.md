---
layout: post
title: 面向对象 (OOP) 的五个基本原则
date: 2022-04-12 20:17 +0800
categories: [Software Development] 
tags: [Architecture Design,OOP]
--- 

在程序设计领域， **SOLID**（单一功能、开闭原则、里氏替换、接口隔离以及依赖反转）是由罗伯特·C·马丁在21世纪早期其著作《敏捷软件开发：原则、模式与实践》（Agile Software Development: Principles, Patterns, and Practices）中引入的记忆术首字母缩略字，指代了面向对象编程和面向对象设计的五个基本原则

SOLID 原则旨在解决软件开发中常见的几个核心问题：

- **代码脆弱性**：当系统中的一个微小改动引发了连锁反应，导致其他不相关部分的代码崩溃时，我们称之为“脆弱性”。SOLID 原则通过解耦和单一职责来减少这种脆弱性。
- **维护成本高**：缺乏良好设计的代码往往难以理解、难以修改。SOLID 原则通过提高内聚性和降低耦合度，使得代码更易于维护和迭代。
- **可扩展性差**：当业务需求发生变化时，如果现有代码无法轻松地进行扩展，而必须进行大规模的修改，则说明系统的可扩展性差。开放封闭原则直接解决了这个问题，鼓励我们在不修改现有代码的情况下添加新功能。
- **复用性低**：当模块之间高度耦合时，一个模块很难被单独提取出来在其他项目中复用。SOLID 原则通过抽象和解耦，使得模块更加独立，从而提高了代码的复用性。
- **设计复杂性**：当一个类承担了太多职责，或者一个接口过于庞大时，会导致设计变得复杂且难以管理。单一职责原则和接口隔离原则通过鼓励更小、更专注的设计来解决这个问题。

## 单一职责原则（Single-Resposibility Principle）

> 一个类，最好只做一件事，只有一个引起它的变化。单一职责原则可以看做是低耦合、高内聚在面向对象原则上的引申，将职责定义为引起变化的原因，以提高内聚性来减少引起变化的原因。

如果一个类承担了多项职责，那么其中一项职责的变更可能会影响到其他不相关的职责，相互之间就产生影响，从而大大损伤其内聚性和耦合度。

通常意义下的单一职责，就是指只有一种单一功能，不要为类实现过多的功能点，以保证实体只有一个引起它变化的原因。

**案例:**

反例：一个用户管理类做了太多事:

```java
// 反例：一个违反SRP的User类
class User {
    private String name;
    private String email;

    // 职责1: 管理用户数据
    public User(String name, String email) {
        this.name = name;
        this.email = email;
    }

    public void saveToDatabase() {
        // 职责2: 处理数据库持久化
        System.out.println("Saving user to database: " + this.name);
    }

    public void sendEmail(String message) {
        // 职责3: 处理邮件发送
        System.out.println("Sending email to " + this.email + ": " + message);
    }
}
```

这个 `User` 类包含了三个不同的职责：管理用户属性、持久化到数据库、以及发送邮件。如果数据库逻辑改变，或者邮件发送服务需要更新，`User` 类都必须被修改。这违反了SRP。

正例：将职责分离到不同的类

```java
// 正例：遵循SRP的类
class User {
    private String name;
    private String email;

    // 只负责管理用户数据
    public User(String name, String email) {
        this.name = name;
        this.email = email;
    }
    // ... 其他与用户数据相关的getter/setter方法
}

class UserPersistence {
    // 只负责用户持久化
    public void save(User user) {
        System.out.println("Saving user to database: " + user.getName());
    }
}

class EmailService {
    // 只负责邮件发送
    public void sendEmail(String email, String message) {
        System.out.println("Sending email to " + email + ": " + message);
    }
}
```
现在，每个类都只专注于一个职责。如果数据库逻辑需要修改，我们只需更改 `UserPersistence` 类；如果邮件服务改变，我们只需修改 `EmailService`。这使得代码更易于维护。

## 开放封闭原则（Open-Closed principle）

> 软件实体应该是可扩展的，而不可修改的。也就是，对扩展开放，对修改封闭的。开放封闭原则主要体现在两个方面:

1. 对扩展开放，意味着有新的需求或变化时，可以对现有代码进行扩展，以适应新的情况。
2. 对修改封闭，意味着类一旦设计完成，就可以独立完成其工作，而不要对其进行任何尝试的修改。

实现开开放封闭原则的核心思想就是对抽象编程，而不对具体编程，因为抽象相对稳定。让类依赖于固定的抽象，所以修改就是封闭的；

而通过面向对象的继承和多态机制，又可以实现对抽象类的继承，通过覆写其方法来改变固有行为，实现新的拓展方法，所以就是开放的。

当需求变更时，你应该通过添加新的代码（扩展）来实现，而不是去修改已有的、经过测试的代码。这能让你的系统更稳定、更健壮。

> “需求总是变化”没有不变的软件，所以就需要用封闭开放原则来封闭变化满足需求，同时还能保持软件内部的封装体系稳定，不被需求的变化影响。
{: .prompt-tip }

**案例:**

反例：一个计算器类，每次新增操作都需要修改

```java
// 反例：违反OCP的计算器
class Calculator {
    public double calculate(char operation, double a, double b) {
        if (operation == '+') {
            return a + b;
        } else if (operation == '-') {
            return a - b;
        } else if (operation == '*') {
            return a * b;
        }
        // 如果要增加除法，就需要修改这个方法
        return 0;
    }
}
```

如果我们需要增加“除法”功能，就必须修改 `calculate` 方法，增加一个新的 `else if` 分支。这违反了对修改封闭的原则。

正例：通过接口和多态实现

```java
// 正例：遵循OCP的计算器
interface Operation {
    double apply(double a, double b);
}

class Addition implements Operation {
    public double apply(double a, double b) {
        return a + b;
    }
}

class Subtraction implements Operation {
    public double apply(double a, double b) {
        return a - b;
    }
}

class NewCalculator {
    public double calculate(Operation operation, double a, double b) {
        return operation.apply(a, b);
    }
}

// 增加新操作时，只需新增类，而不需要修改NewCalculator
class Division implements Operation {
    public double apply(double a, double b) {
        if (b == 0) throw new IllegalArgumentException("Cannot divide by zero.");
        return a / b;
    }
}
```

现在，`NewCalculator` 类对修改是封闭的。如果我们要增加“除法”功能，只需创建一个新的 `Division` 类来实现 `Operation` 接口，`NewCalculator` 的代码不需要做任何改动。这正是对扩展开放的体现。

## 里氏替换原则（Liskov-Substituion Principle）

> **子类必须能够替换其基类**。这一思想体现为对继承机制的约束规范，LSP 强调了继承的正确性，确保了多态的实现不会破坏程序的正确性。

在父类和子类的具体行为中，必须严格把握继承层次中的关系和特征，将基类替换为子类，程序的行为不会发生任何变化。

> 同时，这一约束反过来则是不成立的，子类可以替换基类，但是基类不一定能替换子类。
{: .prompt-info }

> 里氏替换的具体使用和实现原理可参考[Java 中的多态能力](/posts/polymorphism-in-java/#java-中的子类型多态)
{: .prompt-tip }

**案例:**

反例：正方形继承长方形

```java
// 反例：违反LSP的继承
class Rectangle {
    protected double width;
    protected double height;

    public void setWidth(double width) { this.width = width; }
    public void setHeight(double height) { this.height = height; }
}

class Square extends Rectangle {
    // 正方形的边长必须相等
    public void setWidth(double width) {
        this.width = width;
        this.height = width;
    }
    public void setHeight(double height) {
        this.height = height;
        this.width = height;
    }
}
```

这个设计违反了LSP。考虑一个使用 `Rectangle` 的方法：

```java
public void test(Rectangle r) {
    r.setWidth(5);
    r.setHeight(4);
    // 期望：面积是 20
    System.out.println("Expected area: " + (5 * 4));
    System.out.println("Actual area: " + (r.width * r.height));
}
```

当传入 `Rectangle` 对象时，结果是 `20`。但如果传入` Square` 对象，`setWidth(5)` 会将 `height` 也设置为 `5`，`setHeight(4)` 会将 `width` 也设置为 `4`，最终面积是 `16`，而不是预期的 `20`。子类替换父类后，程序的行为发生了改变，导致了不期望的结果。

正例：不使用继承，使用独立的类

更合理的设计是让 `Square` 和 `Rectangle` 两个类互不继承，或者都继承自一个更通用的 `Shape` 接口。

```java
// 正例：遵循LSP
interface Shape {
    double getArea();
}

class Rectangle implements Shape {
    // ...
}

class Square implements Shape {
    // ...
}
```

## 接口隔离原则（Interface-Segregation Principle）

> 使用多个小的专门的接口，而不要使用一个大的总接口。

具体而言，接口隔离原则体现在：接口应该是内聚的，应该避免"胖接口"。一个类对另外一个类的依赖应该建立在**最小的接口**上, 这鼓励我们创建更小、更具体的接口，这样可以避免一个类因为实现了它不需要的方法而承担多余的职责，实现类实现了胖接口中过多不需要的方法和属性, 这是一种接口污染。

接口有效地将细节和抽象隔离，体现了对抽象编程的一切好处，接口隔离强调接口的单一性。而胖接口存在明显的弊端，会导致实现的类型必须完全实现接口的所有方法、属性等；

而某些时候，实现类型并非需要所有的接口定义，在设计上这是“浪费”，而且在实施上这会带来潜在的问题，对胖接口的修改将导致一连串的客户端程序需要修改，有时候这是一种灾难。在这种情况下，将胖接口分解为多个特点的定制化方法，使得客户端仅仅依赖于它们的实际调用的方法，从而解除了客户端不会依赖于它们不用的方法。

分离的手段主要有以下两种：
1. 委托分离，通过增加一个新的类型来委托客户的请求，隔离客户和接口的直接依赖，但是会增加系统的开销。
2. 多重继承分离，通过接口多继承来实现客户的需求，这种方式是较好的。

**案例:**

反例：一个庞大的设备接口

```java
// 反例：违反ISP的“胖接口”
interface MultiFunctionDevice {
    void print();
    void scan();
    void fax();
}

class SimplePrinter implements MultiFunctionDevice {
    public void print() {
        System.out.println("Printing...");
    }
    public void scan() {
        // 这个简单的打印机不支持扫描，被迫实现一个空方法或抛出异常
        throw new UnsupportedOperationException("Scanning not supported.");
    }
    public void fax() {
        // 这个简单的打印机不支持传真，被迫实现一个空方法或抛出异常
        throw new UnsupportedOperationException("Faxing not supported.");
    }
}
```

`MultiFunctionDevice` 接口过于庞大，迫使 `SimplePrinter` 实现了它根本不需要的方法。这违反了ISP。

正例：将接口拆分为更小的部分

```java
// 正例：遵循ISP
interface Printer {
    void print();
}

interface Scanner {
    void scan();
}

interface FaxMachine {
    void fax();
}

// 简单的打印机只实现它需要的接口
class SimplePrinter implements Printer {
    public void print() {
        System.out.println("Printing...");
    }
}

// 多功能一体机实现所有接口
class AllInOnePrinter implements Printer, Scanner, FaxMachine {
    public void print() {
        System.out.println("Printing...");
    }
    public void scan() {
        System.out.println("Scanning...");
    }
    public void fax() {
        System.out.println("Faxing...");
    }
}
```

现在，客户端（使用这些类的代码）可以根据自己的需求，只依赖于它需要的接口。`SimplePrinter` 只依赖 `Printer` 接口，从而避免了不必要的依赖。

## 依赖倒置原则（Dependecy-Inversion Principle）

> 高层模块不应该依赖于低层模块，它们都应该依赖于抽象。抽象不应该依赖于细节，细节应该依赖于抽象
    
我们知道，依赖一定会存在于类与类、模块与模块之间。当两个模块之间存在紧密的耦合关系时，最好的方法就是分离接口和实现：在依赖之间定义一个抽象的接口使得高层模块调用接口，而底层模块实现接口的定义，以此来有效控制耦合关系，达到依赖于抽象的设计目标。

抽象的稳定性决定了系统的稳定性，因为抽象是不变的，依赖于抽象是面向对象设计的精髓，也是依赖倒置原则的核心。
    
依赖于抽象是一个通用的原则，而某些时候依赖于细节则是在所难免的，必须权衡在抽象和具体之间的取舍，方法不是一层不变的。依赖于抽象，就是对接口编程，不要对实现编程。

**案例:**

反例：高层模块直接依赖低层模块

```java
// 反例：违反DIP
class MySqlDatabase {
    public void save(String data) {
        System.out.println("Saving " + data + " to MySQL.");
    }
}

class ShoppingCart {
    private MySqlDatabase database;

    public ShoppingCart() {
        this.database = new MySqlDatabase(); // 直接依赖具体实现
    }

    public void checkout(String data) {
        database.save(data);
    }
}
```

`ShoppingCart` 是高层模块（业务逻辑），它直接依赖于 `MySqlDatabase` 这个低层模块（具体实现）。如果将来要换成其他数据库（例如 MongoDB），`ShoppingCart` 的代码就必须被修改，这使得系统缺乏灵活性。

正例：依赖抽象而不是具体实现

```java
// 正例：遵循DIP
interface Database {
    void save(String data);
}

class MySqlDatabase implements Database {
    public void save(String data) {
        System.out.println("Saving " + data + " to MySQL.");
    }
}

class MongoDatabase implements Database {
    public void save(String data) {
        System.out.println("Saving " + data + " to MongoDB.");
    }
}

class ShoppingCart {
    private Database database; // 依赖抽象接口

    // 通过构造函数进行依赖注入
    public ShoppingCart(Database database) {
        this.database = database;
    }

    public void checkout(String data) {
        database.save(data);
    }
}
```

现在，`ShoppingCart` 只依赖于 `Database` 这个抽象接口。在创建 `ShoppingCart` 实例时，我们可以通过依赖注入（如构造函数注入）来传入任何实现了 Database 接口的对象。这使得高层模块和低层模块之间完全解耦，你可以轻松地在 MySqlDatabase 和 MongoDatabase 之间切换，而无需改动 `ShoppingCart` 的代码。

## 权衡与取舍

在实际开发中，SOLID原则并非教条，而是一套指导我们设计高内聚、低耦合软件的权衡准则。答案很明确：你不需要将它们执行到最极致，过度设计和“YAGNI”（You Ain't Gonna Need It，你不会需要它）原则同样重要。

过度应用SOLID原则会带来新的问题，例如：

- **代码爆炸**：为了实现单一职责，你可能会创建大量的、只包含一两个方法的类。这导致项目文件数量急剧增加，难以导航和理解。
- **复杂性增加**：为了遵循DIP，你可能会引入过多的抽象（接口、抽象类），导致代码结构过于复杂，反而降低了可读性和可维护性。简单的功能被拆分成多个文件，追踪业务逻辑变得困难。
- **开发效率降低**：前期花费大量时间进行“完美”的设计，可能会拖慢开发进度，尤其是在需求变化频繁的敏捷开发环境中。

那么，在实际中，应该如何应用这些原则呢？

**单一职责原则**: 

- **适度原则**：一个类应该只有一个**变更原因**。这个“原因”的粒度是关键。如果一个类既负责业务逻辑，又负责数据持久化，那么它就违反了SRP。但如果一个类包含了多个`getter`/`setter`方法，这通常是可以接受的，因为它们都服务于一个核心职责——管理数据。
- **何时拆分**：当一个类的方法开始变得越来越多，并且其中一些方法属于不同的“概念”时，就是考虑拆分的好时机。一个很好的信号是，你发现自己正在为这个类写一个很长的注释，解释它为什么做了这么多不同的事情。

**开放封闭原则**: 

- **适度原则**：OCP不意味着你永远不能修改旧代码。它主要针对那些频繁变动且可能影响其他模块的核心业务逻辑。对于稳定的、不太可能改变的代码，你不需要为了遵守OCP而引入不必要的抽象。
- **何时应用**：当你的代码中出现大量的`if/else if/else`或`switch/case`语句，并且你预见到未来会新增更多分支时，这就是一个使用OCP（通过策略模式、工厂模式等）来重构的好机会。

**里氏替换原则**: 

- **适度原则**：LSP更多的是一个对**继承关系进行约束**的原则。它提醒我们在使用继承时要谨慎，确保子类行为的合法性。
- **何时应用**：在设计继承体系时，始终问自己一个问题：“子类替换父类后，程序的功能和预期行为是否会改变？”如果答案是“是”，那么你的继承设计就可能存在问题，需要考虑使用组合（Composition）或委托（Delegation）来替代继承。

**接口隔离原则**: 

- **适度原则**：不要为了拆分而拆分。如果一个接口的实现者只有一个，或者所有实现者都需要使用这个接口的所有方法，那么就没有必要将它拆分成多个小接口。
- **何时应用**：当一个接口变得庞大，且一些类只需要使用其中一部分方法时，就应该考虑将接口拆分。ISP的实践可以有效防止客户端被迫依赖它们不需要的功能，减少不必要的耦合。

**依赖倒置原则**: 

- **适度原则**：DIP的关键是**依赖抽象**。但并非所有依赖都需要抽象。如果你的代码依赖于一个稳定且广为人知的库（如Java的`List`），你通常不需要为它创建一个接口。
- **何时应用**：当你依赖的模块是一个**经常变动**的实现（如一个具体的数据库连接、一个第三方API客户端），或者你需要进行单元测试（测试时可以注入一个模拟对象），DIP就变得至关重要。

SOLID原则是**平衡的艺术**。它们是**经验的结晶**，而不是必须遵守的铁律。在实际开发中，你需要：

- **从简单开始**：先实现功能，如果发现代码变得难以维护或扩展，再考虑使用SOLID原则进行重构。
- **考虑项目的规模和阶段**：在一个小型或短期项目中，过度设计可能会浪费时间；而在一个长期维护的大型项目中，遵循SOLID原则能让你受益匪浅。
- **团队共识**：确保你的团队对这些原则有共同的理解，并能一起讨论何时应用、何时简化。

好的设计是**演化**出来的，而不是一开始就完美无缺的。 SOLID原则为这个演化过程提供了清晰的方向。

# 参考
- [面向对象设计的五个基本原则](https://blog.csdn.net/rankun1/article/details/50789571)