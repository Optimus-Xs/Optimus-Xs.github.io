---
layout: post
title: Java 中的多态能力
date: 2022-03-04 23:10 +0800
categories: [Software Development] 
tags: [Java, OOP]
--- 

# 什么是多态
多态是面向对象编程（OOP）的三要素之一, 因外两个是封装和继承。
- 封装是将数据和操作数据的方法绑定在一起，隐藏内部实现细节；
- 继承允许一个类继承另一个类的属性和方法，实现代码重用；
- **多态**则允许不同类的对象对同一方法调用做出不同的响应，增强了代码的灵活性和扩展性。

## 多态的最常见主要类别:

- 特设多态：为个体的特定类型的任意集合定义一个共同接口。只针对特定、不连续的类型集合才能生效的多态形式。它没有一个统一的、抽象的规则。
  > 方法重载（Overloading）： 这是最典型的特设多态。例如，一个 print 函数可以被重载为 print(int i) 和 print(string s)。这两种 print 方法处理的类型（int 和 string）之间没有继承关系，它们只是恰好共享同一个名字，但各自的实现是独立的。
    
- 参数多态：指定一个或多个类型不靠名字而是靠可以标识任何类型的抽象符号。一般指一个函数或数据结构可以处理任意类型的数据，而不需要为每种类型单独编写代码。它通过使用类型参数（Type Parameters）或泛型（Generics）来实现。
  > 泛型（Generics）： 想象一个列表（List）数据结构。你可以创建一个 List<Integer>，也可以创建一个 List<String>，甚至 List<Dog>。List 这个类本身并不关心它内部存储的是什么类型，它只是一个通用的模板。这里的 <T>（T 代表任意类型）就是类型参数。

- 子类型（也叫做子类型多态或包含多态）：一个名字指称很多不同的类的实例，这些类有某个共同的超类, 常见情况是一个对象可以被看作是其父类或接口的实例，从而可以在需要父类对象的地方使用子类对象。
  > 方法重写（Overriding）： 如您所说，一个名字可以指称很多不同的类实例，前提是这些类有共同的超类（父类）或实现了共同的接口。这是动态绑定的基础，也是运行时多态的核心。例如，Animal 类的引用可以指向 Dog 或 Cat 对象，并在调用 makeSound() 方法时，根据实际对象的类型执行不同的行为。

# Java 中的多态包含什么形式
## Java 中的特设多态
特设多态在Java中主要通过**方法重载（Method Overloading）**来实现。

- 概念： 允许在同一个类中定义多个同名方法，但它们的参数列表（数量、类型或顺序）必须不同。编译器会根据方法调用时传入的参数来决定使用哪个方法。这是一种编译时多态。
- 示例代码

```java
class Calculator {
    // 重载1：计算两个整数的和
    public int add(int a, int b) {
        return a + b;
    }

    // 重载2：计算两个双精度浮点数的和
    public double add(double a, double b) {
        return a + b;
    }

    // 重载3：计算三个整数的和
    public int add(int a, int b, int c) {
        return a + b + c;
    }
}

public class Main {
    public static void main(String[] args) {
        Calculator calc = new Calculator();
        System.out.println(calc.add(5, 10));         // 调用重载1
        System.out.println(calc.add(5.0, 10.0));     // 调用重载2
        System.out.println(calc.add(5, 10, 15));     // 调用重载3
    }
}
```

## Java 中的参数多态
参数多态在Java中通过**泛型（Generics）**来实现。

- 概念： 允许你编写可以处理多种类型数据的代码，而不需要为每种类型单独编写。它使用类型参数作为占位符，在实际使用时再指定具体类型。
- Java中的实现：
  - 泛型类： 像 `ArrayList<E>` 和 `Map<K, V>` 这样的集合类就是典型的泛型类。
  - 泛型方法： 可以在类或接口中定义一个泛型方法。

```java
// 泛型类示例：一个可以存储任意类型数据的容器
class Box<T> {
    private T content;

    public void setContent(T content) {
        this.content = content;
    }

    public T getContent() {
        return content;
    }
}

// 泛型方法示例：一个可以打印任意类型数组的方法
class Printer {
    public static <T> void printArray(T[] array) {
        for (T element : array) {
            System.out.print(element + " ");
        }
        System.out.println();
    }
}

public class Main {
    public static void main(String[] args) {
        Box<String> stringBox = new Box<>();
        stringBox.setContent("Hello");
        System.out.println(stringBox.getContent()); // 输出：Hello

        Integer[] intArray = {1, 2, 3};
        Printer.printArray(intArray); // 输出：1 2 3
    }
}
```
## Java 中的子类型多态
子类型多态是Java OOP的核心，通过方法重写（Method Overriding）和父类引用指向子类对象来实现。

