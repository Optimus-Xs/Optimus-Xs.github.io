---
layout: post
title: Java 注解使用
date: 2020-11-13 14:40 +0800
categories: [Software Development] 
tags: [Java]
---

# 注解概述
## 注解的定义
注解，顾名思义，就是对某一事物添加注释说明，其会存放一些信息，这些信息可能对以后某个时段来说是很有用处的。
Java注解又叫java标注，java提供了一套机制，使得我们可以对包、类、方法、域、参数、变量等添加标注(即附上某些信息)，且在以后某个时段通过反射将标注的信息提取出来以供使用

官网描述如下:

> Java 注解用于为 Java 代码提供元数据。作为元数据，注解不直接影响你的代码执行，但也有一些类型的注解实际上可以用于这一目的。Java 注解是从 Java5 开始添加到 Java 的。

将上面的话再翻译一下，如下：
- 元数据在开发中的作用就是做数据约束和标准定义，可以将其理解成代码的规范标准（代码的模板）；
- 代码的模板（元数据）不直接影响代码的执行，它只是帮助我们来更快捷的开发；

综上，注解是一种元数据，可以将它理解为注释、解释，它为我们在代码中添加信息提供了一种形式化的方法，它用于帮助我们更快捷的写代码。

## 注解的作用

在说注解的用途之前，我们先介绍下XML和注解区别：

注解：是一种分散式的元数据，与源代码紧绑定。
xml：是一种集中式的元数据，与源代码无绑定
这部分多用于Java后台的配置项开发中，我们知道几年前服务器的配置项多存放在一个xml文件中，而spring 2.5 之后开始基于注解配置，从而实现了代替配置文件的功能。
注解的用途有很多，上面的只是一个简单的例子，总起起来，注解有如下四大部分作用：

1. 生成文档，通过代码里标识的元数据生成javadoc文档。
2. 编译检查，通过代码里标识的元数据让编译器在编译期间进行检查验证。
3. 编译时动态处理，编译时通过代码里标识的元数据动态处理，例如动态生成代码。
4. 运行时动态处理，运行时通过代码里标识的元数据动态处理，例如使用反射注入实例

# 注解的分类
一般常用的注解可以分为三类：
1. Java自带的标准注解
<br>包括@Override、@Deprecated、@SuppressWarnings等，使用这些注解后编译器就会进行检查。

2. 元注解
元注解是用于定义注解的注解，包括@Retention、@Target、@Inherited、@Documented、@Repeatable 等。
<br>元注解也是Java自带的标准注解，只不过用于修饰注解，比较特殊。

3. 自定义注解
<br>用户可以根据自己的需求定义注解。


## Java自带的标准注解
常用的Java注解如下：

1. @Deprecated – 所标注内容不再被建议使用；
2. @Override – 只能标注方法，表示该方法覆盖父类中的方法；
3. @Documented - 所标注内容可以出现在javadoc中；
4. @Inherited – 只能被用来标注“Annotation类型”，它所标注的Annotation具有继承性；
5. @Retention – 只能被用来标注“Annotation类型”，而且它被用来指定Annotation的RetentionPolicy属性；
6. @Target – 只能被用来标注“Annotation类型”，而且它被用来指定Annotation的ElementType属性；
7. @SuppressWarnings – 所标注内容产生的警告，编译器会对这些警告保持静默；
8. @interface – 用于定义一个注解；

> 其中，4、5、6、8多用于自定义注解，着重记一下。
{: .prompt-tip }

## 元注解
常用的元注解有@Retention、 @Target、 @Document、 @Inherited和@Repeatable五个。
### @Retention
Retention英文意思有保留、保持的意思，它表示注解存在阶段是保留在源码（编译期），字节码（类加载）或者运行期（JVM中运行）。

在@Retention注解中使用枚举RetentionPolicy来表示注解保留时期：

- @Retention(RetentionPolicy.SOURCE)，注解仅存在于源码中，在class字节码文件中不包含
- @Retention(RetentionPolicy.CLASS)， 默认的保留策略，注解会在class字节码文件中存在，但运行时无法获得
- @Retention(RetentionPolicy.RUNTIME)， 注解会在class字节码文件中存在，在运行时可以通过反射获取到, 操作方法看AnnotatedElement(所有被注释类的父类) 

