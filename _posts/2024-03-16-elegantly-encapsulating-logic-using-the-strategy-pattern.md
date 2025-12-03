---
layout: post
title: 如何优雅地使用策略模式封装逻辑
date: 2024-03-16 12:58 +0800
categories: [Software Development]
tags: [Architecture Design, 设计模式]
---

## 什么是策略模式？

### 模式概述
俗话说：条条大路通罗马。在很多情况下，实现某个目标的途径不止一条，例如我们在外出旅游时可以选择多种不同的出行方式，如骑自行车、坐汽车、坐火车或者坐飞机。

这就是变化的地方，可根据实际情况（距离、预算、时间、舒适度等）来选择一种出行方式。

在软件开发中，也常会遇到类似的情况，实现某一个功能有多种算法，此时就可以使用一种设计模式来实现灵活地选择解决途径，也能够方便地增加新的解决途径。

下面介绍一种为了适应算法灵活性而产生的设计模式——策略模式。

### 模式定义
策略模式的主要目的是将算法的定义与使用分开，也就是将算法的行为和环境分开。

将算法的定义放在专门的策略类中，每一个策略类封装了一种实现算法，使用算法的环境类针对抽象策略类进行编程，符合依赖倒转原则。在出现新的算法时，只需要增加一个新的实现了抽象策略类的具体策略类即可。

策略模式定义如下：

> 策略模式(Strategy Pattern)：定义一系列算法类，将每一个算法封装起来，并让它们可以**相互替换**，策略模式让算法独立于使用它的客户而变化，也称为政策模式(Policy)。策略模式是一种对象行为型模式。
{: .prompt-info }

### 特点分析
**主要优点**

- 符合开闭原则，可以在不修改原有系统的基础上选择算法或行为，也可以灵活地增加新的算法或行为
- 将算法的定义和使用分离开来，符合单一职责原则，可最大程度地复用算法
- 算法的实现与使用相互分离，使得算法的变化不会影响客户端代码。

**主要缺点**

系统可能会产生很多具体策略类, 导致类爆炸

### 模式结构

策略模式结构并不复杂，但我们需要理解其中环境类Context的作用，其结构如下图所示：

在策略模式结构图中包含如下三个角色：