- 概念： 允许一个父类引用变量指向它的任何子类对象，并在运行时调用子类重写的方法。这是一种运行时多态。
- Java中的实现：
  - 继承： 子类继承父类。
  - 重写 `Override`： 子类提供了父类中已有的方法的具体实现。
  - 动态绑定/动态链接： 编译器不知道具体调用哪个方法，直到程序运行时才会根据对象的实际类型来决定。
  
Java 中的子类型多态可以总结为以下规则

1. 使用父类类型的引用指向子类的对象； 
2. 该引用只能调用父类中定义的方法和变量； 
3. 如果子类中`Override`了父类中的一个方法，那么在调用这个方法的时候，将会调用子类中的这个方法；（动态连接、动态调用） 
4. 变量不能被`Override`（覆盖），`Override`的概念只针对方法，如果在子类中`Override`了父类中的变量，那么在编译时会报错。 

> `Override`和`Overload`不同的是，如果方法签名不同，就是`Overload`，`Overload`方法是一个新方法, 也就是就是前面提到的[**特设多态**](#java-中的特设多态)的方法重载实现；如果方法签名相同，并且返回值也相同，就是Override
{: .prompt-tip }

>方法名相同，方法参数相同，但方法返回值不同，也是不同的方法。在Java程序中，出现这种情况，编译器会报错。
{: .prompt-warning }

```java
// 父类
class Animal {
    public void makeSound() {
        System.out.println("动物发出声音");
    }
}

// 子类1
class Dog extends Animal {
    @Override
    public void makeSound() {
        System.out.println("汪汪汪");
    }
}

// 子类2
class Cat extends Animal {
    @Override
    public void makeSound() {
        System.out.println("喵喵喵");
    }
}

public class Main {
    public static void main(String[] args) {
        Animal myPet; // 父类引用

        // 这里定义了一个Animal类型的引用，指向新建的Cat类型的对象。
        // 由于Cat是继承自它的父类Animal,
        // 所以Animal类型的引用是可以指向Cat类型的对象的。这就是“向上转型”
        myPet = new Dog();
        myPet.makeSound(); // 在运行时调用Dog的makeSound，输出：汪汪汪

        myPet = new Cat();
        myPet.makeSound(); // 在运行时调用Cat的makeSound，输出：喵喵喵
    }
}
```

### 向上转型的含义

子类是对父类的一个改进和扩充，所以一般子类在功能上较父类更强大，属性较父类更独特， 定义一个父类类型的引用指向一个子类的对象既可以使用子类强大的功能，又可以抽取父类的共性。 所以，父类类型的引用可以调用父类中定义的所有属性和方法，而对于子类中定义而父类中没有的方法，父类引用是无法调用的

### 什么是动态链接

当父类中的一个方法只有在父类中定义而在子类中没有重写的情况下，才可以被父类类型的引用调用； 对于父类中定义的方法，如果子类中重写了该方法，那么父类类型的引用将会调用子类中的这个方法，这就是动态连接。

在上一节中，我们已经知道，引用变量的声明类型可能与其实际类型不符，例如：

```java
myPet = new Dog();
```

现在，我们考虑一种情况，如果子类覆写了父类的方法：

```java
// override
public class Main {
    public static void main(String[] args) {
        Person p = new Student();
        p.run(); // 应该打印Person.run还是Student.run?
    }
}

class Person {
    public void run() {
        System.out.println("Person.run");
    }
}

class Student extends Person {
    @Override
    public void run() {
        System.out.println("Student.run");
    }
}
```

那么，一个实际类型为`Student`，引用类型为`Person`的变量，调用其`run()`方法，调用的是`Person`还是`Student`的`run()`方法？

运行一下上面的代码就可以知道，实际上调用的方法是`Student`的`run()`方法。因此可得出结论：

Java的实例方法调用是基于运行时的实际类型的动态调用，而非变量的声明类型。

举个更加极端的例子:

```java
public void runTwice(Person p) {
    p.run();
    p.run();
}
```

runTwice传入的参数类型是`Person`，我们是无法知道传入的参数实际类型究竟是`Person`，还是`Student`，还是`Person`的其他子类例如`Teacher`，因此，也无法确定调用的是不是`Person`类定义的`run()`方法。

所以，多态的特性就是，运行期才能动态决定调用的子类方法。对某个类型调用某个方法，执行的实际方法可能是某个子类的覆写方法。

### Super使用

在子类的覆写方法中，如果要调用父类的被覆写的方法，可以通过`super`来调用。例如：

```java
class Person {
    protected String name;
    public String hello() {
        return "Hello, " + name;
    }
}

class Student extends Person {
    @Override
    public String hello() {
        // 调用父类的hello()方法:
        return super.hello() + "!";
    }
}
```

### Final 的使用

继承可以允许子类覆写父类的方法。如果一个父类不允许子类对它的某个方法进行覆写，可以把该方法标记为`final`。用`final`修饰的方法不能被`Override`

```java
class Person {
    protected String name;
    public final String hello() {
        return "Hello, " + name;
    }
}

class Student extends Person {
    // compile error: 不允许覆写
    @Override
    public String hello() {
    }
}
```

如果一个类不希望任何其他类继承自它，那么可以把这个类本身标记为`final`。用`final`修饰的类不能被继承：

```java
final class Person {
    protected String name;
}

// compile error: 不允许继承自Person
class Student extends Person {
}

```

对于一个类的实例字段，同样可以用final修饰。用final修饰的字段在初始化后不能被修改。例如：

```java
class Person {
    public final String name = "Unamed";
}
```

对 final 字段重新赋值会报错

也可以在构造方法中初始化final字段：

```java
class Person {
    public final String name;
    public Person(String name) {
        this.name = name;
    }
}
```

这种方法更为常用，因为可以保证实例一旦创建，其final字段就不可修改。

### 覆写Object方法

因为所有的class最终都继承自Object，而Object定义了几个重要的方法：

- `toString()`：把instance输出为String；
- `equals()`：判断两个instance是否逻辑相等；
- `hashCode()`：计算一个instance的哈希值。
  
在必要的情况下，我们可以覆写Object的这几个方法。

# Java 中的多态的实现原理

## 特设多态(方法重载 Overload)实现原理
特设多态在 Java 中的实现是方法重载 (Method Overloading)，其底层机制完全是编译期行为。

- 实现机制：当编译器遇到方法调用时，它会根据调用时提供的参数类型、数量和顺序，在**符号表 (Symbol Table)**中查找最匹配的方法签名 (Method Signature)。方法签名包含了方法名和参数列表，不包括返回值类型。
- 底层原理：在编译过程中，`javac` 编译器会为每个重载的方法生成唯一的、带有参数类型信息的内部名称。例如，`add(int, int)` 和 `add(double, double)` 在字节码中可能被表示为类似 `add_int_int` 和 `add_double_double` 的形式。在 `invokevirtual` 或 `invokestatic` 指令中，会直接指向这个唯一的方法。因此，在运行时，JVM 不需要进行额外的查找，直接就能调用正确的方法。这是一种静态绑定。

## 参数多态(泛型)实现原理

参数多态在 Java 中通过泛型 (Generics) 实现，其底层机制主要是编译期的类型擦除 (Type Erasure)。

**实现机制**：在源代码中，你可以使用类型参数（如 `<T>`）来定义泛型类、接口和方法，实现代码的通用性。

**底层原理**：

- 类型检查：在编译时，编译器会利用泛型信息进行严格的类型检查，确保你在泛型容器中放入和取出的是正确的类型。
- 类型擦除：编译完成后，所有的泛型信息都会被擦除。类型参数会被其上界（通常是 `Object`）替换。例如，`List<String>` 在编译后会变成 `List`，所有对 `String` 类型的操作都会被编译器插入强制类型转换的代码。
- 桥接方法 (Bridge Method)：如果泛型类继承了非泛型类或实现了非泛型接口，并且重写了方法，编译器会生成一个“桥接方法”来确保多态的兼容性。

这种设计使得泛型在 Java 中是伪泛型，其主要作用在于编译期的类型安全检查，而不是在运行时提供真正的类型参数化。

## 子类型多态(继承机制)实现原理

子类型多态在 Java 中的实现是方法重写 (Method Overriding)，其底层机制是运行期的动态绑定 (Dynamic Binding)。

**实现机制**：通过继承，子类可以重写父类的方法。父类类型的引用可以指向子类的实例，并在调用重写方法时，实际执行的是子类的实现。

**底层原理**：

**虚方法表 (Virtual Method Table / VMT / vtable)**：在类加载时，JVM 会为每个类创建一个虚方法表。这个表是一个函数指针（在 JVM 中是方法地址的引用）数组，它包含了该类所有虚方法（可以被重写的方法）的入口。

**方法调用**：当 JVM 遇到 invokevirtual 指令（用于调用虚方法）时，它会：

- 获取栈上对象的实际类型。
- 在对象的虚方法表中，根据方法签名查找对应的方法地址。
- 调用该地址指向的、属于子类的具体方法实现。

这个过程发生在运行时，因为只有在运行时 JVM 才知道对象的实际类型，从而可以沿着继承链找到正确的虚方法表。这种延迟到运行时的绑定，就是动态链接或晚期绑定的核心。

# 参考
- [父类引用指向子类对象](https://blog.csdn.net/gideal_wang/article/details/4913965)
- [多态-Java教程](https://liaoxuefeng.com/books/java/oop/basic/polymorphic/index.html)