如果我们是自定义注解，则通过前面分析，我们自定义注解如果只存着源码中或者字节码文件中就无法发挥作用，而在运行期间能获取到注解才能实现我们目的，所以自定义注解中肯定是使用 @Retention(RetentionPolicy.RUNTIME)，如下：
```java
@Retention(RetentionPolicy.RUNTIME)
  public @interface MyTestAnnotation {
}
```


### @Target
Target的英文意思是目标，这也很容易理解，使用@Target元注解表示我们的注解作用的范围就比较具体了，可以是类，方法，方法参数变量等，同样也是通过枚举类ElementType表达作用类型：

- @Target(ElementType.TYPE) 作用接口、类、枚举、注解
- @Target(ElementType.FIELD) 作用属性字段、枚举的常量
- @Target(ElementType.METHOD) 作用方法
- @Target(ElementType.PARAMETER) 作用方法参数
- @Target(ElementType.CONSTRUCTOR) 作用构造函数
- @Target(ElementType.LOCAL_VARIABLE)作用局部变量
- @Target(ElementType.ANNOTATION_TYPE)作用于注解（@Retention注解中就使用该属性）
- @Target(ElementType.PACKAGE) 作用于包
- @Target(ElementType.TYPE_PARAMETER) 作用于类型泛型，即泛型方法、泛型类、泛型接口 （jdk1.8加入）
- @Target(ElementType.TYPE_USE) 类型使用.可以用于标注任意类型除了 class （jdk1.8加入）
  
一般比较常用的是ElementType.TYPE类型，如下：
```java
  @Retention(RetentionPolicy.RUNTIME)
  @Target(ElementType.TYPE)
  public @interface MyTestAnnotation {
  
  }
```

ElementType.TYPE_PARAMETER的用法示例
```java
class D<@PTest T> { } // 注解@PTest作用于泛型T
```
ElementType.TYPE_USE的用法示例
```java
//用于父类或者接口 
class Test implements @Parent TestP {} 

//用于构造函数
new @Test String("/usr/data")

//用于强制转换和instanceof检查,注意这些注解中用于外部工具
//它们不会对类型转换或者instanceof的检查行为带来任何影响
String path=(@Test String)input;
if(input instanceof @Test String) //注解不会影响

//用于指定异常
public Person read() throws @Test IOException.

//用于通配符绑定
List<@Test ? extends Data>
List<? extends @Test Data>

@Test String.class //非法，不能标注class
```


### @Document
Document的英文意思是文档。它的作用是能够将注解中的元素包含到 Javadoc 中去。

### @Inherited
Inherited的英文意思是继承，但是这个继承和我们平时理解的继承大同小异，一个被@Inherited注解了的注解修饰了一个父类，如果他的子类没有被其他注解修饰，则它的子类也继承了父类的注解。

子类Class\<T\>通过getAnnotations()可获取父类被@Inherited修饰的注解。而注解本身是不支持继承
```java
@Inherited
@Retention( value = RetentionPolicy.RUNTIME)
@Target(value = ElementType.TYPE)
public @interface ATest {  }
----被ATest注解的父类PTest----
@ATest
public class PTest{ }

---Main是PTest的子类----
public class Main extends PTest {
    public static void main(String[] args){
        Annotation an = Main.class.getAnnotations()[0];
          //Main可以拿到父类的注解ATest，因为ATest被元注解@Inherited修饰
        System.out.println(an);
    }
}  
---result--
@com.ATest()  
```

### @Repeatable
JDK1.8新加入的，表明自定义的注解可以在同一个位置重复使用。在没有该注解前，是无法在同一个类型上使用相同的注解多次

Repeatable的英文意思是可重复的。顾名思义说明被这个元注解修饰的注解可以同时作用一个对象多次，但是每次作用注解又可以代表不同的含义。
```java
  //Java8前无法重复使用注解
  @FilterPath("/test/v2")
  @FilterPath("/test/v1")
  public class Test {}
```