![策略模式结构图](https://cdn.jsdelivr.net/gh/Optimus-Xs/Blog-Images/2024-03-16-elegantly-encapsulating-logic-using-the-strategy-pattern%2Fstrategy-pattern-structure.png)

- `Context`（环境类）：环境类是使用算法的角色，它在解决某个问题（即实现某个方法）时可以采用多种策略。在环境类中维持一个对抽象策略类的引用实例，用于定义所采用的策略,,以便随时可以切换当前的策略。
- `Strategy`（抽象策略类）：它为所支持的算法声明了公共的抽象方法，是所有策略类的父类，它可以是抽象类或具体类，也可以是接口。环境类通过抽象策略类中声明的方法在运行时调用具体策略类中实现的算法。
- `ConcreteStrategy`（具体策略类）：它实现了在抽象策略类中声明的算法，在运行时，具体策略类将覆盖在环境类中定义的抽象策略类对象，使用一种具体的算法实现某个业务处理。

## 策略模式的使用场景
只要你发现代码中存在**为了完成同一目标，但有多种可替换的方法（算法）**的情况，并且希望在这些方法之间进行灵活、动态地切换，同时隔离变化，就可以考虑使用策略模式

### 针对同一问题有多种解决方案/算法时
这是策略模式最经典、最主要的应用场景。当你需要根据不同条件选择不同的处理方式，但这些方式（算法）的**目标是相同**的时，可以使用策略模式。

场景举例：

- **电商折扣计算**： 对同一件商品，可能有“新人优惠”、“满减折扣”、“会员特价”、“无折扣”等多种计算价格的策略。
- **文件解析**： 针对不同格式（如 `.xml`、`.json`、`.csv`）的文件，需要不同的解析算法，但最终目标都是提取数据。
- **排序算法**： 同一个数据集，可能需要使用“快速排序”、“冒泡排序”、“归并排序”等多种算法，但最终目标都是将数据排序。

### 需要消除大量的 `if/else` 或 `switch` 语句时
当你的代码中出现非常多的条件分支，用于根据不同的输入执行不同的操作时，这通常意味着“违反开放-封闭原则”（对修改关闭，对扩展开放）。策略模式可以很好地解决这个问题。

**优点**： 将每个分支操作封装到一个独立的策略类中，使得添加新的操作（策略）只需要创建新的类，而无需修改原有代码。

### 需要在运行时（Runtime）决定使用哪种算法时
如果算法的选择不是固定的，而是依赖于应用程序的状态、用户的输入或外部配置，策略模式允许你在程序执行过程中动态地切换算法。

场景举例：

- **数据导出**： 用户选择将数据导出为 PDF、Excel 还是纯文本格式。
- **路由选择**： 在网络系统中，根据网络拥堵情况动态选择不同的传输路由算法。

### 算法的变化独立于使用它的客户端时
如果你预期某种算法会频繁变化或扩展，而你希望使用该算法的客户端代码（上下文 Context）保持稳定，策略模式是理想的选择。

**策略模式的核心优势**： 它将算法的实现细节与算法的使用隔离开来。客户端只与抽象的策略接口打交道，不知道具体策略类的存在。

### 不希望客户端知道复杂的算法细节时
将复杂的算法逻辑封装在独立的策略类中，客户端只需要知道如何调用策略接口即可，有助于简化客户端代码和提高封装性。

## 案例分析
下面将介绍如何使用策略模式来解决一个实际问题。

假设我们正在编写一个电商网站的订单系统，并需要根据不同的支付方式计算订单的总价。目前我们支持两种支付方式：在线支付和货到付款。在线支付的情况下相比货到付款会有一个额外的优惠

### 定义接口
首先，我们需要定义一个`Payment`接口，其中包含计算订单总价的方法：

```java
public interface Payment {
    double calculate(double price);
}
```

### 实现具体策略
然后，我们可以实现具体的支付策略，例如`OnlinePayment`和`CashOnDelivery`：

```java
public class OnlinePayment implements Payment {
    public double calculate(double price) {
        return price * 0.95;
    }
}

public class CashOnDelivery implements Payment {
    public double calculate(double price) {
        return price;
    }
}
```

### 在Context中使用策略
最后，我们可以在`Order`类中使用`Payment`接口，并在运行时动态地选择具体的支付策略：

```java
public class Order {
    private Payment payment;

    public Order(Payment payment) {
        this.payment = payment;
    }

    public void setPayment(Payment payment) {
        this.payment = payment;
    }

    public double calculateTotalPrice(double price) {
        return payment.calculate(price);
    }
}
```

### 测试使用
现在，我们可以编写一个简单的测试程序来测试我们的代码：

```java
public static void main(String[] args) {
    Order order = new Order(new OnlinePayment());

    double totalPrice = order.calculateTotalPrice(100.0);
    System.out.println("Total price (online payment): " + totalPrice);

    order.setPayment(new CashOnDelivery());
    totalPrice = order.calculateTotalPrice(100.0);
    System.out.println("Total price (cash on delivery): " + totalPrice);
}
```

在上面的案例中，我们首先创建了一个`OnlinePayment`对象，并使用它来计算订单的总价。然后，我们将支付策略更改为`CashOnDelivery`，并再次计算订单的总价。

# 参考
- [策略模式(Strategy Pattern)——算法的封装与切换](https://www.cnblogs.com/bytesfly/p/strategy-pattern.html)
- [如何优雅地使用策略模式来实现更灵活、可扩展和易于维护的代码？](https://cloud.tencent.com/developer/article/2293959)