## 自定义注解
在Java中，我们使用@interface注解来自定义一个注解，如下：
```java
public @interface MyTestAnnotation {

}
```
此时，我们已经定义了一个注解MyTestAnnotation ，接着我们就可以在类或者方法上作用我们刚刚新建的注解：
```java
@MyTestAnnotation
public class Test {
   @MyTestAnnotation
   public static void testString(){
   }
}
```
此时，我们已经自定义了一个注解，不过现在这个注解毫无意义。

要如何使注解工作呢？这就需要使用元注解了。

这时候就需要使用java内置的四个元注解对自定义注解的功能和范围进行一些限制


# 注解的使用
## 使用Java自带的注解
Java 自带的注解，就是 java.lang中定义的一套注解，以Override注解为例，使用方法如下：
```java
@Override         //在需要注解的方法上面@Override即可
protected void onCreate() {
      
}
```

## 自定义注解
使用@interface自定义注解时，自动继承了java.lang.annotation.Annotation接口，由编译程序自动完成其他细节。在定义注解时，不能继承其他的注解或接口。@interface用来声明一个注解，其中的每一个方法实际上是声明了一个配置参数。方法的名称就是参数的名称，返回值类型就是参数的类型（返回值类型只能是基本类型、Class、String、enum）。可以通过default来声明参数的默认值。

定义注解格式
```java
public @interface 注解名 {定义体}
```

注解参数的可支持数据类型

- 所有基本数据类型（int,float,boolean,byte,double,char,long,short)
- String类型
- Class类型
- enum类型
- Annotation类型
- 以上所有类型的数组

下面通过源码来展示自定义注解：
首先，我们自定义一个注解：AuthorAnnotation 来标记作者的信息

```java
/**
 * 自定义注解：作者信息注解
 */
@Target(ElementType.FIELD)
@Retention(RetentionPolicy.RUNTIME)
@Documented
public @interface AuthorAnnotation {
	// 名字
	String name();
	// 年龄
	int age() default 19;
	// 性别
	String gender() default "男";
}
```
其次，再定义一个注解：BookAnnotation 来标记故事书籍的内容信息
```java
/**
 * 自定义注解：树的信息注解
 */
@Target({ ElementType.TYPE, ElementType.METHOD })
@Retention(RetentionPolicy.RUNTIME)
@Documented
@Inherited
public @interface BookAnnotation {
	// 书名
	String bookName();
	// 女主人公
	String heroine();
	// 书的简介
	String briefOfBook();
	// 书的销量
	int sales() default 10000;
}
```
最后，我们定义一种类型的书：LoveStoryBook，类注解标记的是《硅谷之火》，为了区分，方法注解标记的是《think in java》
```java
/**
 * 爱的故事
 */
@BookAnnotation(bookName = "硅谷之火",
				briefOfBook = "本书以一个个生动的故事，介绍了这些计算机业余爱好者以怎样的创新精神和不懈的努力，将计算机技术的力量包装在一个小巧玲珑的机壳里，实现了个人拥有计算机的梦想",
				sales = 1000001)
public class LoveStoryBook {
	@AuthorAnnotation(name = "迈克尔.斯韦因", gender = "男")
	private String user;
	@BookAnnotation(bookName = "think in java",
			briefOfBook = "本书详细地阐述了面向对象原理。覆盖了所有基础知识,同时论述了高级特性,适合初学者与专业人员的经典的面向对象叙述方式,为更新的Java SE5/6增加了新的示例和章节",
			sales = 100000)
	public void getBookInfo(){
	}
}
```
注解解析

上面已经将要注解的类和两个注解类实现了，下面定义一个类：ParseAnnotation，来解析我们自定义的注解

```java
public class ParseAnnotation {
	/**
	 *
	 * 解析类注解
	 * LoveStoryBook
	 * @throws ClassNotFoundException
	 */
    public static void parseTypeAnnotation() throws ClassNotFoundException{
        @SuppressWarnings("rawtypes")
		Class clazz = Class.forName("com.akathink.entity.LoveStoryBook");
        Annotation[] annotations = clazz.getAnnotations();
        for (Annotation annotation : annotations) {
            BookAnnotation bookAnnotation = (BookAnnotation) annotation;
            System.out.println("书名：" + bookAnnotation.bookName() + "\n" +
            					"书的简介：" + bookAnnotation.briefOfBook() + "\n"+
            					"书的销量：" + bookAnnotation .sales() + "\n");
        }
    }
 /**
  * 解析方法注解
  * @throws ClassNotFoundException
  */
    public static void parseMethodAnnotation() throws ClassNotFoundException{
        Method[] methods = LoveStoryBook.class.getDeclaredMethods();
        for (Method method : methods) {
             /*
             * 判断方法中是否有指定注解类型的注解
             */  
            boolean hasAnnotation = method.isAnnotationPresent(BookAnnotation.class);
            if(hasAnnotation){
            	 BookAnnotation bookAnnotation = (BookAnnotation) method.getAnnotation(BookAnnotation.class);
                 System.out.println("书名：" + bookAnnotation.bookName() + "\n" +
                 					"书的简介：" + bookAnnotation.briefOfBook() + "\n"+
                 					"书的销量：" + bookAnnotation .sales() + "\n");
            }
        }
    }
  /**
   * 解析域注解
   * @throws ClassNotFoundException
   */
    public static void parseFieldAnnotation() throws ClassNotFoundException{
        Field[] fields = LoveStoryBook.class.getDeclaredFields();
        for (Field field : fields) {
            boolean hasAnnotation = field.isAnnotationPresent(AuthorAnnotation.class);
            if(hasAnnotation){
            	AuthorAnnotation authorAnnotation = field.getAnnotation(AuthorAnnotation.class);
            	 System.out.println("作者：" +authorAnnotation.name() + "\n" +
      					"性别：" + authorAnnotation.gender() + "\n");
            }
        }
    }
}
```
最后的最后就是验证我们自定义的注解是否正确
```java
public class AnnotationDemo {
	public static void main(String[] args) throws ClassNotFoundException {
		//解析域的注解
		System.out.println("下面是解析域的注解信息：\n\n");
		ParseAnnotation.parseFieldAnnotation();
		//解析方法的注解
		System.out.println("下面是解析方法的注解信息：\n\n");
		ParseAnnotation.parseMethodAnnotation();
		//解析类的注解
		System.out.println("下面是解析类的注解信息:\n\n");
		ParseAnnotation.parseTypeAnnotation();
	}
}
```
```
下面是解析域的注解信息：
作者：迈克尔.斯韦因
性别：男
下面是解析方法的注解信息：
书名：think in java
书的简介：本书详细地阐述了面向对象原理。覆盖了所有基础知识,同时论述了高级特性,适合初学者与专业人员的经典的面向对象叙述方式,为更新的Java SE5/6增加了新的示例和章节
书的销量：100000
下面是解析类的注解信息:
书名：硅谷之火
书的简介：本书以一个个生动的故事，介绍了这些计算机业余爱好者以怎样的创新精神和不懈的努力，将计算机技术的力量包装在一个小巧玲珑的机壳里，实现了个人拥有计算机的梦想
书的销量：1000001
```
>注意
>
>- 对局部变量的注解只能在源码级别上进行处理，class文件并不描述局部变量。因此，所有的局部变量注解在编译完一个类的时候就会被遗弃掉。同样的，对包的注解不能在源码级别之外存在。
>- 一条没有@Target限制的注解可以应用于任何项上。
>- @Inherited元注解只能应用于对类的注解
{: .prompt-tip }

## 通过反射访问注解
程序通过反射获取了某个类的对象之后，程序就可以调用该对象的如下四个方法来访问注解信息：

- 方法1： T getAnnotation(Class annotationClass)：返回该程序元素上存在的、指定类型的注解，如果该类型注解不存在，则返回null
- 方法2：Annotation[] getAnnotations()：返回该程序元素上存在的所有注解
- 方法3：boolean is AnnotationPresent(Class<?extends Annotation> annotationClass)：判断该程序元素上是否包含指定类型的注解，存在，则返回true；否则，返回false
- 方法4：Annotation[] getDeclaredAnnotations()：返回直接存在于此元素上的所有注解。与其他方法不同的是，该方法将忽略继承的注释。如果没有注解直接存在于此元素上，则返回长度为零的一个数组，该方法的调用者可以随意修改返回的数组，可是，这不会对其他调用者返回的数组产生任何影响。


